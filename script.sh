rm -rf .repo/local_manifests/
rm -rf external/chromium-webview
rm -rf hardware/qcom-caf/msm8998/audio
rm -rf hardware/qcom-caf/msm8998/display
rm -rf hardware/qcom-caf/msm8998/media
rm -rf device/asis/X00T
rm -rf device/asus/X00TD
rm -rf vendor/asus
rm -rf device/asus/sdm660-common
rm -rf vendor/lineage-priv/keys
rm -rf vendor/lineage/signing/keys

#repo init
repo init -u https://github.com/2by2-Project/manifest.git -b Bismuth --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone https://github.com/Kyura-Playground/local_manifests.git -b Rising .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

#Sync
/opt/crave/resync.sh
echo "============="
echo "Sync success"
echo "============="

rm -rf system/sepolicy
git clone https://github.com/ikwfahmi/system_sepolicy -b Bismuth system/sepolicy

# Export
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

#build
lunch X00TD-userdebug && make installclean && m bacon
