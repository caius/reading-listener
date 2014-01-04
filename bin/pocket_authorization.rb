#!/usr/bin/env ruby
#
#  pocket_authorization
#  Grabs access token & username from Pocket (getpocket.com) for a given
#  application against your account. Implements http://getpocket.com/developer/docs/authentication
#  as a script effectively.
#
#  USAGE
#   1. Register an application with pocket - http://getpocket.com/developer/apps/new
#   2. Run this script with `CONSUMER_KEY=<key from app page>` and follow instructions in browser
#   3. Make a note of the username & access token in the script output
#
#
#
#  MIT License
#
#  Copyright (c) 2011 Caius Durling caius@swedishcampground.com
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
#  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
#  and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in all copies or substantial portions
#  of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
#  TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
#  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#  DEALINGS IN THE SOFTWARE.
#

require "rest-client"
require "json"

POCKET_API_BASE = "https://getpocket.com/v3/oauth"
REDIRECT_URI = "dev://null/"

def post(api_path, params={}, &block)
  url = "#{POCKET_API_BASE}#{api_path}"
  RestClient.post(url, params.to_json, {:content_type => :json, :"x-accept" => "application/json"}) do |response, request, result|
    if Net::HTTPOK === result
      block.call(JSON.parse(response.body))
    else
      raise [result.inspect, response.inspect]
    end
  end
end

consumer_key = ENV["CONSUMER_KEY"].to_s

if consumer_key == ""
  puts "ERR: CONSUMER_KEY needs to be set"
  exit(1)
end

request_token = post("/request", consumer_key: consumer_key, redirect_uri: REDIRECT_URI) { |body| body["code"] }

if request_token.to_s == ""
  puts "ERR: got blank request code from request step"
  exit(1)
end

auth_url = "https://getpocket.com/auth/authorize?request_token=#{request_token}&redirect_uri=#{REDIRECT_URI}"
`open "#{auth_url}"`

print "Hit enter once you've authorized this script"
$stdin.gets


access_token, username = post("/authorize", consumer_key: consumer_key, code: request_token) { |body| [body["access_token"], body["username"]] }

puts <<-EOF
Successfully authed against the pocket API.
  [Consumer Key: #{consumer_key.inspect}]
  [Request Code: #{request_token.inspect}]

  Username: #{username.inspect}
  Access Token: #{access_token.inspect}
EOF
