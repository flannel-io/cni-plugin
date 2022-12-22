#!/usr/bin/env bash
set -ex

cd $(dirname $0)/..
source ./scripts/version.sh

mkdir -p "${GOPATH}"/src/github.com/flannel-io/cni-plugin/release-"${TAG}"
mkdir -p "${GOPATH}"/src/github.com/flannel-io/cni-plugin/dist
cd "${GOPATH}"/src/github.com/flannel-io/cni-plugin
umask 0022

# linux archives
for arch in amd64 386 arm arm64 s390x mips64le ppc64le; do
    echo $arch
    for format in tgz; do
        FILENAME=cni-plugin-flannel-linux-$arch-"${TAG}".$format
        FILEPATH="${RELEASE_DIR}"/$FILENAME
        tar -C "${OUTPUT_DIR}" --owner=0 --group=0 -caf "$FILEPATH" flannel-$arch
    done
done

# windows archive
FILENAME=cni-plugin-flannel-windows-"${GOARCH}"-"${TAG}".$format
FILEPATH="${RELEASE_DIR}"/$FILENAME
tar -C "${OUTPUT_DIR}" --owner=0 --group=0 -caf "$FILEPATH" flannel-amd64.exe

cd "${SRC_DIR}"
# linux
for arch in amd64 386 arm arm64 s390x mips64le ppc64le; do
  GOOS=${GOOS:-$("${GO}" env GOOS)}
  RELEASE_DIR=${GOPATH}/src/github.com/flannel-io/cni-plugin/release-"${TAG}" \
  OUTPUT_DIR=${GOPATH}/src/github.com/flannel-io/cni-plugin/dist \
  GOARCH=$arch ./scripts/check_static.sh >> static-check.log
done

# windows
for arch in amd64; do
  unset GOARCH
  unset GOOS
  echo $arch
  RELEASE_DIR=${GOPATH}/src/github.com/flannel-io/cni-plugin/release-"${TAG}" \
  OUTPUT_DIR=${GOPATH}/src/github.com/flannel-io/cni-plugin/dist \
  GOARCH=$arch GOOS=windows ./scripts/check_static.sh >> static-check.log
done

cd "${RELEASE_DIR}"
for f in *.tgz; do sha1sum $f > $f.sha1; done
for f in *.tgz; do sha256sum $f > $f.sha256; done
for f in *.tgz; do sha512sum $f > $f.sha512; done