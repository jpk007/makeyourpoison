#!/usr/bin/env bash
# =============================================================================
# MakeYourPoison – From-scratch Linux ISO builder
# No distro base. Linux kernel compiled from source + busybox userspace.
# Desktop environments use Alpine Linux apk packages (musl, static-friendly).
# =============================================================================
set -euo pipefail

# ── Helpers ──────────────────────────────────────────────────────────────────
progress() { echo "PROGRESS:${1}:${2}"; }
info()     { echo "[INFO]  $*"; }
die()      { echo "[ERROR] $*" >&2; exit 1; }

# ── Environment ──────────────────────────────────────────────────────────────
DESKTOP="${BUILD_DESKTOP:-none}"
PACKAGES="${BUILD_PACKAGES:-}"
APP_BUNDLES="${BUILD_APP_BUNDLES:-}"
TZ="${BUILD_LOCALE_TIMEZONE:-UTC}"
LANG_LOCALE="${BUILD_LOCALE_LANGUAGE:-en_US.UTF-8}"
KEYBOARD="${BUILD_LOCALE_KEYBOARD:-us}"
GRUB_TIMEOUT="${BUILD_GRUB_TIMEOUT:-5}"
SPLASH="${BUILD_SPLASH_SCREEN:-true}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"

KERNEL_IMAGE="${KERNEL_IMAGE:-/opt/kernels/vmlinuz}"
BUSYBOX_BIN="${BUSYBOX_BIN:-/opt/busybox/busybox}"

WORKDIR="$(mktemp -d /tmp/myp-build.XXXXXX)"
ROOTFS="${WORKDIR}/rootfs"
INITRAMFS_DIR="${WORKDIR}/initramfs"
ISO_STAGE="${WORKDIR}/iso"

trap 'rm -rf "${WORKDIR}"' EXIT

# ── Alpine mirror for apk packages (desktop/apps) ────────────────────────────
ALPINE_VERSION="3.19"
ALPINE_ARCH="x86_64"
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main"
ALPINE_COMMUNITY="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community"

# ── Step 1: Validate kernel + busybox ────────────────────────────────────────
progress 2 "Checking pre-compiled artifacts"
[[ -f "${KERNEL_IMAGE}" ]] || die "Kernel not found at ${KERNEL_IMAGE}"
[[ -f "${BUSYBOX_BIN}" ]] || die "busybox not found at ${BUSYBOX_BIN}"
info "Kernel: ${KERNEL_IMAGE}"
info "Busybox: ${BUSYBOX_BIN}"

# ── Step 2: Create rootfs skeleton ───────────────────────────────────────────
progress 5 "Creating rootfs directory structure"
mkdir -p \
    "${ROOTFS}"/{bin,sbin,usr/bin,usr/sbin,usr/lib,lib,lib64,lib/x86_64-linux-gnu} \
    "${ROOTFS}"/{etc,proc,sys,dev,run,tmp} \
    "${ROOTFS}"/{root,home,mnt,media,opt,srv} \
    "${ROOTFS}"/etc/{init.d,network,apk} \
    "${ROOTFS}"/usr/{share,include,local} \
    "${ROOTFS}"/usr/local/{bin,sbin,lib} \
    "${ROOTFS}"/var/{cache,lib,log}
# Do NOT pre-create var/run or var/lock — alpine-baselayout makes these symlinks
# (var/run → ../run, var/lock → ../run/lock) and will fail if they exist as dirs
chmod 1777 "${ROOTFS}/tmp"

# Install busybox and create symlinks
cp "${BUSYBOX_BIN}" "${ROOTFS}/bin/busybox"
chmod +x "${ROOTFS}/bin/busybox"

