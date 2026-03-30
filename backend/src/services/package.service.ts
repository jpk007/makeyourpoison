import { Package } from '@distroforge/shared'

// Alpine apk-compatible package catalog (used by build-scratch.sh via apk add)
const catalog: Package[] = [
  // Editors
  { id: 'vim', name: 'vim', description: 'Vi IMproved — highly configurable text editor', category: 'Editors', size: 3 },
  { id: 'neovim', name: 'neovim', description: 'Hyperextensible Vim-based text editor', category: 'Editors', size: 8 },
  { id: 'nano', name: 'nano', description: 'Small, friendly text editor', category: 'Editors', size: 1 },
  { id: 'micro', name: 'micro', description: 'Modern and intuitive terminal text editor', category: 'Editors', size: 8 },
  // Development
  { id: 'git', name: 'git', description: 'Fast distributed version control system', category: 'Development', size: 12 },
  { id: 'gcc', name: 'gcc', description: 'GNU C compiler', category: 'Development', size: 35 },
  { id: 'g++', name: 'g++', description: 'GNU C++ compiler', category: 'Development', size: 36 },
  { id: 'make', name: 'make', description: 'GNU make build automation tool', category: 'Development', size: 2 },
  { id: 'cmake', name: 'cmake', description: 'Cross-platform build system generator', category: 'Development', size: 20 },
  { id: 'python3', name: 'python3', description: 'Python 3 interpreter', category: 'Development', size: 30 },
  { id: 'py3-pip', name: 'py3-pip', description: 'PyPA recommended tool for installing Python packages', category: 'Development', size: 5 },
  { id: 'nodejs', name: 'nodejs', description: 'JavaScript runtime built on V8', category: 'Development', size: 45 },
  { id: 'npm', name: 'npm', description: 'Node.js package manager', category: 'Development', size: 15 },
  { id: 'go', name: 'go', description: 'Go programming language', category: 'Development', size: 180 },
  { id: 'rust', name: 'rust', description: 'Systems programming language focused on safety', category: 'Development', size: 200 },
  { id: 'docker', name: 'docker', description: 'Container runtime and tooling', category: 'Development', size: 120 },
  { id: 'docker-compose', name: 'docker-compose', description: 'Define and run multi-container Docker apps', category: 'Development', size: 25 },
  { id: 'gdb', name: 'gdb', description: 'GNU Debugger', category: 'Development', size: 10 },
  { id: 'strace', name: 'strace', description: 'System call tracer', category: 'Development', size: 2 },
  // Shell
  { id: 'bash', name: 'bash', description: 'GNU Bourne Again shell', category: 'Shell', size: 2 },
  { id: 'zsh', name: 'zsh', description: 'Z shell — powerful interactive shell', category: 'Shell', size: 4 },
  { id: 'fish', name: 'fish', description: 'Friendly interactive shell', category: 'Shell', size: 8 },
  // Terminal utilities
  { id: 'tmux', name: 'tmux', description: 'Terminal multiplexer', category: 'Terminal', size: 2 },
  { id: 'screen', name: 'screen', description: 'Full-screen window manager for terminals', category: 'Terminal', size: 2 },
  { id: 'htop', name: 'htop', description: 'Interactive process viewer', category: 'Terminal', size: 1 },
  { id: 'btop', name: 'btop', description: 'Resource monitor with a nice TUI', category: 'Terminal', size: 3 },
  { id: 'neofetch', name: 'neofetch', description: 'System info script for the terminal', category: 'Terminal', size: 1 },
  { id: 'bat', name: 'bat', description: 'cat clone with syntax highlighting', category: 'Terminal', size: 3 },
  { id: 'exa', name: 'exa', description: 'Modern replacement for ls', category: 'Terminal', size: 2 },
  { id: 'ripgrep', name: 'ripgrep', description: 'Fast grep alternative', category: 'Terminal', size: 4 },
  { id: 'fzf', name: 'fzf', description: 'Command-line fuzzy finder', category: 'Terminal', size: 2 },
  { id: 'jq', name: 'jq', description: 'Lightweight JSON processor', category: 'Terminal', size: 1 },
  { id: 'yq', name: 'yq', description: 'YAML/JSON/XML processor', category: 'Terminal', size: 2 },
  // Network
  { id: 'curl', name: 'curl', description: 'Command line tool for transferring data', category: 'Network', size: 2 },
  { id: 'wget', name: 'wget', description: 'Network file retrieval utility', category: 'Network', size: 2 },
  { id: 'openssh', name: 'openssh', description: 'OpenSSH client and server', category: 'Network', size: 5 },
  { id: 'rsync', name: 'rsync', description: 'Fast file copying tool', category: 'Network', size: 2 },
  { id: 'nmap', name: 'nmap', description: 'Network exploration and security auditing tool', category: 'Network', size: 10 },
  { id: 'wireguard-tools', name: 'wireguard-tools', description: 'WireGuard VPN tools', category: 'Network', size: 2 },
  // System
  { id: 'ufw', name: 'ufw', description: 'Uncomplicated firewall', category: 'System', size: 1 },
  { id: 'sudo', name: 'sudo', description: 'Allow certain users to run commands as root', category: 'System', size: 1 },
  { id: 'util-linux', name: 'util-linux', description: 'Miscellaneous system utilities', category: 'System', size: 4 },
  { id: 'e2fsprogs', name: 'e2fsprogs', description: 'ext2/ext3/ext4 filesystem utilities', category: 'System', size: 3 },
  { id: 'coreutils', name: 'coreutils', description: 'GNU core utilities', category: 'System', size: 5 },
  // Multimedia
  { id: 'ffmpeg', name: 'ffmpeg', description: 'Complete multimedia framework', category: 'Multimedia', size: 80 },
  { id: 'vlc', name: 'vlc', description: 'Multimedia player and streamer', category: 'Multimedia', size: 65 },
  { id: 'mpv', name: 'mpv', description: 'Minimal video player based on MPlayer', category: 'Multimedia', size: 20 },
  { id: 'audacity', name: 'audacity', description: 'Multi-track audio editor', category: 'Multimedia', size: 40 },
  // Graphics
  { id: 'gimp', name: 'gimp', description: 'GNU Image Manipulation Program', category: 'Graphics', size: 90 },
  { id: 'inkscape', name: 'inkscape', description: 'Vector graphics editor', category: 'Graphics', size: 85 },
  { id: 'imagemagick', name: 'imagemagick', description: 'Image manipulation tools', category: 'Graphics', size: 15 },
  // Office
  { id: 'libreoffice', name: 'libreoffice', description: 'Office productivity suite', category: 'Office', size: 300 },
  { id: 'thunderbird', name: 'thunderbird', description: 'Email and news client', category: 'Office', size: 75 },
  // Internet
  { id: 'firefox', name: 'firefox', description: 'Mozilla Firefox web browser', category: 'Internet', size: 75 },
  { id: 'chromium', name: 'chromium', description: 'Open-source web browser', category: 'Internet', size: 120 },
  // Security
  { id: 'gnupg', name: 'gnupg', description: 'GNU Privacy Guard — encryption tool', category: 'Security', size: 5 },
  { id: 'wireshark', name: 'wireshark', description: 'Network traffic analyzer', category: 'Security', size: 45 },
  { id: 'fail2ban', name: 'fail2ban', description: 'Bans IPs with too many auth failures', category: 'Security', size: 3 },
  { id: 'clamav', name: 'clamav', description: 'Open-source antivirus engine', category: 'Security', size: 40 },
  // Fonts
  { id: 'font-noto', name: 'font-noto', description: 'Noto fonts — broad Unicode coverage', category: 'Fonts', size: 50 },
  { id: 'ttf-dejavu', name: 'ttf-dejavu', description: 'DejaVu fonts', category: 'Fonts', size: 8 },
]

export const packageService = {
  search(query: string): Package[] {
    if (!query.trim()) return catalog.slice(0, 50)
    const q = query.toLowerCase()
    return catalog.filter(
      (pkg) =>
        pkg.name.toLowerCase().includes(q) ||
        pkg.description.toLowerCase().includes(q) ||
        pkg.category.toLowerCase().includes(q)
    )
  },
}
