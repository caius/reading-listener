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
    :notebookGuid => NOTEBOOK_GUID,
    :attributes => Evernote::EDAM::Type::NoteAttributes.new(
      :sourceApplication => "ReadingList",
      :sourceURL => url,
    ),
  )
  NOTE_STORE.createNote(TOKEN, note)
end

def notes_for(url)
  query = Evernote::EDAM::NoteStore::NoteFilter.new(
    :notebookGuid => NOTEBOOK_GUID,
    :words => %{sourceUrl:"#{url}"},
  )

  result_spec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new(
    :includeAttributes => true,
    :includeDeleted => true,
    :includeNotebookGuid => true,
  )

  NOTE_STORE.findNotesMetadata(TOKEN, query, 0, 1, result_spec).totalNotes
end

# Creds
TOKEN = File.read(File.join(ENV["HOME"], ".evernote-token")).strip

# Set up the NoteStore client
client = EvernoteOAuth::Client.new(
  token: TOKEN,
  sandbox: false,
)
NOTE_STORE = client.note_store

NOTEBOOK = NOTE_STORE.listNotebooks.find {|x| x.name.downcase == NOTEBOOK_NAME }

unless NOTEBOOK
  fail "Couldn't find notebook called #{NOTEBOOK_NAME.inspect}"
end

NOTEBOOK_GUID = NOTEBOOK.guid

URLS.each do |url|
  if notes_for(url).zero?
    create_note_for(url)
    puts "[ADDED] #{url.inspect}"
  else
    puts "[DUPLICATE] #{url.inspect}"
  end
end
