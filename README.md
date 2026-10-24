# X00TD LineageOS 22.2

Script build Crave dengan alur yang sama seperti branch Infinity:

1. Bersihkan source yang bentrok, init dan sync LineageOS 22.2.
2. Setup environment dan KernelSU; keys ikut dari local manifest.
3. Jalankan `lunch lineage_X00TD-bp1a-userdebug`, `make installclean`, lalu `m bacon`.
4. Upload `out/target/product/X00TD/lineage*.zip` ke Pixeldrain, lalu pindahkan ZIP ke root source.

Jalankan dari root source Android yang sudah memiliki `.repo`:

```bash
curl -fLSs https://raw.githubusercontent.com/Kyura-Ground/build_script/lineage-22.2/script.sh -o /tmp/build-lineage.sh
bash /tmp/build-lineage.sh
```

KernelSU mengikuti branch `master` terbaru dari backslashxx, seperti script Infinity.
Setup memakai `curl`; opsi KSU dibaca dari `arch/arm64/configs/vendor/extra/ksu.config` melalui `TARGET_KERNEL_CONFIG` di device tree.
Keys di `vendor/lineage-priv/keys` tetap dipertahankan. Build menghasilkan vanilla LineageOS; GApps dipasang terpisah.

Pemeriksaan lokal:

```bash
bash -n script.sh
shellcheck script.sh
python3 tests/smoke.py
```

Smoke test berjalan offline dengan sync, build, dan upload yang dimock.
