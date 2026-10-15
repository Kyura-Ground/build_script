#!/bin/bash
set -eo pipefail

#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/Evolution-X/manifest -b cnb -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
rm -rf .repo/local_manifests
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b Evox .repo/local_manifests
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
# envsetup contains optional probes and pipelines that are not errexit-safe.
# Reference: https://github.com/kelexine/local_manifests/commit/193bd08fd920ce8582c4295d2b096fba2a04c370
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

# Setup keys, gunakan kembali keys yang sudah ada
if [ ! -d vendor/evolution-priv/keys ]; then
    git clone --depth=1 https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
fi
cd vendor/evolution-priv/keys
if [ ! -f Android.bp ] || [ ! -s avb.pk8 ]; then
    # make_key's EXIT trap returns 1 even after generating valid keys.
    # Adapted from Abhinav Jhanwar, 2026-09-20:
    # https://github.com/DiamaneOS/diamaneos-tools/commit/9c0286f94998a3b892c3aeabc096e6dab1fbbd22
    keys_status=0
    ./keys.sh || keys_status=$?
    if [ "$keys_status" -ne 0 ] && [ "$keys_status" -ne 1 ]; then
        echo "Key generation failed (status $keys_status)." >&2
        exit "$keys_status"
    fi
fi
test -s Android.bp
test -s avb_custom_key.bin
# Validate every key expected by keys.sh, including keys from an earlier run.
override_keys=$(grep -o ':.*override' keys.mk | sort -u)
for key in avb ../../../build/make/target/product/security/*.pk8 $override_keys; do
    key=${key##*/}
    key=${key%.pk8}
    key=${key#:}
    if ! openssl x509 -in "$key.x509.pem" -noout -checkend 0 >/dev/null ||
       ! openssl pkcs8 -inform DER -in "$key.pk8" -nocrypt -out /dev/null; then
        echo "Missing or invalid signing key: $key" >&2
        exit 1
    fi
done
cd ../../..
echo "=========="
echo "Keys ready"
echo "=========="

# Setup device
lunch lineage_X00TD-cp2a-user
make installclean
m evolution -j$(nproc --all)
