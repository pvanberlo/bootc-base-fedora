registry := "ghcr.io/pvanberlo"
image := registry + "/bootc-base-fedora"
runtime := env("CONTAINER_RUNTIME", `command -v podman || command -v docker`)

# Build the image locally
build:
    {{runtime}} build -t {{image}}:local .

# Run a shell in the built image
run:
    {{runtime}} run --rm -it {{image}}:local /bin/bash

# Build a disk image from an explicit image ref
image type image_ref:
    #!/usr/bin/env bash
    set -euo pipefail
    # re-derived here because Just variables are not available in shebang recipes
    runtime="${CONTAINER_RUNTIME:-$(command -v podman || command -v docker)}"
    mkdir -p output
    extra_args=()
    bib_args=()
    if [ -f config.toml ]; then
        extra_args+=(-v "$(pwd)/config.toml:/config.toml")
        bib_args+=(--config /config.toml)
    fi
    # podman needs :z for SELinux relabeling; docker does not support it
    if [[ "$runtime" == *"podman"* ]]; then
        extra_args+=(-v "$(pwd)/output":/output:z)
        extra_args+=(-v /var/lib/containers/storage:/var/lib/containers/storage)
    else
        extra_args+=(-v "$(pwd)/output":/output)
    fi
    "$runtime" run --rm --privileged \
        "${extra_args[@]}" \
        quay.io/centos-bootc/bootc-image-builder:latest \
        --type {{type}} \
        --rootfs xfs \
        --output /output \
        "${bib_args[@]}" \
        {{image_ref}}
    echo "Image saved to output/{{type}}/"

# Build a disk image from the local build
image-local type:
    just image {{type}} {{image}}:local

# Build a disk image from GHCR
image-ghcr type tag="latest":
    just image {{type}} {{image}}:{{tag}}

# Remove generated disk images
clean:
    rm -rf output

# Shortcuts
qcow2:
    just image-local qcow2

vmdk:
    just image-local vmdk
