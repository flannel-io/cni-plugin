#!/usr/bin/env bash
set -e
cd $(dirname "$0")/..

if [ -z "$VERSION" ]; then
	set +e
	git describe --tags --abbrev=0 > /dev/null 2>&1
	if [ "$?" != "0" ]; then
		VERSION="master"
	else
		VERSION=$(git describe --tags --abbrev=0)
	fi
	set -e
fi

export GOOS="${GOOS:-linux}"
export GOARCH="${GOARCH:-amd64}"
export GOFLAGS="${GOFLAGS} -mod=vendor"
export GLDFLAGS+="-X main.Version=${VERSION:-master}"

mkdir -p "${PWD}/dist"

echo "Building flannel for ${GOOS} in ${GOARCH}"

if [ "$GOOS" == "linux" ]; then
    go build ${GOFLAGS} -ldflags "${GLDFLAGS}" -o "${PWD}/dist/flannel-${GOARCH}" "$@" .
else
    go build ${GOFLAGS} -ldflags "${GLDFLAGS}" -o "${PWD}/dist/flannel.exe" "$@" .
fi
