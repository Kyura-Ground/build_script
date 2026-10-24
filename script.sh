#!/bin/bash
set -eo pipefail

if [ ! -d .repo ]; then
    echo "Run this script from the Crave Android source root." >&2
    exit 1
fi

# Remove source directories that may belong to a previous Crave ROM.
# Keep signing keys so subsequent builds retain the same identity.
remove_lists=(
    .repo/local_manifests
    device/asus/X00TD
    device/asus/sdm660-common
    kernel/asus/sdm660
    vendor/asus/X00TD
    vendor/asus/sdm660-common
    build/soong
)
echo "Removing conflicting source directories..."
rm -rf -- "${remove_lists[@]}"

#repo init
repo init --depth=1 --git-lfs -u https://github.com/LineageOS/android.git -b lineage-22.2 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b lineage-22.2 .repo/local_manifests
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

# Set up build environment
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
export TZ="Asia/Jakarta"
# envsetup contains optional probes and pipelines that are not errexit-safe.
# Reference: https://github.com/kelexine/local_manifests/commit/193bd08fd920ce8582c4295d2b096fba2a04c370
set +e
# shellcheck source=/dev/null
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

# Build LineageOS 22.2 (vanilla).
unset WITH_GAPPS
lunch lineage_X00TD-bp1a-userdebug
make installclean
m bacon

# Upload LineageOS Build
for file in out/target/product/X00TD/lineage*.zip; do
    if [ -f "$file" ]; then
        echo "Mulai mengupload LineageOS: $file"
        curl --fail --show-error -T "$file" -u :8490fc51-f593-4c87-8e35-3379cf5a94a3 https://pixeldrain.com/api/file/
        echo -e "\nUpload selesai untuk $file"

        # Pindahkan file ke direktori utama agar tidak terupload ulang nanti.
        mv "$file" ./
        echo "--------------MOVED LINEAGE BUILD TO ROOT DIRECTORY--------------"
    else
        echo "File tidak ditemukan!" >&2
        exit 1
    fi
done
