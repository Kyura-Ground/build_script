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
    device/axion/common
    kernel/asus/sdm660
    build/soong
)
echo "Removing conflicting source directories..."
# Remove legacy nested vendor checkouts only before the combined tree exists.
if [[ ! -e vendor/asus/.git ]]; then
    rm -rf -- vendor/asus/X00TD vendor/asus/sdm660-common
fi

rm -rf -- "${remove_lists[@]}"

#repo init
repo init --depth=1 --git-lfs -u https://github.com/LineageOS/android.git -b lineage-23.2 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b lineage-23.2 .repo/local_manifests
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

# Guard against syncing a tree for a different kernel generation.
kernel_version=$(awk '/^VERSION = / { version=$3 } /^PATCHLEVEL = / { patch=$3 } END { print version "." patch }' kernel/asus/sdm660/Makefile)
if [[ "$kernel_version" != 4.4 ]]; then
    echo "Expected Linux 4.4, found $kernel_version." >&2
    exit 1
fi

# setup KernelSU
cd kernel/asus/sdm660
curl -fLSs "https://raw.githubusercontent.com/backslashxx/KernelSU/master/kernel/setup.sh" | bash -s master
cd ../../..
echo "==========="
echo "XXKSU done"
echo "==========="

# Build LineageOS 23.2 (vanilla) on the server.
unset WITH_GAPPS TARGET_GAPPS_VARIANT
export WITH_GMS=false
breakfast X00TD userdebug
m installclean

build_start=$(mktemp .lineage-build-start.XXXXXX)
trap 'rm -f -- "$build_start"' EXIT
m -j"${BUILD_JOBS:-32}" bacon

# Upload only packages produced by this build.
uploaded=false
shopt -s nullglob
for file in out/target/product/X00TD/lineage-23.2-*-X00TD.zip; do
    if [[ -f "$file" && "$file" -nt "$build_start" ]]; then
        echo "Mulai mengupload LineageOS: $file"
        curl --fail --show-error -T "$file" -u :8490fc51-f593-4c87-8e35-3379cf5a94a3 https://pixeldrain.com/api/file/
        echo -e "\nUpload selesai untuk $file"

        # Pindahkan file ke direktori utama agar tidak terupload ulang nanti.
        mv "$file" ./
        uploaded=true
        echo "--------------MOVED LINEAGE BUILD TO ROOT DIRECTORY--------------"
    fi
done
if [[ "$uploaded" != true ]]; then
    echo "File tidak ditemukan! No new LineageOS 23.2 package was produced." >&2
    exit 1
fi
