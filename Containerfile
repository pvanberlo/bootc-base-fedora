FROM quay.io/fedora/fedora-bootc:44

RUN dnf upgrade -y && \
    dnf clean all

COPY rootfs/ /
