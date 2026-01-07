rm -rf .repo/local_manifests/
rm -rf external/chromium-webview
rm -rf out/soong out/host/linux-x86
rm -rf hardware/qcom-caf/msm8998
rm -rf hardware/qcom-caf/sdm660
rm -rf device/asus/sdm660-common
rm -rf vendor/asus

# Symlink libncurses 6 >> 5
# sudo ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
# sudo ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6   /usr/lib/x86_64-linux-gnu/libtinfo.so.5
# echo "============="
# echo "lib6 >> lib5  "
# echo "============="

#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 16 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone -b Infinity-16 https://github.com/ikwfahmi/local_manifests.git .repo/local_manifests
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
lunch infinity_X00TD-userdebug && make installclean && m bacon