# Create busybox applet symlinks
for applet in sh ash bash ls cp mv rm mkdir rmdir cat echo printf \
    grep sed awk find sort uniq wc head tail cut tr \
    mount umount chroot pivot_root switch_root \
    mdev modprobe insmod depmod \
    ifconfig ip route ping \
    wget curl \
    gzip gunzip tar xz \
    dd df du free ps top kill \
    chmod chown chgrp ln readlink \
    hostname uname date \
    sleep sleep usleep \
    env test true false \
    init halt reboot poweroff \
    getty login passwd \
    vi nano more less \
    tar zip unzip \
    sysctl dmesg \
    ash sh; do
    ln -sf /bin/busybox "${ROOTFS}/bin/${applet}" 2>/dev/null || true
done
ln -sf /bin/busybox "${ROOTFS}/sbin/init"
ln -sf /bin/sh "${ROOTFS}/bin/bash" 2>/dev/null || true

# ── Step 3: Essential /etc files ─────────────────────────────────────────────
progress 10 "Writing base configuration files"

cat > "${ROOTFS}/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/sh
nobody:x:65534:65534:nobody:/:/bin/false
EOF

cat > "${ROOTFS}/etc/group" <<'EOF'
root:x:0:
nogroup:x:65534:
EOF

cat > "${ROOTFS}/etc/shadow" <<'EOF'
root::19000:0:::::
EOF
chmod 600 "${ROOTFS}/etc/shadow"

cat > "${ROOTFS}/etc/hostname" <<'EOF'
makeyourpoison
EOF

cat > "${ROOTFS}/etc/hosts" <<'EOF'
127.0.0.1   localhost makeyourpoison
::1         localhost
EOF

cat > "${ROOTFS}/etc/resolv.conf" <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

cat > "${ROOTFS}/etc/fstab" <<'EOF'
none    /proc   proc    defaults    0 0
none    /sys    sysfs   defaults    0 0
none    /dev    devtmpfs defaults   0 0
none    /tmp    tmpfs   defaults    0 0
EOF

cat > "${ROOTFS}/etc/profile" <<EOF
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export HOME=/root
export TERM=linux
export LANG=${LANG_LOCALE}
EOF

# locale-like stub
cat > "${ROOTFS}/etc/locale.conf" <<EOF
LANG=${LANG_LOCALE}
LC_ALL=${LANG_LOCALE}
EOF

cat > "${ROOTFS}/etc/timezone" <<EOF
${TZ}
EOF

# busybox init reads /etc/inittab — without it, init exits immediately → kernel panic
cat > "${ROOTFS}/etc/inittab" <<'EOF'
# MakeYourPoison live system
::sysinit:/bin/sh /etc/rc
::respawn:/sbin/getty -L tty0 115200 vt100
::respawn:/sbin/getty -L tty1 115200 vt100
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF

# Minimal startup script
cat > "${ROOTFS}/etc/rc" <<'EOF'
#!/bin/sh
mount -t proc     none /proc  2>/dev/null
mount -t sysfs    none /sys   2>/dev/null
mount -t devtmpfs none /dev   2>/dev/null || true
mount -t tmpfs    none /tmp   2>/dev/null || true
hostname makeyourpoison
echo "MakeYourPoison: live system ready. Login as root (no password)."
EOF
chmod +x "${ROOTFS}/etc/rc"

# ── Step 4: Install Alpine apk packages for desktop/apps ─────────────────────
# We bootstrap Alpine's apk tool into the rootfs so we can install packages.
# This gives us a musl-based userspace on top of our custom kernel.

# Global apk-static binary path (set by install_alpine_base, used by install_packages)
APK_STATIC=""

