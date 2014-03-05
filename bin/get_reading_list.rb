#!/usr/bin/env ruby

require "CFPropertyList"
require_relative "../lib/reading_list"

bookmark_file = ENV.fetch("BOOKMARK_FILE") { ENV["HOME"] + "/Library/Safari/Bookmarks.plist"}

plist = CFPropertyList::List.new(:file => bookmark_file)
data = CFPropertyList.native_types(plist.value)

reading_list = ReadingList.from_bookmarks_list(data)

puts reading_list.items.map { |item| ReadingList::ItemPresenter.new(item).to_json }
