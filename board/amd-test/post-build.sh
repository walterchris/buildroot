#!/bin/bash
set -e

TARGET_DIR=$1

# Enable SSH root login
if [ -f "${TARGET_DIR}/etc/ssh/sshd_config" ]; then
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' "${TARGET_DIR}/etc/ssh/sshd_config"
fi

# For dropbear (create if doesn't exist)
mkdir -p "${TARGET_DIR}/etc/dropbear" 2>/dev/null || true

# Configure serial console
if ! grep -q "ttyS0" "${TARGET_DIR}/etc/inittab"; then
    echo "ttyS0::respawn:/sbin/getty -L ttyS0 115200 vt100" >> "${TARGET_DIR}/etc/inittab"
fi

# Create welcome message
cat > "${TARGET_DIR}/etc/issue" << 'EOF'

AMD Security Suite Test Environment
====================================
Hostname: \n
Kernel: \r on \m

Login: root
Password: amdtest

Serial console: ttyS0 at 115200 baud
SSH: Enabled on all interfaces

WARNING: This system has /dev/mem restrictions DISABLED
         Use only for hardware security testing!

EOF

# Create motd
cat > "${TARGET_DIR}/etc/motd" << 'EOF'

Welcome to AMD Test Suite Environment
======================================

This minimal Linux system is designed for AMD hardware security testing.

Key features:
- /dev/mem access unrestricted (CONFIG_STRICT_DEVMEM disabled)
- MSR access enabled (/dev/cpu/*/msr)
- Serial console on ttyS0 (115200 baud)
- SSH server running (Dropbear)

To copy amd-suite binary to this system:
  scp amd-suite root@<ip-address>:/root/

To run the test suite:
  ./amd-suite exec-tests --set=all

Network interfaces:
EOF

echo "  eth0 - DHCP enabled" >> "${TARGET_DIR}/etc/motd"

cat >> "${TARGET_DIR}/etc/motd" << 'EOF'

Useful commands:
  ip addr                - Show network configuration
  lsmod                  - List loaded kernel modules
  modprobe msr           - Load MSR module (if not loaded)
  dmesg | grep -i amd    - Show AMD-related kernel messages
  cat /proc/cpuinfo      - Show CPU information
  hexdump -C -n 32 /dev/mem - Test /dev/mem access

EOF

# Set hostname
echo "amd-test" > "${TARGET_DIR}/etc/hostname"

# Configure network
mkdir -p "${TARGET_DIR}/etc/network"
cat > "${TARGET_DIR}/etc/network/interfaces" << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hostname amd-test
EOF

echo "Post-build script completed successfully"
