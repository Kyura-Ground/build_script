rm -rf .repo/local_manifests/
rm -rf external/chromium-webview
rm -rf out/soong out/host/linux-x86
rm -rf hardware/qcom-caf/msm8998
rm -rf hardware/qcom-caf/sdm660
rm -rf device/asus/sdm660-common
rm -rf vendor/asus

# Symlink libncurses 6 >> 5
sudo ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
sudo ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6   /usr/lib/x86_64-linux-gnu/libtinfo.so.5
echo "============="
echo "lib6 >> lib5  "
echo "============="

#repo init
repo init -u https://github.com/ArrowOS-T/android_manifest.git -b arrow-13.1_ext
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone https://github.com/Kyura-Ground/local_manifests.git -b Arrow13 .repo/local_manifests
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
lunch arrow_X00TD-user && make installclean && m bacon