install_alpine_base() {
    progress 15 "Bootstrapping Alpine package manager"

    mkdir -p /tmp/apk-bootstrap

    # Resolve the current apk-tools-static version from the package index
    # (avoids hard-coding a version that may not exist)
    local APKINDEX_URL="${ALPINE_MIRROR}/${ALPINE_ARCH}/APKINDEX.tar.gz"
    wget -q -O /tmp/apk-bootstrap/APKINDEX.tar.gz "${APKINDEX_URL}" \
        || die "Failed to download Alpine package index from ${APKINDEX_URL}"
    tar -xzf /tmp/apk-bootstrap/APKINDEX.tar.gz -C /tmp/apk-bootstrap/ 2>/dev/null \
        || die "Failed to extract APKINDEX"
    local APK_VERSION
    APK_VERSION=$(awk '/^P:apk-tools-static$/{found=1} found && /^V:/{print substr($0,3); exit}' \
        /tmp/apk-bootstrap/APKINDEX 2>/dev/null || echo "")
    [[ -n "${APK_VERSION}" ]] || die "Could not determine apk-tools-static version from APKINDEX"
    info "apk-tools-static version: ${APK_VERSION}"

    wget -q -O /tmp/apk-bootstrap/apk-static.apk \
        "${ALPINE_MIRROR}/${ALPINE_ARCH}/apk-tools-static-${APK_VERSION}.apk" \
        || die "Failed to download apk-tools-static-${APK_VERSION}.apk"

    cd /tmp/apk-bootstrap
    tar -xzf apk-static.apk 2>/dev/null || die "Failed to extract apk-static.apk"
    APK_STATIC=$(find /tmp/apk-bootstrap -name 'apk.static' | head -1)
    [[ -n "${APK_STATIC}" ]] || die "Could not find apk.static binary after extraction"
    chmod +x "${APK_STATIC}"

    # Configure Alpine repos in rootfs
    mkdir -p "${ROOTFS}/etc/apk"
    cat > "${ROOTFS}/etc/apk/repositories" <<REPOS
${ALPINE_MIRROR}
${ALPINE_COMMUNITY}
REPOS

    # --initdb initialises the apk database on an empty rootfs (required on first run)
    "${APK_STATIC}" \
        --root "${ROOTFS}" \
        --arch "${ALPINE_ARCH}" \
        --no-cache \
        --allow-untrusted \
        --initdb \
        add alpine-base musl musl-utils openrc \
        || die "Failed to bootstrap Alpine base packages"

    info "Alpine base bootstrapped"
}

install_packages() {
    local pkgs="$*"
    [[ -z "${pkgs}" ]] && return
    progress 25 "Installing packages: ${pkgs}"
    # Use the apk-static binary directly with --root so we don't need chroot
    "${APK_STATIC}" \
        --root "${ROOTFS}" \
        --arch "${ALPINE_ARCH}" \
        --no-cache \
        --allow-untrusted \
        add ${pkgs} \
        || info "Warning: some packages may not have installed"
}

install_desktop() {
    case "${DESKTOP,,}" in
        gnome)
            progress 30 "Installing GNOME desktop"
            # Alpine has gnome packages in community
            install_packages gnome gnome-apps-extras gdm dbus
            ;;
        kde)
            progress 30 "Installing KDE Plasma desktop"
            install_packages plasma plasma-desktop sddm dbus
            ;;
        xfce)
            progress 30 "Installing XFCE desktop"
            install_packages xfce4 xfce4-terminal lightdm lightdm-gtk-greeter dbus
            ;;
        hyprland)
            progress 30 "Installing Hyprland compositor"
            install_packages hyprland xwayland dbus foot
            ;;
        none|"")
            progress 30 "No desktop — minimal console environment"
            ;;
        *)
            progress 30 "Unknown desktop '${DESKTOP}', skipping"
            ;;
    esac
}

install_app_bundles() {
    for bundle in ${APP_BUNDLES}; do
        case "${bundle,,}" in
            dev)
                progress 45 "Installing Dev bundle"
                install_packages git gcc g++ make python3 nodejs npm vim curl wget
                ;;
            office)
                progress 45 "Installing Office bundle"
                install_packages libreoffice thunderbird
                ;;
            gaming)
                progress 45 "Installing Gaming bundle"
                install_packages steam wine lutris
                ;;
            minimal)
                progress 45 "Installing Minimal bundle (already minimal)"
                ;;
        esac
    done
}

