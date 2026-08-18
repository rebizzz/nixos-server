#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-github:rebizzz/nixos-server}"
HOST="${HOST:-nixos-server}"

echo "=========================================="
echo " NixOS One-Shot Installer ($HOST)"
echo "=========================================="

# 1. Enable 8GB zram0 swap to prevent OOM
echo "[1/4] Configuring 8GB zram0 compressed swap..."
modprobe zram || true

if [ ! -b /dev/zram0 ]; then
  zramctl -f -s 8G --algorithm zstd 2>/dev/null || true
fi

if [ -b /dev/zram0 ]; then
  swapoff /dev/zram0 2>/dev/null || true
  if [ -e /sys/block/zram0/reset ]; then
    echo 1 > /sys/block/zram0/reset 2>/dev/null || true
  fi
  echo zstd > /sys/block/zram0/comp_algorithm 2>/dev/null || echo lz4 > /sys/block/zram0/comp_algorithm || true
  echo 8G > /sys/block/zram0/disksize 2>/dev/null || true
  mkswap /dev/zram0
  swapon -p 100 /dev/zram0
  sysctl vm.swappiness=180 >/dev/null
  echo "✓ /dev/zram0 swap (8GB) active."
fi

# Remount all tmpfs and overlay stores to 6GB
echo "Expanding Live ISO tmpfs sizes to 6GB..."
mount -o remount,size=6G / 2>/dev/null || true
mount -o remount,size=6G /nix/.rw-store 2>/dev/null || true
mount -o remount,size=6G /tmp 2>/dev/null || true
mount -o remount,size=6G /run 2>/dev/null || true

# Clean caches
rm -rf /tmp/* /root/.cache/nix /home/nixos/.cache/nix 2>/dev/null || true

# 2. Partition and format with Disko
echo ""
echo "[2/4] Partitioning & formatting drives via Disko..."
nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake "$REPO#$HOST"

# 3. Install NixOS
echo ""
echo "[3/4] Installing NixOS from $REPO#$HOST..."
nixos-install --flake "$REPO#$HOST" --no-root-passwd --no-channel-copy

# 4. Finish & Reboot
echo ""
echo "[4/4] Installation complete! Rebooting in 5 seconds..."
sleep 5
reboot
