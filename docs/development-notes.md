# Current development notes (2026-11-06)

`master` is the source-only branch. Only these existing files differ from upstream:
`hid.c`, `hid.h`, `scenes/hid_scene_start.c`, `transport_ble.c`,
`views/hid_media.c`, and `views/hid_media.h`.

The original manifest, application version (1.1), directory layout and GitHub
Actions/uFBT configuration are unchanged. Windows helpers and these notes belong
only to `dev`, never to the proposed upstream PR.

## Readability and resource management

- The BLE HID profile stays in the existing BLE transport implementation.
- One allocation owns all three initialized input reports, replacing three
  separate report allocations.
- Shared validation and report-sending helpers remove repeated boilerplate.
- Profile shutdown frees the owning allocation. View exit callbacks run before
  either USB or Bluetooth transport is restored, so held keys are released while
  the transport remains valid.
- The descriptor and usage-to-bit lookup share a single ordered Consumer usage
  list. Keyboard, mouse and Consumer report formats are preserved.
- Media handling distinguishes Flipper input keys from HID usages, and rejects
  unsupported Consumer usages without sending redundant reports.

## Verification

Official Flipper firmware 1.5.1, target f7, API 88.2, OPPO Find N5 / Android 16.
`ufbt lint` and both Bluetooth/USB builds passed using the original build flow.
Bluetooth Remote was installed, read back, and matched the local FAP:

```text
SHA256 89d87aa28a627b08da5f33068cff4153391b725ffe3f1cf216f2fdce2743240d
```

On-device checks passed for real Bluetooth play/pause in an active VLC session,
keyboard volume DOWN/UP events, mouse REL_X movement, held-key release on view
exit, and profile/app close and restart. Key Mapper special permissions remained
off. USB received build/API checks only; it was not functionally tested.

Earlier Bilibili half-screen/full-screen playback tests passed before this final
readability/resource refactor. The previous intermittent app-routing issue was
not assigned a definitive framework/app cause. One later VLC check deliberately
recorded that Android still selected Bilibili as the media-button target; starting
VLC playback selected its session and restored expected media-key routing.

Local records are under `D:\project\flipper\env`, including
`quality-vlc-media.json`, `quality-keyboard-volume.json`,
`quality-mouse-report.json`, `exit-held-key.log`, and
`backups\hid_ble-quality-final-installed.fap`. Paired-device keys, SDKs,
downloaded APKs, device screenshots and toolchain binaries are not committed.