install_extra_packages() {
    [[ -z "${PACKAGES}" ]] && return
    progress 50 "Installing extra packages: ${PACKAGES}"
    install_packages ${PACKAGES}
}

# Bootstrap Alpine and install everything
install_alpine_base
install_desktop
install_app_bundles
install_extra_packages

# ── Post-install: configure live system ──────────────────────────────────────
progress 52 "Configuring live system"

# Clear root password so live boot logs in automatically (no password prompt)
sed -i 's|^root:[^:]*:|root::|' "${ROOTFS}/etc/shadow"

# Configure inittab for auto-login on tty0/tty1 (Alpine overwrites ours earlier)
# Use our own /etc/rc for sysinit — NOT /etc/init.d/rcS (Alpine OpenRC path)
cat > "${ROOTFS}/etc/inittab" <<'EOF'
# MakeYourPoison live system
::sysinit:/etc/rc
# Open tty0/tty1 directly — bypasses getty tty ownership issues
tty0::respawn:/bin/sh -c 'exec /bin/ash -l </dev/tty0 >/dev/tty0 2>&1'
tty1::respawn:/bin/sh -c 'exec /bin/ash -l </dev/tty1 >/dev/tty1 2>&1'
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
EOF

# Write /etc/rc here (after Alpine install) so Alpine can't overwrite it
cat > "${ROOTFS}/etc/rc" <<'EOF'
#!/bin/sh
mount -t proc     none /proc 2>/dev/null || true
mount -t sysfs    none /sys  2>/dev/null || true
mount -t devtmpfs none /dev  2>/dev/null || true
mount -t tmpfs    none /tmp  2>/dev/null || true
hostname makeyourpoison
echo ""
echo "  Welcome to MakeYourPoison Live!"
echo "  Logged in as root."
echo ""
EOF
chmod +x "${ROOTFS}/etc/rc"

# Also restore our locale/hostname/rc settings Alpine may have overwritten
cat > "${ROOTFS}/etc/hostname" <<'EOF'
makeyourpoison
EOF

cat > "${ROOTFS}/etc/profile" <<EOF
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export HOME=/root
export TERM=linux
export LANG=${LANG_LOCALE}
export PS1='[\u@makeyourpoison \W]\$ '
echo ""
echo "  Welcome to MakeYourPoison Live!"
echo "  Type 'startx' to start the desktop, or use the console."
echo ""
EOF

# Also write /root/.profile so ash picks it up on auto-login
cp "${ROOTFS}/etc/profile" "${ROOTFS}/root/.profile"

# ── Step 5: Build initramfs (live-boot init) ──────────────────────────────────
progress 55 "Building initramfs with live-boot support"
mkdir -p "${INITRAMFS_DIR}"/{bin,sbin,lib,lib64,dev,proc,sys,mnt,run,newroot}
mkdir -p "${INITRAMFS_DIR}"/mnt/{live,overlay,work,upper}

# Use Debian's busybox-static for the initramfs (known-good, pre-tested binary)
# Our self-compiled busybox is used for the rootfs only
INITRAMFS_BB="$(command -v busybox || echo /bin/busybox)"
if [[ ! -f "${INITRAMFS_BB}" ]]; then
    INITRAMFS_BB="${BUSYBOX_BIN}"
    info "Warning: system busybox not found, falling back to compiled binary"
fi
info "Initramfs busybox: ${INITRAMFS_BB}"
cp "${INITRAMFS_BB}" "${INITRAMFS_DIR}/bin/busybox"
chmod +x "${INITRAMFS_DIR}/bin/busybox"
for applet in sh ash mount umount mkdir rmdir mdev switch_root \
    modprobe insmod lsmod sleep echo cat ls grep find uname; do
    ln -sf /bin/busybox "${INITRAMFS_DIR}/bin/${applet}" 2>/dev/null || true
done
ln -sf /bin/busybox "${INITRAMFS_DIR}/sbin/init"

