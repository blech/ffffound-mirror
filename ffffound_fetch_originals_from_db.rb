#!/usr/bin/ruby
require 'rubygems'

require 'etc' 
require 'hpricot'
require 'json'
require 'open-uri'
require 'sqlite3'
require 'time'
require 'date'

def fetch_orignals(db)
  filenames = {}

  images_sql = "SELECT orig_src from images"

  db.execute( images_sql ) do |orig_src|
    src = orig_src[0]
    parts = src.split('/')
    filename = parts[-1]

    # handle filename collisions, more or less
    if filenames[filename]:

      if src == filenames[filename]:
      	next
      end

      if src.match('bbc.co.uk'):
      	filename = parts[-3]+"-"+parts[-1]
	next

      else
      	filename = parts[0]+"-"+parts[-1]
      	
      	# double-check
      	if filenames[filename]:
      	  puts "!!!! still colliding"
	  # should rescue, but...
      	  next
      	end
      end

    end   

    filenames[filename] = src

    url = "http://" + src
    
    download_file(url, filename)
  end
end

def download_file(url, filename)
  # does it exist?
  if not File.exist?('originals/'+filename):
  
    begin
      writeOut = open("originals/"+filename, 'wb')

      # TODO find out if there's anything to save
      # (rather than create 0 byte files)_

      writeOut.write(open(url).read)
      writeOut.close
    
      puts '  downloaded ' + url + " to " + filename
    rescue
      puts '! error with '+url
    end
    
  else
    puts '- already downloaded '+url+' to '+filename
    
  end

end

# this needs work
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

begin
  FileUtils.mkdir "originals"
rescue
end

path = 'db/ffffound-'+user+'.db' # ick
db = SQLite3::Database.new(path)

fetch_orignals(db)
exit

# puts img.to_json 
# DONE puts img.to_database_table(s)
