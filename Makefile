.PHONY: build_linux build_windows test_linux
.PHONY: clean release

REGISTRY?=rancher/flannel-cni-plugin
QEMU_VERSION=v3.0.0

# Default tag and architecture. Can be overridden
TAG?=$(shell git describe --tags --dirty --always)
ARCH?=amd64
# Only enable CGO (and build the UDP backend) on AMD64
ifeq ($(ARCH),amd64)
	CGO_ENABLED=1
else
	CGO_ENABLED=0
endif

# Go version to use for builds
GO_VERSION=1.15.5

release: dist/qemu-s390x-static dist/qemu-ppc64le-static dist/qemu-aarch64-static dist/qemu-arm-static
	ARCH=amd64 make dist/flannel-$(TAG)-amd64.docker
	ARCH=arm make dist/flannel-$(TAG)-arm.docker
	ARCH=arm64 make dist/flannel-$(TAG)-arm64.docker
	ARCH=ppc64le make dist/flannel-$(TAG)-ppc64le.docker
	ARCH=s390x make dist/flannel-$(TAG)-s390x.docker
	@echo "Everything should be built for $(TAG)"
	@echo "Add all flannel-* and *.tar.gz files from dist/ to the Github release"
	@echo "Use make docker-push-all to push the images to a registry"

dist/flannel-$(TAG)-$(ARCH).docker: dist/flannel-$(ARCH)
	docker build -f Dockerfile.$(ARCH) -t $(REGISTRY):$(TAG)-$(ARCH) .
#	docker save -o dist/flannel-$(TAG)-$(ARCH).docker $(REGISTRY):$(TAG)-$(ARCH)

build_linux:
	GOOS=linux scripts/build_flannel.sh

build_windows:
	GOOS=windows scripts/build_flannel.sh

# This will build flannel cni-plugin natively using golang image
dist/flannel-$(ARCH): dist/qemu-$(ARCH)-static
	# valid values for ARCH are [amd64 arm arm64 ppc64le s390x]
	docker run -e CGO_ENABLED=$(CGO_ENABLED) -e GOARCH=$(ARCH) -e GOCACHE=/go -e GOOS=linux -e  GOFLAGS="${GOFLAGS} -mod=vendor" \
		-u $(shell id -u):$(shell id -g) \
		-v $(CURDIR)/dist/qemu-$(ARCH)-static:/usr/bin/qemu-$(ARCH)-static \
		-v $(CURDIR):/go/src/github.com/flannel-io/flannel:ro \
		-v $(CURDIR)/bin:/go/src/github.com/flannel-io/flannel/bin \
		-v $(CURDIR)/dist:/go/src/github.com/flannel-io/flannel/dist \
		golang:$(GO_VERSION) /bin/bash -c '\
		cd /go/src/github.com/flannel-io/flannel && \
        go build -o "./bin/flannel" . && \
		mv bin/flannel dist/flannel-$(ARCH)'

dist/qemu-%-static:
	if [ "$(@F)" = "qemu-amd64-static" ]; then \
		wget -O dist/qemu-amd64-static https://github.com/multiarch/qemu-user-static/releases/download/$(QEMU_VERSION)/qemu-x86_64-static; \
	elif [ "$(@F)" = "qemu-arm64-static" ]; then \
		wget -O dist/qemu-arm64-static https://github.com/multiarch/qemu-user-static/releases/download/$(QEMU_VERSION)/qemu-aarch64-static; \
	else \
		wget -O dist/$(@F) https://github.com/multiarch/qemu-user-static/releases/download/$(QEMU_VERSION)/$(@F); \
	fi 

docker-push: dist/flannel-$(TAG)-$(ARCH).docker
	docker push $(REGISTRY):$(TAG)-$(ARCH)

docker-manifest-amend:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend $(REGISTRY):$(TAG) $(REGISTRY):$(TAG)-$(ARCH)

docker-manifest-push:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push --purge $(REGISTRY):$(TAG)

docker-push-all:
	ARCH=amd64 make docker-push docker-manifest-amend
	ARCH=arm make docker-push docker-manifest-amend
	ARCH=arm64 make docker-push docker-manifest-amend
	ARCH=ppc64le make docker-push docker-manifest-amend
	ARCH=s390x make docker-push docker-manifest-amend
	make docker-manifest-push

test_linux:
	scripts/test_linux.sh

build_image: build_linux
	docker build . -f Dockerfile.linux

push_image: build_image
	docker push quay.io/coreos/flannel-cni:${VERSION}

clean:
	rm -f dist/flannel*
	rm -f dist/qemu-*

#release: build_image test_linux push_image


