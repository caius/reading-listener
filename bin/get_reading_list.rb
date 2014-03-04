#!/usr/bin/env ruby

require "CFPropertyList"
require_relative "../lib/reading_list"

bookmark_file = ENV.fetch("BOOKMARK_FILE") { ENV["HOME"] + "/Library/Safari/Bookmarks.plist"}

plist = CFPropertyList::List.new(:file => bookmark_file)
data = CFPropertyList.native_types(plist.value)

reading_list = ReadingList.from_bookmarks_list(data)

reading_list.items.each do |item|
  p item.date_added
  p item.preview
  p item.title
  p item.url
  p item.uuid
  puts;puts
end
