#!/usr/bin/env bash
#
# Run CNI plugin tests.
#
# This needs sudo, as we'll be creating net interfaces.
#
set -ex

# switch into the repo root directory
cd $(dirname "$0")/..

# What version of the containernetworking/plugins should we use for testing
# We now set TEST_TAG in the Makefile and pass it in
CNI_VERSION=${TAG}

echo "Running tests"

function download_cnis {
    pushd dist/
    curl -L https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION/cni-plugins-linux-amd64-$CNI_VERSION.tgz | tar -xz
    popd
}

function testrun {
    download_cnis
    sudo -E bash -c "umask 0; PATH=${GOPATH}/dist:$(pwd)/dist:${PATH} go test $@"
}

COVERALLS=${COVERALLS:-""}

if [ -n "${COVERALLS}" ]; then
    echo "with coverage profile generation..."
else
    echo "without coverage profile generation..."
fi

PKG=${PKG:-$(go list ./... | xargs echo)}

i=0
for t in ${PKG}; do
    if [ -n "${COVERALLS}" ]; then
        COVERFLAGS="-covermode set -coverprofile ${i}.coverprofile"
    fi
    echo "${t}"
    testrun "${COVERFLAGS:-""} ${t}"
    i=$((i+1))
done

echo "Checking gofmt..."
fmtRes=$(go fmt $PKG)
if [ -n "${fmtRes}" ]; then
    echo -e "go fmt checking failed:\n${fmtRes}"
    exit 255
fi

echo "Checking govet..."
vetRes=$(go vet $PKG)
if [ -n "${vetRes}" ]; then
    echo -e "govet checking failed:\n${vetRes}"
    exit 255
fi

# TODO: Figure out how to run this outside of the containernetworking
# Run the pkg/ns tests as non root user
#mkdir /tmp/cni-rootless
#(export XDG_RUNTIME_DIR=/tmp/cni-rootless; cd pkg/ns/; unshare -rmn go test)
