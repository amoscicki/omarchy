#!/bin/bash

# Wrapper script to run omarchy installation as regular user
# This script detects if running as root and switches to a regular user

set -e

# Find the first regular user (UID >= 1000, not nobody/nogroup)
REGULAR_USER=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" {print $1; exit}')

if [ -z "$REGULAR_USER" ]; then
  echo "Error: No regular user found in the system"
  echo "Please create a regular user first or run as a non-root user"
  exit 1
fi

echo "======================================"
echo "  Omarchy Installation Wrapper"
echo "======================================"
echo

# If running as root, switch to regular user
if [ "$EUID" -eq 0 ]; then
  echo "Detected root user. Switching to user: $REGULAR_USER"
  echo

  # Get the directory where this script is located
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Make sure the regular user can access omarchy directory
  if [ "$SCRIPT_DIR" = "/home/user/omarchy" ] || [ "$SCRIPT_DIR" = "/root/omarchy" ]; then
    echo "Copying omarchy to /home/$REGULAR_USER/omarchy ..."
    cp -R "$SCRIPT_DIR" "/home/$REGULAR_USER/"
    chown -R "$REGULAR_USER":"$REGULAR_USER" "/home/$REGULAR_USER/omarchy"

    echo "Running installation as $REGULAR_USER ..."
    echo

    # Switch to regular user and run the installation
    exec sudo -u "$REGULAR_USER" bash -c "cd /home/$REGULAR_USER/omarchy && ./run.sh"
  else
    # If omarchy is in user's home directory already
    echo "Running installation as $REGULAR_USER from $SCRIPT_DIR ..."
    echo
    exec sudo -u "$REGULAR_USER" bash -c "cd '$SCRIPT_DIR' && ./run.sh"
  fi
else
  # Already running as regular user
  echo "Running as user: $(whoami)"
  echo "Starting installation..."
  echo

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "$SCRIPT_DIR"
  exec ./run.sh
fi
