#!/usr/bin/env bash
set -euo pipefail

# Build a minimal image and the sample kernel module
# Usage: scripts/build-image.sh [build-dir]

BUILD_DIR_REL="${1:-build}"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)"

"${ROOT_DIR}/scripts/setup-build.sh" "${BUILD_DIR_REL}"

set +u
source "${ROOT_DIR}/layers/poky/oe-init-build-env" "${BUILD_DIR_REL}" >/dev/null
set -u

bitbake hello-mod core-image-minimal
