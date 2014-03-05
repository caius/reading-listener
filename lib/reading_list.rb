require "date"
require "json"

def Date(obj)
  Date.parse(obj)
end

class ReadingList
  attr_accessor :data

  def self.from_bookmarks_list(bookmarks_data)
    rl = bookmarks_data["Children"].find {|child| child["Title"] == "com.apple.ReadingList" }
    raise "Couldn't extract reading list from #{bookmarks_data.inspect}" unless rl
    ReadingList.new(rl)
  end

  def initialize(data)
    self.data = data
  end

  def items
    @items ||= data["Children"].map { |child| Item.new(child) }
  end
end

class ReadingList
  class Item
    attr_accessor :data

    def initialize(data)
      self.data = data
    end

    def date_added
      @date_added ||= data["ReadingList"]["DateAdded"]
    end

    def preview
      @preview ||= data["ReadingList"]["PreviewText"]
    end

    def title
      @title ||= data["URIDictionary"]["title"]
    end

    def url
      @url ||= data["URLString"]
    end

    def uuid
      @uuid ||= data["WebBookmarkUUID"]
    end

  end

  ItemPresenter = Struct.new(:item) do
    def to_json(*args)
      {
        :date_added => item.date_added,
        :title => item.title,
        :url => item.url,
        :uuid => item.uuid,
      }.to_json(*args)
    end
  end
end

if __FILE__ == $0
  item = ReadingList::Item.new(
    "ReadingList" => {
      "DateAdded" => Date("2014-03-04 20:36:46 +0000"),
      "PreviewText" => "FreeAgent is accounting software for small businesses and freelancers, recommended by 99.5% of our users. Try us today!"
    },
    "ReadingListNonSync" => {
      "AddedLocally" => true,
      "ArchiveOnDisk" => true,
      "DateLastFetched" => Date("2014-03-04 20:36:55 +0000"),
      "FetchResult" => 1
    },
    "Sync" => {
      "Key" => "\"[STRIPPED]\"",
      "ServerID" => "[STRIPPED]"
    },
    "URIDictionary" => {
      "title" => "Accounting software, simplified - FreeAgent"
    },
    "URLString" => "http://www.freeagent.com/",
    "WebBookmarkType" => "WebBookmarkTypeLeaf",
    "WebBookmarkUUID" => "[STRIPPED]"
  )
  
  
  p item
  puts ""

  p item.date_added
  p item.preview
  p item.title
  p item.url
  p item.uuid

end
