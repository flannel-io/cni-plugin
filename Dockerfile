ARG GOLANG_VERSION
FROM library/golang:${GOLANG_VERSION}-alpine AS build
ARG TAG
RUN set -x \
    && apk --no-cache add \
    bash \
    curl \
    git \
    tar
COPY ./scripts/semver-parse.sh /semver-parse.sh
RUN chmod +x /semver-parse.sh
RUN curl -sL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s v1.43.0
RUN git clone -b $(/semver-parse.sh ${TAG} all) --depth=1 https://github.com/flannel-io/cni-plugin ${GOPATH}/src/github.com/flannel-io/cni-plugin
WORKDIR ${GOPATH}/src/github.com/flannel-io/cni-plugin


FROM build AS flannel-cni
ARG TAG

WORKDIR ${GOPATH}/src/github.com/flannel-io/cni-plugin

RUN \
    set -ex; \
    source ./scripts/version.sh; \
    chmod +x ./scripts/*

ENV SRC_DIR=${SRC_DIR:-${pwd}}
ENV DOCKER=${DOCKER:-docker}
ENV GO=${GO:-go}
ENV GOPATH=${GOPATH:-'${go env GOPATH}'}
ENV RELEASE_DIR=${GOPATH}/src/github.com/flannel-io/cni-plugin/release-${TAG}
ENV OUTPUT_DIR=${GOPATH}/src/github.com/flannel-io/cni-plugin/dist

# Always clean first
RUN \
    rm -rf ${OUTPUT_DIR} \
    && rm -rf ${RELEASE_DIR} \
    && mkdir -p ${RELEASE_DIR} \
    && mkdir -p ${OUTPUT_DIR}

RUN go mod vendor && go mod tidy

# for ARCH IN ${ALL_ARCH}; do
RUN \
    for arch in amd64 386 arm arm64 s390x mips64le ppc64le; do \
        GOARCH=${arch} ./scripts/build_flannel.sh; \
        for format in tgz; do \
            FILENAME=cni-plugin-flannel-linux-${arch}-${TAG}.${format}; \
            FILEPATH=${RELEASE_DIR}/${FILENAME}; \
            tar -C ${OUTPUT_DIR} --owner=0 --group=0 -caf ${FILEPATH} . ; \
        done; \
    done

RUN \
    GOOS=windows GOARCH=amd64 ./scripts/build_flannel.sh; \
    for format in tgz; do \
        FILENAME=cni-plugin-flannel-windows-${GOARCH}-${TAG}.${format}; \
        FILEPATH=${RELEASE_DIR}/${FILENAME}; \
        tar -C ${OUTPUT_DIR} --owner=0 --group=0 -caf ${FILEPATH} . ; \
    done

RUN \
    for arch in amd64 386 arm arm64 s390x mips64le ppc64le; do \
        GOARCH=${arch} ./scripts/check_static.sh >> static-check.log; \
    done


WORKDIR ${RELEASE_DIR}
RUN \
    for f in *.tgz; do sha1sum ${f} > ./${f}.sha1; done; \
    for f in *.tgz; do sha256sum ${f} > ./${f}.sha256; done; \
    for f in *.tgz; do sha512sum ${f} > ./${f}.sha512; done;

FROM build AS flannel-cni-collect
ARG TAG
COPY --from=flannel-cni  ${GOPATH}/src/github.com/flannel-io/cni-plugin/dist/ /go/src/github.com/flannel-io/cni-plugin/dist/
COPY --from=flannel-cni  ${GOPATH}/src/github.com/flannel-io/cni-plugin/release-${TAG}/ /go/src/github.com/flannel-io/cni-plugin/release-${TAG}/
COPY --from=flannel-cni  ${GOPATH}/src/github.com/flannel-io/cni-plugin/static-check.log /go/src/github.com/flannel-io/cni-plugin/static-check.log
