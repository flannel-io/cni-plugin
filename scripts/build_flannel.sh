#!/usr/bin/env bash
set -e
cd $(dirname "$0")/..

export GOOS="${GOOS:-linux}"
export GOFLAGS="${GOFLAGS} -mod=vendor"

mkdir -p "${PWD}/bin"

echo "Building flannel for $GOOS"

if [ "$GOOS" == "linux" ]; then
    go build -o "${PWD}/bin/flannel" "$@" .
else
    go build -o "${PWD}/bin/flannel.exe" "$@" .
fi
