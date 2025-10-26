#!/usr/bin/env bash
set -euo pipefail

# Create a Yocto build directory and configure layers and local.conf
# Usage: scripts/setup-build.sh [build-dir]

BUILD_DIR_REL="${1:-build}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"
LAYERS_DIR="${ROOT_DIR}/layers"
BUILD_DIR="${ROOT_DIR}/${BUILD_DIR_REL}"

export DL_DIR="${DL_DIR:-${ROOT_DIR}/cache/downloads}"
export SSTATE_DIR="${SSTATE_DIR:-${ROOT_DIR}/cache/sstate}"

mkdir -p "${DL_DIR}" "${SSTATE_DIR}"

# oe-init-build-env references unset vars; relax nounset while sourcing
set +u
source "${LAYERS_DIR}/poky/oe-init-build-env" "${BUILD_DIR_REL}" >/dev/null
set -u

BBLAYERS_CONF="${BUILD_DIR}/conf/bblayers.conf"
LOCAL_CONF="${BUILD_DIR}/conf/local.conf"

# Ensure our custom layer exists and is registered
CUSTOM_LAYER="${ROOT_DIR}/layers/meta-kernel-labs"
if [ ! -f "${CUSTOM_LAYER}/conf/layer.conf" ]; then
  echo "ERROR: Custom layer not found at ${CUSTOM_LAYER}." >&2
  exit 1
fi

add_layer() {
  local path="$1"
  if ! bitbake-layers show-layers 2>/dev/null | awk '{print $1}' | grep -qx "$path"; then
    bitbake-layers add-layer "$path"
  fi
}

# Write bblayers.conf explicitly to avoid bitbake server dependency on macOS mounts
cat >"${BBLAYERS_CONF}" <<EOF
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
  ${CUSTOM_LAYER} \
"
EOF

# Basic local.conf tuning for Mac M1 inside Docker
# Ensure MACHINE is qemuarm64 (replace if present, otherwise append)
if grep -q '^\s*MACHINE\b' "${LOCAL_CONF}"; then
  sed -i 's/^\s*MACHINE.*/MACHINE ?= "qemuarm64"/' "${LOCAL_CONF}"
else
  echo 'MACHINE ?= "qemuarm64"' >> "${LOCAL_CONF}"
fi

# Append DL_DIR and SSTATE_DIR (override any earlier defaults)
grep -q '^\s*DL_DIR\b' "${LOCAL_CONF}" || echo "DL_DIR = \"${DL_DIR}\"" >> "${LOCAL_CONF}"
grep -q '^\s*SSTATE_DIR\b' "${LOCAL_CONF}" || echo "SSTATE_DIR = \"${SSTATE_DIR}\"" >> "${LOCAL_CONF}"

# Other sensible defaults
grep -q '^\s*PACKAGE_CLASSES\b' "${LOCAL_CONF}" || echo 'PACKAGE_CLASSES = "package_ipk"' >> "${LOCAL_CONF}"
grep -q '^\s*BB_NUMBER_THREADS\b' "${LOCAL_CONF}" || echo 'BB_NUMBER_THREADS ?= "8"' >> "${LOCAL_CONF}"
grep -q '^\s*PARALLEL_MAKE\b' "${LOCAL_CONF}" || echo 'PARALLEL_MAKE ?= "-j8"' >> "${LOCAL_CONF}"

# Ensure our module gets included in the image for testing
grep -q 'hello-mod' "${LOCAL_CONF}" || echo 'IMAGE_INSTALL:append = " hello-mod"' >> "${LOCAL_CONF}"

echo "\nConfigured build dir: ${BUILD_DIR}" 
