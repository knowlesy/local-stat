# ⚡ LocalStat

A lightweight, native macOS menu bar application designed for Apple Silicon Macs. It provides a "zero-fiddling" dashboard for monitoring hardware system performance and AI service usage.

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![macOS](https://img.shields.io/badge/macOS-14.0+-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)

---

## ✨ Features

### Hardware Monitoring
LocalStat uses low-level Mach kernel APIs and native system tools to monitor your system with near-zero overhead.
- 🎛️ **CPU**: Real-time aggregate usage across all cores.
- 🧠 **Memory**: Active memory pressure monitoring.
- 💾 **Disk**: Available storage tracking, plus real-time Read/Write bandwidth (MB/s) and max I/O latency (ms) via IOKit.
- 🎮 **GPU**: Apple Silicon specific GPU utilization monitoring (No `sudo` required!).
- 🌐 **Network**: 
  - Tracks all active local and public IP addresses.
  - Interactive SwiftUI Charts graphing 30-minutes of rolling Upload/Download history.
  - Real-time Network Process monitor tracking which apps are consuming bandwidth (`nettop` integrated without `sudo`).

### System Interactions
LocalStat provides immediate access to deeper system insights:
- 📋 **Click-to-Copy Commands**: Click any hardware widget (CPU, RAM, Disk) to copy its corresponding terminal command to your clipboard.
- ⚙️ **`btop` Support**: A dedicated toggle in Settings switches native commands (like `top` and `iostat`) to `btop` for power users.
- 🖥️ **Disk Drilldown**: Copies a targeted command (`sudo du -h -d 2 ~/ ...`) to instantly find exactly what's eating your home folder space.
- 🌐 **Network IPs**: Click your Public or Local IP to copy `curl icanhazip.com` or `ifconfig` instantly.

### AI Token Tracking
Keep an eye on your AI usage limits. LocalStat automatically detects installed tools and reads local log files to give you token counts and session metrics—no API keys or configuration needed.
- 🤖 **Claude Code (CLI)**: Tracks rich token metrics per session from local JSONL data.
- 💬 **Claude Desktop App**: Monitors session events and activity.
- 💻 **Claude for VS Code**: Reads extension debug logs.
- ✨ **Gemini / Antigravity**: Monitors Antigravity brain transcripts.
- 🐙 **GitHub Copilot**: Tracks VS Code extension metrics (requires Trace logging).

### Dynamic Theming
Beautiful, curated color palettes built in.
- 🎨 **Catppuccin**: Full support for all 4 flavors (🌻 Latte, 🪴 Frappé, 🌺 Macchiato, 🌿 Mocha).
- 🌌 **Antigravity**: A custom deep space dark theme with electric violet accents.

---

## 🚀 Installation & Setup

macOS Gatekeeper blocks unsigned apps, and we don't want to force you to run scary `xattr` bypass commands or pay Apple $99/year to distribute this free tool. 

Therefore, LocalStat is designed to be **built securely on your own machine** (which macOS automatically trusts!).

### Building from Source

**Requirements:**
- macOS 14.0 (Sonoma) or newer
- Xcode 16+ or the Swift command line tools
- An Apple Silicon Mac (Intel Macs will work, but GPU monitoring will be disabled)

1. **Clone the repository**
   ```bash
   git clone https://github.com/knowlesy/local-stat.git
   cd local-stat
   ```

2. **Create the App DMG**
   We've provided a simple script that compiles the ultra-lightweight Swift project and packages it into a native `.dmg` file for you.
   ```bash
   chmod +x scripts/create_dmg.sh
   ./scripts/create_dmg.sh
   ```

3. **Install**
   The script will generate a `LocalStat.dmg` file in the root directory. Open it, and drag LocalStat to your Applications folder!

*(A Homebrew Cask is planned for the future for 1-click installations!)*

---

## ⚙️ Architecture Overview

LocalStat is a native Swift 6 application utilizing the modern `MenuBarExtra` API introduced in SwiftUI.
- **Sudoless Execution**: All system monitors run in user-space. GPU monitoring uses `ioreg -c IOGPU` rather than `powermetrics` to avoid requiring administrative privileges.
- **Local Data Parsing**: AI tracking works exclusively by reading local log files (e.g., `~/.claude/projects/`, `~/.gemini/`). It never transmits your data.
- **Resource Efficiency**: Update intervals are configurable, and background operations use modern Swift Concurrency.

---

## 🤝 Contributing

Contributions are welcome! If you'd like to add support for another AI tool or improve the hardware monitoring, please see our [CONTRIBUTING.md](CONTRIBUTING.md) guide.

---

## 📜 License & Credits

LocalStat is licensed under the MIT License. See [LICENSE](LICENSE) for more details.

**Credits:**
- Color palettes provided by the [Catppuccin](https://catppuccin.com) project.
