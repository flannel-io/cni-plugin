#!/usr/bin/env bash
set -ex

cd "$(dirname "${0}")"/..
source ./scripts/version.sh

SRC_DIR=${SRC_DIR:-$PWD}
DOCKER=${DOCKER:-docker}
GO=${GO:-go}
GOPATH=${GOPATH:-$(go env GOPATH)}

RELEASE_DIR=${GOPATH}/src/github.com/flannel-io/cni-plugin/release-"${TAG}"
OUTPUT_DIR=${GOPATH}/src/github.com/flannel-io/cni-plugin/dist

# Always clean first
rm -rf "${OUTPUT_DIR}"
rm -rf "${RELEASE_DIR}"
mkdir -p "${RELEASE_DIR}"
mkdir -p "${OUTPUT_DIR}"


$DOCKER run -ti -v "${SRC_DIR}":"${GOPATH}"/src/github.com/flannel-io/cni-plugin:z -e TAG="${TAG}" --rm golang:"${GOLANG_VERSION}-alpine" \
/bin/sh -ex -c "\
    mkdir -p ${GOPATH}/src/github.com/flannel-io/cni-plugin/release-${TAG};
    mkdir -p ${GOPATH}/src/github.com/flannel-io/cni-plugin/dist;
    cd ${GOPATH}/src/github.com/flannel-io/cni-plugin; umask 0022;
    apk --no-cache add bash tar git; \
    source ./scripts/version.sh; \
        chmod +x ./scripts/* ; 

    go mod vendor && go mod tidy

    for arch in amd64 386 arm arm64 s390x mips64le ppc64le; do \
        echo \$arch;\
        GOARCH=\$arch ./scripts/build_flannel.sh; \
        for format in tgz; do \
            FILENAME=cni-plugin-flannel-linux-\$arch-${TAG}.\$format; \
            FILEPATH=${RELEASE_DIR}/\$FILENAME; \
            tar -C ${OUTPUT_DIR} --owner=0 --group=0 -caf \$FILEPATH . ; \
        done; \
    done;

    GOOS=windows GOARCH=amd64 ./scripts/build_flannel.sh; \
    for format in tgz; do \
        FILENAME=cni-plugin-flannel-windows-${GOARCH}-${TAG}.\$format; \
        FILEPATH=${RELEASE_DIR}/\$FILENAME; \
        tar -C ${OUTPUT_DIR} --owner=0 --group=0 -caf \$FILEPATH . ; \
    done;

    for arch in amd64 386 arm arm64 s390x mips64le ppc64le; do \
        GOARCH=\$arch ./scripts/check_static.sh >> static-check.log; \
    done;

    cd ${RELEASE_DIR}; \
        for f in *.tgz; do sha1sum \$f > \$f.sha1; done; \
        for f in *.tgz; do sha256sum \$f > \$f.sha256; done; \
        for f in *.tgz; do sha512sum \$f > \$f.sha512; done;
    "
