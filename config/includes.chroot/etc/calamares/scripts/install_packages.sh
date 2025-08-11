#!/bin/bash
# /etc/calamares/scripts/install_packages.sh

# --- 0. SETUP AND ROBUST LOGGING ---
# This script creates its own log file to ensure we capture all output.
LOG_FILE="/home/$1/post-install-script.log"
exec > >(tee -a ${LOG_FILE}) 2>&1

set -e

echo "--- Script started at $(date) ---"
echo "Logging output to ${LOG_FILE}"

# --- 1. VALIDATE INPUT ---
if [ -z "$1" ]; then
  echo "FATAL: No username was provided to the script."
  exit 1
fi

NEW_USER="$1"
USER_HOME="/home/$NEW_USER"

if [ ! -d "$USER_HOME" ]; then
  echo "FATAL: Home directory $USER_HOME for user $NEW_USER does not exist."
  exit 1
fi

echo "Starting post-installation setup for user: $NEW_USER"


# --- 2. CONFIGURE APT SOURCES (Self-Contained) ---
# We are putting this back in, as the script needs to ensure APT is configured.
echo "Creating a new, complete /etc/apt/sources.list for Trixie..."
cat > /etc/apt/sources.list << EOF
# Main Debian Trixie Repository
deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware

# Debian Trixie Security Updates
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware

# Debian Trixie Updates (volatile)
deb http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware
EOF

# Ensure the sources.list.d directory exists.
mkdir -p /etc/apt/sources.list.d
# We will NOT clean this directory, as it's safer to let installers manage their own files.

echo "Running 'apt-get update' to use the new repository configuration..."
apt-get update


# --- 3. CHECK NETWORK CONNECTIVITY ---
# This check is still valuable to provide a clear error if the internet is down.
echo "Pinging debian.org to check for internet connectivity..."
if ! ping -c 3 debian.org; then
    echo "WARNING: Network connectivity check failed. The script will proceed but may fail if package downloads are required."
fi
echo "Network check complete."


# --- 4. INSTALL SYSTEM-WIDE DEPENDENCIES ---
echo "Installing system-wide dependencies (Go, build tools, etc.)..."
# Add --allow-unauthenticated temporarily if GPG keys are an issue on first run, though Brave's script should handle its own.
apt-get install -y build-essential curl git wget tar


# --- 5. BRAVE BROWSER INSTALLATION ---
echo "Installing Brave Browser system-wide..."
curl -fsS https://dl.brave.com/install.sh | bash


# --- 6. ARGUS INSTALLATION (as the new user) ---
#echo "Installing Argus for user $NEW_USER in home directory $USER_HOME..."
#sudo -H -u "$NEW_USER" bash <<EOF
#set -e
#echo "Running Argus install script as user: \$(whoami) in home directory: \$HOME"

#mkdir -p "\$HOME/.config/argus"

#ARGUS_TEMP_DIR=\$(mktemp -d -p "\$HOME")
#trap 'rm -rf "\$ARGUS_TEMP_DIR"' EXIT

#git clone https://github.com/KillAllChickens/argus "\$ARGUS_TEMP_DIR"
#cd "\$ARGUS_TEMP_DIR"
#./scripts/install-linux.sh

#echo "Argus installation complete."
#EOF

# --- Setup flatpak/flathub as user ---
echo "Setting up flatpak for user $NEW_USER without D-Bus..."

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install -y flathub it.mijorus.gearlever


# --- install helper binaries ---
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

git clone https://github.com/KillAllChickens/KACOS-scripts "$TMP_DIR"
cd "$TMP_DIR"
chmod +x ./kac-*
cp ./kac-* /usr/local/bin/

# --- Install GUI apps ---
GUI_TMP_DIR=$(mktemp -d)
trap 'rm -rf "$GUI_TMP_DIR"' EXIT

cd "$GUI_TMP_DIR"
wget https://github.com/KillAllChickens/KACOS-Qt-Apps/releases/latest/download/welcomer.tar.gz
tar -xzvf welcomer.tar.gz
cp ./welcomer /usr/bin/kac-welcomer


# --- FINAL CLEANUP (as root) ---
echo "Cleaning up apt cache..."
apt-get clean
rm -rf /var/lib/apt/lists/*

# Set correct ownership for the log file
chown ${NEW_USER}:${NEW_USER} ${LOG_FILE}

echo "--- Custom package installation finished successfully at $(date) ---"
exit 0
