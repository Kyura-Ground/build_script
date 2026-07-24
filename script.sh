# cleanup
remove_lists=(
    .repo/local_manifests
    device/asus/X00TD
    device/asus/sdm660-common
    kernel/asus/sdm660
    vendor/asus
    vendor/asus/X00TD
    vendor/asus/sdm660-common
    vendor/evolution-priv/keys
    vendor/lineage-priv/keys/
)

do_reclone() {
    rm -rf $3
    echo "-- Recloning $3 ..."
    git clone --depth=1 $1 -b $2 $3
}

echo "-- Removing ${remove_lists[@]}"
rm -rf "${remove_lists[@]}"

# Symlink libncurses 6 >> 5
sudo ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
sudo ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6   /usr/lib/x86_64-linux-gnu/libtinfo.so.5
echo "============="
echo "lib6 >> lib5  "
echo "============="

#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/crdroid-13-fork/android.git -b 13.0 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#Sync
[ -f /usr/bin/resync ] && /usr/bin/resync || /opt/crave/resync.sh
echo "============="
echo "Sync success"
echo "============="

#local_manifest
git clone --depth=1 https://github.com/Kyura-Ground/android_device_asus_X00TD-4.4.git -b device/asus/X00TD
git clone --depth=1 https://github.com/Kyura-Ground/android_device_asus_sdm660-common-4.4.git device/asus/sdm660-common
git clone --depth=1 https://github.com/Kyura-Ground/proprietary_vendor_asus_X00TD-4.4.git vendor/asus/X00TD
git clone --depth=1 https://github.com/Kyura-Ground/proprietary_vendor_asus_sdm660-common-4.4.git vendor/asus/sdm660-common
git clone --depth=1 https://github.com/Kyura-Ground/android_kernel_asus_sdm660-4.4.git kernel/asus/sdm660
git clone --depth=1 https://github.com/Kyura-Ground/public-keys.git -b main vendor/lineage-priv/keys/
echo "============================"
echo "Clone X00TD Resources done"
echo "============================"

# setup KernelSU
if [ -d kernel/asus/sdm660 ]; then 
cd kernel/asus/sdm660
curl -LSs "https://raw.githubusercontent.com/backslashxx/KernelSU/master/kernel/setup.sh" | bash -s master
cd ../../..
fi
echo "======= XXKSU done ======"

# Set up build environment
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
export TZ="Asia/Jakarta"
source build/envsetup.sh

# rm -rf vendor/evolution-priv/keys
# git clone --depth=1 https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
# cd vendor/evolution-priv/keys
# ./keys.sh
# cd ../../..

# rm -rf hardware/qcom-caf/sdm660/audio
# git clone --depth=1 -b lineage-23.2-caf-sdm660 https://github.com/SonicBSV/android_hardware_qcom-caf_sdm660_audio.git hardware/qcom-caf/sdm660/audio

# rm -rf build/soong
# git clone --depth=1 -b 16.2 https://github.com/Kyura-Ground/build_soong build/soong

# Setup untuk perangkat
lunch derp_X00TD-user
make installclean
mka derp

# Upload VANILLA Build
for file in out/target/product/X00TD/DerpFest*.zip; do
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
