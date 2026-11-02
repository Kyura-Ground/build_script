#!/bin/bash
set -eo pipefail

[ -d .repo ] || { echo "Jalankan dari root source Android Crave." >&2; exit 1; }

# Cleanup
remove_lists=(
    .repo/local_manifests
    device/asus/X00TD
    device/asus/sdm660-common
    kernel/asus/sdm660
    vendor/asus
    vendor/voltage-priv/keys
    vendor/infinity-priv/keys
    vendor/evolution-priv/keys
    vendor/lineage-priv/keys
    vendor/lunaris-priv/keys
)
rm -rf -- "${remove_lists[@]}"

# Source Lunaris dan local manifest
repo init --depth=1 --no-repo-verify --git-lfs \
    -u https://github.com/Lunaris-AOSP/android -b 16.2 \
    -g default,-mips,-darwin,-notdefault

git clone --depth=1 -b Lunaris16 \
    https://github.com/Kyura-Ground/local_manifests.git .repo/local_manifests

repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)

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
export WITH_GMS=false
lunch lineage_X00TD-bp4a-user
make installclean
m bacon

# Upload Vanilla
for file in out/target/product/X00TD/Lunaris-AOSP-*.zip; do
    if [ -f "$file" ]; then
        echo "Mengupload: $file"
        curl -fS --retry 3 -T "$file" -u ":8490fc51-f593-4c87-8e35-3379cf5a94a3" https://pixeldrain.com/api/file/
        echo
        mv -- "$file" ./
    fi
done
