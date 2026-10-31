# alpine-apk — personal Alpine Linux repository (j34ni)

Alpine packages not (yet) available in aports, built for **Alpine edge / x86_64 + riscv64**.
Current contents:
- HPE Slingshot (SHS) userspace stack: `cassini-headers`, `cxi-uapi-headers`, `libcxi`, `xpmem`, `libfabric`
- MPI: `mpich` 4.3.2 (plus the `osu-micro-benchmarks` suite built against it)
- Math libraries: `openblas` 0.3.34 (DYNAMIC_ARCH runtime dispatch; fixes the broken dispatch of community openblas 0.3.30-r2) with `liblapack`/`liblapacke` subpackages
- `hypre` 3.2.0 (MPICH-linked, shared) — PETSc BoomerAMG preconditioner package

Builds are incremental: each push rebuilds only the packages whose APKBUILD
fingerprint changed (`built-manifest-<arch>.txt`), and publishes the full set.

## Use the repository

On any Alpine edge system or container (x86_64 or riscv64 — the same repo
line serves both, `apk` picks the right arch):

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

The build is native: run the same `alpine:edge` image for the target arch.

x86_64:

    docker run --rm -e WS=/ws -e KEYS=/keys -e CACHE=/cache \
      -v "$PWD:/ws" -v /path/to/keys:/keys -v "$PWD/.distfiles:/cache" \
      alpine:edge sh /ws/scripts/build.sh

riscv64 on native RISC-V hardware (same command; `abuild` detects the arch via
`apk --arch`), or emulated on any Docker host via qemu-user binfmt
(works, but very slow for openblas/petsc — prefer CI for real builds):

    docker run --privileged --rm tonistiigi/binfmt --install riscv64
    docker run --rm --platform linux/riscv64 -e WS=/ws -e KEYS=/keys -e CACHE=/cache \
      -v "$PWD:/ws" -v /path/to/keys:/keys -v "$PWD/.distfiles:/cache" \
      alpine:edge sh /ws/scripts/build.sh

Output (signed apks + signed APKINDEX.tar.gz) in `out/j34ni/<arch>/`
(noarch packages land in `out/j34ni/noarch/`).
Pushes to `main` trigger the Actions workflow: x86_64 on `ubuntu-latest`,
riscv64 on the free RISE hosted runner (`ubuntu-24.04-riscv`, real RISC-V
hardware — requires the one-time install of the RISE GitHub App, see
riscv-runners.riseproject.dev). The workflow publishes `edge/j34ni/`
(x86_64 + riscv64 + noarch) and `keys/` to GitHub Pages.
