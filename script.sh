#!/bin/bash
set -eo pipefail

repo init --depth=1 --git-lfs \
    -u https://github.com/Lunaris-AOSP/android \
    -b 16.2 \
    -g default,-mips,-darwin,-notdefault

git clone --depth=1 --branch Lunaris16 \
    https://github.com/Kyura-Ground/local_manifests.git \
    .repo/local_manifests

repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)

export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
export TZ=Asia/Jakarta

set +e
source build/envsetup.sh
envsetup_status=$?
set -e

if [ "$envsetup_status" -ne 0 ]; then
    exit "$envsetup_status"
fi

(
    cd kernel/asus/sdm660
    curl -fLSs \
        https://raw.githubusercontent.com/backslashxx/KernelSU/master/kernel/setup.sh \
        | bash -s master
)

export WITH_GMS=false
lunch lineage_X00TD-bp4a-user
make installclean
m bacon

shopt -s nullglob

for file in out/target/product/X00TD/Lunaris-AOSP-*.zip; do
    echo "Mengupload: $file"

    curl -fS --retry 3 \
        --upload-file "$file" \
        --user ":8490fc51-f593-4c87-8e35-3379cf5a94a3" \
        https://pixeldrain.com/api/file/

    echo
    mv -- "$file" ./
done