# Copy kernel modules into initramfs (Hyper-V + live-boot essentials)
KVER=$(ls /opt/kernel-modules/lib/modules/ 2>/dev/null | head -1)
if [[ -n "${KVER}" ]]; then
    info "Copying kernel modules for ${KVER}"
    mkdir -p "${INITRAMFS_DIR}/lib/modules/${KVER}"
    cp -r "/opt/kernel-modules/lib/modules/${KVER}/." \
        "${INITRAMFS_DIR}/lib/modules/${KVER}/"
    # Run depmod so modprobe can resolve dependencies
    depmod -b "${INITRAMFS_DIR}" "${KVER}" 2>/dev/null || true
else
    info "Warning: no kernel modules found at /opt/kernel-modules"
fi

# Write the live-boot /init script
cat > "${INITRAMFS_DIR}/init" <<'INITSCRIPT'
#!/bin/sh
# MakeYourPoison live-boot init
# Mounts squashfs from ISO, sets up overlayfs, pivots root
# NOTE: no set -e — initramfs must never exit unexpectedly

msg() { echo "MYP: $*" > /dev/console 2>/dev/null; echo "MYP: $*"; }

rescue_shell() {
    msg "RESCUE: $1"
    msg "Dropping to shell. Type 'exit' to retry."
    exec /bin/sh < /dev/console > /dev/console 2>&1
}

# Basic mounts — must not fail silently
mount -t proc     none /proc  2>/dev/null || true
mount -t sysfs    none /sys   2>/dev/null || true
mount -t devtmpfs none /dev   2>/dev/null || mdev -s

# Populate /dev
mdev -s 2>/dev/null || true

# Load drivers — Hyper-V bus must come first, then storage
msg "loading drivers..."
modprobe hv_vmbus  2>/dev/null || true
sleep 1
for mod in hv_storvsc hv_netvsc hyperv_keyboard hid_hyperv \
           hyperv_fb squashfs overlay loop isofs vfat cdrom sr_mod; do
    modprobe "$mod" 2>/dev/null || true
done
sleep 1
mdev -s 2>/dev/null || true

msg "scanning for live medium..."

# Try to find the squashfs on any block device (45 second window)
SQUASHFS=""
FOUND_DEV=""
for attempt in $(seq 1 45); do
    mdev -s 2>/dev/null || true
    for dev in /dev/sr0 /dev/sr1 /dev/sda /dev/sdb /dev/sdc \
               /dev/hda /dev/hdb /dev/vda /dev/vdb; do
        [ -b "$dev" ] || continue
        mkdir -p /mnt/cdrom
        if mount -t iso9660 -o ro "$dev" /mnt/cdrom 2>/dev/null; then
            if [ -f /mnt/cdrom/live/filesystem.squashfs ]; then
                SQUASHFS=/mnt/cdrom/live/filesystem.squashfs
                FOUND_DEV="$dev"
                msg "found squashfs on $dev"
                break 2
            fi
            umount /mnt/cdrom 2>/dev/null || true
        fi
    done
    msg "waiting for device... ($attempt/45)"
    sleep 1
done

if [ -z "$SQUASHFS" ]; then
    rescue_shell "ERROR: could not find live/filesystem.squashfs on any device"
fi

# Mount squashfs as the lower (read-only) layer
mkdir -p /mnt/live /mnt/overlay /newroot
if ! mount -t squashfs -o loop,ro "$SQUASHFS" /mnt/live; then
    rescue_shell "ERROR: failed to mount squashfs from $FOUND_DEV"
fi
msg "squashfs mounted OK"

# Set up overlayfs — writable tmpfs layer on top of squashfs
mount -t tmpfs tmpfs /mnt/overlay
mkdir -p /mnt/overlay/upper /mnt/overlay/work
if ! mount -t overlay overlay \
    -o lowerdir=/mnt/live,upperdir=/mnt/overlay/upper,workdir=/mnt/overlay/work \
    /newroot; then
    rescue_shell "ERROR: failed to mount overlayfs"
fi
msg "overlayfs ready, switching root..."

