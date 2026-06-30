rm -rf .repo/local_manifests/

#repo init
repo init -u https://github.com/crdroid-13-fork/android.git -b 13.0 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

#Sync
/opt/crave/resync.sh
echo "============="
echo "Sync success"
echo "============="

#local_manifest
git clone --depth=1 https://github.com/Kyura-Ground/android_device_asus_X00TD-4.19.git -b 13.0 device/asus/X00TD
git clone --depth=1 https://github.com/muralivijay/android_device_asus_sdm660-common-4.19.git -b 13.0 device/asus/sdm660-common
git clone --depth=1 https://github.com/muralivijay/proprietary_vendor_asus-4.19.git -b 13.0 vendor/asus
git clone --depth=1 --recursive https://github.com/muralivijay/android_kernel_asus_sdm660-4.19.git -b Ratibor-Rebased-Murali kernel/asus/sdm660-common
echo "============================"
echo "Clone X00TD Resources done"
echo "============================"

# Export
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

rm -rf hardware/qcom-caf/msm8998/display
rm -rf hardware/qcom-caf/msm8998/audio
rm -rf hardware/qcom-caf/msm8998/media
echo "====== Removed legacy msm8998 HALS ======="

git clone --depth=1 https://github.com/muralivijay/android_hardware_qcom-caf_sdm660_audio -b lineage-20.0-caf-sdm660 hardware/qcom-caf/msm8998/audio
git clone --depth=1 https://github.com/muralivijay/android_hardware_qcom-caf_sdm660_display -b lineage-20.0-caf-sdm660 hardware/qcom-caf/msm8998/display
git clone --depth=1 https://github.com/muralivijay/android_hardware_qcom-caf_sdm660_media -b lineage-20.0-caf-sdm660 hardware/qcom-caf/msm8998/media
echo "====== cloned 4.19 msm8998 HALS ======="

# Check keys before procced build
if [ -d "vendor/extra" ]; then
    echo "✓ Keys found for sign build. Proceeding build..."
    lunch lineage_X00TD-user && mka clean && mka clobber && mka bacon
else
    echo "✗ Error: keys not found Directory 'vendor/extra'."
    echo "Stopping script execution."
    exit 1
fi
