# X00TD AxionOS Android 16 — Linux 4.4

Candidate workflow for the first X00TD AxionOS server build. The selected kernel
backport queues, Kconfig dependencies, upstream metadata and signatures have
been checked. This branch has not been validated by a ROM build or device boot.

Run the workflow on the build server from an Android source root containing
`.repo`. It initializes `AxionAOSP/android` on `lineage-23.2`, then uses
`Kyura-Ground/local_manifests` on `axion-23.2-4.4` for the ASUS Linux 4.4 trees.
That manifest/source branch must be published before running the workflow.

The selected variant is **vanilla without GApps**, explicitly requested by the
user. Configuration uses `axion X00TD userdebug va`; the build uses
`ax -b -j${BUILD_JOBS:-32}`. Axion performs installclean in that helper.
The existing KernelSU setup and build identity settings are retained.

Existing signing keys in `vendor/lineage-priv/keys` are preserved. The script
does not run `gk` or generate a new signing identity. Upload credentials and the
upload destination remain as configured by the user. Output selection follows
Axion's `axion*.zip` package name; uploaded zips are moved to the source root.

Source sync retains the server's resync wrapper when available. The fallback
uses `repo sync -j8` with bounded retry handling.

## Offline verification

```bash
bash -n script.sh
python3 tests/smoke.py
```

The smoke checks use mocked git/repo/build/upload commands and temporary
fixtures. They verify failure propagation, the vanilla selection, artifact
handling, and preservation of the existing key files. They do not compile a ROM,
contact a build server, or upload a real artifact.

Reference: [AxionOS A16 build instructions](https://github.com/AxionAOSP/android/blob/lineage-23.2/README.mkdn).
