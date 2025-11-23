#!/data/data/com.termux/files/usr/bin/bash

# Alpine Linux Termux Manual Installation Script (with PRoot)
# No root required, does not use proot-distro

echo "================================================"
echo "  Alpine Linux Termux Manual Installation Script"
echo "================================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Error checking function
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERROR]${NC} $1"
        exit 1
    fi
}

# Info message function
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Warning message function
warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Installation directory
ALPINE_DIR="$HOME/alpine-fs"
SCRIPT_DIR="$HOME"

# 1. Update and repair Termux packages
info "Updating and repairing Termux packages..."
info "This may take a few minutes..."

# Update package database
pkg update -y 2>/dev/null || {
    warn "Normal update failed, changing repository..."
    termux-change-repo
    pkg update -y
}

# Upgrade critical libraries and packages
info "Upgrading system packages..."
pkg upgrade -y libandroid-posix-semaphore 2>/dev/null || true
pkg upgrade -y 2>/dev/null || {
    warn "Some packages could not be upgraded, continuing..."
}

# 2. Install/reinstall required packages
info "Installing required packages..."
pkg install -y --reinstall proot wget tar -o Dpkg::Options::="--force-confnew"
check_error "Failed to install required packages"

# Test if wget is working
info "Testing wget..."
if ! wget --version >/dev/null 2>&1; then
    echo -e "${RED}[ERROR]${NC} wget is not working properly."
    echo "Please close Termux completely, reopen it, and run the script again."
    exit 1
fi
info "✓ wget is working"

# Check if running via pipe (early detection)
PIPED_INPUT=false
if [ ! -t 0 ]; then
    PIPED_INPUT=true
    warn "Script is running via pipe, default values will be used"
fi

# 3. Check for existing installation
if [ -d "$ALPINE_DIR" ]; then
    warn "Alpine Linux installation already exists: $ALPINE_DIR"

    # If running via pipe, automatically remove and reinstall
    if [ "$PIPED_INPUT" = true ]; then
        response="y"
        info "Default choice: Existing installation will be removed and reinstalled"
    else
        read -p "Do you want to remove the existing installation and reinstall? (y/n): " response
    fi

    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        info "Removing existing installation..."
        rm -rf "$ALPINE_DIR"
        check_error "Failed to remove installation"
    else
        info "Installation cancelled."
        exit 0
    fi
fi

# 4. Create installation directory
info "Creating installation directory: $ALPINE_DIR"
mkdir -p "$ALPINE_DIR"
check_error "Failed to create directory"

# 5. Download Alpine Linux minirootfs
info "Downloading Alpine Linux minirootfs..."
info "This may take a few minutes, please wait..."

# Architecture detection
case $(uname -m) in
    aarch64|arm64)
        ARCH="aarch64"
        ;;
    armv7l|armv8l)
        ARCH="armv7"
        ;;
    x86_64)
        ARCH="x86_64"
        ;;
    i686|i386)
        ARCH="x86"
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

info "Architecture: $ARCH"

# Fetch available Alpine versions
info "Checking available Alpine Linux versions..."

# Get latest versions from Alpine mirrors
AVAILABLE_VERSIONS=$(wget -qO- https://dl-cdn.alpinelinux.org/alpine/ 2>/dev/null | \
    grep -oP 'href="v\K[0-9]+\.[0-9]+(?=/)' | \
    sort -Vru | \
    head -n 4)

if [ -z "$AVAILABLE_VERSIONS" ]; then
    echo -e "${RED}[ERROR]${NC} Could not detect Alpine versions. Check your internet connection."
    warn "Using fallback known versions..."
    AVAILABLE_VERSIONS="3.21
3.20
3.19
3.18"
fi

# Store 4 versions in array
VERSION_ARRAY=($AVAILABLE_VERSIONS)

VERSION_1="${VERSION_ARRAY[0]}"
VERSION_2="${VERSION_ARRAY[1]}"
VERSION_3="${VERSION_ARRAY[2]}"
VERSION_4="${VERSION_ARRAY[3]}"

