#!/usr/bin/env bash
set -euo pipefail

# Run the built core-image-minimal under QEMU (no KVM, suitable for Mac M1)
# Usage: scripts/run-qemu.sh [build-dir]

BUILD_DIR_REL="${1:-build}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"

set +u
source "${ROOT_DIR}/layers/poky/oe-init-build-env" "${BUILD_DIR_REL}" >/dev/null
set -u

# Force nographic to avoid X11/SDL requirements on macOS
export QEMU_AUDIO_DRV=none
runqemu nographic slirp
