#!/bin/bash

set -e
set -o pipefail

JENKINSUID=${JENKINSUID:-1000}
JENKINSGUID=${JENKINSGUID:-1000}

cleanup() {
  chown -R "$JENKINSUID:$JENKINSGUID" tmp log
}
trap "cleanup" SIGINT SIGTERM SIGHUP SIGQUIT EXIT

PACKAGE=${PACKAGE:-}
OPT_REPO=${OPT_REPO:-}
BUILD_ARCH=${BUILD_ARCH:-}

sed -i '/stty sane/d' /usr/sbin/slackrepo
sed -i '/^PKGBACKUP/d' "/etc/slackrepo/slackrepo_$OPT_REPO.conf"
sed -i "/^LINT/s/'n'/'y'/" "/etc/slackrepo/slackrepo_$OPT_REPO.conf"

if [[ "$BUILD_ARCH" != "" ]] ; then
  sed -i "s/^ARCH.*$/ARCH=$BUILD_ARCH/" "/etc/slackrepo/slackrepo_$OPT_REPO.conf"
fi

# use the sources from the build
CWD="$(pwd)"
(
  cd "/var/lib/slackrepo/$OPT_REPO"

  if [ -L slackbuilds ] ; then
    unlink slackbuilds
  fi

  ln -sf "$CWD" slackbuilds
)

mkdir -p tmp

echo "Determining list of packages to build"

su -l -c "slackrepo --preview build $PACKAGE" > tmp/preview_build

sed -i -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" tmp/preview_build
<tmp/preview_build sed '0,/^SUMMARY/d' | sed '0,/^Pending/d' | sed -n '/Estimated/q;p' | sed 's/^[[:space:]]*//' | cut -d' ' -f1 > tmp/project_list
