.PHONY: vendor build_linux build_windows build_all build_all_docker
.PHONY: clean vendor release

REGISTRY?=docker.io/flannel/flannel-cni-plugin

# Default tag and architecture. Can be overridden
TAG?=$(shell git describe --tags --dirty --always)
ARCH?=amd64
SRC_DIR?=$(pwd)
GO?=$(go)
GOPATH?=$(go env GOPATH)

# this is the upstream CNI plugin version used for testing
TEST_TAG?=v1.4.1

# Only enable CGO (and build the UDP backend) on AMD64
ifeq ($(ARCH),amd64)
	CGO_ENABLED=1
else
	CGO_ENABLED=0
endif

# Go version to use for builds. Can be overridden
GOLANG_VERSION?=1.21.11

build_all: vendor build_all_linux build_windows
	@echo "All arches should be built for $(TAG)"

build_all_linux: vendor
	GOOS=linux GOARCH=amd64 scripts/build_flannel.sh
	GOOS=linux GOARCH=386 scripts/build_flannel.sh
	GOOS=linux GOARCH=arm scripts/build_flannel.sh
	GOOS=linux GOARCH=arm64 scripts/build_flannel.sh
	GOOS=linux GOARCH=s390x scripts/build_flannel.sh
	GOOS=linux GOARCH=ppc64le scripts/build_flannel.sh
	GOOS=linux GOARCH=riscv64 scripts/build_flannel.sh

vendor:
	go mod tidy
	go mod vendor

build_all_docker: vendor
	docker build \
		--no-cache \
		--build-arg GOLANG_VERSION=$(GOLANG_VERSION) \
		--build-arg TAG=$(TAG) \
		--tag $(REGISTRY):$(TAG) \
		--tag $(REGISTRY):$(TAG)-$(ARCH) \
		-f Dockerfile \
		.

build_linux: vendor
	GOOS=linux GOARCH=$(ARCH) scripts/build_flannel.sh

build_windows: vendor
	GOOS=windows GOARCH=$(ARCH) scripts/build_flannel.sh

test_linux: vendor build_linux
	TAG=$(TEST_TAG) scripts/test_linux.sh

clean:
	rm -f dist/flannel*
	rm -f release/cni-plugin-flannel*

package: vendor
	scripts/package.sh

release: build_all
	scripts/package.sh

release_docker: clean vendor
	scripts/release.sh
	@echo "Everything should be built for $(TAG)"
	@echo "Add all flannel-* and *.tar.gz files from dist/ and release/ to the Github release"
