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

@path = 'db/ffffound-blech.db' # ick

# oauth for tumblr
@key = ""
@secret = ""
@site = 'http://www.tumblr.com'
@callback_url = 'oob'

def auth_tumblr()
  consumer = OAuth::Consumer.new(@key, @secret,
                                 { :site => @site,
                                   :request_token_path => '/oauth/request_token',
                                   :authorize_path => '/oauth/authorize',
                                   :access_token_path => '/oauth/access_token',
                                   :http_method => :post })
  
  request_token = consumer.get_request_token(:oauth_callback => @callback_url)
  puts "please visit "+request_token.authorize_url+" and paste the code here"
  
  oauth_verifier = gets.strip
  
  access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
  return access_token
end

def post_to_tumblr(access_token, image_path, source, timestamp)
  image_data = IO.read(image_path)
  
  r = access_token.post("http://api.tumblr.com/v2/blog/bbbblech.tumblr.com/post",
                        { :type => "photo",
                          :state => "draft",
                          :date => timestamp,
                          :link => source,
                          :data => image_data,
                        })
  puts r
end

# ok we're all set. Now to do the work.
def images_from_db(access_token)
  db = SQLite3::Database.new(@path)
  sql = "select src, orig_url, date, related, posted from images where date != '0' order by date asc limit 980  offset 20"
  
  db.execute(sql) do |row|
    image_path = row[0].split('/')[-1].split('_')[0]
    image_path = "images/#{image_path}.jpg"
    if not File.exists?(image_path):
      puts "#{image_path} not found (original URL #{row[1]})"
      next
    end
  
    source = row[1]
  
    epoch = row[2]
    timestamp = Time.at(epoch.to_i).strftime("%Y-%m-%d %H:%M:%S GMT")
  
    # related = row[3].split(',')
    
    puts "#{image_path} #{source} #{timestamp}"
    post_to_tumblr(access_token, image_path, source, timestamp)    
  end
end

access_token = auth_tumblr()
images_from_db(access_token)

#user_info = access_token.get("http://api.tumblr.com/v2/user/info")
#puts user_info
