# cleanup
remove_lists=(
    .repo/local_manifests
    device/asus/X00TD
    kernel/asus/sdm660
    vendor/asus
    vendor/evolution-priv/keys
    packages/overlays/Lineage/fonts
    prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9
)

do_reclone() {
    rm -rf $3
    echo "-- Recloning $3 ..."
    git clone --depth=1 $1 -b $2 $3
}

echo "-- Removing ${remove_lists[@]}"
rm -rf "${remove_lists[@]}"

#repo init
repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/Evolution-X/manifest -b cnb -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone --depth=1 https://github.com/Kyura-Ground/local_manifests.git -b Evox .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

#Sync
[ -f /usr/bin/resync ] && /usr/bin/resync || /opt/crave/resync.sh
echo "============="
echo "Sync success"
echo "============="

# ==========================================================
# FIX KONFLIK MODULE ALREADY DEFINED
# Dijalankan SETELAH sync agar folder tidak diunduh ulang
# ==========================================================
echo "================================================="
echo " Menghapus folder QCOM-CAF dan Font yang bentrok "
echo "================================================="
rm -rf hardware/qcom-caf/sdm845
rm -rf hardware/qcom-caf/msm8998

# Set up build environment
export BUILD_USERNAME=kyura
export BUILD_HOSTNAME=crave
export TZ="Asia/Jakarta"
source build/envsetup.sh

rm -rf vendor/evolution-priv/keys
git clone --depth=1 https://github.com/Evolution-X/vendor_evolution-priv_keys-template vendor/evolution-priv/keys
cd vendor/evolution-priv/keys
./keys.sh
cd ../../..

echo "========================"
echo " Starting Build: Vanilla"
echo "========================"

# Setup untuk perangkat
lunch lineage_X00TD-cp2a-user
make installclean
m evolution

# Upload VANILLA Build
for file in out/target/product/X00TD/EvolutionX*.zip; do
    if [ -f "$file" ]; then
        echo "Mulai mengupload VANILLA: $file"
        curl -T "$file" -u :8490fc51-f593-4c87-8e35-3379cf5a94a3 https://pixeldrain.com/api/file/
        echo -e "\nUpload selesai untuk $file"
        
        # Pindahkan file ke direktori utama agar tidak terupload ulang nanti
        mv "$file" ./
        echo "--------------MOVED VANILLA BUILD TO ROOT DIRECTORY--------------"
    else
        echo "File tidak ditemukan!"
    fi
done