# Move existing mounts into the new root
mkdir -p /newroot/proc /newroot/sys /newroot/dev /newroot/tmp
mount --move /proc /newroot/proc 2>/dev/null || true
mount --move /sys  /newroot/sys  2>/dev/null || true
mount --move /dev  /newroot/dev  2>/dev/null || true

# switch_root into new root, try init candidates in order
for init_path in /sbin/init /bin/init /bin/busybox /bin/sh /bin/ash; do
    if [ -x "/newroot${init_path}" ]; then
        msg "switch_root -> ${init_path}"
        exec switch_root /newroot "${init_path}"
    fi
done

# Nothing worked — dump diagnostics and drop to shell
msg "switch_root FAILED. Mounts:"
cat /proc/mounts > /dev/console 2>/dev/null
msg "Contents of /newroot:"
ls -la /newroot > /dev/console 2>/dev/null
msg "Dropping to rescue shell (you are in the initramfs)."
exec /bin/sh < /dev/console > /dev/console 2>&1
INITSCRIPT
chmod +x "${INITRAMFS_DIR}/init"

# Pack the initramfs
info "Packing initramfs..."
(cd "${INITRAMFS_DIR}" && find . | cpio -H newc -o | gzip -9 > "${WORKDIR}/initramfs.gz")
info "initramfs size: $(du -sh "${WORKDIR}/initramfs.gz" | cut -f1)"

# ── Step 6: Create squashfs rootfs ────────────────────────────────────────────
progress 65 "Creating squashfs filesystem"
mksquashfs "${ROOTFS}" "${WORKDIR}/filesystem.squashfs" \
    -comp xz \
    -e proc sys dev tmp run \
    -no-progress \
    -noappend
info "squashfs size: $(du -sh "${WORKDIR}/filesystem.squashfs" | cut -f1)"

# ── Step 7: Assemble ISO directory structure ──────────────────────────────────
progress 72 "Assembling ISO structure"
mkdir -p "${ISO_STAGE}"/{live,boot/grub,EFI/BOOT}

cp "${KERNEL_IMAGE}" "${ISO_STAGE}/live/vmlinuz"
cp "${WORKDIR}/initramfs.gz" "${ISO_STAGE}/live/initramfs.gz"
cp "${WORKDIR}/filesystem.squashfs" "${ISO_STAGE}/live/filesystem.squashfs"

# ── Step 8: GRUB config ───────────────────────────────────────────────────────
progress 78 "Configuring GRUB bootloader"

SPLASH_PARAM=""
[[ "${SPLASH}" == "true" ]] && SPLASH_PARAM=" splash quiet"

cat > "${ISO_STAGE}/boot/grub/grub.cfg" <<GRUBCFG
set default=0
set timeout=${GRUB_TIMEOUT}

# Visual theme
if [ -f /boot/grub/theme/theme.txt ]; then
    set theme=/boot/grub/theme/theme.txt
fi

insmod all_video
insmod gfxterm
terminal_output gfxterm

menuentry "MakeYourPoison Live" {
    linux  /live/vmlinuz root=live:CDLABEL=MYPOISON rw init=/init${SPLASH_PARAM} \
        lang=${KEYBOARD} timezone=${TZ} locale=${LANG_LOCALE} \
        video=hyperv_fb:1280x720
    initrd /live/initramfs.gz
}

menuentry "MakeYourPoison Live (Hyper-V / nomodeset)" {
    linux  /live/vmlinuz root=live:CDLABEL=MYPOISON rw init=/init nomodeset \
        video=hyperv_fb:1024x768
    initrd /live/initramfs.gz
}

menuentry "MakeYourPoison Live (safe mode)" {
    linux  /live/vmlinuz root=live:CDLABEL=MYPOISON rw init=/init nomodeset
    initrd /live/initramfs.gz
}

menuentry "Boot from first hard disk" {
    set root=(hd0)
    chainloader +1
}
GRUBCFG

