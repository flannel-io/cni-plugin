#!/usr/bin/env bash
set -e
cd $(dirname "$0")/..

export GOOS="${GOOS:-linux}"
export GOARCH="${GOARCH:-amd64}"
export GOFLAGS="${GOFLAGS} -mod=vendor"

mkdir -p "${PWD}/bin"

echo "Building flannel for ${GOOS} in ${GOARCH}"

if [ "$GOOS" == "linux" ]; then
    go build -o "${PWD}/bin/flannel-${GOARCH}" "$@" .
else
    go build -o "${PWD}/bin/flannel.exe" "$@" .
fi
