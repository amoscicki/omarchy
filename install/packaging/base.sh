#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

if [ "${OMARCHY_INSTALL:-}" = "" ]; then
  OMARCHY_INSTALL=$(dirname "$script_dir")
fi

pkg_file="$OMARCHY_INSTALL/omarchy-base.packages"

if [ ! -f "$pkg_file" ]; then
  echo "Package list not found: $pkg_file" >&2
  exit 1
fi

set --

line=""

while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    ''|'#'*)
      ;;
    *)
      set -- "$@" "$line"
      ;;
  esac
done < "$pkg_file"

if [ "$#" -eq 0 ]; then
  exit 0
fi

pacman_cmd="pacman"
pacman_args="-S --noconfirm --needed"

if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    sudo "$pacman_cmd" $pacman_args "$@"
  else
    echo "sudo is required to install packages" >&2
    exit 1
  fi
else
  "$pacman_cmd" $pacman_args "$@"
fi
