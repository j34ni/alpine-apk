# alpine-apk — personal Alpine Linux repository (j34ni)

Alpine packages not (yet) available in aports, built for **Alpine edge / x86_64**.
Current contents:
- HPE Slingshot (SHS) userspace stack: `cassini-headers`, `cxi-uapi-headers`, `libcxi`, `xpmem`, `libfabric`
- MPI: `mpich` 4.3.2 (plus the `osu-micro-benchmarks` suite built against it)
- Math libraries: `openblas` 0.3.34 (DYNAMIC_ARCH runtime dispatch; fixes the broken dispatch of community openblas 0.3.30-r2) with `liblapack`/`liblapacke` subpackages

Builds are incremental: each push rebuilds only the packages whose APKBUILD
fingerprint changed (`built-manifest.txt`), and publishes the full set.

## Use the repository

On any Alpine edge x86_64 system or container:

    wget -O /etc/apk/keys/jeani@uio.no-6ab13a56.rsa.pub \
      https://j34ni.github.io/alpine-apk/keys/jeani@uio.no-6ab13a56.rsa.pub
    echo "https://j34ni.github.io/alpine-apk/edge/j34ni" >> /etc/apk/repositories
    apk update
    apk add libfabric libcxi xpmem

The public signing key lives in `keys/`; the private key never enters this
repository (GitHub Actions secret `ABUILD_PRIVKEY_B64`).

## Layout

    j34ni/<pkg>/APKBUILD   packages (abuild derives the repo name "j34ni" from this dir)
    keys/                  public key served at /keys/
    scripts/build.sh       build entrypoint (docker or CI, runs as root, drops to abuild)
    scripts/build-as-abuild.sh

## Build locally

    docker run --rm -e WS=/ws -e KEYS=/keys -e CACHE=/cache \
      -v "$PWD:/ws" -v /path/to/keys:/keys -v "$PWD/.distfiles:/cache" \
      alpine:edge sh /ws/scripts/build.sh

Output (signed apks + signed APKINDEX.tar.gz) in `out/j34ni/x86_64/`.
Pushes to `main` trigger the Actions workflow which publishes `edge/j34ni/`
and `keys/` to GitHub Pages.
