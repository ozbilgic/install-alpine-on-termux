# Alpine Linux Termux Installer

[Türkçe](README.tr.md) | English

Automatic installation script for Alpine Linux on Termux (without root).

## Features

- Automatic Alpine Linux installation on Termux
- No root access required
- Uses PRoot (does not use proot-distro)
- Supports multiple Alpine Linux versions
- Automatic version detection and selection
- User creation with sudo privileges
- Auto-start option
- Pipe installation support

## Supported Architectures

- ARM64 (aarch64)
- ARMv7
- x86_64
- x86

## Installation

### Method 1: One Command Automatic Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ozbilgic/install-alpine-on-termux/main/alpine-installer.sh | bash
```


### Method 2: Direct Installation

```bash
bash alpine-installer.sh
```

## Usage

1. Run the installation script:
   ```bash
   bash alpine-installer.sh
   ```

2. Follow the on-screen instructions:
   - Select Alpine Linux version (latest 4 versions available)
   - Choose whether to enable auto-start
   - Decide whether to start Alpine immediately

3. On first login to Alpine, run the setup script:
   ```bash
   sh /root/first-setup.sh
   ```

4. The first setup will:
   - Update package lists
   - Install essential packages (nano, vim, wget, curl, git, sudo, bash)
   - Offer to create a non-root user with sudo privileges

## Starting Alpine Linux

If you didn't enable auto-start, you can start Alpine Linux manually:

```bash
./start-alpine.sh
```

## Auto-start

If you enabled auto-start, Alpine Linux will automatically start every time you open Termux.

To disable auto-start:
```bash
nano ~/.bashrc
# Delete the Alpine Linux auto-start section at the end
```

## Exiting Alpine Linux

To exit Alpine Linux and return to Termux:
```bash
exit
```

## Reinstallation

If you want to reinstall Alpine Linux:

1. Remove the existing installation:
   ```bash
   rm -rf ~/alpine-fs
   ```

2. Run the installer again:
   ```bash
   bash alpine-installer.sh
   ```

## What Gets Installed

- Alpine Linux minirootfs (minimal installation)
- Essential packages: nano, vim, wget, curl, git, sudo, bash, shadow
- DNS configuration (Google DNS: 8.8.8.8, 8.8.4.4)
- PRoot environment for running Alpine

## Directory Structure

```
$HOME/
├── alpine-fs/           # Alpine Linux root filesystem
└── start-alpine.sh      # Startup script
```

## Troubleshooting

### wget not working
Close Termux completely, reopen it, and run the script again.

### Download fails
The script will automatically offer alternative Alpine Linux versions if the selected version fails to download.

### Extraction fails
The script will validate and re-download the tar file if extraction fails.

### Package installation issues
Update Termux packages:
```bash
pkg update -y
pkg upgrade -y
```

## Alpine Linux vs Ubuntu

Alpine Linux is:
- Much lighter and faster than Ubuntu
- Uses less storage space
- Uses `apk` package manager instead of `apt`
- Uses OpenRC instead of systemd
- Ideal for minimal installations and containers

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
