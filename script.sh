#!/bin/bash
set -eo pipefail

if [ ! -d .repo ]; then
    echo "Jalankan dari root source Android Crave." >&2
    exit 1
fi

rm -rf -- \
    .repo/local_manifests \
    device/asus/X00TD \
    device/asus/sdm660-common \
    kernel/asus/sdm660 \
    vendor/asus \
    build/soong \
    vendor/infinity-priv/keys \
    vendor/evolution-priv/keys \
    vendor/lineage-priv/keys \
    vendor/lunaris-priv/keys

repo init --depth=1 --git-lfs \
    -u https://github.com/Lunaris-AOSP/android \
    -b 16.2 \
    -g default,-mips,-darwin,-notdefault

git clone --depth=1 --branch Lunaris16 \
    https://github.com/Kyura-Ground/local_manifests.git \
    .repo/local_manifests

if [ -x /usr/bin/resync ]; then
    /usr/bin/resync
elif [ -f /opt/crave/resync.sh ]; then
    bash /opt/crave/resync.sh
else
    repo sync -c --force-sync --optimized-fetch \
        --no-tags --no-clone-bundle --prune \
        --retry-fetches=3 -j8
fi

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
