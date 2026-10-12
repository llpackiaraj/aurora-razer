# aurora-razer

[Aurora DX (NVIDIA open)](https://getaurora.dev) with [OpenRazer](https://openrazer.github.io) built in, so Razer devices get full control (DPI, polling rate, battery, Chroma lighting) through [Polychromatic](https://polychromatic.app).

What it adds on top of `ghcr.io/ublue-os/aurora-dx-nvidia-open:stable`:

- **OpenRazer kernel driver**, prebuilt by Universal Blue for the exact kernel in each Aurora build and signed with the key Aurora already uses, so it works with **Secure Boot**. No DKMS/akmods compiling on your PC.
- **openrazer-daemon** from [Terra](https://terra.fyralabs.com), the same source Bazzite uses, enabled as a user service.

Nothing else changes. A GitHub Actions workflow checks Aurora every day and rebuilds when it has an update, so you keep getting normal Aurora updates.

## Switch to this image

Your layered packages carry over, and the previous image stays in the boot menu for rollback.

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/llpackiaraj/aurora-razer:latest
systemctl reboot
```

After rebooting:

```bash
# You need to be in the plugdev group (check with: id -nG)
sudo usermod -aG plugdev "$USER"   # only if plugdev is missing, then log out and back in

# The GUI
flatpak install -y flathub app.polychromatic.controller

# Check the daemon sees your devices
systemctl --user status openrazer-daemon
```

## Go back to stock Aurora

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/aurora-dx-nvidia-open:stable
systemctl reboot
```

## Build locally

```bash
KERNEL=$(skopeo inspect docker://ghcr.io/ublue-os/aurora-dx-nvidia-open:stable --format '{{index .Labels "ostree.linux"}}')
podman build --build-arg KERNEL_VERSION="$KERNEL" -t localhost/aurora-razer .
```

## Notes

- The image isn't signed, hence `ostree-unverified-registry`. It's built only from this repo's public workflow.
- If a build fails because Universal Blue hasn't published the driver for a new kernel yet, the next daily run picks it up. Your PC just stays on the previous image meanwhile.
