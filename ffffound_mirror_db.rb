#!/usr/bin/ruby
require 'rubygems'

require 'etc' 
require 'hpricot'
require 'json'
require 'open-uri'
require 'sqlite3'
require 'time'
require 'date'

def populate_db(db, user, type)
  domain = "http://ffffound.com/"
  offset = 0

  images_sql = <<EOS
  INSERT OR REPLACE INTO 
      images (id, url, src, title, orig_url, orig_src, count, date, related) 
      values (:id, :ffffound_url, :ffffound_img, :title, :orig_url, :orig_img, :count, :date, :rel)
EOS

  images_ins  = db.prepare(images_sql)
  # related_ins = db.prepare( "insert into related values (?, ?, ?)" )
  
  img = []
  
  while
    if user == "all" # wow, this is naughty
      doc = Hpricot(open("#{ domain }/?offset=#{ offset }&"))
    else
      doc = Hpricot(open("#{ domain }/home/#{ user }/#{ type }/?offset=#{ offset }&"))
    end
    
    images = (doc/"blockquote.asset")
    puts "Got #{ images.size.to_s } images at offset #{ offset.to_s }"
    break if (images.size == 0)
    
    images.each do |image|
      # can I make this block into a method somehow?
      info = {}
    
      # image title
      title_elem = (image/"div.title")
      info[:title] = title_elem.at("a").inner_html
    
      # original source image
      src_elem = (image/"div.title")
      info[:orig_url] = src_elem.at("a")["href"]
      
      # from description, break out img url, date posted (relative!), count
      desc_elem = (image/"div.description")
      desc = desc_elem.inner_html
      info[:orig_img] = desc.gsub(/<br ?\/?>.*/, "")
    
      datestr  = desc.gsub(/.*<br ?\/?>/, "")
      datestr  = datestr.gsub(/<a h.*/, "")
      datestr  = datestr+" +0900" # ffffound uses Japanese time, UTC +0900
      begin
        dt = Time.parse(datestr)
      rescue
      end
      info[:date] = dt.to_i
    
      count    = desc_elem.at("a").inner_text
      count    = count.gsub(/[\D]/, "")
      info[:count] = count
    
      # ffffound image URL and page URL, and ffffound ID (could generate
      # URL from ID but would lose ?c form; src would lose _m)
      image_block = (image/"table td")
      ffffound_url = image_block.at("a")['href']
      ffffound_img = image_block.at("img")['src']
    
      id = ffffound_img
      id = ffffound_img.split('/')[6]
      id = id.gsub(/_.*/, "")
      info[:id] = id
    
      info[:ffffound_url] = ffffound_url
      info[:ffffound_img] = ffffound_img
    
      download_file(ffffound_img, id)
    
      # might as well get related asset IDs
      rel = Array.new
      
      relateds = (image/"div.related_to_item_xs")
      relateds.each do |related|
        path = related.at("a")['href']
        id   = path[ path.index(/\//, 2)+1 .. -1 ]
        rel.push(id)
        # TODO normalised table for related IDs
      end
    
      info[:rel] = rel.join(",")
      img.unshift(info)
  
      # put in db
      images_ins.bind_params(info)
      images_ins.execute
  
    end
  
    break if (images.size < 25) # more efficient than doing another fetch
    offset = offset + 25
  end
  
  puts "Got #{ img.size } images"
end

def create_db(db)
  images = <<EOC
    CREATE TABLE IF NOT EXISTS
        images  (id TEXT PRIMARY KEY,
                 url TEXT,
                 src TEXT,
                 title TEXT,
                 orig_url TEXT,
                 orig_src TEXT,
                 date INTEGER,
                 count INTEGER,
                 related TEXT,
                 posted BOOL);
EOC
  
  related = <<EOC
    CREATE TABLE IF NOT EXISTS
        related  (id INTEGER PRIMARY KEY,
                  source INTEGER
                  related INTEGER);
EOC

  tumblr = <<EOC
    CREATE TABLE tumblr  (id INTEGER PRIMARY KEY,
                     ffffound_id TEXT,
                     tumblr_id INTEGER,
                     create_status INTEGER,
                     edit_status INTEGER);
EOC
  
  db.execute(images)
  db.execute(related)
  
  return true
end

def download_file(url, id)
  # TODO file type awareness
  # does it exist?
  if not File.exist?('images/'+id+'.jpg'):
  
    writeOut = open("images/"+id+'.jpg', 'wb')
    writeOut.write(open(url).read)
    writeOut.close
    
    puts '  downloaded ' + id
  end
end

def create_paths()
  ['images', 'db'].each do |path|
    if not File.exist?(path):
      FileUtils.mkdir(path)
    end
  end
end

# this needs work (is there a more idiomatic way to do this?)
user = ARGV[0] 
type = ARGV[1] || 'found'

if not user:
  puts "A ffffound username must be supplied"
  exit
else
  if user == "--all"
     puts "Invoked for all posts"
     user = "all"
  end
  puts "Invoked for posts by #{user} of type #{type}"
end

create_paths()

path = 'db/ffffound-'+user+'.db' # ick
db = SQLite3::Database.new(path)

create_db(db)
populate_db(db, user, type)
exit

# puts img.to_json 
# DONE puts img.to_database_table(s)
