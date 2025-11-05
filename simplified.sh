#!/bin/bash
# Simplified Omarchy Installation Script for ext4
# Achieves same packages and configs as run.sh but in a more direct way

set -e

echo "=============================================="
echo "  Omarchy Simplified Installation"
echo "  For Arch Linux on ext4"
echo "=============================================="

# Setup environment
export OMARCHY_PATH="$HOME/.local/share/omarchy"
export OMARCHY_INSTALL="$OMARCHY_PATH/install"
export OMARCHY_DISABLE_BTRFS_FEATURES=1
export PATH="$OMARCHY_PATH/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy omarchy to target location if needed
if [ "$SCRIPT_DIR" != "$OMARCHY_PATH" ]; then
  echo "Copying omarchy to $OMARCHY_PATH..."
  mkdir -p "$OMARCHY_PATH"
  cp -R "$SCRIPT_DIR"/* "$OMARCHY_PATH/"
  cd "$OMARCHY_PATH"
fi

# Fix GPG keyring and install required tools
echo "Setting up package management..."
sudo sed -i 's/^SigLevel\s*=.*/SigLevel = Never/' /etc/pacman.conf
sudo pacman -Sy --noconfirm --needed --overwrite '*' gum python-terminaltexteffects base-devel

# Configure pacman with omarchy settings
echo "Configuring pacman..."
sudo cp -f ~/.local/share/omarchy/default/pacman/pacman.conf /etc/pacman.conf
sudo cp -f ~/.local/share/omarchy/default/pacman/mirrorlist /etc/pacman.d/mirrorlist

# Disable signature verification permanently
sudo sed -i 's/^SigLevel\s*=.*/SigLevel = Never/' /etc/pacman.conf

# Add Apple T2 repo if detected
if lspci -nn 2>/dev/null | grep -q "106b:180[12]"; then
  echo "Apple T2 detected, adding arch-mact2 repo..."
  cat <<EOF | sudo tee -a /etc/pacman.conf >/dev/null

[arch-mact2]
Server = https://github.com/NoaHimesaka1873/arch-mact2-mirror/releases/download/release
SigLevel = Never
EOF
fi

# Install all base packages
echo "Installing base packages (~139 packages)..."
sudo pacman -Sy --noconfirm --needed --overwrite '*' $(grep -v '^#' "$OMARCHY_INSTALL/omarchy-base.packages" | grep -v '^$')

# Install fonts
echo "Installing fonts..."
mkdir -p ~/.local/share/fonts
cp ~/.local/share/omarchy/config/omarchy.ttf ~/.local/share/fonts/
fc-cache

# Setup nvim
echo "Setting up neovim..."
omarchy-nvim-setup

