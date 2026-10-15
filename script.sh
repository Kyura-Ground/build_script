#!/bin/bash
set -eo pipefail

#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/VoltageOS/manifest.git -b 17 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
rm -rf .repo/local_manifests
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b Voltage .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

#Sync
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j"$(nproc --all)"
echo "============="
echo "Sync success"
echo "============="

# Set up build environment
export TZ="Asia/Jakarta"

set +e
set +o pipefail
source build/envsetup.sh
envsetup_status=$?
set -eo pipefail
if [ "$envsetup_status" -ne 0 ]; then
    exit "$envsetup_status"
fi

export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=serverhive

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

# Setup keys (repo sudah ikut sync VoltageOS)
cd vendor/voltage-priv/keys
# make_key bisa exit 1 setelah menghasilkan keys.
./keys.sh || [ "$?" -eq 1 ]
cd ../../..
echo "========================"
echo "Key generation completed"
echo "========================"

# Setup device
m installclean
brunch X00TD
