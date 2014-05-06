#!/usr/bin/env bash

url="${1}"

if [[ -z $url ]]; then
  echo "USAGE: $0 URL"
  exit 1
fi

osascript <<APPLESCRIPT
tell application "Evernote"
  set NotebookName to "Reading List Archive"

  set urlToStore to "${url}"

  set query to "notebook:\"" & NotebookName & "\" sourceURL:\"" & urlToStore & "\""

  set found_notes to find notes query

  if (length of found_notes) = 0 then
    create note from url urlToStore notebook NotebookName
    return "CREATED " & urlToStore
  end if
end tell
APPLESCRIPT
