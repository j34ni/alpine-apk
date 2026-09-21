#!/bin/sh
# Compile tous les paquets du repo, dans l'ordre des dependances. Signe avec PACKAGER_PRIVKEY.
set -eu
: "${WS:?}" : "${KEYS:?}" : "${CACHE:?}"
: "${PACKAGER:=j34ni <jeani@uio.no>}"
PKGS="cassini-headers cxi-uapi-headers libcxi xpmem libfabric"

CFG="$HOME/.config/abuild"
mkdir -p "$CFG"
{
	printf 'PACKAGER="%s"\n' "$PACKAGER"
	printf 'REPODEST="%s/out"\n' "$WS"
} > "$CFG/abuild.conf"
cp "$KEYS"/*.rsa "$CFG/"
cp "$KEYS"/*.rsa.pub "$CFG/"
chmod 600 "$CFG"/*.rsa
printf 'PACKAGER_PRIVKEY="%s"\n' "$(echo "$CFG"/*.rsa)" >> "$CFG/abuild.conf"
sudo cp "$CFG"/*.rsa.pub /etc/apk/keys/

export PACKAGER DISTDIR="$CACHE"
for p in $PKGS; do
	echo "==== BUILD $p"
	cd "$WS/j34ni/$p"
	abuild -r -k
done
echo "==== PAQUETS :"
find "$WS/out" -name '*.apk' | sort
