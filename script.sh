#!/bin/bash
set -eo pipefail

if [ ! -d .repo ]; then
    echo "Run this script from the Crave Android source root." >&2
    exit 1
fi

# Remove source and signing-key directories from previous Crave ROM builds.
remove_lists=(
    .repo/local_manifests
    device/asus/X00TD
    device/asus/sdm660-common
    kernel/asus/sdm660
    vendor/asus
    build/soong
    vendor/infinity-priv/keys
    vendor/evolution-priv/keys
    vendor/lineage-priv/keys
)
echo "Removing conflicting source directories..."
rm -rf -- "${remove_lists[@]}"

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
if [ -x /usr/bin/resync ]; then
    /usr/bin/resync
elif [ -f /opt/crave/resync.sh ]; then
    bash /opt/crave/resync.sh
else
    repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune --retry-fetches=3 -j8
fi
echo "============="
echo "Sync success"
echo "============="

# Apply reviewed source patches once, retaining their original metadata.
apply_source_patch() {
    local source_path="$1"
    local patch_file="$2"
    if git -C "$source_path" apply --reverse --check "$patch_file" 2>/dev/null; then
        echo "Already applied: ${patch_file##*/}"
        return 0
    fi
    git -C "$source_path" apply --check "$patch_file"
    git -C "$source_path" -c commit.gpgsign=false am "$patch_file"
}

patch_dir="$PWD/device/asus/X00TD/infinity"
apply_source_patch build/soong "$patch_dir/soong-memory.patch"
for patch_name in telephony-ecno telephony-pinstorage; do
    apply_source_patch frameworks/opt/telephony "$patch_dir/$patch_name.patch"
done

# Set up build environment
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
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

# The local manifest syncs the shared Android 17 signing identity.
cd vendor/lineage-priv/keys
test -s Android.bp
test -s avb.pk8
# Validate every key referenced by the Android 17 keys.mk configuration.
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

# Build the GApps variant.
export WITH_GAPPS=false
lunch infinity_X00TD-user
make installclean
m bacon

# Upload GApps Build
for file in out/target/product/X00TD/Project_Infinity-X*.zip; do
    if [ -f "$file" ]; then
        echo "Mulai mengupload GApps: $file"
        curl -T "$file" -u :8490fc51-f593-4c87-8e35-3379cf5a94a3 https://pixeldrain.com/api/file/
        echo -e "\nUpload selesai untuk $file"

        # Pindahkan file ke direktori utama agar tidak terupload ulang nanti.
        mv "$file" ./
        echo "--------------MOVED GAPPS BUILD TO ROOT DIRECTORY--------------"
    else
        echo "File tidak ditemukan!"
    fi
done
