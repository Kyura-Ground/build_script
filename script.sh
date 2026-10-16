#!/bin/bash
set -eo pipefail

PIXELDRAIN_API_KEY="${PIXELDRAIN_API_KEY:-8490fc51-f593-4c87-8e35-3379cf5a94a3}"

#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/YAAP/manifest -b seventeen -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
rm -rf .repo/local_manifests
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b YAAP .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

#Sync
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune --retry-fetches=3 -j8
echo "============="
echo "Sync success"
echo "============="

# Apply the device compatibility patches once.
apply_device_patch() {
    local repo="$1"
    local patch="$PWD/device/asus/X00TD/yaap/$2"
    local patch_id="$(git patch-id --stable < "$patch" | cut -d ' ' -f1)"
    if git -C "$repo" apply --reverse --check "$patch" 2>/dev/null; then
        return
    fi
    if git -C "$repo" log -100 --no-merges -p | git patch-id --stable |
        awk -v id="$patch_id" '$1 == id { found=1 } END { exit !found }'; then
        return
    fi
    git -C "$repo" -c commit.gpgsign=false am "$patch"
}
apply_device_patch hardware/lineage/interfaces lineage-touch-hidl.patch
apply_device_patch frameworks/opt/telephony telephony-hidl.patch
apply_device_patch frameworks/opt/telephony telephony-ecno.patch

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
if [ ! -d vendor/yaap-priv/keys ]; then
    git clone --depth=1 https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/yaap-priv/keys
else
    git -C vendor/yaap-priv/keys fetch --depth=1 \
        https://github.com/Evolution-X/vendor_evolution-priv_keys-template master
    git -C vendor/yaap-priv/keys checkout FETCH_HEAD -- keys.mk keys.sh make_key.sh
fi
cd vendor/yaap-priv/keys
sed -i 's|vendor/evolution-priv/keys|vendor/yaap-priv/keys|g' keys.mk
# Refresh certificate modules and generate missing keys; make_key preserves existing pairs.
keys_status=0
./keys.sh || keys_status=$?
if [ "$keys_status" -ne 0 ] && [ "$keys_status" -ne 1 ]; then
    echo "Key generation failed (status $keys_status)." >&2
    exit "$keys_status"
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

# Build both variants and preserve each ZIP before the next installclean.
mkdir -p dist
for TARGET_BUILD_GAPPS in false true; do
    export TARGET_BUILD_GAPPS
    lunch yaap_X00TD-user
    make installclean
    m yaap -j$(nproc --all)

    product_out="$(get_build_var PRODUCT_OUT)"
    yaap_version="$(get_build_var YAAP_VERSION)"
    variant=VANILLA
    if [ "$TARGET_BUILD_GAPPS" = true ]; then
        variant=GAPPS
    fi
    zip_name="YAAP-$yaap_version-$variant"
    cp -v "$product_out/YAAP-$yaap_version.zip" "dist/$zip_name.zip"

    file="dist/$zip_name.zip"
    echo "Mulai upload: $file"
    curl --fail-with-body --show-error -T "$file" -u ":$PIXELDRAIN_API_KEY" \
        https://pixeldrain.com/api/file/ | tee "dist/$zip_name.pixeldrain.json"
    echo
done
