#!/usr/bin/env ruby
# encoding: UTF-8

require "yaml"
require "rest-client"
require "json"
require "time"

SAVE_COMMAND = File.expand_path("add_to_reading_list", File.dirname(__FILE__)).freeze

def save_to_reading_list(url, title=nil)
  system SAVE_COMMAND, *[url, title].compact
end

CONFIG = YAML.load_file(File.expand_path("~/.pocket"))

class PocketItem
  def initialize(data)
    self.data = data
  end

  def id
    @id ||= data["item_id"]
  end

  def url
    @url ||= data["resolved_url"] || data["given_url"] || nil
  end

  def title
    @title ||= data["resolved_title"] || data["given_title"] || nil
  end

  private
  attr_accessor :data
end

auth_params = {
  consumer_key: CONFIG["consumer_key"],
  access_token: CONFIG["access_token"],
}

default_headers = {
  :content_type => :json,
  :"X-Accept" => "application/json",
}

params = {
  detailType: "simple",
  state: "unread",
  sort: "oldest",
}

pocket_items = RestClient.post("https://getpocket.com/v3/get", params.merge(auth_params).to_json, default_headers) do |response, request, result|
  if Net::HTTPOK === result
    r = JSON.parse(response.body)["list"]
    Hash === r ? r.values : r
  else
    raise [result.inspect, response.inspect].inspect
  end
end.map {|i| PocketItem.new(i) }

if pocket_items.empty?
  puts "Nothing received to copy"
  exit(0)
end

items_to_archive = []

pocket_items.each do |item|
  if item.url.nil?
    puts "!!!ERROR!!! url is nil: #{item.inspect}"
    next
  end
  p [item.url, item.title]
  save_to_reading_list(item.url, item.title)
  items_to_archive << item
end

puts ">> Added #{items_to_archive.size} items to Reading List"

if items_to_archive.empty?
  puts "Nothing to archive"
  exit(0)
end

api_actions = items_to_archive.map do |item|
  {
    action: "archive",
    item_id: item.id
  }
end

params = {actions: api_actions}.merge(auth_params)
archived = RestClient.post("https://getpocket.com/v3/send", params.to_json, default_headers) do |response, request, result|
  if Net::HTTPOK === result
    r = JSON.parse(response.body)["status"]
    r == 1
  else
    raise [result.inspect, response.inspect].inspect
  end
end

msg = if archived
  ">> Archived copied items successfully"
else
  "ERR: failed to archive copied items successfully"
end
puts msg