# Success message
if [ ${#VERSION_ARRAY[@]} -ge 4 ]; then
    info "✓ Successfully detected the latest 4 Alpine Linux versions"
fi

# Get latest point release for each version
get_latest_point_release() {
    local base_version=$1
    local latest_point=$(wget -qO- "https://dl-cdn.alpinelinux.org/alpine/v${base_version}/releases/${ARCH}/" 2>/dev/null | \
        grep -oP "alpine-minirootfs-${base_version}\.\K[0-9]+" | \
        sort -Vru | \
        head -n 1)

    if [ -z "$latest_point" ]; then
        # Use base version .0 as fallback
        echo "${base_version}.0"
    else
        # Use latest point release
        echo "${base_version}.${latest_point}"
    fi
}

VERSION_1_FULL=$(get_latest_point_release "$VERSION_1")
VERSION_2_FULL=$(get_latest_point_release "$VERSION_2")
VERSION_3_FULL=$(get_latest_point_release "$VERSION_3")
VERSION_4_FULL=$(get_latest_point_release "$VERSION_4")

# Let user choose
echo ""
echo -e "${BLUE}Which Alpine Linux version would you like to install?${NC}"
echo -e "${YELLOW}(Alpine is a lightweight, security-oriented distribution)${NC}"
echo ""
echo "  1) Alpine ${VERSION_1_FULL}"
echo "  2) Alpine ${VERSION_2_FULL}"
echo "  3) Alpine ${VERSION_3_FULL}"
echo "  4) Alpine ${VERSION_4_FULL}"
echo ""

# If running via pipe, use default choice
if [ "$PIPED_INPUT" = true ]; then
    version_choice=1
    info "Default choice: Alpine ${VERSION_1_FULL}"
else
    read -p "Your choice (1, 2, 3, or 4): " version_choice
fi

# Set selected version and alternatives
case $version_choice in
    1)
        ALPINE_VERSION="$VERSION_1_FULL"
        ALPINE_BASE_VERSION="$VERSION_1"
        ALTERNATIVES=("$VERSION_2_FULL:$VERSION_2" "$VERSION_3_FULL:$VERSION_3" "$VERSION_4_FULL:$VERSION_4")
        info "Alpine ${VERSION_1_FULL} selected"
        ;;
    2)
        ALPINE_VERSION="$VERSION_2_FULL"
        ALPINE_BASE_VERSION="$VERSION_2"
        ALTERNATIVES=("$VERSION_1_FULL:$VERSION_1" "$VERSION_3_FULL:$VERSION_3" "$VERSION_4_FULL:$VERSION_4")
        info "Alpine ${VERSION_2_FULL} selected"
        ;;
    3)
        ALPINE_VERSION="$VERSION_3_FULL"
        ALPINE_BASE_VERSION="$VERSION_3"
        ALTERNATIVES=("$VERSION_1_FULL:$VERSION_1" "$VERSION_2_FULL:$VERSION_2" "$VERSION_4_FULL:$VERSION_4")
        info "Alpine ${VERSION_3_FULL} selected"
        ;;
    4)
        ALPINE_VERSION="$VERSION_4_FULL"
        ALPINE_BASE_VERSION="$VERSION_4"
        ALTERNATIVES=("$VERSION_1_FULL:$VERSION_1" "$VERSION_2_FULL:$VERSION_2" "$VERSION_3_FULL:$VERSION_3")
        info "Alpine ${VERSION_4_FULL} selected"
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Invalid choice. You must select 1, 2, 3, or 4."
        exit 1
        ;;
esac

# Dynamically build download URLs
ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_BASE_VERSION}/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"

echo ""

cd "$HOME"

# Attempt download
info "Download URL: $ALPINE_URL"
wget --timeout=30 --tries=3 --continue "${ALPINE_URL}" -O alpine.tar.gz

