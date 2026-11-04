#!/bin/bash
set -eo pipefail

if [ ! -d .repo ]; then
    directory_contents=$(ls -A)
    [ -z "$directory_contents" ] || { echo "Jalankan dari direktori kosong atau root source Android (.repo)." >&2; exit 1; }
fi

# Cleanup source; signing keys tetap dipertahankan.
remove_lists=(
    .repo/local_manifests
    device/asus/X00TD
    device/asus/sdm660-common
    kernel/asus/sdm660
    vendor/asus
)
rm -rf -- "${remove_lists[@]}"

# Source LineageOS dan local manifest
repo init --depth=1 --git-lfs \
    -u https://github.com/LineageOS/android.git -b lineage-24.0 \
    -g default,-mips,-darwin,-notdefault

git clone --depth=1 -b lineage-24.0 \
    https://github.com/Kyura-Ground/local_manifests.git .repo/local_manifests

# Sync
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)

# Guard against syncing a different kernel generation.
kernel_version=$(awk '/^VERSION = / { version=$3 } /^PATCHLEVEL = / { patch=$3 } END { print version "." patch }' kernel/asus/sdm660/Makefile)
if [[ "$kernel_version" != 4.4 ]]; then
    echo "Expected Linux 4.4, found $kernel_version." >&2
    exit 1
fi

# KernelSU
(
    cd kernel/asus/sdm660
    curl -fLSs https://raw.githubusercontent.com/backslashxx/KernelSU/master/kernel/setup.sh | bash -s master
)

# Build environment
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
export TZ=Asia/Jakarta

set +e
source build/envsetup.sh
envsetup_status=$?
set -e
if [ "$envsetup_status" -ne 0 ]; then
    echo "Environment setup failed (status $envsetup_status)." >&2
    exit "$envsetup_status"
fi

# Vanilla; signing keys disinkronkan oleh local manifest.
unset WITH_GAPPS TARGET_GAPPS_VARIANT
export WITH_GMS=false
lunch lineage_X00TD-cp2a-user
make installclean
build_start=$(mktemp .lineage-build-start.XXXXXX)
trap 'rm -f -- "$build_start"' EXIT
m bacon

# Upload Vanilla
uploaded=false
shopt -s nullglob
for file in out/target/product/X00TD/lineage-24.0-*-X00TD.zip; do
    if [[ -f "$file" && "$file" -nt "$build_start" ]]; then
        echo "Mengupload: $file"
        curl -fS --retry 3 -T "$file" -u :8490fc51-f593-4c87-8e35-3379cf5a94a3 https://pixeldrain.com/api/file/
        echo
        uploaded=true
    fi
done
if [[ "$uploaded" != true ]]; then
    echo "File tidak ditemukan! No new LineageOS 24.0 package was produced." >&2
    exit 1
fi
