# Aurora DX (NVIDIA open) + OpenRazer driver and daemon.
#
# KERNEL_VERSION must match the base image's kernel (its "ostree.linux" label).
# The GitHub workflow reads it automatically; for a local build see README.md.

ARG BASE_IMAGE=ghcr.io/ublue-os/aurora-dx-nvidia-open:stable
ARG FEDORA_VERSION=44
ARG KERNEL_VERSION

# Universal Blue's prebuilt kmods, signed with the key Aurora already enrolls
# for Secure Boot (the same one its xone/v4l2loopback modules use).
FROM ghcr.io/ublue-os/akmods:main-${FEDORA_VERSION}-${KERNEL_VERSION} AS akmods

FROM ${BASE_IMAGE}

ARG KERNEL_VERSION

COPY build.sh /tmp/build.sh

RUN --mount=type=bind,from=akmods,src=/rpms,dst=/tmp/akmods-rpms \
    KERNEL_VERSION="${KERNEL_VERSION}" bash /tmp/build.sh && \
    rm -f /tmp/build.sh

RUN bootc container lint
