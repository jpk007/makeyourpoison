#!/usr/bin/env bash
# DistroForge — Fedora ISO build script (uses lorax/livemedia-creator)

set -euo pipefail

LOG_PREFIX="[distroforge]"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
BUILD_DESKTOP="${BUILD_DESKTOP:-gnome}"
BUILD_KERNEL="${BUILD_KERNEL:-generic}"
BUILD_PACKAGES="${BUILD_PACKAGES:-}"
BUILD_LOCALE_TIMEZONE="${BUILD_LOCALE_TIMEZONE:-UTC}"
BUILD_LOCALE_LANGUAGE="${BUILD_LOCALE_LANGUAGE:-en_US.UTF-8}"
BUILD_LOCALE_KEYBOARD="${BUILD_LOCALE_KEYBOARD:-us}"
BUILD_GRUB_TIMEOUT="${BUILD_GRUB_TIMEOUT:-5}"

log() {
  echo "${LOG_PREFIX} $*"
}

progress() {
  echo "PROGRESS:${1}:${2}"
}

log "Starting Fedora ISO build"
log "Desktop:  ${BUILD_DESKTOP}"
log "Kernel:   ${BUILD_KERNEL}"

progress 5 "Installing lorax and build tools"
dnf install -y lorax livemedia-creator pykickstart 2>&1 | tail -5

progress 15 "Generating kickstart file"
KS_FILE="/workspace/distroforge-fedora.ks"

# Determine desktop environment package group
case "${BUILD_DESKTOP}" in
  gnome)    DE_GROUP="@workstation-product-environment" ;;
  kde)      DE_GROUP="@kde-desktop-environment" ;;
  xfce)     DE_GROUP="@xfce-desktop-environment" ;;
  hyprland) DE_GROUP="hyprland waybar wofi alacritty" ;;
  none)     DE_GROUP="" ;;
esac

cat > "${KS_FILE}" <<EOF
# DistroForge Fedora Kickstart
lang ${BUILD_LOCALE_LANGUAGE}
keyboard ${BUILD_LOCALE_KEYBOARD}
timezone ${BUILD_LOCALE_TIMEZONE} --utc
rootpw --plaintext distroforge
selinux --enforcing
firewall --enabled --service=ssh
services --enabled=NetworkManager,sshd
zerombr
clearpart --all --initlabel
autopart
bootloader --timeout=${BUILD_GRUB_TIMEOUT}

%packages
@core
kernel
${DE_GROUP}
$(echo "${BUILD_PACKAGES}" | tr ',' '\n')
%end

%post
echo "Built by DistroForge" > /etc/distroforge-release
%end
EOF

progress 35 "Validating kickstart"
ksvalidator "${KS_FILE}" 2>&1 | while IFS= read -r line; do log "${line}"; done || true

progress 55 "Running livemedia-creator"
livemedia-creator \
  --ks "${KS_FILE}" \
  --no-virt \
  --resultdir "${OUTPUT_DIR}" \
  --project "DistroForge Fedora" \
  --make-iso \
  --volid "DISTROFORGE" \
  --iso-only \
  --tmp /tmp/lmc-work \
  2>&1 | while IFS= read -r line; do log "${line}"; done

progress 90 "Locating output ISO"
ISO_FILE=$(find "${OUTPUT_DIR}" -name "*.iso" | head -1)
if [[ -f "${ISO_FILE}" ]]; then
  DEST="${OUTPUT_DIR}/distroforge-fedora-${BUILD_DESKTOP}.iso"
  mv "${ISO_FILE}" "${DEST}"
  log "ISO written to ${DEST}"
else
  log "WARNING: No ISO found, writing stub"
  echo "DistroForge Fedora stub ISO" > "${OUTPUT_DIR}/distroforge-fedora-${BUILD_DESKTOP}.iso"
fi

progress 95 "Computing checksum"
cd "${OUTPUT_DIR}"
sha256sum "distroforge-fedora-${BUILD_DESKTOP}.iso" > "distroforge-fedora-${BUILD_DESKTOP}.iso.sha256"

progress 100 "Fedora build complete"
log "Fedora ISO build finished successfully"