# Check download
if [ $? -ne 0 ] || [ ! -f alpine.tar.gz ] || [ ! -s alpine.tar.gz ]; then
    echo -e "${RED}[ERROR]${NC} Failed to download Alpine ${ALPINE_VERSION}."
    rm -f alpine.tar.gz

    # Offer alternative versions
    echo ""
    warn "Download failed for Alpine ${ALPINE_VERSION}."
    echo ""
    echo -e "${BLUE}Would you like to try one of the alternative versions?${NC}"
    echo ""

    # Show alternatives
    for i in "${!ALTERNATIVES[@]}"; do
        ALT_FULL=$(echo "${ALTERNATIVES[$i]}" | cut -d: -f1)
        echo "  $((i+1))) Alpine ${ALT_FULL}"
    done
    echo "  $((${#ALTERNATIVES[@]}+1))) Cancel installation"
    echo ""

    # If running via pipe, automatically try first alternative
    if [ "$PIPED_INPUT" = true ]; then
        alt_choice=1
        info "Default choice: Trying first alternative version"
    else
        read -p "Your choice: " alt_choice
    fi

    # Validate choice
    if [ "$alt_choice" -ge 1 ] && [ "$alt_choice" -le "${#ALTERNATIVES[@]}" ] 2>/dev/null; then
        selected_index=$((alt_choice-1))
        ALPINE_VERSION=$(echo "${ALTERNATIVES[$selected_index]}" | cut -d: -f1)
        ALPINE_BASE_VERSION=$(echo "${ALTERNATIVES[$selected_index]}" | cut -d: -f2)
        ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_BASE_VERSION}/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"

        info "Trying Alpine ${ALPINE_VERSION}..."
        info "Download URL: $ALPINE_URL"
        wget --timeout=30 --tries=3 --continue "${ALPINE_URL}" -O alpine.tar.gz

        # Check alternative download
        if [ $? -ne 0 ] || [ ! -f alpine.tar.gz ] || [ ! -s alpine.tar.gz ]; then
            echo -e "${RED}[ERROR]${NC} Failed to download Alpine ${ALPINE_VERSION} as well."
            echo "Check your internet connection and try again."
            rm -f alpine.tar.gz
            exit 1
        fi
    else
        echo "Installation cancelled."
        exit 1
    fi
fi

info "Alpine minirootfs downloaded successfully ($(du -h alpine.tar.gz | cut -f1))"

# 6. Extract rootfs
info "Extracting Alpine Linux minirootfs..."
info "This may take a few minutes..."

cd "$ALPINE_DIR"

# Validate tar file
info "Validating tar file..."
tar -tzf "$HOME/alpine.tar.gz" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} Tar file is corrupted, re-downloading..."
    rm -f "$HOME/alpine.tar.gz"
    cd "$HOME"
    wget --timeout=30 --tries=3 --continue "${ALPINE_URL}" -O alpine.tar.gz
    check_error "Re-download failed"
fi

# Try different tar parameters
info "Extracting files..."
proot --link2symlink tar -xf "$HOME/alpine.tar.gz" 2>/dev/null || \
tar -xf "$HOME/alpine.tar.gz" 2>/dev/null

# Check
if [ ! -d "$ALPINE_DIR/usr" ] || [ ! -d "$ALPINE_DIR/etc" ]; then
    echo -e "${RED}[ERROR]${NC} Rootfs was not extracted properly."
    echo "Please check manually: ls -la $ALPINE_DIR"
    exit 1
fi

info "Rootfs extracted successfully"

# Clean up downloaded file
rm "$HOME/alpine.tar.gz"
info "Temporary files cleaned up"

# 7. Configure DNS settings
info "Configuring DNS..."
echo "nameserver 8.8.8.8" > "$ALPINE_DIR/etc/resolv.conf"
echo "nameserver 8.8.4.4" >> "$ALPINE_DIR/etc/resolv.conf"

# 8. Create startup script
info "Creating startup script..."
cat > "$SCRIPT_DIR/start-alpine.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# Disable termux-exec
unset LD_PRELOAD

ALPINE_DIR="$HOME/alpine-fs"

# Create required directories
mkdir -p "$ALPINE_DIR/dev"
mkdir -p "$ALPINE_DIR/proc"
mkdir -p "$ALPINE_DIR/sys"
mkdir -p "$ALPINE_DIR/tmp"
mkdir -p "$ALPINE_DIR/root"

# Check for username
ALPINE_USER=""
if [ -f "$ALPINE_DIR/root/.alpine-user" ]; then
    ALPINE_USER=$(cat "$ALPINE_DIR/root/.alpine-user")
fi

