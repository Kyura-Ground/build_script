#!/bin/bash
set -eo pipefail

#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 17 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
rm -rf .repo/local_manifests
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b infinity-17 .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

#Sync
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)
echo "============="
echo "Sync success"
echo "============="

# Set up build environment
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=serverhive
export TZ="Asia/Jakarta"
. build/envsetup.sh

# Setup device dependencies sebelum KernelSU
bash device/asus/X00TD/vendorsetup.sh
echo "========================="
echo "Device dependencies ready"
echo "========================="

# setup KernelSU
cd kernel/asus/sdm660
curl -fLSs "https://raw.githubusercontent.com/backslashxx/KernelSU/master/kernel/setup.sh" | bash -s master
cd ../../..
echo "==========="
echo "XXKSU done"
echo "==========="

# Setup keys
if [ ! -d vendor/evolution-priv/keys ]; then
    git clone --depth=1 https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
fi
cd vendor/evolution-priv/keys
if [ ! -f Android.bp ] || [ ! -s avb.pk8 ]; then
    ./keys.sh
fi
test -s Android.bp
test -s avb.pk8
cd ../../..

# Setup device
lunch infinity_X00TD-user
make installclean
m bacon -j$(nproc --all)
