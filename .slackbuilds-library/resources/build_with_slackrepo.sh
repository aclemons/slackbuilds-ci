#l/bin/bash

set -e
set -o pipefail

UPDATE=${UPDATE:-}

if [[ $UPDATE == "true" ]] ; then
  PROJECT=
else
  PROJECT=${PROJECT:-}
fi
OPT_REPO=${OPT_REPO:-}
BUILD_ARCH=${BUILD_ARCH:-}
SETARCH=${SETARCH:-}

sed -i '/stty sane/d' /usr/sbin/slackrepo
sed -i '/^PKGBACKUP/d' "/etc/slackrepo/slackrepo_$OPT_REPO.conf"
sed -i "/^LINT/s/'n'/'y'/" "/etc/slackrepo/slackrepo_$OPT_REPO.conf"
sed -i "s,^SBREPO=.*$,SBREPO=\"$(pwd)\",g" "/etc/slackrepo/slackrepo_$OPT_REPO.conf"
sed -i "s,^LOGDIR=.*$,LOGDIR=\"$(pwd)/log\",g" "/etc/slackrepo/slackrepo_$OPT_REPO.conf"

if [[ "$BUILD_ARCH" != "" ]] ; then
  sed -i "s/^ARCH.*$/ARCH=$BUILD_ARCH/" "/etc/slackrepo/slackrepo_$OPT_REPO.conf"
fi

mkdir -p "tmp/$PROJECT"

if [[ $UPDATE == "true" ]] ; then
  su -l -c "$SETARCH slackrepo update" | tee "tmp/$PROJECT/build"
else
  su -l -c "$SETARCH slackrepo build $PROJECT" | tee "tmp/$PROJECT/build"
fi

sed -i -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" "tmp/$PROJECT/build"