# Start Alpine with PRoot
if [ -n "$ALPINE_USER" ]; then
    # If user exists, start with that user
    proot \
        --root-id \
        --link2symlink \
        --kill-on-exit \
        --rootfs="$ALPINE_DIR" \
        --bind=/dev \
        --bind=/proc \
        --bind=/sys \
        --bind=/sdcard \
        --cwd=/home/$ALPINE_USER \
        --mount=/proc \
        --mount=/sys \
        --mount=/dev \
        /usr/bin/env -i \
        HOME=/home/$ALPINE_USER \
        USER=$ALPINE_USER \
        TERM="$TERM" \
        LANG=C.UTF-8 \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        /bin/sh -c "/bin/su -l $ALPINE_USER"
else
    # If no user, start with root
    proot \
        --root-id \
        --link2symlink \
        --kill-on-exit \
        --rootfs="$ALPINE_DIR" \
        --bind=/dev \
        --bind=/proc \
        --bind=/sys \
        --bind=/sdcard \
        --cwd=/root \
        --mount=/proc \
        --mount=/sys \
        --mount=/dev \
        /usr/bin/env -i \
        HOME=/root \
        TERM="$TERM" \
        LANG=C.UTF-8 \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        /bin/sh --login
fi
EOF

chmod +x "$SCRIPT_DIR/start-alpine.sh"

# 9. Create first setup script (to run inside Alpine)
info "Preparing first setup script..."
cat > "$ALPINE_DIR/root/first-setup.sh" << 'EOF'
#!/bin/sh

echo "Starting Alpine Linux first setup. This may take a while, please wait..."

echo "Updating package lists..."
apk update
apk upgrade

echo "Configuring locale settings..."
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

echo "Installing essential packages..."
apk add nano vim wget curl git sudo bash shadow

# Fix hosts file
echo '127.0.0.1 localhost' > /etc/hosts
echo '127.0.1.1 localhost.localdomain' >> /etc/hosts

echo ""
echo "================================================"
echo "  Alpine Linux basic setup completed!"
echo "================================================"
echo ""

# New user creation option
read -p "Would you like to create a new non-root user? (y/n): " create_user

if [ "$create_user" = "y" ] || [ "$create_user" = "Y" ]; then
    echo ""
    echo "Creating new user..."
    echo ""

    # Get username
    while true; do
        read -p "Username: " username

        # Username validation
        if [ -z "$username" ]; then
            echo "Error: Username cannot be empty."
            continue
        fi

        if id "$username" >/dev/null 2>&1; then
            echo "Error: User '$username' already exists."
            continue
        fi

        if ! echo "$username" | grep -Eq '^[a-z][-a-z0-9]*$'; then
            echo "Error: Invalid username. Must start with a lowercase letter and contain only letters, numbers, and hyphens."
            continue
        fi

        break
    done

    # Create user with bash shell
    adduser -s /bin/bash "$username"

    if [ $? -eq 0 ]; then
        echo "✓ User '$username' created"

        # Grant sudo privileges (automatic)
        echo ""
        echo "Granting sudo privileges..."

        # Add user to wheel group (Alpine's sudo group)
        adduser "$username" wheel

        # Create sudoers configuration
        echo "$username ALL=(ALL:ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$username"
        chmod 0440 "/etc/sudoers.d/$username"

        echo "✓ Sudo privileges granted to '$username'"

        # Save username (for start-alpine.sh)
        echo "$username" > /root/.alpine-user

        echo ""
        echo "✓ User created successfully!"
        echo ""
        echo "Termux will automatically start with user '$username' every time it opens."
        echo ""
        echo "To switch to the new user:"
        echo "  su - $username"
        echo ""
    else
        echo "✗ Failed to create user"
    fi
else
    echo "New user not created."
fi

echo ""
echo "================================================"
echo "  Setup completed!"
echo "================================================"
echo ""
echo "First setup script completed."
echo "You can delete this file: rm /root/first-setup.sh"
echo ""
EOF

chmod +x "$ALPINE_DIR/root/first-setup.sh"

