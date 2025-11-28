# AMD Test Suite Buildroot Environment

A minimal bootable Linux system for AMD hardware security testing with unrestricted hardware access.

## Features

✅ **Unrestricted `/dev/mem` access** - No kernel restrictions
✅ **MSR access enabled** - Direct CPU register access
✅ **Serial console** - BMC/KVM support (115200 baud)
✅ **SSH server** - Remote access via Dropbear
✅ **AMD security features** - SME/SEV/SEV-SNP kernel support
✅ **Bootable USB/ISO** - GRUB2 with EFI support
✅ **Network ready** - DHCP on eth0

## Quick Start

```bash
# Build the system
./build-amd-test.sh

# Write to USB
sudo dd if=output/images/rootfs.iso9660 of=/dev/sdX bs=4M status=progress

# Boot, login (root/amdtest), copy binary
scp amd-suite root@<ip>:/root/

# Run tests
./amd-suite exec-tests --set=all
```

## What's Different from Regular Linux?

This system has these kernel security features **DISABLED** for hardware testing:
- `CONFIG_STRICT_DEVMEM` - Allows reading any physical memory
- `CONFIG_IO_STRICT_DEVMEM` - Allows accessing MMIO regions

This enables the AMD suite to:
- Read PSP MMIO registers for Platform Secure Boot (PSB) status
- Access AMD security controller registers
- Read firmware tables and hardware configuration
- Perform comprehensive hardware security audits

## Documentation

- **[AMD-TEST-BUILD-GUIDE.md](AMD-TEST-BUILD-GUIDE.md)** - Complete build and usage guide
- **[output/images/README.txt](output/images/README.txt)** - Generated after build

## System Details

| Component | Configuration |
|-----------|--------------|
| **Kernel** | Linux 6.6.63 with AMD features |
| **Init** | BusyBox init |
| **SSH** | Dropbear (lightweight) |
| **Filesystem** | 512MB ext4 |
| **Boot** | GRUB2 EFI |
| **Size** | ~150-200MB ISO |
| **Default Login** | root / amdtest |

## Build Requirements

- Linux build system (Debian, Ubuntu, Fedora, Arch, etc.)
- 4 GB RAM
- 20 GB free disk space
- Build tools: gcc, make, git, wget
- Time: 30-60 minutes for first build

## Directory Structure

```
├── build-amd-test.sh          # Quick build script
├── AMD-TEST-BUILD-GUIDE.md    # Detailed documentation
├── configs/
│   └── amd_test_defconfig     # Buildroot configuration
├── board/amd-test/
│   ├── linux*.fragment        # Kernel config fragments
│   ├── grub*.cfg              # Boot configuration
│   └── post-*.sh              # Build scripts
└── output/images/             # Final bootable images (after build)
```

## Use Cases

This bootable environment is designed for:

1. **AMD Security Auditing** - Testing PSB, SME, TSME, SEV, SEV-SNP
2. **Hardware Testing** - Direct hardware register access
3. **Firmware Analysis** - Reading BIOS/UEFI tables
4. **Security Research** - Low-level AMD platform security
5. **Compliance Testing** - Verifying security configurations

## Important Notes

⚠️ **Security Warning**: This system has hardware security restrictions disabled. Only use on isolated test systems for authorized security testing.

⚠️ **Not for Production**: This is a specialized testing environment, not suitable for regular use or deployment.

## Troubleshooting

### Build fails
```bash
make clean
make amd_test_defconfig
make -j$(nproc)
```

### USB won't boot
- Check BIOS boot order
- Try both UEFI and Legacy modes
- Verify with `sudo fdisk -l /dev/sdX`

### No network
```bash
ip link set eth0 up
dhclient eth0
```

### Can't access /dev/mem on the test system
```bash
# Verify kernel config
zcat /proc/config.gz | grep STRICT_DEVMEM
# Should show: # CONFIG_STRICT_DEVMEM is not set

# Test access
hexdump -C -n 32 /dev/mem
```

## Support

For Buildroot issues, see: https://buildroot.org/docs.html

For AMD Test Suite issues, see: https://github.com/9elements/converged-security-suite

## License

This Buildroot configuration follows Buildroot's licensing (GPL-2.0).
Individual packages have their own licenses.

## Contributing

Improvements welcome! Areas for enhancement:
- Additional kernel modules
- More debugging tools
- Alternative boot configurations
- Documentation improvements

---

**Built with ❤️ for AMD hardware security testing**
