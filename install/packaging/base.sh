#!/bin/sh

set -eu

: "${OMARCHY_INSTALL:?OMARCHY_INSTALL is not set}"

pkg_file="$OMARCHY_INSTALL/omarchy-base.packages"

if [ ! -f "$pkg_file" ]; then
  echo "Package list not found: $pkg_file" >&2
  exit 1
fi

set --
line=""

while true; do
  if ! IFS= read -r line; then
    [ -n "$line" ] || break
  fi

  case "$line" in
    ''|'#'*)
      ;;
    *)
      set -- "$@" "$line"
      ;;
  esac

  line=""
done < "$pkg_file"

if [ "$#" -eq 0 ]; then
  exit 0
fi

pacman_cmd="pacman"

if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    set -- sudo "$pacman_cmd" -S --noconfirm --needed "$@"
  else
    echo "sudo is required to install packages" >&2
    exit 1
  fi
else
  set -- "$pacman_cmd" -S --noconfirm --needed "$@"
fi

"$@"
