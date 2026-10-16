#!/bin/bash
set -eo pipefail

: "${PIXELDRAIN_API_KEY:?Set PIXELDRAIN_API_KEY sebelum menjalankan script.}"

#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 17 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
rm -rf .repo/local_manifests
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b Infinity .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

#Sync
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)
echo "============="
echo "Sync success"
echo "============="

# Apply the existing Infinity-X telephony fix once.
telephony_patch="$PWD/device/asus/X00TD/infinity/telephony-ecno.patch"
if ! git -C frameworks/opt/telephony apply --reverse --check "$telephony_patch" 2>/dev/null; then
    git -C frameworks/opt/telephony -c commit.gpgsign=false am "$telephony_patch"
fi

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

# setup KernelSU
cd kernel/asus/sdm660
curl -fLSs "https://raw.githubusercontent.com/backslashxx/KernelSU/master/kernel/setup.sh" | bash -s master
cd ../../..
echo "==========="
echo "XXKSU done"
echo "==========="

# Setup keys, gunakan kembali keys yang sudah ada
if [ ! -d vendor/infinity-priv/keys ]; then
    git clone --depth=1 -b QPR3 https://github.com/ProjectInfinity-X/vendor_infinity-priv_keys-template vendor/infinity-priv/keys
fi
cd vendor/infinity-priv/keys
if [ ! -f Android.bp ] || [ ! -s testkey.pk8 ]; then
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
# Validate every key expected by keys.sh, including keys from an earlier run.
override_keys=$(grep -o ':.*override' keys.mk | sort -u)
for key in ../../../build/make/target/product/security/*.pk8 $override_keys; do
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

# Build both variants and preserve each ZIP before the next installclean.
mkdir -p dist
for WITH_GAPPS in false true; do
    export WITH_GAPPS
    lunch infinity_X00TD-user
    make installclean
    m bacon -j$(nproc --all)

    product_out="$(get_build_var PRODUCT_OUT)"
    zip_name="$(get_build_var ZIP_NAME)"
    cp -v "$product_out/$zip_name.zip" dist/

    file="dist/$zip_name.zip"
    echo "Mulai upload: $file"
    curl --fail-with-body --show-error -T "$file" -u ":$PIXELDRAIN_API_KEY" \
        https://pixeldrain.com/api/file/ | tee "dist/$zip_name.pixeldrain.json"
    echo
done
