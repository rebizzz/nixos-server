#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo " NixOS Server One-Shot Installer"
echo "=========================================="

# 1. Enable zram0 swap to prevent OOM
echo "[1/4] Configuring zram0 compressed swap..."
modprobe zram || true

# If /dev/zram0 doesn't exist yet, create one using zramctl or sysfs
if [ ! -b /dev/zram0 ]; then
  zramctl -f -s 4G --algorithm zstd 2>/dev/null || true
fi

if [ -b /dev/zram0 ]; then
  swapoff /dev/zram0 2>/dev/null || true
  if [ -e /sys/block/zram0/reset ]; then
    echo 1 > /sys/block/zram0/reset 2>/dev/null || true
  fi
  echo zstd > /sys/block/zram0/comp_algorithm 2>/dev/null || echo lz4 > /sys/block/zram0/comp_algorithm || true
  echo 4G > /sys/block/zram0/disksize 2>/dev/null || true
  mkswap /dev/zram0
  swapon -p 100 /dev/zram0
  sysctl vm.swappiness=180 >/dev/null
  echo "✓ /dev/zram0 swap (4GB) active."
else
  echo "⚠ Warning: /dev/zram0 not available, continuing with physical RAM."
fi

# Show available memory
free -h

# 2. Partition and format with Disko
echo ""
echo "[2/4] Partitioning & formatting drives via Disko..."
nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake github:rebizzz/nixos-server#nixos-server

# 3. Install NixOS
echo ""
echo "[3/4] Installing NixOS from github:rebizzz/nixos-server..."
nixos-install --flake github:rebizzz/nixos-server#nixos-server --no-root-passwd

# 4. Finish & Reboot
echo ""
echo "[4/4] Installation complete! Rebooting in 5 seconds..."
sleep 5
reboot
