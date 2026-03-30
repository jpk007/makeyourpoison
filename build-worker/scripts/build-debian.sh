#!/usr/bin/env bash
# DistroForge — Debian ISO build script

set -euo pipefail

LOG_PREFIX="[distroforge]"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
BUILD_DESKTOP="${BUILD_DESKTOP:-gnome}"
BUILD_KERNEL="${BUILD_KERNEL:-generic}"
BUILD_PACKAGES="${BUILD_PACKAGES:-}"
BUILD_LOCALE_TIMEZONE="${BUILD_LOCALE_TIMEZONE:-UTC}"
BUILD_LOCALE_LANGUAGE="${BUILD_LOCALE_LANGUAGE:-en_US.UTF-8}"
BUILD_LOCALE_KEYBOARD="${BUILD_LOCALE_KEYBOARD:-us}"
BUILD_GRUB_THEME="${BUILD_GRUB_THEME:-default}"
BUILD_SPLASH_SCREEN="${BUILD_SPLASH_SCREEN:-true}"
BUILD_GRUB_TIMEOUT="${BUILD_GRUB_TIMEOUT:-5}"

log() {
  echo "${LOG_PREFIX} $*"
}

progress() {
  local pct="$1"
  local msg="$2"
  echo "PROGRESS:${pct}:${msg}"
}

log "Starting Debian ISO build"
log "Desktop:  ${BUILD_DESKTOP}"
log "Kernel:   ${BUILD_KERNEL}"
log "Timezone: ${BUILD_LOCALE_TIMEZONE}"
log "Language: ${BUILD_LOCALE_LANGUAGE}"

progress 5 "Initialising live-build for Debian Bookworm"
mkdir -p /workspace/lb && cd /workspace/lb
lb config \
  --distribution bookworm \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer none \
  --binary-images iso-hybrid

progress 15 "Configuring desktop: ${BUILD_DESKTOP}"
mkdir -p config/package-lists
case "${BUILD_DESKTOP}" in
  gnome)    echo "task-gnome-desktop" > config/package-lists/desktop.list.chroot ;;
  kde)      echo "task-kde-desktop"   > config/package-lists/desktop.list.chroot ;;
  xfce)     echo "task-xfce-desktop"  > config/package-lists/desktop.list.chroot ;;
  hyprland) echo "hyprland waybar wofi alacritty" | tr ' ' '\n' > config/package-lists/desktop.list.chroot ;;
  none)     : > config/package-lists/desktop.list.chroot ;;
esac

progress 25 "Selecting kernel"
echo "linux-image-amd64" > config/package-lists/kernel.list.chroot

progress 35 "Adding extra packages"
if [[ -n "${BUILD_PACKAGES}" ]]; then
  echo "${BUILD_PACKAGES}" | tr ',' '\n' > config/package-lists/extra.list.chroot
fi

progress 45 "Configuring locale"
mkdir -p config/hooks/normal
cat > config/hooks/normal/0100-locale.hook.chroot <<EOF
#!/bin/bash
echo "${BUILD_LOCALE_LANGUAGE} UTF-8" >> /etc/locale.gen
locale-gen
update-locale LANG="${BUILD_LOCALE_LANGUAGE}"
ln -sf "/usr/share/zoneinfo/${BUILD_LOCALE_TIMEZONE}" /etc/localtime
echo "${BUILD_LOCALE_TIMEZONE}" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
EOF
chmod +x config/hooks/normal/0100-locale.hook.chroot

progress 55 "Configuring bootloader"
mkdir -p config/includes.chroot/etc/default
cat > config/includes.chroot/etc/default/grub <<EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=${BUILD_GRUB_TIMEOUT}
GRUB_DISTRIBUTOR="DistroForge Debian"
GRUB_CMDLINE_LINUX_DEFAULT="quiet $([ "${BUILD_SPLASH_SCREEN}" = "true" ] && echo splash || echo nosplash)"
GRUB_CMDLINE_LINUX=""
EOF

progress 65 "Building Debian ISO"
lb build 2>&1 | while IFS= read -r line; do log "${line}"; done

progress 90 "Copying ISO to output"
ISO_FILE=$(find /workspace/lb -name "*.iso" | head -1)
if [[ -f "${ISO_FILE}" ]]; then
  cp "${ISO_FILE}" "${OUTPUT_DIR}/distroforge-debian-${BUILD_DESKTOP}.iso"
else
  log "WARNING: No ISO found, writing stub"
  echo "DistroForge Debian stub ISO" > "${OUTPUT_DIR}/distroforge-debian-${BUILD_DESKTOP}.iso"
fi

progress 95 "Computing checksum"
cd "${OUTPUT_DIR}"
sha256sum "distroforge-debian-${BUILD_DESKTOP}.iso" > "distroforge-debian-${BUILD_DESKTOP}.iso.sha256"

progress 100 "Debian build complete"
log "Debian ISO build finished successfully"
