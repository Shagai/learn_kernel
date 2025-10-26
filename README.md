# Yocto + Kernel Module Lab (Mac M1 friendly)

This project gives you a ready-to-use Dockerized Yocto environment on Apple Silicon (Mac M1/M2), plus a minimal out‑of‑tree kernel module you can build and run in QEMU.

- Target: `qemuarm64` (runs fine without KVM on macOS)
- Yocto branch: `scarthgap` by default (override via `YOCTO_BRANCH`)
- Sample module: `hello-mod` (prints messages on load/unload and auto-loads at boot)

## Prereqs
- Docker Desktop for Mac (Apple Silicon)
- 70–100 GB free disk space for Yocto downloads + sstate caches over time
- Allocate at least 4 CPUs and 8–12 GB RAM to Docker for a reasonable first build

## Quick Start

1) Build the image and launch a dev shell

```bash
cd docker
YOCTO_BRANCH=scarthgap docker compose build
docker compose run --rm dev
```

2) Fetch Yocto layers

```bash
scripts/bootstrap.sh            # grabs poky + meta-openembedded for the chosen branch
```

3) Configure build dir and layers

```bash
scripts/setup-build.sh          # creates ./build and wires layers, cache, machine
```

4) Build the image and the sample module

```bash
scripts/build-image.sh          # bitbake hello-mod and core-image-minimal
```

5) Run under QEMU (console only, no GUI)

```bash
scripts/run-qemu.sh             # boots core-image-minimal for qemuarm64
```

When the system boots, `hello` should be auto-loaded. You can verify:

```bash
# inside QEMU shell
lsmod | grep hello || modinfo hello
dmesg | tail -n 50 | grep hello
```

Exit QEMU with `Ctrl-A x` if using the `nographic` console.

## Editing and Rebuilding the Kernel Module

- Source: `layers/meta-kernel-labs/recipes-kernel/hello-mod/files/hello.c`
- Recipe: `layers/meta-kernel-labs/recipes-kernel/hello-mod/hello-mod.bb`

Typical loop:

```bash
# inside container
edit layers/meta-kernel-labs/recipes-kernel/hello-mod/files/hello.c
source layers/poky/oe-init-build-env build
bitbake -c clean hello-mod && bitbake hello-mod
bitbake core-image-minimal
scripts/run-qemu.sh
```

Tip: use `bitbake -c devshell hello-mod` to open a build shell pinned to the recipe’s environment.

## Caching

Downloads and sstate are persisted at `./cache` and mounted into the container. First build is heavy; subsequent builds get faster.

## Changing Targets

- Machine: edit `build/conf/local.conf` after `scripts/setup-build.sh`
  - Examples: `qemux86-64` (will be slow on M1 due to emulation), `qemuarm` (32-bit), or a real board layer if you add it.
- Yocto branch: set `YOCTO_BRANCH` before `docker compose build` or pass to `scripts/bootstrap.sh`.

## Notes for Apple Silicon

- This setup uses an `arm64` container and builds an `arm64` QEMU target. That’s the fastest path on M1.
- QEMU runs without KVM (no hardware accel on macOS). It’s slower than Linux on bare metal but usable for module dev.
- If you must build x86_64 targets, you can set `platform: linux/amd64` in `docker/docker-compose.yml`. Expect significantly slower builds.
 
### Colima/Docker Desktop note

On some macOS host mounts, BitBake’s UNIX socket cannot be created in the mounted workspace (EPERM). If you hit server start errors, use the provided helper to build inside the container’s filesystem while still using host caches:

```bash
# Parse and list recipes (internal build dir)
docker run --rm -v $PWD:/work -v $PWD/cache:/work/cache yocto-dev:scarthgap \
  -lc 'scripts/bitbake-internal.sh -p >/dev/null && scripts/bitbake-internal.sh -s | grep hello-mod'

# Build the module and a minimal image
docker run --rm -v $PWD:/work -v $PWD/cache:/work/cache yocto-dev:scarthgap \
  -lc 'scripts/bitbake-internal.sh hello-mod core-image-minimal'

# Boot the last image
docker run --rm -it -v $PWD:/work -v $PWD/cache:/work/cache yocto-dev:scarthgap \
  -lc 'source layers/poky/oe-init-build-env /home/builder/build >/dev/null && runqemu nographic slirp'
```

## Where to Look Next

- Explore `build/tmp/work/.../hello-mod/.../packages-split/` to see packaged artifacts.
- Add more modules by copying the `hello-mod` recipe and changing names/files.
- Use `devtool add` to import external module sources into a layer.

## Common Commands (inside container)

```bash
source layers/poky/oe-init-build-env build
bitbake -s                     # list recipes
bitbake -c cleanall hello-mod  # nuke build + downloads for the module
runqemu nographic slirp        # boot the last built qemu image
```

## Troubleshooting

- If `runqemu` complains about networking, `runqemu nographic slirp` forces user networking that requires no TAP/TUN.
- If you see locale warnings, ensure `LANG=en_US.UTF-8` (already set in the image).
- If file permissions look odd on macOS, the container runs as your UID/GID by default via compose.
