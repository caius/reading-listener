#!/usr/bin/env ruby

URLS = ARGF.read.split("\n")

if URLS.empty?
  fail "No URLs passed"
end

require "evernote_oauth"

NOTEBOOK_NAME = "Reading List Archive".downcase.freeze

def create_note_for(url)
  note = Evernote::EDAM::Type::Note.new(
    :title => url,
    :content => %{<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd"><en-note><![CDATA[#{url}]]></en-note>},
    :notebookGuid => notebook_guid,
    :attributes => Evernote::EDAM::Type::NoteAttributes.new(
      :sourceApplication => "ReadingList",
      :sourceURL => url,
    ),
  )
  NOTE_STORE.createNote(TOKEN, note)
end

def notes_for(url)
  query = Evernote::EDAM::NoteStore::NoteFilter.new(
    :notebookGuid => notebook_guid,
    :words => %{sourceUrl:"#{url}"},
  )

  result_spec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new(
    :includeAttributes => true,
    :includeDeleted => true,
    :includeNotebookGuid => true,
  )

  NOTE_STORE.findNotesMetadata(token, query, 0, 1, result_spec).totalNotes
end

def token
  @token ||= File.read(File.join(ENV["HOME"], ".evernote-token")).strip
end

def client
  # Set up the NoteStore client
  @client ||= EvernoteOAuth::Client.new(
    token: token,
    sandbox: false,
  )
end

def note_store
  @note_store ||= client.note_store
end

def notebook
  @notebook = begin
    nb = note_store.listNotebooks.find {|x| x.name.downcase == NOTEBOOK_NAME }

    unless nb
      fail "Couldn't find notebook called #{NOTEBOOK_NAME.inspect}"
    end

    nb
  end
end

def notebook_guid
  @notebook_guid ||= notebook.guid
end

def run(urls)
  urls.each do |url|
    if notes_for(url).zero?
      create_note_for(url)
      puts "[ADDED] #{url.inspect}"
    else
      puts "[DUPLICATE] #{url.inspect}"
    end
  end

rescue Evernote::EDAM::Error::EDAMSystemException => e
  if e.errorCode == 19 # Rate Limit Reached
    puts "ERROR: Rate Limit reached; try again in #{e.rateLimitDuration} seconds"
    exit(1)
  else
    p e.inspect
    raise
  end
end

run(URLS)
