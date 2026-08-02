# fedora-cosmic-atomic-dx — Justfile
# Run `just` or `just --list` to see available commands

image := "fedora-cosmic-atomic-dx-nvidia"
tag := "44"
full_image := "localhost/" + image + ":" + tag

# Build the OCI image locally
build:
    podman build --no-cache -t {{ image }}:{{ tag }} .

# Build and install (rebases your system)
install: build
    podman save {{ image }}:{{ tag }} | sudo podman load
    @bash scripts/pin-current.sh
    @sudo rpm-ostree rebase ostree-unverified-image:containers-storage:{{ full_image }}@$(sudo podman image inspect {{ full_image }} --format '{{"{{.Digest}}"}}' 2>/dev/null)
    @echo "==> Reboot to apply: sudo systemctl reboot"

# Run structural tests (no build required)
test:
    bats tests/bats/us*.bats

# Run build validation tests (requires built image)
test-build: build
    BUILD_TEST=1 bats tests/bats/build-validation.bats

# Run all tests
test-all: test test-build

# Run the bootstrap script (post-install user setup)
setup:
    bash scripts/bootstrap.sh

# Prune podman storage
clean:
    podman system prune -af
    sudo podman system prune -af 2>/dev/null || true

# Full pipeline: clean, build, test, install
all: clean build test install
