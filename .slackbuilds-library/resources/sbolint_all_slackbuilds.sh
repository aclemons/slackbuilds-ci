#!/bin/bash

set -e
set -o pipefail

process_build() {
  local file="$1"

  mkdir -p log/"$file"

  sbolint -q "$file" > log/"$file"/"$(basename "$file")" || true
}
export -f process_build

mkdir -p log

# shellcheck disable=SC2016
find . -name '*.SlackBuild' -printf '%P\n' | xargs -I xx dirname xx | parallel process_build

# clear some things for now
find log -type f -print0 | xargs -0 sed -i '/xmind: WARN: README has lines >72 characters/d'
find log -type f -print0 | xargs -0 sed -i '/fuse-overlayfs: WARN: README has lines >72 characters/d'
find log -type f -print0 | xargs -0 sed -i '/mumble-server: WARN: README has lines >72 characters/d'

find log -empty -type f -delete
find log -empty -type d -delete

mkdir -p log

printf "<?xml version='1.0'?>\n" > checkstyle.xml
printf '<checkstyle>\n' >> checkstyle.xml

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

    printf "<file name='%s/%s'>\n" "$dir" "$warning_file" >> checkstyle.xml

    line="$(printf '%s\n' "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')"

    severity="warning"
    if printf '%s\n' "$line" | grep ERR > /dev/null 2>&1 ; then
      severity="error"
    fi

    line="$(printf '%s\n' "$line" | cut -d' ' -f 4-)"

    printf "  <error column='%s' severity='%s' message='%s'/>\n" "$warning_col" "$severity" "$line" >> checkstyle.xml
    printf "</file>\n" >> checkstyle.xml
  done < "$file"

  rm "$file"
done

printf '</checkstyle>\n' >> checkstyle.xml

rm -rf log

mkdir log
mv checkstyle.xml log
