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
set +e
. build/envsetup.sh
envsetup_status=$?
set -e
if [ "$envsetup_status" -ne 0 ]; then
    echo "Environment setup failed (status $envsetup_status)." >&2
    exit "$envsetup_status"
fi
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
rm -rf vendor/evolution-priv/keys
git clone --depth=1 https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
cd vendor/evolution-priv/keys
./keys.sh
cd ../../..

# Setup device
lunch infinity_X00TD-user
make installclean
m bacon -j$(nproc --all)
