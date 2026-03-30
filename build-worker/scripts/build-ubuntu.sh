#!/usr/bin/env bash
# DistroForge — Ubuntu ISO build script
# Bottom-up: Linux kernel → debootstrap chroot → squashfs → bootable ISO
# No live-build dependency.

set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────────
LOG_PREFIX="[distroforge]"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
BUILD_DESKTOP="${BUILD_DESKTOP:-gnome}"
BUILD_KERNEL="${BUILD_KERNEL:-generic}"
BUILD_PACKAGES="${BUILD_PACKAGES:-}"
BUILD_APP_BUNDLES="${BUILD_APP_BUNDLES:-}"
BUILD_LOCALE_TIMEZONE="${BUILD_LOCALE_TIMEZONE:-UTC}"
BUILD_LOCALE_LANGUAGE="${BUILD_LOCALE_LANGUAGE:-en_US.UTF-8}"
BUILD_LOCALE_KEYBOARD="${BUILD_LOCALE_KEYBOARD:-us}"
BUILD_SPLASH_SCREEN="${BUILD_SPLASH_SCREEN:-true}"
BUILD_GRUB_TIMEOUT="${BUILD_GRUB_TIMEOUT:-5}"

UBUNTU_MIRROR="http://archive.ubuntu.com/ubuntu/"
UBUNTU_RELEASE="jammy"
CHROOT="/workspace/chroot"
ISO_ROOT="/workspace/iso"
ISO_NAME="distroforge-ubuntu-${BUILD_DESKTOP}.iso"

# ─── Helpers ──────────────────────────────────────────────────────────────────
log()      { echo "${LOG_PREFIX} $*"; }
progress() { echo "PROGRESS:${1}:${2}"; }

run_in_chroot() {
  chroot "${CHROOT}" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    export LANG=C
    $*
  "
}

cleanup() {
  log "Cleaning up mounts..."
  for mnt in dev/pts dev proc sys; do
    umount -lf "${CHROOT}/${mnt}" 2>/dev/null || true
  done
}
trap cleanup EXIT

# ─── Step 1: Bootstrap minimal Ubuntu base ────────────────────────────────────
progress 5 "Bootstrapping Ubuntu ${UBUNTU_RELEASE} base"
log "Running debootstrap — this takes a few minutes..."
rm -rf "${CHROOT}" "${ISO_ROOT}"
mkdir -p "${CHROOT}" "${ISO_ROOT}/casper" "${ISO_ROOT}/boot/grub" "${ISO_ROOT}/.disk"

debootstrap \
  --arch=amd64 \
  --include=ca-certificates,locales,sudo \
  "${UBUNTU_RELEASE}" \
  "${CHROOT}" \
  "${UBUNTU_MIRROR}"

# ─── Step 2: Configure apt sources ────────────────────────────────────────────
progress 15 "Configuring package sources"
cat > "${CHROOT}/etc/apt/sources.list" << EOF
deb ${UBUNTU_MIRROR} ${UBUNTU_RELEASE} main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${UBUNTU_RELEASE}-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ ${UBUNTU_RELEASE}-security main restricted universe multiverse
EOF

# Bind-mount kernel-required filesystems
mount --bind /dev     "${CHROOT}/dev"
mount --bind /dev/pts "${CHROOT}/dev/pts"
mount -t proc  proc  "${CHROOT}/proc"
mount -t sysfs sysfs "${CHROOT}/sys"

# Prevent services starting during install
cat > "${CHROOT}/usr/sbin/policy-rc.d" << 'EOF'
#!/bin/sh
exit 101
EOF
chmod +x "${CHROOT}/usr/sbin/policy-rc.d"

# ─── Step 3: Select kernel package ────────────────────────────────────────────
progress 20 "Selecting kernel: ${BUILD_KERNEL}"
case "${BUILD_KERNEL}" in
  lowlatency) KERNEL_PKG="linux-lowlatency" ;;
  zen)        KERNEL_PKG="linux-lowlatency" ;;  # closest Ubuntu equivalent
  hardened)   KERNEL_PKG="linux-generic-hwe-22.04" ;;
  *)          KERNEL_PKG="linux-generic" ;;
esac

