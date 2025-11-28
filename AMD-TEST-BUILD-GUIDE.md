# AMD Test Suite Buildroot Build Guide

## Overview

This Buildroot configuration creates a minimal Linux system for testing AMD hardware security features with unrestricted `/dev/mem` and MSR access.

## Quick Start

```bash
cd /home/nabla/workspace/buildroot-amd-test

# Load the configuration
make amd_test_defconfig

# Build (this will take 30-60 minutes depending on your system)
make -j$(nproc)

# Output will be in output/images/
ls -lh output/images/
```

## What's Included

### Kernel Configuration
- **CONFIG_STRICT_DEVMEM=n** - Unrestricted /dev/mem access
- **CONFIG_IO_STRICT_DEVMEM=n** - Unrestricted MMIO access
- **CONFIG_X86_MSR=y** - MSR access enabled
- **CONFIG_AMD_MEM_ENCRYPT=y** - AMD SME/SEV support
- **Serial console** - 115200 baud on ttyS0

### System Features
- **Root password**: `amdtest`
- **SSH server**: Dropbear (lightweight SSH)
- **Serial console**: ttyS0 at 115200 baud (for BMC/KVM)
- **Network**: DHCP on eth0
- **Filesystem**: 512MB ext4 root filesystem
- **Boot**: GRUB2 with EFI support

### Included Tools
- bash, vim, nano
- strace, ltrace, gdb (debugging)
- ethtool, iproute2, tcpdump (networking)
- util-linux (hexdump, etc.)

## Build Process Details

### 1. Configure

```bash
make amd_test_defconfig
```

### 2. Optional: Customize

```bash
# Buildroot configuration
make menuconfig

# Kernel configuration
make linux-menuconfig

# BusyBox configuration
make busybox-menuconfig
```

### 3. Build

```bash
# Full build (first time: ~30-60 minutes)
make -j$(nproc)

# Rebuild just the kernel
make linux-rebuild

# Rebuild root filesystem
make
```

### 4. Output Files

After build completes, check `output/images/`:

```
output/images/
├── bzImage              # Linux kernel
├── rootfs.ext4          # Root filesystem
├── rootfs.iso9660       # Bootable ISO (for USB/CD)
├── grub.cfg             # GRUB menu
└── README.txt           # Usage instructions
```

## Creating Bootable USB

### Method 1: Using dd (Linux/Mac)

```bash
# Find your USB device
lsblk

# Write ISO to USB (replace sdX with your device!)
sudo dd if=output/images/rootfs.iso9660 of=/dev/sdX bs=4M status=progress conv=fsync

# Sync and eject
sudo sync
sudo eject /dev/sdX
```

### Method 2: Using Rufus (Windows)

1. Download Rufus from https://rufus.ie/
2. Select your USB device
3. Select `output/images/rootfs.iso9660`
4. Click "Start"

## Booting the System

### Via USB Boot

1. Insert USB into AMD EPYC system
2. Power on and press Boot Menu key (F11/F12/DEL - varies by vendor)
3. Select USB device
4. Choose "AMD Test Suite (Serial + VGA)" from GRUB menu

### Via Serial Console (BMC)

Configure your serial terminal:
- Speed: 115200 baud
- Data bits: 8
- Parity: None
- Stop bits: 1
- Flow control: None

Example with screen:
```bash
screen /dev/ttyUSB0 115200
```

Example with minicom:
```bash
minicom -D /dev/ttyUSB0 -b 115200
```

## After Boot

### Login

```
Username: root
Password: amdtest
```

### Check Network

```bash
# Show IP address
ip addr show eth0

# If no IP, request one
dhclient eth0
```

### Copy amd-suite Binary

From your build machine:
```bash
scp /path/to/amd-suite root@<ip-address>:/root/
```

Or mount the converged-security-suite and copy from there.

### Run Tests

```bash
chmod +x /root/amd-suite
/root/amd-suite exec-tests --set=all
```

## Verify /dev/mem Access

```bash
# Should work without "operation not permitted"
hexdump -C -n 32 /dev/mem

# Check MSR access
ls -la /dev/cpu/0/msr

# Load MSR module if needed
modprobe msr
```

## Troubleshooting

### Build Fails

```bash
# Clean everything and rebuild
make clean
make amd_test_defconfig
make -j$(nproc)
```

### Kernel Config Issues

```bash
# Check applied fragments
cat output/build/linux-*/. config | grep -i strict_devmem
# Should show: # CONFIG_STRICT_DEVMEM is not set
```

### USB Won't Boot

- Check BIOS boot order
- Try both UEFI and Legacy boot modes
- Verify USB is bootable: `sudo fdisk -l /dev/sdX`

### No Network After Boot

```bash
# Check interface status
ip link show eth0

# Bring interface up
ip link set eth0 up

# Request DHCP
dhclient -v eth0
```

