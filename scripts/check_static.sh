#!/usr/bin/env bash
set -ex

cd $(dirname $0)/..
source ./scripts/version.sh

# assert that the linux flannel-cni binary is fully statically linked
if [ $GOOS = "linux" ] && [ $GOARCH != "s390x" ] && type -a scripts/go-assert-static.sh >/dev/null 2>&1; then
    if scripts/go-assert-static.sh dist/flannel-${GOARCH}; then 
        echo "verified static links for dist/flannel-${GOARCH}"
    else
        echo "failed to verify static links for dist/flannel-${GOARCH}"
    fi
fi

# assert that the windows flannel-cni binary is fully statically linked
if [ $GOOS = "windows" ] && type -a scripts/go-assert-static.sh >/dev/null 2>&1; then
    if scripts/go-assert-static.sh dist/flannel-${GOARCH}.exe; then 
        echo "verified static links for dist/flannel-${GOARCH}.exe"
    else
        echo "failed to verify static links for dist/flannel-${GOARCH}.exe"
    fi
fi