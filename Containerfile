ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/cosmic-atomic"
ARG FEDORA_MAJOR_VERSION="44"
ARG BREW_IMAGE="ghcr.io/ublue-os/brew:latest"
ARG BREW_IMAGE_SHA=""
# Digest pin when CI provides SHA; falls back to tag for local builds
FROM ${BREW_IMAGE} AS brew
FROM scratch AS ctx
COPY /system_files /system_files
COPY /build_files /build_files
COPY --from=brew /system_files /system_files/shared

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}
ARG AKMODS_FLAVOR="coreos-stable"
ARG FEDORA_MAJOR_VERSION="44"
ARG IMAGE_NAME="atomic-cosmic"
ARG IMAGE_VENDOR="jrgrant"
ARG SHA_HEAD_SHORT="unknown"
ARG UBLUE_IMAGE_TAG="stable"
ARG IMAGE_FLAVOR="dx"

RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    bash /ctx/build_files/shared/build.sh

CMD ["/sbin/init"]

# Makes /opt writeable — allows Chrome and other apps to self-update
# between image rebuilds (matches Bluefin's pattern)
RUN rm -rf /opt && ln -s /var/opt /opt

RUN bootc container lint
