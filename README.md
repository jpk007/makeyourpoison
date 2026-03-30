# MakeYourPoison

> **Work in progress** — MakeYourPoison is currently in active development. Expect rough edges, missing features, and breaking changes.

Build your own Linux ISO from the browser. Pick a desktop environment, packages, kernel, and locale settings, then download a fully bootable ISO assembled from the Linux kernel compiled from [kernel.org](https://kernel.org) source. No distro base. No shortcuts.

## Features

- **From-scratch ISOs** — no Ubuntu/Debian/Arch base. Linux kernel compiled from source + busybox userspace
- **Desktop environments** — GNOME, KDE Plasma, XFCE, Hyprland, or minimal console
- **App bundles** — Dev, Office, Gaming, Minimal
- **Custom packages** — searchable catalog
- **Kernel flavours** — generic, lowlatency, zen, hardened
- **Live boot** — squashfs + overlayfs, boots from ISO without installation
- **BIOS + UEFI** — dual boot support via GRUB
- **Live build progress** — real-time logs streamed via WebSocket

## Stack

| Layer | Tech |
|---|---|
| Frontend | Vue 3, Vite, Pinia, Tailwind CSS, PWA |
| Backend | Node.js 20, Express 5, TypeScript |
| Queue | Bull + Redis |
| Database | PostgreSQL |
| Build worker | Docker (multi-stage: kernel + busybox compiled from source) |
| Realtime | WebSocket (`ws`) |

## Getting Started

### Prerequisites

- Node.js 20+
- Docker
- Redis (`docker run -p 6379:6379 redis:alpine`)
- PostgreSQL

### Install

```bash
npm install          # installs all workspaces (frontend, backend, shared)
```

### Run (dev)

```bash
cd frontend && npm run dev    # http://localhost:5173
cd backend && npm run dev     # http://localhost:3000
```

### Build the ISO builder image

First-time build compiles the Linux kernel (~30–60 min):

```bash
cd build-worker && docker build -t makeyourpoison-builder:latest .
```

### Environment variables

**`backend/.env`**
```
PORT=3000
NODE_ENV=development
DATABASE_URL=postgres://postgres:postgres@localhost:5432/makeyourpoison
REDIS_HOST=localhost
REDIS_PORT=6379
DOCKER_IMAGE=makeyourpoison-builder:latest
BUILD_OUTPUT_PATH=/tmp/myp-builds
MAX_CONCURRENT_BUILDS=2
```

**`frontend/.env`**
```
VITE_API_BASE_URL=http://localhost:3000/api
VITE_WS_URL=ws://localhost:3000/ws
```

## Wizard Steps

1. **Desktop** — choose your desktop environment
2. **Packages** — search and select packages
3. **App Bundles** — Dev / Office / Gaming / Minimal
4. **Kernel** — generic, lowlatency, zen, hardened
5. **Locale** — timezone, language, keyboard
6. **Boot** — GRUB theme, splash screen, timeout
7. **Review** — summary + estimated ISO size
8. **Build** — trigger job, watch live logs, download ISO

## How Builds Work

1. Frontend POSTs config → backend saves to PostgreSQL → returns `configId`
2. Frontend POSTs to `/api/build/start` → Bull job queued → returns `jobId`
3. Backend spawns `docker run makeyourpoison-builder:latest` with env vars
4. Build script inside Docker:
   - Uses pre-compiled kernel (`/opt/kernels/vmlinuz`) and busybox (`/opt/busybox/busybox`)
   - Bootstraps Alpine `apk` for desktop/package installation
   - Builds custom initramfs with live-boot `/init` (squashfs + overlayfs + `switch_root`)
   - Assembles bootable ISO with xorriso (BIOS + UEFI)
5. `PROGRESS:N:msg` lines from the script update progress via WebSocket to the frontend
6. Completed ISO available for download via `/api/build/download/:jobId`

## Milestones

### Milestone 1 — First Successful Live Boot
**Date: 29 March 2026**

The first ISO built entirely from scratch booted successfully inside Hyper-V on Windows 11.

![First successful live boot](success/Screenshot%202026-03-29%20224810.png)

Boot sequence confirmed working end-to-end:
- Kernel compiled from [kernel.org](https://kernel.org) source (Linux 6.6.22)
- Hyper-V drivers loaded from initramfs (`hv_vmbus` → `hv_storvsc`)
- squashfs found on `/dev/sr0`
- overlayfs mounted (read-only squashfs + writable tmpfs layer)
- `switch_root` into live rootfs
- Alpine-based userspace with working root shell
- `ls` confirmed full filesystem tree: `bin dev home lib media mnt opt proc root sbin srv sys tmp usr var`

## License

MIT
