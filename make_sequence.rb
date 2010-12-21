#!/usr/bin/ruby
require 'rubygems'

require 'fileutils'
require 'sqlite3'

def make_sequence(db)
  filenames = {}

  images_sql = "SELECT id, date from images WHERE date != 0 ORDER BY date"

  counter = 1

  db.execute( images_sql ) do |row|
    id = row[0]
    epoch = row[1]

    FileUtils.cp('images/'+id+'.jpg', 'ordered/ffffound-'+counter.to_s+'.jpg')
    counter += 1
  end

  images_sql = "SELECT id, date from images WHERE date == 0 ORDER BY id"

  db.execute( images_sql ) do |row|
    id = row[0]
    epoch = row[1]

    FileUtils.cp('images/'+id+'.jpg', 'ordered/ffffound-'+counter.to_s+'.jpg')
    counter += 1
  end
end

# this needs work
user = ARGV[0] 

if not user:
  puts "A ffffound username must be supplied"
  exit
else
  if user == "--all"
     puts "Invoked for all posts"
     user = "all"
  end
  puts "Invoked for posts by #{user}"
end

path = 'db/ffffound-'+user+'.db' # ick
db = SQLite3::Database.new(path)

make_sequence(db)
exit

# once this is done, you can pad the images to the same size with
# sips -p 480 480 --padColor ffffff ordered/*
# assuming you're on Mac OS X. Otherwise, I'm sure convert can do the same
