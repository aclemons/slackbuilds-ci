#!/bin/bash

set -e
set -o pipefail

if [ ! -e .shellcheckrc ] ; then
  printf "disable=SC2086,SC2236,SC2046,SC2044,SC2231\n" > .shellcheckrc
fi

mkdir -p log

docker run --rm  -v "$(pwd)":/mnt --entrypoint sh koalaman/shellcheck-alpine:latest -c 'shellcheck --format checkstyle --severity warning $(find . -name "*.SlackBuild")'  > log/shellcheck.xml

sed -i '/LIBDIRSUFFIX appears unused/d' log/shellcheck.xml
sed -i 's,\./mnt/,,g' log/shellcheck.xml
