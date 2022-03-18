#!/bin/bash

set -e
set -o pipefail

mkdir -p log

# shellcheck disable=SC2016
find . -name '*.SlackBuild' -printf '%P\n' | xargs -I xx dirname xx | xargs -I xx bash -c 'mkdir -p "log/xx" && perl sbolint -q "xx" > "log/xx/$(basename xx)"' || true

# clear some things for now
find log -type f | xargs sed -i '/xmind: WARN: README has lines >72 characters/d'
find log -type f | xargs sed -i '/fuse-overlayfs: WARN: README has lines >72 characters/d'

find log -empty -type f -delete
find log -empty -type d -delete

find log -type f | while read -r file ; do
  dir="$(printf '%s\n' "$file" | sed 's/log\///')"
  dir="$(dirname "$dir")"

  printf "<?xml version='1.0'?>\n" > "$file".xml
  printf '<checkstyle>\n' >> "$file".xml

  while read -r line ; do
    warning_file="$(printf '%s\n' "$line" | cut -d' ' -f 3 | sed 's/:.*$//')"
    warning_col="$(printf '%s\n' "$line" | cut -d' ' -f 3 | sed 's/^.*://')"

    if ! printf '%s\n' "$warning_col" | grep -P '^[0-9][0-9]*$' > /dev/null 2>&1 ; then
      warning_col="0"
    fi

    printf "<file name='%s/%s'>\n" "$dir" "$warning_file" >> "$file".xml

    line="$(printf '%s\n' "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')"

    severity="warning"
    if printf '%s\n' "$line" | grep ERR > /dev/null 2>&1 ; then
      severity="error"
    fi

    line="$(printf '%s\n' "$line" | cut -d' ' -f 4-)"

    printf "  <error column='%s' severity='%s' message='%s'/>\n" "$warning_col" "$severity" "$line" >> "$file".xml
    printf "</file>\n" >> "$file".xml
  done < "$file"

  printf '</checkstyle>\n' >> "$file".xml

  rm "$file"
done
