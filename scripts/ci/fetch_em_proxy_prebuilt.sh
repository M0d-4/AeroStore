#!/usr/bin/env bash
# Download libem_proxy-ios.a / libem_proxy-sim.a etc. before xcodebuild (same as em_proxy Xcode "Fetch prebuilt" phase).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EM="${ROOT}/Dependencies/em_proxy"
CLONE_URL="${FLUXSTORE_EM_PROXY_CLONE_URL:-https://github.com/SideStore/em_proxy.git}"
# SideStore/em_proxy `master` tip no longer ships fetch-prebuilt.sh + em_proxy.xcodeproj; pin the tree FluxStore expects.
# Bump when you update the Dependencies/em_proxy submodule in this repo (match `git ls-tree HEAD Dependencies/em_proxy`).
DEFAULT_EM_PROXY_REV="816dc73350dd456a24232963db77a3064fd9af8a"
REV="${FLUXSTORE_EM_PROXY_REV:-${DEFAULT_EM_PROXY_REV}}"

ensure_em_proxy_tree() {
  if [[ -f "${EM}/fetch-prebuilt.sh" ]]; then
    return 0
  fi
  echo "Dependencies/em_proxy missing or incomplete; trying git submodule…" >&2
  cd "${ROOT}"
  git submodule sync --recursive || true
  git submodule update --init --recursive "Dependencies/em_proxy" || true
  if [[ -f "${EM}/fetch-prebuilt.sh" ]]; then
    return 0
  fi
  echo "Submodule did not populate em_proxy; cloning ${CLONE_URL} at ${REV}…" >&2
  rm -rf "${EM}"
  mkdir -p "$(dirname "${EM}")"
  git clone --recursive "${CLONE_URL}" "${EM}"
  git -C "${EM}" checkout -q "${REV}"
  git -C "${EM}" submodule update --init --recursive
  if [[ ! -f "${EM}/fetch-prebuilt.sh" ]]; then
    echo "error: em_proxy checkout at ${REV} has no fetch-prebuilt.sh under ${EM}" >&2
    exit 1
  fi
}

ensure_em_proxy_tree
cd "${EM}"

if ! command -v wget >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install wget
  else
    echo "error: wget is required to fetch em_proxy prebuilts" >&2
    exit 1
  fi
fi
chmod +x ./fetch-prebuilt.sh
./fetch-prebuilt.sh em_proxy
test -f libem_proxy-ios.a && test -f libem_proxy-sim.a && test -f em_proxy.h
echo "em_proxy prebuilts OK."
