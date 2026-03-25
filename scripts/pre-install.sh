#!/bin/bash
# Interactive Arch Linux Pre-Installation Script
# Formats, labels, and mounts partitions without hardcoded values
# WARNING: This will ERASE all data on the specified partitions.

set -euo pipefail

echo "=== Arch Linux Pre-Installation Partition Setup ==="
echo ""
echo "Available disks:"
lsblk -d -o NAME,SIZE,TYPE | grep -E "disk|loop"
echo ""

# Get disk
read -p "Enter disk to partition on (e.g., nvme0n1 or sda): " DISK
DISK="/dev/$DISK"

if [ ! -b "$DISK" ]; then
  echo "❌ Error: $DISK is not a valid block device"
  exit 1
fi

echo ""
echo "Available partitions on $DISK:"
lsblk "$DISK" -o NAME,SIZE,TYPE,FSTYPE
echo ""

# Get EFI partition
read -p "Enter EFI partition (e.g., p1 for nvme0n1p1 or 1 for sda1): " EFI_NUM
EFI="${DISK}p${EFI_NUM}"
[ "${DISK: -1}" = "1" ] && EFI="${DISK}${EFI_NUM}"  # Handle sda vs nvme

if [ ! -b "$EFI" ]; then
  echo "❌ Error: $EFI is not a valid partition"
  exit 1
fi

# Get SWAP partition
read -p "Enter SWAP partition (e.g., p7 for nvme0n1p7 or 2 for sda2): " SWAP_NUM
SWAP="${DISK}p${SWAP_NUM}"
[ "${DISK: -1}" = "1" ] && SWAP="${DISK}${SWAP_NUM}"

if [ ! -b "$SWAP" ]; then
  echo "❌ Error: $SWAP is not a valid partition"
  exit 1
fi

# Get ROOT partition
read -p "Enter ROOT partition (e.g., p8 for nvme0n1p8 or 3 for sda3): " ROOT_NUM
ROOT="${DISK}p${ROOT_NUM}"
[ "${DISK: -1}" = "1" ] && ROOT="${DISK}${ROOT_NUM}"

if [ ! -b "$ROOT" ]; then
  echo "❌ Error: $ROOT is not a valid partition"
  exit 1
fi

echo ""
echo "=== Summary ==="
echo "Disk:  $DISK"
echo "EFI:   $EFI  -> FAT32 (Label: ARCH EFI)"
echo "SWAP:  $SWAP -> Swap (Label: ARCH LINUX SWAP)"
echo "ROOT:  $ROOT -> ext4 (Label: ARCH LINUX)"
echo ""
echo "⚠️  WARNING: All data on these partitions will be ERASED!"
echo ""
read -p "Type 'YES' to confirm and proceed: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
  echo "❌ Aborted by user."
  exit 1
fi

echo ""
echo "🔄 Formatting partitions..."
mkfs.fat -F32 -n "ARCH EFI" "$EFI"
mkswap -L "ARCH LINUX SWAP" "$SWAP"
mkfs.ext4 -L "ARCH LINUX" "$ROOT"

echo ""
echo "🔄 Mounting partitions..."
mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot
swapon "$SWAP"

echo ""
echo "✅ Partition setup complete! Current partition layout:"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
