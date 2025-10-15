#!/bin/bash
set -ex

PROG=${PROG:-flannel}
REGISTRY=${REGISTRY:-docker.io/flannel/flannel-cni-plugin}
REPO=${REPO:-rancher}
GO=${GO-go}
GOARCH=${GOARCH:-$("${GO}" env GOARCH)}
GOOS=${GOOS:-$("${GO}" env GOOS)}
SRC_DIR=${SRC_DIR:-$PWD}
DOCKER=${DOCKER:-docker}
GOPATH=${GOPATH:-$(go env GOPATH)}

if [ -z "$GOOS" ]; then
    if [ "${OS}" == "Windows_NT" ]; then
      GOOS="windows"
    else
      UNAME_S=$(shell uname -s)
		  if [ "${UNAME_S}" == "Linux" ]; then
			    GOOS="linux"
		  elif [ "${UNAME_S}" == "Darwin" ]; then
				  GOOS="darwin"
		  elif [ "${UNAME_S}" == "FreeBSD" ]; then
				  GOOS="freebsd"
		  fi
    fi
fi

GIT_TAG=$(git describe --tags --dirty --always)
TREE_STATE=clean
COMMIT=$(git rev-parse HEAD)$(if ! git diff --no-ext-diff --quiet --exit-code; then echo .dirty; fi)
PLATFORM=${GOOS}-${GOARCH}
RELEASE=${PROG}-${GOARCH}
# hardcode versions unless set specifically
VERSION=${VERSION:-v1.0.0}
GOLANG_VERSION=${GOLANG_VERSION:-1.24.3}

if [ -d .git ]; then
    COMMIT=$(git log -n3 --pretty=format:"%H %ae" | cut -f1 -d\  | head -1)
    if [ -z "${COMMIT}" ]; then
        COMMIT=$(git rev-parse HEAD || true)
    fi
fi

VERSION="${GIT_TAG:0:6}"

if [ -z "${TAG}" ]; then
  TAG=${VERSION}
fi

RELEASE_DIR=release
OUTPUT_DIR=dist

echo  "Version: ${VERSION}"
echo  "Commit: ${COMMIT}"

