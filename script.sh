#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/halcyonproject/manifest -b 16.2 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b Hakcyon-16 .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

#Sync
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)
echo "============="
echo "Sync success"
echo "============="

# setup KernelSU
# if [ -d kernel/asus/sdm660 ]; then 
# cd kernel/asus/sdm660
# curl -LSs "https://raw.githubusercontent.com/backslashxx/KernelSU/master/kernel/setup.sh" | bash -s master
# cd ../../..
# fi
# echo "======= RKSU done ======"

# Set up build environment
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=serverhive
export TZ="Asia/Jakarta"
source build/envsetup.sh

rm -rf vendor/evolution-priv/keys
git clone --depth=1 https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
cd vendor/evolution-priv/keys
./keys.sh
cd ../../..

rm -rf hardware/qcom-caf/sdm660/audio
git clone --depth=1 -b lineage-23.2-caf-sdm660 https://github.com/rsuntk-asus-sdm660/android_hardware_qcom-caf_audio.git hardware/qcom-caf/sdm660/audio
# git clone --depth=1 -b 16.0 https://github.com/Kyura-Ground/android_build.git build/make

rm -rf build/make
git clone --depth=1 https://github.com/Kyura-Ground/build_make.git build/make

# echo "========================"
# echo " Starting Build: Vanilla"
# echo "========================"
# Setup untuk perangkat
lunch halcyon_X00TD-bp4a-user
make installclean
mka carthage