# ── Step 9: Build EFI image ───────────────────────────────────────────────────
progress 82 "Building EFI boot image"

# Create EFI FAT image
EFI_IMG="${WORKDIR}/efi.img"
dd if=/dev/zero of="${EFI_IMG}" bs=1M count=4 2>/dev/null
mkfs.vfat "${EFI_IMG}" >/dev/null
mmd -i "${EFI_IMG}" ::/EFI ::/EFI/BOOT >/dev/null 2>&1 || true

# Build GRUB EFI binary
grub-mkimage \
    --format=x86_64-efi \
    --output="${WORKDIR}/BOOTX64.EFI" \
    --prefix=/boot/grub \
    all_video boot btrfs cat chain configfile echo efifwsetup efinet ext2 \
    fat font gfxmenu gfxterm gfxterm_background gzio halt help \
    hfsplus iso9660 jpeg keystatus loadenv loopback linux ls lsefi lsefimmap \
    lsefisystab lssal memdisk minicmd normal ntfs part_apple part_msdos \
    part_gpt password_pbkdf2 png probe reboot regexp search search_fs_uuid \
    search_fs_file search_label sleep smbios squash4 test tpm true video xfs

mcopy -i "${EFI_IMG}" "${WORKDIR}/BOOTX64.EFI" ::/EFI/BOOT/ >/dev/null 2>&1 || \
    cp "${WORKDIR}/BOOTX64.EFI" "${ISO_STAGE}/EFI/BOOT/BOOTX64.EFI"
cp "${EFI_IMG}" "${ISO_STAGE}/boot/grub/efi.img"

# ── Step 10: Embed GRUB into ISO (BIOS boot) ─────────────────────────────────
progress 88 "Embedding GRUB for BIOS boot"

# Create BIOS core.img
GRUB_BIOS_MODS="/usr/lib/grub/i386-pc"
[[ -d "${GRUB_BIOS_MODS}" ]] || die "GRUB BIOS modules not found at ${GRUB_BIOS_MODS}"

grub-mkimage \
    --format=i386-pc \
    --output="${WORKDIR}/core.img" \
    --prefix=/boot/grub \
    biosdisk iso9660 linux normal configfile search search_label \
    gzio squash4 part_msdos part_gpt fat ext2

cat "${GRUB_BIOS_MODS}/cdboot.img" "${WORKDIR}/core.img" > "${WORKDIR}/bios.img"
cp "${WORKDIR}/bios.img" "${ISO_STAGE}/boot/grub/bios.img"

# Copy GRUB BIOS modules into ISO
mkdir -p "${ISO_STAGE}/boot/grub/i386-pc"
cp "${GRUB_BIOS_MODS}"/*.mod "${ISO_STAGE}/boot/grub/i386-pc/" 2>/dev/null || true

# ── Step 11: Assemble final ISO with xorriso ──────────────────────────────────
progress 92 "Assembling bootable ISO with xorriso"

_BASE_NAME="${BUILD_ISO_NAME:-makeyourpoison}"
ISO_NAME="${_BASE_NAME}-$(date +%Y%m%d-%H%M%S).iso"
ISO_OUT="${OUTPUT_DIR}/${ISO_NAME}"
mkdir -p "${OUTPUT_DIR}"

xorriso -as mkisofs \
    -iso-level 3 \
    -volid "MYPOISON" \
    -appid "MakeYourPoison Live ISO" \
    -publisher "MakeYourPoison" \
    -b boot/grub/bios.img \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --embedded-boot "${WORKDIR}/bios.img" \
    --protective-msdos-label \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -o "${ISO_OUT}" \
    "${ISO_STAGE}"

# ── Done ─────────────────────────────────────────────────────────────────────
ISO_SIZE=$(du -sh "${ISO_OUT}" | cut -f1)
progress 100 "ISO build complete: ${ISO_NAME} (${ISO_SIZE})"
info "Output: ${ISO_OUT}"
echo "BUILD_OUTPUT:${ISO_OUT}"