# Install app icons
echo "Installing app icons..."
ICON_DIR="$HOME/.local/share/applications/icons"
mkdir -p "$ICON_DIR"
cp ~/.local/share/omarchy/applications/icons/*.png "$ICON_DIR/"

# Install webapps
echo "Installing webapps..."
omarchy-webapp-install "HEY" https://app.hey.com HEY.png "omarchy-webapp-handler-hey %u" "x-scheme-handler/mailto"
omarchy-webapp-install "Basecamp" https://launchpad.37signals.com Basecamp.png
omarchy-webapp-install "WhatsApp" https://web.whatsapp.com/ WhatsApp.png
omarchy-webapp-install "Google Photos" https://photos.google.com/ "Google Photos.png"
omarchy-webapp-install "Google Contacts" https://contacts.google.com/ "Google Contacts.png"
omarchy-webapp-install "Google Messages" https://messages.google.com/web/conversations "Google Messages.png"
omarchy-webapp-install "ChatGPT" https://chatgpt.com/ ChatGPT.png
omarchy-webapp-install "YouTube" https://youtube.com/ YouTube.png
omarchy-webapp-install "GitHub" https://github.com/ GitHub.png
omarchy-webapp-install "X" https://x.com/ X.png
omarchy-webapp-install "Figma" https://figma.com/ Figma.png
omarchy-webapp-install "Discord" https://discord.com/channels/@me Discord.png
omarchy-webapp-install "Zoom" https://app.zoom.us/wc/home Zoom.png "omarchy-webapp-handler-zoom %u" "x-scheme-handler/zoommtg;x-scheme-handler/zoomus"

# Install TUIs
echo "Installing TUI apps..."
omarchy-tui-install "Disk Usage" "bash -c 'dust -r; read -n 1 -s'" float "$ICON_DIR/Disk Usage.png"
omarchy-tui-install "Docker" "lazydocker" tile "$ICON_DIR/Docker.png"

# Copy config files
echo "Copying config files..."
mkdir -p ~/.config
cp -R ~/.local/share/omarchy/config/* ~/.config/
cp ~/.local/share/omarchy/default/bashrc ~/.bashrc

# Setup theme system
echo "Setting up theme system..."
sudo ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-previous-symbolic.svg /usr/share/icons/Yaru/scalable/actions/go-previous-symbolic.svg
sudo ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-next-symbolic.svg /usr/share/icons/Yaru/scalable/actions/go-next-symbolic.svg
mkdir -p ~/.config/omarchy/themes
for f in ~/.local/share/omarchy/themes/*; do ln -nfs "$f" ~/.config/omarchy/themes/; done
mkdir -p ~/.config/omarchy/current
ln -snf ~/.config/omarchy/themes/tokyo-night ~/.config/omarchy/current/theme
ln -snf ~/.config/omarchy/current/theme/backgrounds/1-scenery-pink-lakeside-sunset-lake-landscape-scenic-panorama-7680x3215-144.png ~/.config/omarchy/current/background
mkdir -p ~/.config/btop/themes
ln -snf ~/.config/omarchy/current/theme/btop.theme ~/.config/btop/themes/current.theme
mkdir -p ~/.config/mako
ln -snf ~/.config/omarchy/current/theme/mako.ini ~/.config/mako/config
sudo mkdir -p /etc/chromium/policies/managed /etc/brave/policies/managed
sudo chmod a+rw /etc/chromium/policies/managed /etc/brave/policies/managed

# Configure Docker
echo "Configuring Docker..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
{
    "log-driver": "json-file",
    "log-opts": { "max-size": "10m", "max-file": "5" },
    "dns": ["172.17.0.1"],
    "bip": "172.17.0.1/16"
}
EOF
sudo mkdir -p /etc/systemd/resolved.conf.d
echo -e '[Resolve]\nDNSStubListenerExtra=172.17.0.1' | sudo tee /etc/systemd/resolved.conf.d/20-docker-dns.conf >/dev/null
sudo systemctl restart systemd-resolved
sudo usermod -aG docker ${USER}
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/no-block-boot.conf <<'EOF'
[Unit]
DefaultDependencies=no
EOF

# Configure networking
echo "Configuring network services..."
sudo systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true
sudo systemctl mask systemd-networkd-wait-online.service 2>/dev/null || true

# Setup plymouth boot splash
echo "Setting up plymouth..."
if [ "$(plymouth-set-default-theme 2>/dev/null)" != "omarchy" ]; then
  sudo cp -r "$HOME/.local/share/omarchy/default/plymouth" /usr/share/plymouth/themes/omarchy/
  sudo plymouth-set-default-theme omarchy
fi

# Configure SDDM login manager
echo "Configuring SDDM..."
sudo mkdir -p /etc/sddm.conf.d
if [ ! -f /etc/sddm.conf.d/autologin.conf ]; then
  cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf
[Autologin]
User=$USER
Session=hyprland-uwsm

[Theme]
Current=breeze
EOF
fi

# Setup DNS resolver
echo "Setting up DNS resolver..."
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Configure firewall
echo "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 53317/udp  # LocalSend
sudo ufw allow 53317/tcp  # LocalSend
sudo ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns'
sudo ufw --force enable
sudo ufw-docker install 2>/dev/null || true
sudo ufw reload

# Enable all systemd services
echo "Enabling systemd services..."
sudo systemctl daemon-reload
sudo systemctl enable docker iwd sddm ufw

echo ""
echo "=============================================="
echo "  Installation Complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo "1. Reboot your system: sudo reboot"
echo "2. Log in and Hyprland will start automatically"
echo ""
echo "Note: You are now in the 'docker' group."
echo "You'll need to log out and back in for that to take effect."
echo ""
echo "Skipped (ext4 specific):"
echo "- Btrfs snapshot features"
echo "- Limine bootloader configuration"
echo "- Hardware-specific fixes (run config/hardware/* manually if needed)"
echo ""
