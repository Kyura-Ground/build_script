# X00TD LineageOS 24.0 — Linux 4.4

Run `script.sh` from an empty server directory or an Android source root with
`.repo`. The workflow follows the Lunaris script: cleanup source, repo init,
local manifest, sync, KernelSU, envsetup, lunch, installclean, build and upload.

It selects `LineageOS/android` and local manifest branch `lineage-24.0`, builds
vanilla with `lunch lineage_X00TD-cp2a-user`, `make installclean` and `m bacon`.
Signing keys are preserved. ZIP files remain in `out/target/product/X00TD/` after
upload. As in the Lunaris script, an upload is skipped when no matching ZIP exists.

Offline verification:

```bash
bash -n script.sh
python3 tests/smoke.py
```

Tests mock sync, builds and uploads; they do not run a kernel/ROM build.
