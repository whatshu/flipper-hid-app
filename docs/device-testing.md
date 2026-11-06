> Archived investigation snapshot. For the current source layout and verification, see [development notes](development-notes.md).

# Device testing (2026-11-05)

This file records the November 5 observations. The
[November 6 follow-up](keymapper-device-testing.md) found that native play/pause
worked in the tested Bilibili playlist half-screen/full-screen pages and VLC,
even with Key Mapper stopped and its special permissions revoked. The earlier
failure was not reproduced after the user restored the devices.

Windows; official Flipper Zero firmware 1.5.1 (f7, API 88.2);
OPPO Find N5 PKH110, Android 16, Oplus ROM property V16.1.0,
build PKH110_16.0.10.501(CN01); VLC 3.7.1 and Bilibili.

## Release baseline

The release app's Media view sent Consumer Control usages. OK, volume and track
keys produced no corresponding Android EV_KEY events in the captured tests.
Movie's keyboard arrows did arrive. A fresh Bluetooth identity with the original
descriptor did not fix this. The exact parser/stack defect was not identified.

Android exposed Keyboard and Mouse input devices. The absence of a separately
named Consumer device alone is not evidence of failure: the working candidate
merges its Consumer keys into the Keyboard input device.

## Current experimental build

- `ble_hid_profile.c` adapts the official 1.5.1 profile and encodes 12 explicit
  Consumer Control usages in a two-byte bitmap instead of the original array.
- The app advertises `Remote Eat5elea`, with a separate `.bt_hid_remote.keys`.
  The original `.bt_hid.keys` and original FAP are preserved/backed up.
- Media (Android) uses true Consumer Play/Pause for OK. Up/down remain keyboard
  volume usages; left/right remain keyboard arrows. The earlier Space and
  experimental keyboard 0xE8 pause mappings are no longer used.
- Leaving the Media view releases both report types.

| Test | Observed result |
| --- | --- |
| Real Flipper OK over Bluetooth | MSC_SCAN 000c00cd; KEY_PLAYPAUSE DOWN/UP |
| Android policy log | KEYCODE_MEDIA_PLAY_PAUSE (85), scan code 164 |
| VLC foreground | PLAYING at 130000 ms -> PAUSED at 132033 ms |
| Bilibili foreground, half-screen | Media key arrives; player does not pause |
| Bilibili foreground, confirmed full-screen | Media key arrives; player remains PLAYING |
| Bilibili with NotificationShade focused | Same Flipper OK changes PAUSED -> PLAYING |
| ADB input keyevent media-key references | Foreground Bilibili also fails to react |
| Direct system MediaSession dispatch | Bilibili responds to play/pause dispatch |
| Android-mode volume | Keyboard volume events work; user also confirmed working |

The direct ADB session dispatch is a diagnostic reference, not proof of a working
Bluetooth solution. Bluetooth tests and ADB-injected references are labeled
separately in the diagnostic JSON (`adb_reference`).

These results distinguish two problems: the release Consumer report did not
produce input events, whereas the current report does; Bilibili's remaining
failure depends on foreground input routing. The evidence does not identify
whether Bilibili, ColorOS, or their interaction consumes the foreground event.
See [the research note](android-media-research.md) for Android's documented routing
and an existing helper app candidate. No helper app has been installed or tested.

## Seeking and verification limits

Keyboard arrows sometimes seek in VLC with its overlay hidden, and sometimes
select UI controls. Space was also focus-sensitive. The earlier blanket claim
that these keyboard shortcuts fixed playback control was too broad. Seeking is
deferred at the user's request. Original Media left/right mean previous/next
track, which is a different command from seeking within a video.

Both USB and BLE artifacts have built against API 88.2. Only BLE has received
phone functional testing. No phone root access or Flipper firmware flash was
used. The current phone helper proposal remains unverified on this device.

Evidence files in `D:\project\flipper\env` include:

- `media-original.json`, `movie-keyboard.json`, `fresh-pair-media.json`
- `bili-one-consumer-pause.json`, `bili-fullscreen-confirmed.json`
- `bili-notification-media.json`, `vlc-focused-media-toggle.json`

Backups are under `D:\project\flipper\env\backups`. At the latest test stop,
VLC and Bilibili were paused and USB stay-awake was restored to 0. The user's
subsequent volume setting was left as set. The Flipper was left connected as
Remote in Media (Android). These are snapshots, not guarantees about later
manual device activity.
