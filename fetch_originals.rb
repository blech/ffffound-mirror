#!/usr/bin/ruby
require 'rubygems'

require 'open-uri'
require 'sqlite3'
require 'fileutils'

def fetch_orignals(db)
  filenames = {}

  images_sql = "SELECT id, orig_src from images"

  db.execute( images_sql ) do |row|
    id = row[0]
    src = row[1]

    # this needs work
    filetype = src.split('.')[-1][0,3]
    if filetype == "jpe"
        filetype = "jpg"        
    end

    filename = id+"."+filetype
    url = "http://" + src

    download_file(url, filename, id)
  end
end

def download_file(url, filename, id)
  # does it exist?
  if File.exist?('images/originals/'+filename)
    puts '- already downloaded '+url+' to '+filename
    return
  end
    
  begin
    image_data = open(url).read
  rescue
    puts '  error with '+url
    return
  end
  
  puts "image #{id}"
  puts "remote size #{image_data.length}"
  puts "local size  "+File.size("images/#{id}.jpg").to_s

  if image_data.length > File.size("images/#{id}.jpg")
    writeOut = open("images/originals/"+filename, 'wb')
    writeOut.write(image_data)
    writeOut.close
    puts '+ downloaded ' + url + " to " + filename
  else
    puts '  downloaded image was no bigger: not saved'
  end

  puts ""  
end

# this needs work
user = ARGV[0] 
type = ARGV[1] || 'found'

if not user
  puts "A ffffound username must be supplied"
  exit
else
  if user == "--all"
     puts "Invoked for all posts"
     user = "all"
  end
  puts "Invoked for posts by #{user} of type #{type}"
end

if not File.exist?("images/originals")
    FileUtils.mkdir "images/originals"
end

path = 'db/ffffound-'+user+'.db' # ick
db = SQLite3::Database.new(path)

fetch_orignals(db)
exit

# puts img.to_json 
# DONE puts img.to_database_table(s)
