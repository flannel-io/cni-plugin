#!/usr/bin/env bash
set -ex

cd $(dirname $0)/..

source ./scripts/version.sh

if [ -z "${GODEBUG}" ]; then
    EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -w"
    DEBUG_GO_GCFLAGS=""
    DEBUG_TAGS=""
else
    DEBUG_GO_GCFLAGS='-gcflags=all=-N -l'
fi

BUILDTAGS="netgo osusergo no_stage static_build"
GO_BUILDTAGS="${GO_BUILDTAGS} ${BUILDTAGS} ${DEBUG_TAGS}"
PKG="github.com/flannel-io/cni-plugin"
VENDOR_PREFIX="${PKG}/vendor/"

VERSION_FLAGS="
    -X main.Version=${VERSION}
    -X main.Commit=${COMMIT:0:8}
    -X main.Program=${PROG:-flannel}
    -X main.buildDate=${BUILD_DATE}
"
# STATIC_FLAGS='-linkmode external -extldflags "-static"'
#STATIC_FLAGS='-extldflags "-static -Wl,--fatal-warnings"'
# shellcheck disable=SC2089
STATIC_FLAGS='-extldflags "-static"'

GO_LDFLAGS="${STATIC_FLAGS} ${EXTRA_LDFLAGS}"

mkdir -p "${PWD}/dist"

if [ -z ${CGO_ENABLED} ]; then
  CGO_ENABLED=${CGO_ENABLED}
else
  CGO_ENABLED=0
fi

echo "Building flannel for ${GOOS} in ${GOARCH}"
echo "${DEBUG_GO_GCFLAGS}"

if [ "${GOOS}" = "linux" ]; then
    go build \
    -tags "${GO_BUILDTAGS}" \
    ${GO_GCFLAGS} ${GO_BUILD_FLAGS} \
    -o "${PWD}/dist/${PROG}-${GOARCH}" \
    -ldflags "${GO_LDFLAGS} ${VERSION_FLAGS}" \
    ${GO_TAGS}
elif [ "${GOOS}" = "windows" ]; then
    go build \
    -tags "${GO_BUILDTAGS}" \
    ${GO_GCFLAGS} ${GO_BUILD_FLAGS} \
    -o "${PWD}/dist/${PROG}-${GOARCH}.exe" \
    -ldflags "${VERSION_FLAGS} ${GO_LDFLAGS}"
else 
   echo "GOOS:${GOOS} is not yet supported"
   echo "Please file a new GitHub issue requesting support for GOOS:${GOOS}"
   echo "https://github.com/flannel-io/cni-plugin/issues"
   exit 1
fi
