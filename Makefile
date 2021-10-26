.PHONY: vendor build_linux build_windows build_all build_all_docker
.PHONY: clean vendor release 

REGISTRY?=docker.io/flannelcni/flannel-cni-plugin

# Default tag and architecture. Can be overridden
TAG?=$(shell git describe --tags --dirty --always)
ARCH?=amd64
ALL_ARCH=("amd64" "386" "arm" "arm64" "s390x" "mips64le" "ppc64le")
# Only enable CGO (and build the UDP backend) on AMD64
ifeq ($(ARCH),amd64)
	CGO_ENABLED=1
else
	CGO_ENABLED=0
endif

# Go version to use for builds. Can be overridden
GOLANG_VERSION?=1.16.10

build_all: vendor build_all_linux build_windows
	@echo "All arches should be built for $(TAG)"

build_all_linux: vendor
	GOOS=linux GOARCH=amd64 scripts/build_flannel.sh
	GOOS=linux GOARCH=386 scripts/build_flannel.sh
	GOOS=linux GOARCH=arm scripts/build_flannel.sh
	GOOS=linux GOARCH=arm64 scripts/build_flannel.sh
	GOOS=linux GOARCH=s390x scripts/build_flannel.sh
	GOOS=linux GOARCH=mips64le scripts/build_flannel.sh
	GOOS=linux GOARCH=ppc64le scripts/build_flannel.sh

vendor:
	go mod tidy
	go mod vendor

build_all_docker: vendor 
	docker build \
		--no-cache \
		--build-arg GOLANG_VERSION=$(GOLANG_VERSION) \
		--build-arg TAG=$(TAG) \
		--build-arg ALL_ARCH=$(ALL_ARCH) \
		--tag $(REGISTRY):$(TAG) \
		--tag $(REGISTRY):$(TAG)-$(ARCH) \
		-f Dockerfile \
		.

build_linux: vendor
	GOOS=linux GOARCH=$(ARCH) scripts/build_flannel.sh

build_windows: vendor
	GOOS=windows GOARCH=$(ARCH) scripts/build_flannel.sh

test_linux: vendor
	scripts/test_linux.sh

clean:
	rm -f dist/flannel*
	rm -f release/cni-plugin-flannel*

release: vendor
	scripts/release.sh
	@echo "Everything should be built for $(TAG)"
	@echo "Add all flannel-* and *.tar.gz files from dist/ and release/ to the Github release"