# cleanup
remove_lists=(
.repo/local_manifests
device/qcom/sepolicy
device/qcom/sepolicy-legacy-um
device/qcom/sepolicy_vndr/legacy-um
device/asus/sdm660-common
device/asus/X00TD
external/chromium-webview
external/rust
kernel/asus/sdm660
out/target/product/X00TD
prebuilts/clang/host/linux-x86
packages/modules/Nfc
packages/apps/Nfc
system/nfc
vendor/extras
vendor/addons
vendor/asus/sdm660-common
vendor/asus/X00TD
)

echo "-- Removing ${remove_lists[@]}"
rm -rf "${remove_lists[@]}"

# Symlink libncurses 6 >> 5
# sudo ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
# sudo ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6   /usr/lib/x86_64-linux-gnu/libtinfo.so.5
# echo "============="
# echo "lib6 >> lib5  "
# echo "============="

#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 16 -g default,-mips,-darwin,-notdefault
"=================="
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

# setup KernelSU
if [ -d kernel/asus/sdm660 ]; then 
	cd kernel/asus/sdm660
	curl -LSs "https://raw.githubusercontent.com/rsuntk/KernelSU/main/kernel/setup.sh" | bash -s main
	cd ../../..
fi

rm -rf frameworks/base
git clone https://github.com/ikwfahmi/frameworks_base.git -b 16 frameworks/base

rm -rf lineage-sdk
git clone https://github.com/ikwfahmi/custom-sdk.git -b 16 lineage-sdk

# Export
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

git clone https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
cd vendor/evolution-priv/keys
./keys.sh
cd ../../..

#build
lunch infinity_X00TD-user && make installclean && m bacon
