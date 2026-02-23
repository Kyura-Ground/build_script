# cleanup
remove_lists=(
    .repo/local_manifests
    device/asus/X00TD
    device/lineage/sepolicy
    device/qcom/sepolicy
    device/qcom/sepolicy-legacy-um
    device/qcom/sepolicy_vndr/legacy-um
    external/chromium-webview
    kernel/asus/sdm660
    out/target/product/X00TD
    prebuilts/clang/host/linux-x86
    packages/modules/Nfc
    packages/apps/Nfc
    system/nfc
    vendor/extras
    vendor/addons
    vendor/asus
    vendor/lineage-priv/keys
    vendor/evolution-priv/keys
)

do_reclone() {
    rm -rf $3
    echo "-- Recloning $3 ..."
    git clone --depth=1 $1 -b $2 $3
}

echo "-- Removing ${remove_lists[@]}"
rm -rf "${remove_lists[@]}"

# Symlink libncurses 6 >> 5
# sudo ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
# sudo ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6   /usr/lib/x86_64-linux-gnu/libtinfo.so.5
# echo "============="
# echo "lib6 >> lib5  "
# echo "============="

# repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 16 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

# local_manifest
git clone --depth=1 https://github.com/ikwfahmi/local_manifests.git -b Infinity-16 .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Sync
[ -f /usr/bin/resync ] && /usr/bin/resync || /opt/crave/resync.sh
echo "============="
echo "Sync success"
echo "============="

# Setup KernelSU
if [ -d kernel/asus/sdm660 ]; then 
    cd kernel/asus/sdm660
    curl -LSs "https://raw.githubusercontent.com/Sorayukii/KernelSU-Next/stable/kernel/setup.sh" | bash -s hookless
    cd ../../..
fi
echo "======= RKSU done ======"

# Set up build environment
export BUILD_USERNAME=kenq
export BUILD_HOSTNAME=crave
export TZ="Asia/Jakarta"
source build/envsetup.sh

rm -rf vendor/evolution-priv/keys
git clone https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
cd vendor/evolution-priv/keys
./keys.sh
cd ../../..

echo "========================"
echo " Starting Build: VANILLA"
echo "========================"
# Device setup
lunch infinity_X00TD-bp4a-user
make installclean

# Set flag for Vanilla (Without GMS)
export WITH_GMS=false
m bacon

# Upload VANILLA Build
for file in out/target/product/X00TD/Project_Infinity*.zip; do
    if [ -f "$file" ]; then
        echo "Starting VANILLA upload: $file"
        curl -T "$file" -u :9942b260-7d7b-45bc-b25e-3a016652bcf2 https://pixeldrain.com/api/file/
        echo -e "\nUpload completed for $file"
        
        # Move the file to the root directory to avoid re-uploading later
        mv "$file" ./
        echo "--------------MOVED VANILLA BUILD TO ROOT DIRECTORY--------------"
    else
        echo "File not found!"
    fi
done

echo "========================"
echo " Starting Build: GAPPS"
echo "========================"
# MUST clean again before changing variants to avoid conflicts
make installclean

# Set flag for GAPPS
export WITH_GMS=true
export TARGET_USES_MINI_GAPPS=true
m bacon

# Upload GAPPS Build
for file in out/target/product/X00TD/Project_Infinity*.zip; do
    if [ -f "$file" ]; then
        echo "Starting GAPPS upload: $file"
        curl -T "$file" -u :9942b260-7d7b-45bc-b25e-3a016652bcf2 https://pixeldrain.com/api/file/
        echo -e "\nUpload completed for $file"
        
        # Also move the GAPPS file to the root directory
        mv "$file" ./
        echo "--------------MOVED GAPPS BUILD TO ROOT DIRECTORY--------------"
    else
        echo "File not found!"
    fi
done
