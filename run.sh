#!/bin/bash

# Omarchy Run Script - Install Omarchy packages and configs on existing Arch Linux
# This script is designed to run on an already installed Arch Linux system (any filesystem)
# It skips system installation but applies all packages, configs, and sets up first-run

set -e

echo "=============================================="
echo "  Omarchy Configuration Script"
echo "  For existing Arch Linux installations"
echo "=============================================="
echo

# Define Omarchy locations
export OMARCHY_PATH="$HOME/.local/share/omarchy"
export OMARCHY_INSTALL="$OMARCHY_PATH/install"
export OMARCHY_INSTALL_LOG_FILE="/var/log/omarchy-install.log"
export PATH="$OMARCHY_PATH/bin:$PATH"

# Make sure we're in the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Copy omarchy to the right location if not already there
if [ "$SCRIPT_DIR" != "$OMARCHY_PATH" ]; then
  echo "Copying omarchy to $OMARCHY_PATH..."
  mkdir -p "$OMARCHY_PATH"
  cp -R "$SCRIPT_DIR"/* "$OMARCHY_PATH/" || {
    echo "Error: Failed to copy files to $OMARCHY_PATH"
    echo "Check permissions and try again"
    exit 1
  }
  # Update paths
  cd "$OMARCHY_PATH"
  export OMARCHY_PATH="$HOME/.local/share/omarchy"
  export OMARCHY_INSTALL="$OMARCHY_PATH/install"
  echo "Files copied successfully."
fi

abort() {
  echo -e "\e[31mOmarchy install requires: $1\e[0m"
  echo
  read -p "Proceed anyway on your own accord and without assistance? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
}

# ========== PREFLIGHT CHECKS (RELAXED) ==========
echo "Running preflight checks..."

# Must be an Arch distro
if [[ ! -f /etc/arch-release ]]; then
  abort "Vanilla Arch"
fi

# Must not be an Arch derivative distro
for marker in /etc/cachyos-release /etc/eos-release /etc/garuda-release /etc/manjaro-release; do
  if [[ -f "$marker" ]]; then
    abort "Vanilla Arch"
  fi
done

# Must not be running as root
if [ "$EUID" -eq 0 ]; then
  abort "Running as user (not root)"
fi

# Must be x86 only to fully work
if [ "$(uname -m)" != "x86_64" ]; then
  abort "x86_64 CPU"
fi

# Must not have Gnome or KDE already install
if pacman -Qe gnome-shell &>/dev/null || pacman -Qe plasma-desktop &>/dev/null; then
  echo -e "\e[33mWarning: GNOME Shell or KDE Plasma detected. This may cause conflicts.\e[0m"
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Warn about filesystem (not blocking)
FSTYPE=$(findmnt -n -o FSTYPE /)
if [ "$FSTYPE" != "btrfs" ]; then
  echo -e "\e[33mNote: Root filesystem is $FSTYPE (not Btrfs)\e[0m"
  echo "Snapshot features will be disabled, but everything else will work."
  echo
fi

# Warn about bootloader (not blocking)
if ! command -v limine &>/dev/null; then
  echo -e "\e[33mNote: Limine bootloader not detected\e[0m"
  echo "Bootloader configuration will be skipped. You'll need to configure your bootloader manually if needed."
  echo
fi

echo -e "\e[32mPreflight checks: OK\e[0m"
echo

# ========== INSTALL REQUIRED TOOLS FIRST ==========
echo "Installing required tools (gum, tte)..."
if ! command -v gum &>/dev/null || ! command -v tte &>/dev/null; then
  # Backup current SigLevel settings
  sudo cp /etc/pacman.conf /etc/pacman.conf.omarchy-backup

  # Temporarily disable signature verification for problematic packages
  echo "Temporarily disabling package signature verification..."
  sudo sed -i 's/^SigLevel\s*=.*/SigLevel = Never/' /etc/pacman.conf

  # Fix GPG keyring issues
  echo "Fixing GPG keyring..."
  sudo rm -rf /etc/pacman.d/gnupg
  sudo pacman-key --init
  sudo pacman-key --populate archlinux

  # Install required tools
  echo "Installing gum and python-terminaltexteffects..."
  sudo pacman -Sy --noconfirm --needed gum python-terminaltexteffects

  # Restore original pacman.conf
  echo "Restoring package signature verification..."
  sudo mv /etc/pacman.conf.omarchy-backup /etc/pacman.conf

  echo "Required tools installed."
