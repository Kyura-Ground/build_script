rm -rf .repo/local_manifests/
rm -rf hardware/qcom-caf/msm8998/audio
rm -rf hardware/qcom-caf/msm8998/display
rm -rf hardware/qcom-caf/msm8998/media
rm -rf device/asis/X00T
rm -rf device/asus/X00TD
rm -rf vendor/asus
rm -rf device/asus/sdm660-common
rm -rf vendor/lineage-priv/keys
rm -rf vendor/lineage/signing/keys
rm -rf prebuilts/clang/host/linux-x86

#repo init
repo init -u https://github.com/crdroidandroid/android.git -b 16.0 --git-lfs --no-clone-bundle
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone https://github.com/Kyura-Playground/local_manifests.git -b Crdroid .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

#Sync
/opt/crave/resync.sh
echo "============="
echo "Sync success"
echo "============="

# Export
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

#build
brunch X00TD && make installclean

# Upload to PixelDrain
echo "======= Starting Upload to PixelDrain ======"
crave pull out/target/product/X00TD/*.zip
ZIP_FILE=$(ls out/target/product/X00TD/*.zip | head -n 1)
if [ -f "$ZIP_FILE" ]; then
    echo "Uploading $ZIP_FILE to PixelDrain..."
    curl -T "$ZIP_FILE" -u :a7221521-6fdf-4fc5-b7cc-48c3401835a6 https://pixeldrain.com/api/file/
    echo "====== Upload Complete ======"
else
    echo "No ZIP file found to upload"
fi
