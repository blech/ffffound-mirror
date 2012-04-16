#!/usr/bin/ruby
require 'rubygems'

require 'etc'
require 'hpricot'
require 'json'
require 'open-uri'
require 'sqlite3'
require 'time'
require 'date'
require 'oauth'

# oauth config for tumblr
@key = ""
@secret = ""

# I should fix these
@path = 'db/ffffound-blech.db' # ick
@site = 'found.husk.org'

def auth_tumblr()
  consumer = OAuth::Consumer.new(@key, @secret,
                                 { :site => 'http://www.tumblr.com',
                                   :request_token_path => '/oauth/request_token',
                                   :authorize_path => '/oauth/authorize',
                                   :access_token_path => '/oauth/access_token',
                                   :http_method => :post })
  
  request_token = consumer.get_request_token(:oauth_callback => 'oob')
  puts "please visit "+request_token.authorize_url+" and paste the code here"
  
  oauth_verifier = gets.strip
  
  access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
  return access_token
end

def upload_image_to_tumblr(access_token, image_path, source, timestamp)
  image_data = IO.read(image_path)
  
  r = access_token.post("http://api.tumblr.com/v2/blog/#{@site}/post",
                        { :type => "photo",
                          :state => "draft",
                          :date => timestamp,
                          :link => source,
                          :data => image_data,
                        })

  if r.code != 201
    puts "This image did not upload; aborting"
    puts r.body()
    abort
  end
  return JSON.parse(r.body())
end

def prepare_upload(row, images_ins)
  image_path = "images/#{row[0]}.jpg"
  if not File.exists?(image_path):
    puts "#{image_path} not found (original URL #{row[1]})"
    return
  end

  source = row[1]
  epoch = row[2]
  timestamp = Time.at(epoch.to_i).strftime("%Y-%m-%d %H:%M:%S GMT")
  # related = row[3].split(',')
  puts "Uploading image path #{image_path} from #{timestamp} (#{source})"
  
  response = upload_image_to_tumblr(access_token, image_path, source, timestamp)

  if response['meta']['status'] == 201
    info = {:ffffound_id => row[0], 
            :tumblr_id => response['response']['id'], 
            :create_status => response['meta']['status']}
    images_ins.bind_params(info)
    images_ins.execute
  else
    puts response
  end
end

# ok we're all set. Now to do the work.
def upload_images_from_db(access_token)
  db = SQLite3::Database.new(@path)
  find_sql = <<EOS
SELECT images.id, orig_url, date, related, posted 
  FROM images 
  LEFT OUTER JOIN tumblr ON images.id = tumblr.ffffound_id
 WHERE tumblr.ffffound_id is null AND date != '0' 
 ORDER BY date ASC
EOS

  insert_sql = <<EOS
INSERT OR REPLACE INTO 
  tumblr (ffffound_id, tumblr_id, create_status) 
  values (:ffffound_id, :tumblr_id, :create_status)
EOS
  images_ins  = db.prepare(insert_sql)
  
  db.execute(find_sql) do |row|
    prepare_upload(row, images_ins)
  end
end

def publish_uploaded_images(access_token)
  db = SQLite3::Database.new(@path)
  
  find_sql = <<EOS
    SELECT tumblr_id, images.id AS ffffound_id, date, orig_url 
      FROM tumblr, images 
     WHERE tumblr.ffffound_id = images.id
       AND tumblr.published IS NULL
     LIMIT 50
EOS
  
  update_sql = "UPDATE tumblr SET tumblr_id=:new_id, published=1 WHERE tumblr_id=:id"
  update_ins  = db.prepare(update_sql)
  
  db.execute(find_sql) do |row|
    tumblr_id = row[0]
    
    # fix time (in case it doesn't stick when marking as published)
    # (which is something I should check...)
    epoch = row[2]
    timestamp = Time.at(epoch.to_i).strftime("%Y-%m-%d %H:%M:%S GMT")
    puts "for #{tumblr_id} timestamp is #{timestamp}"
    
    # build tags
    tags = "ffffound:id=#{row[1]}, "
    domain = row[3].split('/')[2]
    tags << "original:domain=#{domain}, "
    
    if domain.index('flickr.com')
      url_parts = row[3].split('/')
      if url_parts[3] == "photos"
        tags << "flickr:url=http://www.flickr.com/photos/#{url_parts[4]}/#{url_parts[5]}/, "
      end
    end
    
    r = access_token.post("http://api.tumblr.com/v2/blog/#{@site}/post/edit",
                          { :id => tumblr_id,
                            :state => "published",
                            :tags => tags,
                          })
    
    begin
      response = JSON.parse(r.body())
    rescue JSON::ParserError => e
      puts "JSON parsing error: #{e}"
      puts "Response code: #{r.code}"
      puts "Response body: #{r.body()}"
      next
    end

    if response['meta']['status'] == 200
      new_id = response['response']['id']
      info = {:new_id => new_id, :id => tumblr_id}
      update_ins.bind_params(info)
      update_ins.execute()
      
      # update date and time on 'new' image
      r = access_token.post("http://api.tumblr.com/v2/blog/#{@site}/post/edit",
                            { :id => new_id,
                              :date => timestamp,
                              :tags => tags,
                            })
      puts "updating time: got response #{r.body()}\n"
      puts "Visit this post: http://bbbblech.tumblr.com/post/#{new_id}/\n"
_    else
      puts "This image did not publish: #{tumblr_id}\n  #{r.body()}"
    end
  end
end

access_token = auth_tumblr()

user_info = access_token.get("http://api.tumblr.com/v2/user/info")
puts user_info

# upload_images_from_db(access_token)
publish_uploaded_images(access_token)

