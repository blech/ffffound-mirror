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
@key = "3luShD2ApVSMWKRXTQdmvGac7IIrVUAkVk0BKjQJwkowCYgSNh"
@secret = "yrZ8Wu7422TeHUp7iinWvI8QwQM4Yu7ENqYfiQKKwG12vk5l5z"
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

  if r.code != 201:
    puts "This image did not upload; aborting"
    puts r.body()
    abort
  return JSON.parse(r.body())
  
end

# ok we're all set. Now to do the work.
def images_from_db(access_token)
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
    image_path = "images/#{row[0]}.jpg"
    if not File.exists?(image_path):
      puts "#{image_path} not found (original URL #{row[1]})"
      next
    end
  
    source = row[1]
    epoch = row[2]
    timestamp = Time.at(epoch.to_i).strftime("%Y-%m-%d %H:%M:%S GMT")
    # related = row[3].split(',')
    puts "Uploading image path #{image_path} from #{timestamp} (#{source})"
    
    response = post_to_tumblr(access_token, image_path, source, timestamp)

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
end

access_token = auth_tumblr()
images_from_db(access_token)

# user_info = access_token.get("http://api.tumblr.com/v2/user/info")
# puts user_info

# possibly useful later
# select tumblr_id, date, orig_url from tumblr, images where tumblr.ffffound_id = images.id;
