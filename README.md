# Lunaris AOSP 16.2 for X00TD

Run `script.sh` from an existing Crave Android source root. It switches the
manifest to Lunaris AOSP 16.2 and local manifest branch `Lunaris16`, then builds
`lineage_X00TD-bp4a-user` with `m bacon` and uploads the resulting ROM ZIP.

The local manifest selects device and kernel branch `Lunaris`, the LineageOS
23.2 common and vendor branches, and signing keys in `vendor/lineage-priv/keys`.
The kernel uses the `-Caffeinated` local version.
The device defaults to vanilla; blur and BCR are disabled.

The script removes the listed source and signing-key directories before syncing
and runs `make installclean`. Do not run it in a checkout with uncommitted work
in those directories. KernelSU is set up from backslashxx/KernelSU `master`.
