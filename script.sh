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
    -u https://github.com/ProjectInfinity-X/manifest -b 17 \
    -g default,-mips,-darwin,-notdefault

git clone --depth=1 -b Infinity-4.4 \
    https://github.com/Kyura-Ground/local_manifests.git .repo/local_manifests

# Sync
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all) --jobs-network=4

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
[ "$envsetup_status" -eq 0 ] || exit "$envsetup_status"

# Vanilla; signing keys disinkronkan oleh local manifest.
unset WITH_GAPPS TARGET_GAPPS_VARIANT
export WITH_GAPPS=false
lunch infinity_X00TD-user
make installclean
m bacon

# Upload Vanilla
for file in out/target/product/X00TD/Project_Infinity-X-*.zip; do
    if [ -f "$file" ]; then
        echo "Mengupload: $file"
        curl -fS --retry 3 -T "$file" -u :8490fc51-f593-4c87-8e35-3379cf5a94a3 https://pixeldrain.com/api/file/
        echo
    fi
done
