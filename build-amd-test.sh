#!/bin/bash
#
# AMD Test Suite Buildroot - Quick Build Script
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "AMD Test Suite Buildroot Builder"
echo "============================================"
echo ""

# Check if already configured
if [ -f ".config" ]; then
    echo "Existing configuration found."
    read -p "Reconfigure from scratch? (y/N): " RECONFIG
    if [ "$RECONFIG" = "y" ] || [ "$RECONFIG" = "Y" ]; then
        make clean
        make amd_test_defconfig
    fi
else
    echo "Loading AMD test configuration..."
    make amd_test_defconfig
fi

echo ""
echo "Configuration loaded. Starting build..."
echo ""
echo "This will take approximately 30-60 minutes."
echo "You can monitor progress in this window."
echo ""
read -p "Press Enter to start the build, or Ctrl+C to cancel..."

# Start build with progress
echo ""
echo "Starting build at $(date)"
START_TIME=$(date +%s)

make -j$(nproc) 2>&1 | tee build.log

END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
BUILD_MINUTES=$((BUILD_TIME / 60))
BUILD_SECONDS=$((BUILD_TIME % 60))

echo ""
echo "============================================"
echo "Build completed in ${BUILD_MINUTES}m ${BUILD_SECONDS}s"
echo "============================================"
echo ""

if [ -f "output/images/rootfs.iso9660" ]; then
    echo "✓ Build successful!"
    echo ""
    echo "Output files:"
    ls -lh output/images/
    echo ""
    echo "Bootable ISO: output/images/rootfs.iso9660"
    echo "Size: $(du -h output/images/rootfs.iso9660 | cut -f1)"
    echo ""
    echo "Next steps:"
    echo "1. Write to USB:"
    echo "   sudo dd if=output/images/rootfs.iso9660 of=/dev/sdX bs=4M status=progress"
    echo ""
    echo "2. Copy amd-suite binary to the system after boot:"
    echo "   scp /path/to/amd-suite root@<ip-address>:/root/"
    echo ""
    echo "3. Login credentials:"
    echo "   Username: root"
    echo "   Password: amdtest"
    echo ""
    echo "See AMD-TEST-BUILD-GUIDE.md for detailed instructions"
else
    echo "✗ Build failed!"
    echo ""
    echo "Check build.log for errors"
    exit 1
fi
