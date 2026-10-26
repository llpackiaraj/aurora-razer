#!/usr/bin/bash
# Runs inside the image build. Installs the OpenRazer kernel module from
# Universal Blue's akmods image and the daemon from Terra (as Bazzite does).
set -euo pipefail

: "${KERNEL_VERSION:?KERNEL_VERSION is required}"

# Fail early if the akmods image was built for a different kernel than the base.
installed_kernel="$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core | tail -n1)"
if [[ "${installed_kernel}" != "${KERNEL_VERSION}" ]]; then
    echo "Kernel mismatch: base has ${installed_kernel}, akmods built for ${KERNEL_VERSION}" >&2
    exit 1
fi

shopt -s nullglob
kmod_rpms=(/tmp/akmods-rpms/kmods/kmod-openrazer-*.rpm)
if [[ ${#kmod_rpms[@]} -eq 0 ]]; then
    echo "OpenRazer kernel RPM not found in the akmods image" >&2
    exit 1
fi

# Temporary Terra repo for matching userspace packages. Its kmod/akmod builds are excluded
# so the signed Universal Blue module is the only one that can be installed.
cat > /etc/yum.repos.d/terra-build.repo <<'EOF'
[terra-build]
name=Terra $releasever (build only)
baseurl=https://repos.fyralabs.com/terra$releasever
type=rpm
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://repos.fyralabs.com/terra$releasever/key.asc
enabled=1
excludepkgs=akmod-openrazer kmod-openrazer*
EOF

dnf -y install \
    "${kmod_rpms[@]}" \
    openrazer \
    openrazer-daemon \
    python3-openrazer

rm -f /etc/yum.repos.d/terra-build.repo

# Sanity checks: module present for this kernel, daemon installed.
test -f "/usr/lib/modules/${KERNEL_VERSION}/extra/openrazer/razermouse.ko.xz"
rpm -q kmod-openrazer openrazer openrazer-daemon python3-openrazer

# The daemon is a systemd user service; start it for every user.
if [[ -f /usr/lib/systemd/user/openrazer-daemon.service ]]; then
    systemctl --global enable openrazer-daemon.service
fi

dnf clean all
rm -rf /var/cache/dnf /var/cache/libdnf5 /var/lib/dnf /var/log/dnf* /run/dnf
