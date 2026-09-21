#!/bin/sh
# Prepare l'environnement (root) puis delegue la compilation a l'utilisateur abuild.
# Utilise en local (docker run ... alpine:edge sh /ws/scripts/build.sh) et par la CI GitHub.
set -eu
: "${WS:?WS manquant}"
: "${KEYS:?KEYS manquant}"
: "${CACHE:?CACHE manquant}"

apk add --no-cache alpine-sdk sudo abuild git > /dev/null
getent passwd abuild >/dev/null || adduser -D -G abuild abuild
echo "abuild ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/abuild
mkdir -p "$WS/out" "$CACHE"
chown -R abuild:abuild "$WS" "$CACHE" "$KEYS"
chmod 600 "$KEYS"/*.rsa
su abuild -s /bin/sh -c "WS='$WS' KEYS='$KEYS' CACHE='$CACHE' sh '$WS/scripts/build-as-abuild.sh'"
