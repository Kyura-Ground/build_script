rm -rf .repo/local_manifests/
rm -rf out/soong out/host/linux-x86
rm -rf hardware/qcom-caf/msm8998
rm -rf hardware/qcom-caf/sdm660
rm -rf device/asus/sdm660-common
rm -rf vendor/asus
rm -rf vendor/infinity-priv/keys
rm -rf vendor/evolution-priv/keys
rm -rf vendor/lineage-priv/keys
rm -rf vendor/voltage-priv/keys

# Symlink libncurses 6 >> 5
# sudo ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
# sudo ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6   /usr/lib/x86_64-linux-gnu/libtinfo.so.5
# echo "============="
# echo "lib6 >> lib5  "
# echo "============="

#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/VoltageOS/manifest.git -b 16.2 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone --depth=1 https://github.com/ikwfahmi/local_manifests.git -b Voltage-16 .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

#Sync
[ -f /usr/bin/resync ] && /usr/bin/resync || /opt/crave/resync.sh
echo "============="
echo "Sync success"
echo "============="

# setup KernelSU
if [ -d kernel/asus/sdm660 ]; then 
	cd kernel/asus/sdm660
	curl -LSs "https://raw.githubusercontent.com/rsuntk/KernelSU/main/kernel/setup.sh" | bash -s main
	cd ../../..
fi
echo "======= RKSU done ======"

rm -rf device/voltage/sepolicy
git clone https://github.com/ikwfahmi/device_voltage_sepolicy.git device/voltage/sepolicy
echo "======= sepolicy done ======"

# Export
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

cd vendor/voltage-priv/keys/
bash keys.sh
cd -

#build
make installclean
brunch X00TD
