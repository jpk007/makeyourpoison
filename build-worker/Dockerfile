# ─────────────────────────────────────────────────────────────────────────────
# Stage 1 – Compile Linux kernel from kernel.org source
# ─────────────────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS kernel-builder

ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

RUN apt-get update && apt-get install -y \
    gcc g++ make flex bison bc \
    libelf-dev libssl-dev libncurses-dev \
    curl xz-utils \
    && rm -rf /var/lib/apt/lists/*

ARG KERNEL_VERSION=6.6.22
WORKDIR /build/kernel

RUN curl -fSL "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" \
    -o kernel.tar.xz \
    && tar -xf kernel.tar.xz --strip-components=1 \
    && rm kernel.tar.xz

# Minimal x86_64 config: compressed bzImage, initramfs support, squashfs,
# overlayfs, loopback, ext4, tmpfs, devtmpfs, USB HID, standard network,
# Hyper-V synthetic drivers (storage, network, framebuffer, input)
RUN make defconfig && \
    scripts/config \
        --enable CONFIG_BLK_DEV_LOOP \
        --enable CONFIG_SQUASHFS \
        --enable CONFIG_SQUASHFS_XZ \
        --enable CONFIG_OVERLAY_FS \
        --enable CONFIG_TMPFS \
        --enable CONFIG_DEVTMPFS \
        --enable CONFIG_DEVTMPFS_MOUNT \
        --enable CONFIG_EXT4_FS \
        --enable CONFIG_VFAT_FS \
        --enable CONFIG_FAT_FS \
        --enable CONFIG_ISO9660_FS \
        --enable CONFIG_JOLIET \
        --enable CONFIG_HID_GENERIC \
        --enable CONFIG_USB_HID \
        --enable CONFIG_USB_SUPPORT \
        --enable CONFIG_USB_XHCI_HCD \
        --enable CONFIG_USB_EHCI_HCD \
        --enable CONFIG_USB_OHCI_HCD \
        --enable CONFIG_ATA \
        --enable CONFIG_ATA_PIIX \
        --enable CONFIG_AHCI \
        --enable CONFIG_VIRTIO_BLK \
        --enable CONFIG_VIRTIO_NET \
        --enable CONFIG_NET \
        --enable CONFIG_INET \
        --enable CONFIG_PCI \
        --enable CONFIG_ACPI \
        --enable CONFIG_SMP \
        --enable CONFIG_X86_LOCAL_APIC \
        --enable CONFIG_HYPERVISOR_GUEST \
        --enable CONFIG_HYPERV \
        --enable CONFIG_HYPERV_STORAGE \
        --enable CONFIG_HYPERV_NET \
        --enable CONFIG_HYPERV_KEYBOARD \
        --enable CONFIG_HYPERV_UTILS \
        --enable CONFIG_HYPERV_BALLOON \
        --enable CONFIG_FB \
        --enable CONFIG_FB_HYPERV \
        --enable CONFIG_FRAMEBUFFER_CONSOLE \
        --enable CONFIG_DRM \
        --enable CONFIG_DRM_HYPERV \
        --enable CONFIG_HID_HYPERV_MOUSE && \
    make olddefconfig && \
    make -j"$(nproc)" bzImage modules

RUN mkdir -p /opt/kernels /opt/kernel-modules && \
    cp arch/x86/boot/bzImage /opt/kernels/vmlinuz && \
    cp System.map /opt/kernels/System.map && \
    make INSTALL_MOD_PATH=/opt/kernel-modules modules_install && \
    # Keep only the Hyper-V and essential live-boot modules to save space
    find /opt/kernel-modules -name "*.ko" | grep -vE \
        "hv_|hyperv|vmbus|fb_sys|syscopyarea|sysfillrect|sysimgblt|fb_hyperv|hyperv_fb|squashfs|overlay|loop|isofs|vfat|fat|cdrom|sr_mod|scsi_mod|sd_mod" \
        | xargs rm -f 2>/dev/null || true && \
    find /opt/kernel-modules -type d -empty -delete 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2 – Compile busybox statically
# ─────────────────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS busybox-builder

ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

RUN apt-get update && apt-get install -y \
    gcc make curl xz-utils bzip2 \
    && rm -rf /var/lib/apt/lists/*

ARG BUSYBOX_VERSION=1.36.1
WORKDIR /build/busybox

RUN curl -fSL "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2" \
    -o busybox.tar.bz2 \
    && tar -xf busybox.tar.bz2 --strip-components=1 \
    && rm busybox.tar.bz2

RUN make defconfig && \
    echo "CONFIG_STATIC=y" >> .config && \
    echo "CONFIG_STATIC_LIBGCC=y" >> .config && \
    yes "" | make oldconfig && \
    make -j"$(nproc)"

RUN mkdir -p /opt/busybox && cp busybox /opt/busybox/busybox

# ─────────────────────────────────────────────────────────────────────────────
# Stage 3 – Final ISO assembly image
# ─────────────────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS final

LABEL maintainer="MakeYourPoison"
LABEL description="From-scratch Linux ISO build worker"

ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

RUN apt-get update && apt-get install -y \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    grub-common \
    mtools \
    dosfstools \
    bash \
    curl \
    wget \
    xz-utils \
    cpio \
    gzip \
    findutils \
    jq \
    kmod \
    busybox-static \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy pre-compiled artifacts from builder stages
COPY --from=kernel-builder /opt/kernels/ /opt/kernels/
COPY --from=kernel-builder /opt/kernel-modules/ /opt/kernel-modules/
COPY --from=busybox-builder /opt/busybox/ /opt/busybox/

# Create directories
RUN mkdir -p /output /workspace

WORKDIR /workspace

# Copy build scripts
COPY scripts/ ./scripts/
RUN chmod +x ./scripts/*.sh

# Build configuration environment variables
ENV BUILD_DESKTOP=gnome
ENV BUILD_KERNEL=generic
ENV BUILD_PACKAGES=""
ENV BUILD_APP_BUNDLES=""
ENV BUILD_LOCALE_TIMEZONE=UTC
ENV BUILD_LOCALE_LANGUAGE=en_US.UTF-8
ENV BUILD_LOCALE_KEYBOARD=us
ENV BUILD_GRUB_THEME=default
ENV BUILD_SPLASH_SCREEN=true
ENV BUILD_GRUB_TIMEOUT=5
ENV OUTPUT_DIR=/output
ENV KERNEL_IMAGE=/opt/kernels/vmlinuz
ENV BUSYBOX_BIN=/opt/busybox/busybox

ENTRYPOINT ["/bin/bash", "-c", "./scripts/build-scratch.sh"]
