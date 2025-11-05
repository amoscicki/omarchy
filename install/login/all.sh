run_logged $OMARCHY_INSTALL/login/plymouth.sh
run_logged $OMARCHY_INSTALL/login/default-keyring.sh
run_logged $OMARCHY_INSTALL/login/sddm.sh
if [[ -n ${OMARCHY_DISABLE_BTRFS_FEATURES:-} ]]; then
  echo "Skipping Limine + Snapper setup (Btrfs root filesystem not detected)"
else
  run_logged $OMARCHY_INSTALL/login/limine-snapper.sh
fi
