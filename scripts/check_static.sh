#!/usr/bin/env bash
set -ex

cd $(dirname $0)/..
source ./scripts/version.sh

# assert that the linux flannel cni-plugin binary is fully statically linked

if [[ ${GOOS} == "linux" ]] && type -a scripts/go-assert-static.sh >/dev/null 2>&1; then
  if GOOS=${GOOS} scripts/go-assert-static.sh ${OUTPUT_DIR}/flannel-${GOARCH}; then
    printf 'verified static links for flannel-%s\n' "${GOARCH}"
  else
    echo "failed to verify static links for dist/flannel-${GOARCH}"
  fi
fi

# assert that the windows flannel cni-plugin binary is fully statically linked
if [[ ${GOOS} == "windows" ]] && type -a scripts/go-assert-static.sh >/dev/null 2>&1; then
  if GOOS=${GOOS} scripts/go-assert-static.sh ${OUTPUT_DIR}/flannel-${GOARCH}.exe; then
    printf 'verified static links for flannel-%s.exe\n' "${GOARCH}"
  else
    echo "failed to verify static links for dist/flannel-${GOARCH}.exe"
  fi
fi
