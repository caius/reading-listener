#!/usr/bin/env bash

# This is probably unusable unless you have my machine - sorry!

set -e

ROOT="$(dirname ${0})"

source /usr/local/opt/chruby/share/chruby/chruby.sh
chruby "$(< ~/.ruby-version)"

${ROOT}/archive_to_evernote.rb < <(${ROOT}/get_reading_list.rb | jq -r ".url")