# 10. Installation completed
echo ""
echo "================================================"
info "Alpine Linux installed successfully!"
echo "================================================"
echo ""
echo -e "${BLUE}Installation Directory:${NC} $ALPINE_DIR"
echo ""
echo -e "${GREEN}To start Alpine Linux:${NC}"
echo "  ./start-alpine.sh"
echo ""
echo -e "${GREEN}On first login, run:${NC}"
echo "  sh /root/first-setup.sh"
echo ""
echo "This command will update the system and install essential packages."
echo ""
echo -e "${YELLOW}Note:${NC} To exit Alpine Linux, type 'exit'"
echo ""

# 11. Offer auto-start option to user
echo ""
# If running via pipe, enable auto-start by default
if [ "$PIPED_INPUT" = true ]; then
    auto_start="y"
    info "Default choice: Auto-start enabled."
else
    read -p "Would you like to automatically start Alpine Linux every time Termux opens? (This option also adds the Alpine logo) (y/n): " auto_start
fi

if [ "$auto_start" = "y" ] || [ "$auto_start" = "Y" ]; then
    info "Configuring auto-start setting..."

    # Check .bashrc file
    BASHRC_FILE="$HOME/.bashrc"

    # Add if not already added
    if ! grep -q "start-alpine.sh" "$BASHRC_FILE" 2>/dev/null; then
        # Add logo and auto-start
        cat >> "$BASHRC_FILE" << 'BASHRC_EOF'
# Alpine Linux logo and auto-start
if [ -f "$HOME/start-alpine.sh" ]; then
    BLUE='\033[0;34m'
    RESET='\033[0m'
    clear
    echo ""
    echo -e "${BLUE}"
    echo "     /\     _        _              "
    echo "    /  \   | |      (_)             "
    echo "   / /\ \  | |__ _ _ __ __   ___"
    echo "  / ____ \ | ||  _ \| |  _ \ / _ \ "
    echo " /_/    \_\| || |_) | | | | | ___/ "
    echo "           |_||____/|_|_| |_|\___/ "
    echo "              | |                 "
    echo "              |_|                 "
    echo ""
    echo -e "${RESET}"
    ./start-alpine.sh
fi
BASHRC_EOF
        info "Auto-start setting added"
        info "Alpine Linux will start automatically every time you open Termux"
        echo ""
        echo -e "${YELLOW}Note:${NC} To disable auto-start:"
        echo "  nano ~/.bashrc"
        echo "  (Delete the Alpine Linux auto-start section at the end)"
    else
        warn "Auto-start already configured"
    fi

    # Start now
    echo ""
    # If running via pipe, don't start now
    if [ "$PIPED_INPUT" = true ]; then
        start_now="n"
        info "Script completed. Alpine Linux will start automatically when you close and reopen Termux."
        info "(Don't forget to run the command: sh /root/first-setup.sh in your Alpine session!)"
    else
        read -p "Would you like to start Alpine Linux now? (y/n): " start_now
        if [ "$start_now" = "y" ] || [ "$start_now" = "Y" ]; then
            info "Starting Alpine Linux..."
            exec "$SCRIPT_DIR/start-alpine.sh"
        else
            info "Script completed. Alpine Linux will start automatically when you close and reopen Termux."
            info "(Don't forget to run the command: sh /root/first-setup.sh in your Alpine session!)"
        fi
    fi
else
    info "Auto-start not configured"

    # 12. Offer user option to start Alpine
    echo ""
    # If running via pipe, don't start now
    if [ "$PIPED_INPUT" = true ]; then
        start_alpine="n"
        info "Script completed. Happy coding!"
        echo ""
        echo -e "${GREEN}To start Alpine Linux:${NC}"
        echo "  ./start-alpine.sh"
    else
        read -p "Would you like to start Alpine Linux now? (y/n): " start_alpine
        if [ "$start_alpine" = "y" ] || [ "$start_alpine" = "Y" ]; then
            info "Starting Alpine Linux..."
            exec "$SCRIPT_DIR/start-alpine.sh"
        else
            info "Script completed. Happy coding!"
            info "(Don't forget to run the command: sh /root/first-setup.sh in your Alpine session!)"
            echo ""
            echo -e "${GREEN}To start Alpine Linux:${NC}"
            echo "  ./start-alpine.sh"
        fi
    fi
fi
