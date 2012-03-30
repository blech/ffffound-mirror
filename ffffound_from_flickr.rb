#!/usr/bin/ruby
require 'rubygems'

require 'etc' 
require 'hpricot'
require 'json'
require 'open-uri'
require 'sqlite3'
require 'time'
require 'date'
require 'flickraw'

FlickRaw.api_key = ""
FlickRaw.shared_secret = ""
# FlickRaw.secure = true

def auth_flickr()
  token = flickr.get_request_token
  auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')
  
  puts "Open this url in your process to complete the authication process : #{auth_url}"
  puts "Copy here the number given when you complete the process."
  verify = gets.strip
  
  begin
    flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
    login = flickr.test.login
    puts "You are now authenticated as #{login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"
  rescue FlickRaw::FailedResponse => e
    puts "Authentication failed : #{e.msg}"
  end
end

def id_from_url(flickr)
  m = flickr.match(/\/([\d]+)_/)
  if !m.nil?
    return m[1]
  end

end

def get_flickr_ids()
  ids = []

  path = 'db/ffffound-blech.db' # ick
  db = SQLite3::Database.new(path)
  sql = "select orig_src, id, count from images where orig_src like '%flickr%'"

  db.execute(sql) do |row|
    flickr_id = id_from_url(row[0])
    if flickr_id:
      info = {'flickr_id' => flickr_id, 'ffffound_id' => row[1], 'ffffound_count' => row[2]}
      ids.push(info)
    end
  end

  return ids
end

def get_flickr_faves(ids)
  ids.each do |info|
    begin
      faves = flickr.photos.getFavorites :photo_id => info['flickr_id']
    rescue FlickRaw::FailedResponse => e
      puts "Problem with #{info['flickr_id']}: #{e.msg}"
      info['flickr_count'] = 'x'
      next
    end
    puts "#{info['flickr_id']} #{faves.total}"
    info['flickr_count'] = faves.total
  end
end

def set_flickr_faves(ids)
  ids.each do |info|
    begin
      flickr.favorites.add :photo_id => info['flickr_id']
    rescue FlickRaw::FailedResponse => e
      puts "Problem with #{info['flickr_id']}: #{e.msg}"
      next
    end
    sleep(1)
  end
end

def output_flickr_ids(ids)
  ids.each do |info|
    puts "#{info['flickr_id']}:\t#{info['flickr_count']} flickr faves, #{info['ffffound_count']} bookmarks on ffffound"
  end
end

auth_flickr()
ids = get_flickr_ids()
ids = get_flickr_faves(ids)
# use set_flickr_faves(ids) to mark photos on Flickr that you ffffound as faves
output_flickr_ids(ids)
