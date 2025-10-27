#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/work"
LAYERS_DIR="${ROOT_DIR}/layers"
BUILD_DIR="/home/builder/build"

mkdir -p "${BUILD_DIR}/conf"

set +u
source "${LAYERS_DIR}/poky/oe-init-build-env" "${BUILD_DIR}" >/dev/null
set -u

cat >"${BUILD_DIR}/conf/bblayers.conf" <<EOF
# POKY_BBLAYERS_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "\${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  ${LAYERS_DIR}/poky/meta \
  ${LAYERS_DIR}/poky/meta-poky \
  ${LAYERS_DIR}/poky/meta-yocto-bsp \
  ${LAYERS_DIR}/meta-openembedded/meta-oe \
  ${LAYERS_DIR}/meta-kernel-labs \
"
EOF

LOCAL_CONF="${BUILD_DIR}/conf/local.conf"
grep -q '^\s*DL_DIR\b' "${LOCAL_CONF}" || echo "DL_DIR = \"${ROOT_DIR}/cache/downloads\"" >> "${LOCAL_CONF}"
grep -q '^\s*SSTATE_DIR\b' "${LOCAL_CONF}" || echo "SSTATE_DIR = \"${ROOT_DIR}/cache/sstate\"" >> "${LOCAL_CONF}"
# Force arm64 QEMU target for Apple Silicon (override weak defaults)
if grep -q '^\s*MACHINE\b' "${LOCAL_CONF}"; then
  sed -i 's/^\s*MACHINE.*/MACHINE = "qemuarm64"/' "${LOCAL_CONF}"
else
  echo 'MACHINE = "qemuarm64"' >> "${LOCAL_CONF}"
fi
grep -q '^\s*PACKAGE_CLASSES\b' "${LOCAL_CONF}" || echo 'PACKAGE_CLASSES = "package_ipk"' >> "${LOCAL_CONF}"
grep -q '^\s*BB_NUMBER_THREADS\b' "${LOCAL_CONF}" || echo 'BB_NUMBER_THREADS ?= "8"' >> "${LOCAL_CONF}"
grep -q '^\s*PARALLEL_MAKE\b' "${LOCAL_CONF}" || echo 'PARALLEL_MAKE ?= "-j8"' >> "${LOCAL_CONF}"
grep -q 'hello-mod' "${LOCAL_CONF}" || echo 'IMAGE_INSTALL:append = " hello-mod"' >> "${LOCAL_CONF}"

# Avoid building SDL/GL stack for qemu-system-native on macOS; use nographic
if ! grep -q 'PACKAGECONFIG:remove:pn-qemu-system-native' "${LOCAL_CONF}"; then
  echo 'PACKAGECONFIG:remove:pn-qemu-system-native = " sdl"' >> "${LOCAL_CONF}"
fi

exec bitbake "$@"