### Serial Console Not Working

- Verify serial port in BIOS/BMC settings
- Check cable connection
- Try different boot option in GRUB (Serial only)
- Verify terminal settings (115200 8N1)

## Customization

### Add Your Own Packages

Edit `configs/amd_test_defconfig` and add:

```
BR2_PACKAGE_<PACKAGENAME>=y
```

Then rebuild:
```bash
make amd_test_defconfig
make
```

### Modify Kernel

```bash
# Interactive kernel configuration
make linux-menuconfig

# Save changes
make linux-update-defconfig

# Copy new config
cp output/build/linux-*/.config board/amd-test/linux.config
```

### Change Root Password

Edit `configs/amd_test_defconfig`:
```
BR2_TARGET_GENERIC_ROOT_PASSWD="newpassword"
```

### Add Startup Script

Create `board/amd-test/rootfs_overlay/etc/init.d/S99custom`:

```bash
#!/bin/sh
# Your custom startup commands
```

Add to defconfig:
```
BR2_ROOTFS_OVERLAY="board/amd-test/rootfs_overlay"
```

## Integration with AMD Test Suite

### Automatic Binary Inclusion

To include amd-suite in the image:

1. Create overlay directory:
```bash
mkdir -p board/amd-test/rootfs_overlay/usr/local/bin
```

2. Copy binary (after building):
```bash
cp /path/to/amd-suite board/amd-test/rootfs_overlay/usr/local/bin/
chmod +x board/amd-test/rootfs_overlay/usr/local/bin/amd-suite
```

3. Add to defconfig:
```
BR2_ROOTFS_OVERLAY="board/amd-test/rootfs_overlay"
```

4. Rebuild:
```bash
make
```

## Build System Requirements

### Minimum Requirements
- 4 GB RAM
- 20 GB free disk space
- Modern Linux distribution
- Internet connection (for package downloads)

### Required Packages (Debian/Ubuntu)

```bash
sudo apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    binutils \
    patch \
    bzip2 \
    perl \
    tar \
    cpio \
    unzip \
    rsync \
    file \
    bc \
    wget \
    libncurses-dev \
    git
```

### Required Packages (Fedora/RHEL)

```bash
sudo dnf install -y \
    gcc \
    gcc-c++ \
    make \
    binutils \
    patch \
    bzip2 \
    perl \
    tar \
    cpio \
    unzip \
    rsync \
    file \
    bc \
    wget \
    ncurses-devel \
    git
```

## Advanced Topics

### Cross-Compilation

Buildroot handles cross-compilation automatically. The generated toolchain is in:
```
output/host/bin/
```

### Adding Kernel Modules

If you need to build external kernel modules, use:
```bash
make linux-rebuild
```

### Saving Your Configuration

```bash
# Save Buildroot config
make savedefconfig BR2_DEFCONFIG=configs/amd_test_defconfig

# Save kernel config
make linux-update-defconfig
```

## Performance Tips

### Speed Up Builds

1. **Use ccache**:
```
BR2_CCACHE=y
```

2. **Parallel downloads**:
```
BR2_JLEVEL=$(nproc)
```

3. **Local source mirror** - configure `BR2_PRIMARY_SITE`

### Reduce Image Size

- Disable unnecessary packages
- Use `BR2_OPTIMIZE_2=y` instead of `-Os`
- Strip binaries (default)

## Support and Documentation

- **Buildroot Manual**: https://buildroot.org/docs.html
- **Kernel Documentation**: https://www.kernel.org/doc/
- **GRUB Manual**: https://www.gnu.org/software/grub/manual/

## Files Reference

```
buildroot-amd-test/
├── configs/
│   └── amd_test_defconfig              # Main configuration
├── board/amd-test/
│   ├── linux.config                    # Base kernel config
│   ├── linux-devmem.fragment          # /dev/mem unrestricted
│   ├── linux-serial.fragment          # Serial console config
│   ├── grub.cfg                       # GRUB boot menu
│   ├── grub-early.cfg                 # GRUB early config
│   ├── post-build.sh                  # Post-build customization
│   └── post-image.sh                  # Post-image processing
└── output/
    ├── build/                          # Build artifacts
    ├── host/                           # Host tools
    ├── images/                         # Final images ← YOUR BOOTABLE FILES
    └── target/                         # Target rootfs
```

## Summary

This Buildroot configuration provides a complete, minimal Linux environment specifically designed for AMD hardware security testing with:

✅ Unrestricted `/dev/mem` access
✅ MSR access enabled
✅ Serial console for remote access
✅ SSH server for network access
✅ AMD security features enabled in kernel
✅ Bootable from USB/CD
✅ DHCP networking

Total build time: ~30-60 minutes
Output size: ~150-200 MB ISO image
Memory required: ~128 MB RAM minimum
