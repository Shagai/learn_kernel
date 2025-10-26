#!/usr/bin/env bash
set -euo pipefail

# Fetch poky + meta-openembedded into ./layers
# Usage: scripts/bootstrap.sh [scarthgap|styhead|kirkstone]

BRANCH="${1:-${YOCTO_BRANCH:-scarthgap}}"
LAYERS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. && pwd)/layers"

mkdir -p "${LAYERS_DIR}"
cd "${LAYERS_DIR}"

clone_layer() {
  local repo="$1" name="$2" branch="$3"
  if [ ! -d "${name}" ]; then
    echo "Cloning ${name} (${branch})..."
    git clone --branch "${branch}" --depth 1 "${repo}" "${name}"
  else
    echo "Updating ${name}..."
    (cd "${name}" && git fetch --depth 1 origin "${branch}" && git checkout -B "${branch}" "origin/${branch}")
  fi
}

clone_layer https://git.yoctoproject.org/poky poky "${BRANCH}"
clone_layer https://github.com/openembedded/meta-openembedded meta-openembedded "${BRANCH}"

echo "\nDone. Layers available in ${LAYERS_DIR}" 
