rm -rf .repo/local_manifests/

#repo init
repo init -u https://github.com/Lunaris-AOSP/android -b 16 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

#local_manifest
git clone https://github.com/Kyura-Ground/local_manifests.git -b main .repo/local_manifests
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
lunch lineage_X00TD-bp2a-user && make installclean && m lunaris
