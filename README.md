# X00TD LineageOS 24.0 — Linux 4.4

Run `script.sh` from an empty server directory or an Android source root with
`.repo`. It uses the same workflow as the Lunaris builder: clean device/kernel/
ASUS vendor sources, initialize the ROM and local manifest, sync directly with
all CPUs, set up KernelSU, then source the build environment.

Lineage-specific selections are `LineageOS/android` and local manifest branch
`lineage-24.0`, `lunch lineage_X00TD-cp2a-user`, `make installclean`, and `m bacon`.
The build is vanilla: inherited GApps flags are cleared and `WITH_GMS=false`.

Signing keys remain in place and the manifest syncs the matching key project.
The Linux 4.4 guard and failure propagation remain enabled. Upload uses retry
handling and only takes Lineage 24.0 packages produced by the current build.
ZIP files remain in `out/target/product/X00TD/`; they are not moved after upload.
The existing upload credentials and build identity are retained.

Device, common, combined vendor and Linux 4.4 kernel projects all use
`lineage-24.0`. The manifest retains the legacy msm8998 BSP/power revisions
required by this device. A complete server build and hardware validation are
still required.

## Offline verification

```bash
bash -n script.sh
python3 tests/smoke.py
```

The smoke tests mock source sync, build and upload. They check target selection,
failure propagation, artifact filtering/location and signing-key preservation.
They do not build a kernel/ROM or perform real uploads.
