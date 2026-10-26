# X00TD LineageOS 23.2 — Linux 4.4

Run `script.sh` on the build server from an Android source root containing
`.repo`. It initializes `LineageOS/android` on `lineage-23.2`, then syncs
`Kyura-Ground/local_manifests` on `main` for the ASUS Linux 4.4 trees.

The build is vanilla without GApps. The workflow clears inherited GApps flags,
sets `WITH_GMS=false`, selects `breakfast X00TD userdebug`, runs `m installclean`,
and builds with `m -j${BUILD_JOBS:-32} bacon`. Set `BUILD_JOBS` to adjust parallelism.

The workflow preserves the existing signing keys, KernelSU setup, build identity,
and upload credentials. It does not generate a new signing identity. Only new
`lineage-23.2-*-X00TD.zip` packages from the current build are uploaded; uploaded
packages are moved to the source root.

Source sync retains the server resync wrapper when available. The fallback uses
`repo sync -j8` with bounded retry handling. Legacy nested ASUS vendor checkouts
are removed only when the combined vendor checkout does not yet exist.

This is a source bringup. Offline checks pass; the LineageOS 23.2 ROM still needs
a server build and device validation.

## Offline verification

```bash
bash -n script.sh
python3 tests/smoke.py
```

The smoke checks mock source sync, builds, and uploads in temporary directories.
They check failure propagation, vanilla selection, artifact filtering and
preservation of signing keys. They do not build or upload a real ROM.

Reference: [LineageOS 23.2 source instructions](https://github.com/LineageOS/android/blob/lineage-23.2/README.mkdn).
