rm -rf .repo/local_manifests/
rm -rf prebuilts/clang/host/linux-x86
rm -rf hardware/qcom-caf/

#repo init
repo init -u https://github.com/crdroidandroid/android.git -b 16.0 --git-lfs --no-clone-bundle
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone https://github.com/Kyura-Playground/local_manifests.git -b Crdroid .repo/local_manifests
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
lunch lineage_X00TD-bp2a-userdebug && make installclean && mka bacon

# Pull output files dan upload ke pixeldrain
echo "============================================"
echo "Pulling output files and uploading to pixeldrain"
echo "============================================"

crave pull out/target/product/*/*.zip

# Upload semua file .zip yang berhasil di-pull ke pixeldrain
for zipfile in *.zip; do
    if [ -f "$zipfile" ]; then
        echo "Uploading $zipfile to pixeldrain..."
        curl -T "$zipfile" -u :a7221521-6fdf-4fc5-b7cc-48c3401835a6 https://pixeldrain.com/api/file/
        echo "Upload completed for $zipfile"
    fi
done
