#!/bin/bash

set -e
set -o pipefail

if [ ! -e .shellcheckrc ] ; then
  printf "disable=SC2086,SC2236,SC2046,SC2044,SC2231\n" > .shellcheckrc
fi

mkdir -p log

docker run --rm  -v "$(pwd)":/mnt --entrypoint sh koalaman/shellcheck-alpine:latest -c 'shellcheck --format checkstyle --severity warning $(find . -name "*.SlackBuild")' | \
  sed '/LIBDIRSUFFIX appears unused/d' | sed '/SLKCFLAGS appears unused/d' | sed 's,\./mnt/,,g' > log/shellcheck.xml
  
