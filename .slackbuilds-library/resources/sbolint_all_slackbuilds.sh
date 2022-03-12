#!/bin/bash

set -e
set -o pipefail

mkdir -p log

# shellcheck disable=SC2016
find . -name '*.SlackBuild' -printf '%P\n' | xargs -I xx dirname xx | parallel --halt 0 -q -I xx bash -c 'mkdir -p "log/xx" && perl sbolint -q "xx" > "log/xx/$(basename xx)"' || true
find log -empty -type f -delete
find log -empty -type d -delete

# clear some things for now
find log -type f | parallel -q sed -i '/template comment should be removed/d'
find log -type f | parallel -q sed -i '/doinst.sh exists, but the script doesn/d'
find log -type f | parallel -q sed -i '/script installs doinst.sh, but it does/d'
find log -type f | parallel -q sed -i '/VERSION.*echo.*doesn.t match VERSION in the .info file/d'
find log -type f | parallel -q sed -i '/VERSION ignores environment, try .*echo./d'

find log -empty -type f -delete
find log -empty -type d -delete

find log -type f | while read -r file ; do
  dir="$(printf '%s\n' "$file" | sed 's/log\///')"
  dir="$(dirname "$dir")"

  printf "<?xml version='1.0'?>\n" > "$file".xml
  printf '<checkstyle>\n' >> "$file".xml

  cat "$file" | while read -r line ; do
    warning_file="$(printf '%s\n' "$line" | cut -d' ' -f 3 | sed 's/:.*$//')"
    printf "<file name='%s/%s'>\n" "$dir" "$warning_file" >> "$file".xml

    line="$(printf '%s\n' "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')"

    printf "  <error severity='info' message='%s'/>\n" "$line" >> "$file".xml
    printf "</file>\n" >> "$file".xml
  done

  printf '</checkstyle>\n' >> "$file".xml

  rm "$file"
done