# ─── Step 4: Select desktop packages ──────────────────────────────────────────
progress 25 "Selecting desktop: ${BUILD_DESKTOP}"
case "${BUILD_DESKTOP}" in
  gnome)
    DESKTOP_PKGS="ubuntu-gnome-desktop casper lupin-casper"
    ;;
  kde)
    DESKTOP_PKGS="kubuntu-desktop casper lupin-casper"
    ;;
  xfce)
    DESKTOP_PKGS="xubuntu-desktop casper lupin-casper"
    ;;
  hyprland)
    DESKTOP_PKGS="hyprland waybar wofi alacritty xdg-desktop-portal-hyprland casper lupin-casper"
    ;;
  none)
    DESKTOP_PKGS="casper lupin-casper"
    ;;
  *)
    DESKTOP_PKGS="casper lupin-casper"
    ;;
esac

# ─── Step 5: Select app bundle packages ───────────────────────────────────────
BUNDLE_PKGS=""
for bundle in $(echo "${BUILD_APP_BUNDLES}" | tr ',' ' '); do
  case "${bundle}" in
    dev)     BUNDLE_PKGS="${BUNDLE_PKGS} git build-essential curl wget vim python3 python3-pip nodejs npm" ;;
    office)  BUNDLE_PKGS="${BUNDLE_PKGS} libreoffice thunderbird" ;;
    gaming)  BUNDLE_PKGS="${BUNDLE_PKGS} steam lutris wine" ;;
    minimal) ;;
  esac
done

# Extra user-selected packages
EXTRA_PKGS=""
if [[ -n "${BUILD_PACKAGES}" ]]; then
  EXTRA_PKGS=$(echo "${BUILD_PACKAGES}" | tr ',' ' ')
fi

# ─── Step 6: Install everything into chroot ───────────────────────────────────
progress 35 "Installing kernel and base packages"
run_in_chroot "apt-get update -qq"

# Kernel + firmware first
run_in_chroot "apt-get install -y --no-install-recommends \
  ${KERNEL_PKG} \
  linux-firmware \
  initramfs-tools \
  grub-pc \
  grub-efi-amd64-signed \
  shim-signed"

progress 50 "Installing desktop: ${BUILD_DESKTOP}"
# shellcheck disable=SC2086
run_in_chroot "apt-get install -y ${DESKTOP_PKGS}"

if [[ -n "${BUNDLE_PKGS// /}" ]]; then
  progress 60 "Installing app bundles"
  # shellcheck disable=SC2086
  run_in_chroot "apt-get install -y ${BUNDLE_PKGS}"
fi

if [[ -n "${EXTRA_PKGS// /}" ]]; then
  progress 63 "Installing extra packages"
  # shellcheck disable=SC2086
  run_in_chroot "apt-get install -y ${EXTRA_PKGS}"
fi

# ─── Step 7: Configure locale, timezone, keyboard ────────────────────────────
progress 65 "Configuring locale and timezone"
run_in_chroot "
  echo '${BUILD_LOCALE_LANGUAGE} UTF-8' > /etc/locale.gen
  locale-gen
  update-locale LANG='${BUILD_LOCALE_LANGUAGE}'
  ln -sf /usr/share/zoneinfo/${BUILD_LOCALE_TIMEZONE} /etc/localtime
  echo '${BUILD_LOCALE_TIMEZONE}' > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
"

run_in_chroot "
  cat > /etc/default/keyboard << 'KEYEOF'
XKBMODEL=\"pc105\"
XKBLAYOUT=\"${BUILD_LOCALE_KEYBOARD}\"
XKBVARIANT=\"\"
XKBOPTIONS=\"\"
KEYEOF
  dpkg-reconfigure -f noninteractive keyboard-configuration || true
"

# ─── Step 8: Set hostname and user ────────────────────────────────────────────
echo "distroforge" > "${CHROOT}/etc/hostname"
run_in_chroot "
  useradd -m -s /bin/bash -G sudo live 2>/dev/null || true
  echo 'live:live' | chpasswd
  echo 'live ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/live
"

# ─── Step 9: Clean up chroot ──────────────────────────────────────────────────
progress 70 "Cleaning up chroot"
run_in_chroot "apt-get clean && rm -rf /var/lib/apt/lists/*"
rm -f "${CHROOT}/usr/sbin/policy-rc.d"
rm -f "${CHROOT}/etc/resolv.conf"

# Unmount before squashfs
cleanup

# ─── Step 10: Copy kernel + initrd to ISO ────────────────────────────────────
progress 75 "Copying kernel and initrd"
VMLINUZ=$(find "${CHROOT}/boot" -name "vmlinuz-*" | sort -V | tail -1)
INITRD=$(find  "${CHROOT}/boot" -name "initrd.img-*" | sort -V | tail -1)

if [[ -z "${VMLINUZ}" || -z "${INITRD}" ]]; then
  log "ERROR: kernel or initrd not found in chroot!"
  ls "${CHROOT}/boot/" || true
  exit 1
