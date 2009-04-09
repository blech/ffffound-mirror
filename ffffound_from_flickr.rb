#!/usr/bin/ruby
require 'rubygems'

require 'etc' 
require 'hpricot'
require 'json'
require 'open-uri'
require 'sqlite3'
require 'time'
require 'date'

path = Etc.getpwuid.dir + '/.ffffound.db' # ick
db = SQLite3::Database.new(path)

def id_from_url(flickr)
  m = flickr.match(/photos\/.*?\/([\d]+)/)
  if !m.nil?
    return m[1]
  end
  
  m = flickr.match(/gne\?id=([\d]+)/)
  if !m.nil?
    return m[1]
  end

end

sql = "select orig_url, id, count from images where orig_url like '%flickr%'"
db.execute(sql) do |row|
  flickr = row[0]
  ffffound_id = row[1]
  count = row[2]
  
  flickr_id = id_from_url(flickr)
  if not flickr_id
    puts "Could not find Flickr image ID from url #{flickr}"
    die
  else
    puts "#{ffffound_id} => #{flickr_id} (#{count} bookmarks)"
  end
end

