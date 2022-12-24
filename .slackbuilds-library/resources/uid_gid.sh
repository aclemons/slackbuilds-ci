#!/bin/bash

set -u

grep Group: uid_gid.txt | grep -E -v -- "(--|TBA)" | sort |
while read -r line; do
  name=$( awk '{print $2}' <<<"$line" )
  gid=$( awk '{print $4}' <<<"$line" )

  if ! getent group "$name" >/dev/null; then
    groupadd -g "$gid" "$name"
  fi
done

grep User: uid_gid.txt | grep -E -v -- "(--|TBA)" | sort |
while read -r line; do
  name=$( awk '{print $2}' <<<"$line" )
  uid=$( awk '{print $4}' <<<"$line" )
  gid=$( awk '{print $6}' <<<"$line" )

  if ! getent passwd "$name" >/dev/null; then
    useradd -u "$uid" -g "$gid" "$name"
  fi
done

# vim: fdm=marker
