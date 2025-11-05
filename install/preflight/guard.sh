confirm_continue() {
  local prompt="$1"
  if command -v gum &>/dev/null; then
    gum confirm "$prompt"
  else
    read -p "$prompt [y/N] " -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
  fi
}

abort() {
  echo -e "\e[31mOmarchy install requires: $1\e[0m"
  echo
  confirm_continue "Proceed anyway on your own accord and without assistance?" || exit 1
}

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
  abort "Running as root (not user)"
fi

# Must be x86 only to fully work
if [ "$(uname -m)" != "x86_64" ]; then
  abort "x86_64 CPU"
fi

# Must have secure boot disabled
if bootctl status 2>/dev/null | grep -q 'Secure Boot: enabled'; then
  abort "Secure Boot disabled"
fi

# Must not have Gnome or KDE already install
if pacman -Qe gnome-shell &>/dev/null || pacman -Qe plasma-desktop &>/dev/null; then
  abort "Fresh + Vanilla Arch"
fi

# Must have limine installed
command -v limine &>/dev/null || abort "Limine bootloader"

OMARCHY_ROOT_FSTYPE="$(findmnt -n -o FSTYPE /)"
export OMARCHY_ROOT_FSTYPE

if [ "$OMARCHY_ROOT_FSTYPE" != "btrfs" ]; then
  echo -e "\e[33mWarning: Root filesystem is $OMARCHY_ROOT_FSTYPE (Btrfs recommended)\e[0m"
  echo "Snapshot-related features will be disabled."
  echo
  export OMARCHY_DISABLE_BTRFS_FEATURES=1

  if [[ -z ${OMARCHY_ALLOW_NON_BTRFS:-} ]]; then
    confirm_continue "Continue without Btrfs-specific features?" || exit 1
  fi
else
  unset OMARCHY_DISABLE_BTRFS_FEATURES
fi

# Cleared all guards
echo "Guards: OK"
