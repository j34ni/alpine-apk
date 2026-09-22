#!/bin/sh
# Sets up the environment (root), then delegates compilation to the abuild user.
# Used locally (docker run ... alpine:edge sh /ws/scripts/build.sh) and by GitHub CI.
set -eu
: "${WS:?WS manquant}"
: "${KEYS:?KEYS manquant}"
: "${CACHE:?CACHE manquant}"

apk add --no-cache alpine-sdk sudo abuild git > /dev/null
getent passwd abuild >/dev/null || adduser -D -G abuild abuild
echo "abuild ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/abuild
mkdir -p "$WS/out" "$CACHE"
chown -R abuild:abuild "$WS/out" "$WS/j34ni" "$CACHE" "$KEYS"
chmod 600 "$KEYS"/*.rsa
su abuild -s /bin/sh -c "WS='$WS' KEYS='$KEYS' CACHE='$CACHE' sh '$WS/scripts/build-as-abuild.sh'"
