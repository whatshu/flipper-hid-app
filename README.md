# HID App

This is a standalone version of the HID app Momentum. Thankfully, that project is GPL, so this one is as well.

## Development helpers (dev branch only)

The fork's `master` branch contains only the HID source changes and retains the
original project layout, manifest, version and uFBT workflow. This `dev` branch
adds optional Windows helpers and investigation notes; they are excluded from
the proposed upstream pull request.

From this checkout in PowerShell:

```powershell
.\setup-env.ps1
.\build.ps1
.\build.ps1 launch APPID=hid_ble
```

The helpers use the sibling `..\env` directory for Python, uFBT, the SDK and
toolchain, independently of global PATH. The default SDK matches official
firmware 1.5.1 (f7, API 88.2). For another firmware version, use
`.\setup-env.ps1 -FirmwareVersion <version>`. Setup does not flash firmware.

## Android media controls

Pair `Remote <Flipper name>` once while Bluetooth Remote is running. Its separate
bond file preserves the original `Control` pairing and avoids cached HID report
descriptors. In Media (Android), OK sends real Consumer Play/Pause; up/down use
keyboard volume keys and left/right use arrows. Arrow behavior depends on the
player's focused UI and is not guaranteed to seek.

Start playback in the intended app before testing. Android can route media keys
to the last active media session even when a different paused player is visible.
Key Mapper is not required for the tested setup.

See [current development notes](docs/development-notes.md). Older notes are kept
as historical records and may refer to earlier file names and app metadata.

## Functionality

![screenshots/keynote.png](Keynote)

Keynote - Remote for presentations

![screenshots/keynote-vertical.png](Keynote Vertical)

Keynote Vertical - Alternate remote for presentations

![screenshots/keyboard.png](Keyboard)

Keyboard - A functional keyboard, including modifier keys

![screenshots/numpad.png](Numpad)

Numpad - Number pad

![screenshots/media.png](Media)

Media - Media controls

![screenshots/apple-music-macos.png](Apple Music macOS)

Apple Music macOS - Alternate music controls

![screenshots/movie.png](Movie)

Movie - Media controls for watching a movie

![screenshots/mouse.png](Mouse)

Mouse - Move the cursor and send clicks

![screenshots/tiktoc-yt-shorts.png](TikToc YT Shorts)

TikToc / YT Shorts - Specialized controls for short-form videos

![screenshots/mouse-clicker.png](Mouse Clicker)

Mouse Clicker - Repeatedly click the mouse after a delay

![screenshots/mouse-jiggler.png](Mouse Jiggler)

Mouse Jiggler - Moves the mouse every few seconds

![screenshots/mouse-jiggler-stealth.png](Mouse Jiggler Stealth)

Mouse Jiggler Stealth - Moves the mouse a random direction and distance after a random time period

![PushToTalk](PushToTalk)

PushToTalk - Controls to unmute your microphone with various services
