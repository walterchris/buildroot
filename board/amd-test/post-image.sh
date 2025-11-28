#!/bin/bash
set -e

BOARD_DIR="$(dirname $0)"
BINARIES_DIR="$1"

# Get the UUID of the root filesystem
UUID=$(dumpe2fs "${BINARIES_DIR}/rootfs.ext2" 2>/dev/null | sed -n 's/^Filesystem UUID: *\(.*\)/\1/p')

# Update GRUB config with UUID
cp "${BOARD_DIR}/grub-efi.cfg" "${BINARIES_DIR}/efi-part/EFI/BOOT/grub.cfg"
sed -i "s/UUID_TMP/$UUID/g" "${BINARIES_DIR}/efi-part/EFI/BOOT/grub.cfg"

# Generate genimage config with UUID
sed "s/UUID_TMP/$UUID/g" "${BOARD_DIR}/genimage-efi.cfg" > "${BINARIES_DIR}/genimage-efi.cfg"

# Create the disk image
support/scripts/genimage.sh -c "${BINARIES_DIR}/genimage-efi.cfg"

# Create a symlink for easier access
ln -sf disk.img "${BINARIES_DIR}/amd-test-usb.img"

# Create a README for the output
cat > "${BINARIES_DIR}/README.txt" << 'EOF'
AMD Test Suite Bootable Images
===============================

Files in this directory:
------------------------
- disk.img           : Bootable disk image with GPT partition table
- amd-test-usb.img   : Symlink to disk.img
- rootfs.ext4        : Root filesystem (ext4 format)
- bzImage            : Linux kernel
- efi-part.vfat      : EFI boot partition

How to create a bootable USB:
------------------------------
1. Insert USB drive (will be completely erased!)
2. Identify the device (e.g., /dev/sdb, /dev/sdc)

   lsblk

3. Write the image to USB:

   sudo dd if=disk.img of=/dev/sdX bs=4M status=progress conv=fsync

   OR using the symlink:

   sudo dd if=amd-test-usb.img of=/dev/sdX bs=4M status=progress conv=fsync

   (Replace sdX with your USB device - e.g., sdb, NOT sdb1!)

4. Sync and eject:

   sudo sync
   sudo eject /dev/sdX

How to boot:
------------
1. Insert USB into AMD EPYC system
2. Boot from USB (may need to press F11/F12/DEL for boot menu)
3. Select "AMD Test Suite" from GRUB menu
4. Login with:
   - Username: root
   - Password: amdtest

Network Configuration:
----------------------
- eth0 is configured for DHCP
- After boot, get IP with: ip addr show eth0
- SSH is enabled: ssh root@<ip-address>

Serial Console:
---------------
- Speed: 115200 baud
- Data: 8 bits
- Parity: None
- Stop bits: 1
- Connect via BMC or serial cable to see boot messages

To copy amd-suite binary:
--------------------------
From your build machine:
  scp /path/to/amd-suite root@<ip-address>:/root/

Then on the AMD test system:
  chmod +x /root/amd-suite
  /root/amd-suite exec-tests --set=all

Troubleshooting:
----------------
- No network: Check cable, try 'dhclient eth0'
- Can't login: Password is 'amdtest' (without quotes)
- Serial not working: Check BMC/BIOS serial settings
- USB won't boot: Check BIOS boot order, UEFI mode

Image Details:
--------------
- Kernel: Linux 6.12.59
- Root size: 512MB ext4
- Boot: GRUB2 EFI
- SSH: Dropbear (lightweight)
- Features: Unrestricted /dev/mem, MSR access, AMD security support

EOF

echo "Post-image script completed successfully"
echo "============================================"
echo "Build completed! Check ${BINARIES_DIR}/"
echo "Disk image: ${BINARIES_DIR}/disk.img"
echo "USB image: ${BINARIES_DIR}/amd-test-usb.img"
echo "See ${BINARIES_DIR}/README.txt for instructions"
echo "============================================"
