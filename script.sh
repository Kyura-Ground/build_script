#!/bin/bash
set -eo pipefail

# cleanup
remove_lists=(
    .repo/local_manifests
    device/asus/X00TD
    kernel/asus/sdm660
    vendor/asus
    vendor/voltage-priv/keys
    vendor/evolution-priv/keys
)

echo "-- Removing conflicting directories..."
rm -rf "${remove_lists[@]}"

# repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/Evolution-X/manifest -b cnb -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

# local_manifest
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b Evox .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Sync
[ -f /usr/bin/resync ] && /usr/bin/resync || /opt/crave/resync.sh
echo "============="
echo "Sync success"
echo "============="

# Custom build/soong setup
echo "-- Replacing build/soong ..."
rm -rf build/soong
git clone --depth=1 https://github.com/Kyura-Ground/build_soong build/soong

# Apply the Evox telephony fixes once
for patch_name in telephony-ecno.patch telephony-pinstorage.patch; do
    telephony_patch="$PWD/device/asus/X00TD/evolution/$patch_name"
    if [ -f "$telephony_patch" ]; then
        if ! git -C frameworks/opt/telephony apply --reverse --check "$telephony_patch" 2>/dev/null; then
            echo "Applying telephony patch: $patch_name"
            git -C frameworks/opt/telephony -c commit.gpgsign=false am "$telephony_patch"
        else
            echo "Telephony patch $patch_name already applied."
        fi
    else
        echo "Telephony patch $patch_name not found, skipping."
    fi
done

# setup KernelSU
if [ -d kernel/asus/sdm660 ]; then 
    cd kernel/asus/sdm660
    curl -fLSs "https://raw.githubusercontent.com/backslashxx/KernelSU/master/kernel/setup.sh" | bash -s master
    cd ../../..
    echo "==========="
    echo "XXKSU done"
    echo "==========="
fi

# Set up build environment
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
export TZ="Asia/Jakarta"

# envsetup contains optional probes and pipelines that are not errexit-safe.
set +e
source build/envsetup.sh
envsetup_status=$?
set -e
if [ "$envsetup_status" -ne 0 ]; then
    echo "Environment setup failed (status $envsetup_status)." >&2
    exit "$envsetup_status"
fi

# Setup keys dengan validasi error handling
if [ ! -d vendor/evolution-priv/keys ]; then
    git clone --depth=1 https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
fi
cd vendor/evolution-priv/keys
if [ ! -f Android.bp ] || [ ! -s avb.pk8 ]; then
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
override_keys=$(grep -o ':.*override' keys.mk | sort -u || true)
for key in avb ../../../build/make/target/product/security/*.pk8 $override_keys; do
    key=${key##*/}
    key=${key%.pk8}
    key=${key#:}
    if [ -f "$key.x509.pem" ] && [ -f "$key.pk8" ]; then
        if ! openssl x509 -in "$key.x509.pem" -noout -checkend 0 >/dev/null ||
           ! openssl pkcs8 -inform DER -in "$key.pk8" -nocrypt -out /dev/null; then
            echo "Missing or invalid signing key: $key" >&2
            exit 1
        fi
    fi
done
cd ../../..
echo "=========="
echo "Keys ready"
echo "=========="

echo "========================"
echo " Starting Build: Evox"
echo "========================"

# Setup untuk perangkat
lunch lineage_X00TD-cp2a-user
make installclean
m evolution

# Upload VANILLA Build
for file in out/target/product/X00TD/EvolutionX*.zip; do
    if [ -f "$file" ]; then
        echo "Mulai mengupload VANILLA: $file"
        curl -T "$file" -u :8490fc51-f593-4c87-8e35-3379cf5a94a3 https://pixeldrain.com/api/file/
        echo -e "\nUpload selesai untuk $file"
        
        # Pindahkan file ke direktori utama agar tidak terupload ulang nanti
        mv "$file" ./
        echo "--------------MOVED VANILLA BUILD TO ROOT DIRECTORY--------------"
    else
        echo "File tidak ditemukan!"
    fi
done
