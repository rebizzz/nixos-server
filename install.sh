#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo " NixOS Server One-Shot Installer"
echo "=========================================="

# 1. Enable zram swap to prevent OOM
echo "[1/4] Enabling zram compressed swap..."
modprobe zram || true
if [ -e /sys/block/zram0 ]; then
  # Reset device if already configured
  swapoff /dev/zram0 2>/dev/null || true
  echo 1 > /sys/block/zram0/reset 2>/dev/null || true
  echo zstd > /sys/block/zram0/comp_algorithm 2>/dev/null || echo lz4 > /sys/block/zram0/comp_algorithm || true
  echo 4G > /sys/block/zram0/disksize
  mkswap /dev/zram0
  swapon -p 100 /dev/zram0
  sysctl vm.swappiness=180 >/dev/null
  echo "✓ zram swap (4GB) successfully activated."
else
  echo "⚠ Warning: /sys/block/zram0 not found, skipping zram setup."
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