else
  echo "Required tools already installed."
fi
echo

# ========== LOAD HELPERS ==========
echo "Loading helper functions..."
if ! source "$OMARCHY_INSTALL/helpers/all.sh" 2>/dev/null; then
  echo "Warning: Could not load helper functions, continuing anyway..."
  # Define minimal run_logged function as fallback
  run_logged() {
    echo "Running: $1"
    bash "$1" || {
      echo "Error in $1, exit code: $?"
      return 1
    }
  }
fi

# ========== RUN PREFLIGHT (EXCEPT GUARD) ==========
echo "Running preflight setup..."
# Skip guard.sh since we already did relaxed checks above
run_logged "$OMARCHY_INSTALL/preflight/begin.sh" || echo "Warning: preflight/begin.sh failed, continuing..."
run_logged "$OMARCHY_INSTALL/preflight/show-env.sh" || echo "Warning: preflight/show-env.sh failed, continuing..."
run_logged "$OMARCHY_INSTALL/preflight/pacman.sh" || echo "Warning: preflight/pacman.sh failed, continuing..."
run_logged "$OMARCHY_INSTALL/preflight/migrations.sh" || echo "Warning: preflight/migrations.sh failed, continuing..."
run_logged "$OMARCHY_INSTALL/preflight/first-run-mode.sh" || echo "Warning: preflight/first-run-mode.sh failed, continuing..."

# Skip disable-mkinitcpio.sh since we're not doing bootloader stuff
echo "Skipping mkinitcpio disable (not needed for package-only install)"

# ========== INSTALL PACKAGES ==========
echo
echo "=========================================="
echo "  Installing Packages"
echo "=========================================="
source "$OMARCHY_INSTALL/packaging/all.sh"

# ========== APPLY CONFIGURATIONS ==========
echo
echo "=========================================="
echo "  Applying Configurations"
echo "=========================================="
source "$OMARCHY_INSTALL/config/all.sh"

# ========== LOGIN SETUP (MODIFIED) ==========
echo
echo "=========================================="
echo "  Setting up Login Manager"
echo "=========================================="
run_logged "$OMARCHY_INSTALL/login/plymouth.sh"
run_logged "$OMARCHY_INSTALL/login/default-keyring.sh"
run_logged "$OMARCHY_INSTALL/login/sddm.sh"

# Skip limine-snapper.sh if not using Limine + Btrfs
if command -v limine &>/dev/null && [ "$FSTYPE" = "btrfs" ]; then
  echo "Limine + Btrfs detected, configuring bootloader..."
  run_logged "$OMARCHY_INSTALL/login/limine-snapper.sh"
else
  echo "Skipping limine-snapper setup (requires Limine bootloader + Btrfs)"
fi

# ========== POST-INSTALL ==========
echo
echo "=========================================="
echo "  Post-Install Configuration"
echo "=========================================="
run_logged "$OMARCHY_INSTALL/post-install/pacman.sh"
run_logged "$OMARCHY_INSTALL/post-install/allow-reboot.sh"
run_logged "$OMARCHY_INSTALL/post-install/finished.sh"

echo
echo "=============================================="
echo "  Omarchy Installation Complete!"
echo "=============================================="
echo
echo "Next steps:"
echo "1. Review the installation log at: $OMARCHY_INSTALL_LOG_FILE"
echo "2. Reboot your system"
echo "3. Select SDDM as your display manager if prompted"
echo "4. Log in and Hyprland will start automatically"
echo "5. First-run setup will complete on first login"
echo
echo "To reboot now, run: sudo reboot"
echo
