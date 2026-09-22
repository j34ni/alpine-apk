#!/bin/sh
# Build repo packages in dependency order. Signed with PACKAGER_PRIVKEY.
# Deterministic incremental mode: a package is rebuilt ONLY when its fingerprint
# changes or its apks are missing from out/. Fingerprint = sha256 of its APKBUILD
# plus the APKBUILDs of the j34ni packages it directly depends on. No implicit
# abuild skipping: before any build, stale apks of that package are deleted
# (otherwise abuild would silently skip and publish an outdated package).
set -eu
: "${WS:?}" : "${KEYS:?}" : "${CACHE:?}"
: "${PACKAGER:=j34ni <jeani@uio.no>}"
PKGS="${PKGS:-cassini-headers cxi-uapi-headers libcxi xpmem libfabric openblas metis mpich-4.3.2 scotch scalapack mumps hdf5-mpich petsc lamem osu-micro-benchmarks}"
MANIFEST="$WS/out/built-manifest.txt"
OUT="$WS/out/j34ni/x86_64"

CFG="$HOME/.config/abuild"
mkdir -p "$CFG" "$OUT" "$WS/out"
{
	printf 'PACKAGER="%s"\n' "$PACKAGER"
	printf 'REPODEST="%s/out"\n' "$WS"
} > "$CFG/abuild.conf"
cp "$KEYS"/*.rsa "$CFG/"
cp "$KEYS"/*.rsa.pub "$CFG/"
chmod 600 "$CFG"/*.rsa
printf 'PACKAGER_PRIVKEY="%s"\n' "$(echo "$CFG"/*.rsa)" >> "$CFG/abuild.conf"
sudo cp "$CFG"/*.rsa.pub /etc/apk/keys/

export PACKAGER SRCDEST="$CACHE"
mkdir -p "$SRCDEST"
[ -f "$MANIFEST" ] || : > "$MANIFEST"
NEWMANIFEST="$MANIFEST.new"
: > "$NEWMANIFEST"
# keep manifest lines of packages not in this run's PKGS (partial runs must not
# truncate the manifest)
while read -r line; do
	p2=$(printf '%s' "$line" | cut -d' ' -f2)
	[ -n "$p2" ] || continue
	in=0
	for x in $PKGS; do [ "$x" = "$p2" ] && in=1; done
	[ "$in" = 0 ] && printf '%s\n' "$line" >> "$NEWMANIFEST"
done < "$MANIFEST"

pkgbase() { ( set +u; CARCH=x86_64 CBUILD=x86_64-alpine-linux-musl CHOST=x86_64-alpine-linux-musl srcdir=/tmp pkgdir=/tmp startdir=/tmp . "$WS/j34ni/$1/APKBUILD"; printf '%s' "${pkgname:-}"; ); }

fingerprint() {
	{
		sha256sum "$WS/j34ni/$1/APKBUILD"
		for d in $PKGS; do
			[ "$d" = "$1" ] && continue
			b=$(pkgbase "$d")
			if grep -qE "(^|[[:space:]\"'])$b(-dev|-libs|-static)?([[:space:]\"']|$)" "$WS/j34ni/$1/APKBUILD"; then
				sha256sum "$WS/j34ni/$d/APKBUILD"
			fi
		done
	} | cut -d' ' -f1 | sha256sum | cut -d' ' -f1
}

for p in $PKGS; do
	fp=$(fingerprint "$p")
	line=$(grep -E "^[0-9a-f]{64} $p " "$MANIFEST" || true)
	apks=${line#"$fp $p "}
	[ "$apks" = "$line" ] && apks=""
	ok=1
	if [ -z "$line" ] || [ "$(echo "$line" | cut -d' ' -f1)" != "$fp" ] || [ -z "$apks" ]; then ok=0; fi
	if [ "$ok" = 1 ]; then
		for a in $(echo "$apks" | tr ',' ' '); do
			[ -f "$OUT/$a" ] || { ok=0; break; }
		done
	fi
	if [ "$ok" = 1 ]; then
		echo "==== SKIP $p (fingerprint unchanged, apks present)"
		echo "$fp $p $apks" >> "$NEWMANIFEST"
		continue
	fi
	# stale apks -> explicit removal before rebuilding
	old=$(echo "$apks" | tr ',' ' ')
	[ -n "$old" ] && rm -f $OUT/$old
	rm -rf "$WS/j34ni/$p/src" "$WS/j34ni/$p/pkg" "$WS/j34ni/$p/.abuild"
	cd "$WS/j34ni/$p"
	touch "$WS/out/.build-marker"
	echo "==== FETCH $p"
	abuild fetch || { sleep 30; abuild fetch; } || { sleep 60; abuild fetch; }
	echo "==== BUILD $p"
	abuild -r
	built=$(cd "$OUT" && find . -name '*.apk' -newer "$WS/out/.build-marker" | sed 's|^\./||' | sort | paste -sd,)
	echo "$fp $p $built" >> "$NEWMANIFEST"
done
mv "$NEWMANIFEST" "$MANIFEST"
echo "==== PAQUETS :"
find "$OUT" -name '*.apk' | sort
