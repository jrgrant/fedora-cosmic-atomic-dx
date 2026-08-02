# Containerfile — Fedora COSMIC Atomic Developer Experience image
#
# Builds a custom OCI image on top of Fedora COSMIC Atomic with Bluefin-
# derived developer tooling. Two external images are composed:
#   1. quay.io/fedora-ostree-desktops/cosmic-atomic:44  (base OS)
#   2. ghcr.io/ublue-os/brew:latest                       (Homebrew layer)
#
# Design decisions:
#   - Digest pinning uses ${VAR:+@${VAR}} expansion — when the ARG is
#     empty (local dev), the @digest suffix is omitted entirely; when
#     populated (CI), the builder resolves to the pinned content digest.
#     This is the Null Object pattern applied to build arguments.
#   - Both images are pinned for reproducible CI builds; mutable tags
#     remain the default for local development ergonomics.
#   - BREW_IMAGE_SHA predates this file's digest-pinning strategy and
#     uses the legacy _SHA suffix; BASE_IMAGE_DIGEST uses _DIGEST.
#     Future ARGs should use _DIGEST for consistency.
#   - This file does NOT validate that resolved digests match the
#     current mutable tag — that is a CI concern, not a build concern.

ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/cosmic-atomic"
ARG FEDORA_MAJOR_VERSION="44"
ARG BREW_IMAGE="ghcr.io/ublue-os/brew:latest"
ARG BREW_IMAGE_SHA=""
ARG BASE_IMAGE_DIGEST=""
# Digest pins when CI provides them; fall back to tags for local builds
FROM ${BREW_IMAGE}${BREW_IMAGE_SHA:+@${BREW_IMAGE_SHA}} AS brew
FROM scratch AS ctx
COPY /system_files /system_files
COPY /build_files /build_files
COPY --from=brew /system_files /system_files/shared

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}${BASE_IMAGE_DIGEST:+@${BASE_IMAGE_DIGEST}}
ARG AKMODS_FLAVOR="coreos-stable"
ARG FEDORA_MAJOR_VERSION="44"
ARG IMAGE_NAME="fedora-cosmic-atomic-dx-nvidia"
ARG IMAGE_VENDOR="jrgrant"
ARG SHA_HEAD_SHORT="unknown"
ARG UBLUE_IMAGE_TAG="stable"
ARG IMAGE_FLAVOR="dx"

RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    bash /ctx/build_files/shared/build.sh

CMD ["/sbin/init"]
RUN bootc container lint
