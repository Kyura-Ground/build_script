rm -rf .repo/local_manifests/
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

git clone --branch symbiot-16 https://github.com/nenggala-project/symbiotos_advan_x1_manifest symbiotos_advan_x1_manifest

#repo init
repo init -u https://github.com/VoltageOS/manifest --git-lfs --depth 1 -b 16
"=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone -b Symbiot-16 https://github.com/ikwfahmi/local_manifests.git .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

cp -r ~/symbiotos_advan_x1_manifest/local_manifests .repo/

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

# Creating certs
cd vendor/voltage-priv/keys 
bash ./make_key.sh
cd /crave-devspaces/aosp

# Apply Symbiot patchset
curl -L -o ./symbiot-patcher https://symbiotos.nenggala-project.id/file/symbiot-patcher
chmod +x ./symbiot-patcher
./symbiot-patcher --apply

# Build
brunch X00TD
