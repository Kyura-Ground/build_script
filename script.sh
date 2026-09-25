#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ShinkaiProject/shinkai_manifest.git -b heptakaideka -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
rm -rf .repo/local_manifests
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b hekkaideka .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

#Sync
repo sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)
echo "============="
echo "Sync success"
echo "============="

# setup KernelSU
if [ -d kernel/asus/sdm660 ]; then 
cd kernel/asus/sdm660
curl -LSs "https://raw.githubusercontent.com/backslashxx/KernelSU/master/kernel/setup.sh" | bash -s master
cd ../../..
fi
echo "==========="
echo "XXKSU done"
echo "==========="

# Set up build environment
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=serverhive
export TZ="Asia/Jakarta"
. b*/env*

# rm -rf vendor/evolution-priv/keys
git clone --depth=1 https://github.com/VoltageOS/vendor_voltage-priv_keys vendor/voltage-priv/keys
cd vendor/voltage-priv/keys
./keys.sh
cd ../../..

# Setup device
breakfast X00TD
mka shinkai
