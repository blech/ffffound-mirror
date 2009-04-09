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

sql = "select orig_url, id from images where orig_url like '%flickr%'"
db.execute(sql) do |row|
  flickr = row[0]
  ffffound_id = row[1]
  
  flickr_id = id_from_url(flickr)
  if not flickr_id
    puts flickr
  else
    puts flickr_id, ffffound_id
  end
end