fi

cp "${VMLINUZ}" "${ISO_ROOT}/casper/vmlinuz"
cp "${INITRD}"  "${ISO_ROOT}/casper/initrd"
log "Kernel:  $(basename "${VMLINUZ}")"
log "Initrd:  $(basename "${INITRD}")"

# ─── Step 11: Build squashfs filesystem ───────────────────────────────────────
progress 80 "Building squashfs filesystem (takes a while)"
mksquashfs "${CHROOT}" "${ISO_ROOT}/casper/filesystem.squashfs" \
  -e boot \
  -noappend \
  -comp xz \
  -processors "$(nproc)"

SQUASHFS_SIZE=$(du -sb "${ISO_ROOT}/casper/filesystem.squashfs" | cut -f1)
log "squashfs size: $(( SQUASHFS_SIZE / 1024 / 1024 )) MB"

# Write filesystem size manifest (casper needs this)
printf '%s' "${SQUASHFS_SIZE}" > "${ISO_ROOT}/casper/filesystem.size"

# ─── Step 12: GRUB bootloader config ─────────────────────────────────────────
progress 88 "Writing GRUB config"
SPLASH_CMD=$([ "${BUILD_SPLASH_SCREEN}" = "true" ] && echo "splash" || echo "nosplash")

cat > "${ISO_ROOT}/boot/grub/grub.cfg" << EOF
set default=0
set timeout=${BUILD_GRUB_TIMEOUT}

menuentry "DistroForge Ubuntu (${BUILD_DESKTOP})" {
  linux /casper/vmlinuz boot=casper quiet ${SPLASH_CMD} ---
  initrd /casper/initrd
}

menuentry "DistroForge Ubuntu (safe graphics)" {
  linux /casper/vmlinuz boot=casper nomodeset quiet ---
  initrd /casper/initrd
}
EOF

# Disk info for Ubuntu installers
echo "#Distro DistroForge Ubuntu 22.04 ${BUILD_DESKTOP}" > "${ISO_ROOT}/.disk/info"

# ─── Step 13: Build bootable ISO ─────────────────────────────────────────────
progress 92 "Assembling bootable ISO"
GRUB_EFI_IMG="${ISO_ROOT}/boot/grub/efi.img"

# Create a small FAT image for EFI boot
dd if=/dev/zero of="${GRUB_EFI_IMG}" bs=1M count=4 2>/dev/null
mkfs.vfat "${GRUB_EFI_IMG}"
mmd -i "${GRUB_EFI_IMG}" ::/EFI ::/EFI/BOOT
grub-mkstandalone \
  --format=x86_64-efi \
  --output=/tmp/bootx64.efi \
  --locales="" \
  --fonts="" \
  "boot/grub/grub.cfg=${ISO_ROOT}/boot/grub/grub.cfg"
mcopy -i "${GRUB_EFI_IMG}" /tmp/bootx64.efi ::/EFI/BOOT/BOOTX64.EFI

# Create BIOS boot image
grub-mkstandalone \
  --format=i386-pc \
  --output=/tmp/core.img \
  --locales="" \
  --fonts="" \
  --install-modules="linux normal iso9660 biosdisk memdisk search tar ls" \
  "boot/grub/grub.cfg=${ISO_ROOT}/boot/grub/grub.cfg"
cat /usr/lib/grub/i386-pc/cdboot.img /tmp/core.img > "${ISO_ROOT}/boot/grub/bios.img"

xorriso -as mkisofs \
  -iso-level 3 \
  -full-iso9660-filenames \
  -volid "DISTROFORGE" \
  -eltorito-boot boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --eltorito-catalog boot/grub/boot.cat \
  -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
  -isohybrid-mbr /usr/lib/grub/i386-pc/isohdpfx.bin \
  -output "${OUTPUT_DIR}/${ISO_NAME}" \
  "${ISO_ROOT}"

# ─── Step 14: Checksum ────────────────────────────────────────────────────────
progress 98 "Computing checksum"
cd "${OUTPUT_DIR}"
sha256sum "${ISO_NAME}" > "${ISO_NAME}.sha256"
log "Checksum: $(cat "${ISO_NAME}.sha256")"

ISO_MB=$(du -sm "${OUTPUT_DIR}/${ISO_NAME}" | cut -f1)
log "ISO written: ${OUTPUT_DIR}/${ISO_NAME} (${ISO_MB} MB)"

progress 100 "Build complete"
log "Ubuntu ISO build finished successfully"
