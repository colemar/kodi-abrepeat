# A-B Repeat for Kodi

`service.abrepeat` adds **A-B repeat** (loop a section) to Kodi's built-in player. Kodi has never had this feature natively.

One remote key does all three steps:

| Press | Effect |
|-------|--------|
| 1st | Sets point **A** at the current position |
| 2nd | Sets point **B**, jumps back to A and starts looping |
| 3rd | Clears the loop |

The key works while playing, while paused (with frame stepping as well) and with the OSD open. A/B are cleared automatically when playback starts, stops or ends.

Requires Kodi 19 (Matrix) or later and works on any platform. The add-on has been used on Android TV (Nvidia Shield) and needs no patched Kodi build.

## Installation

1. Download `service.abrepeat-<version>.zip` from [Releases](../../releases).
2. In Kodi go to **Settings → System → Add-ons** and enable **Unknown sources**.
3. Go to **Add-ons → Install from zip file** and select the zip.

The zip can come from a USB stick or from any Kodi network source (SMB, NFS, WebDAV…).

The add-on does **not** assign a key by itself. Pick one of the methods below.

## Mapping a key

### Option 1 – Keymap Editor (recommended, no file editing)

Install **Keymap Editor** from the official Kodi repository (Add-ons → Install from repository → Kodi Add-on repository → Program add-ons), then:

1. Open **Keymap Editor → Edit**.
2. Select the window **Global**. The key then works in every window: fullscreen video, video OSD, paused seek bar. Outside playback it only shows "Nothing is playing".
   *Do not pick "Video OSD Settings": that is the settings dialog opened by the gear icon, not the playback OSD.*
3. Action category **Add-ons** → **Launch A-B Repeat**.
4. Press the remote key you want to use.
5. Back out and choose **Save**.

Keymap Editor writes `userdata/keymaps/gen.xml`. Changes take effect immediately.

### Option 2 – Manual keymap

Copy [`examples/abrepeat.xml`](examples/abrepeat.xml) to `userdata/keymaps/` (in Kodi: *Profile directory/keymaps*, reachable from the File manager) and edit the key name. Then restart Kodi.

```xml
<keymap>
  <global>
    <keyboard>
      <f5>RunScript(service.abrepeat)</f5>
    </keyboard>
  </global>
</keymap>
```

Optional arguments for separate keys:

| Command | Action |
|---------|--------|
| `RunScript(service.abrepeat)` | cycle A → B+loop → off |
| `RunScript(service.abrepeat,a)` | set A |
| `RunScript(service.abrepeat,b)` | set B and start loop |
| `RunScript(service.abrepeat,clear)` | clear |

Keymaps are loaded in alphabetical order and later files win, so `gen.xml` overrides `abrepeat.xml` for the same key.

## Nvidia Shield: using the Netflix button

The Netflix button on the 2019+ Shield remote sends `KEYCODE_BUTTON_12` (199). Android intercepts it to launch Netflix (or shows an "Open with…" dialog), and Kodi never receives it. **Button Mapper** (by flar2, free on the Play Store) can turn it into a key Kodi understands.

1. Install **Button Mapper** on the Shield. When asked, enable it as an **Accessibility Service**.
2. **Add Buttons → Add Button**, then press the Netflix button. It appears as `BUTTON_12 / 199`.
3. Open it, enable **Customize**, then **Single tap → Advanced → Custom keycode (ver 2)**.
   *Ver 2 needs a single adb command. The first "Custom keycode" option needs adb after every reboot.*
4. Grant the permission once over adb, from a PC or from Termux on a phone:

   On the Shield, enable developer options first: Settings → Device Preferences → About → press *Build* 7 times. Then turn on Developer options → **Network debugging**.
   ```bash
   pkg install android-tools          # Termux only
   adb connect <shield-ip>:5555       # accept the prompt on the TV ("Always allow")
   adb shell pm grant flar2.homebutton android.permission.WRITE_SECURE_SETTINGS
   adb disconnect
   ```
   Use the exact command Button Mapper shows if it differs. Network debugging can be turned off afterwards, and the permission survives reboots.
5. In **Enter key code** type `135` (`KEYCODE_F5`) and confirm.
6. Map F5 in Kodi with Keymap Editor (press the Netflix button when asked) or with the manual keymap above.

Any keycode Kodi does not already use works. See the [Android keycode list](https://buttonmapper.com/keycodes).

## Known limitations

- **Overshoot:** the service polls the position every 50 ms, so the jump back to A happens 0.1–0.3 s after B, depending on seek latency.
- **Seek bar on every jump:** the skin shows its seek bar after each jump. Estuary displays it whenever `Player.DisplayAfterSeek` is true, and an add-on cannot suppress it. Hiding it requires a modified skin (`DialogSeekBar.xml`).
- **Keyframes:** seek accuracy depends on Kodi's seeking for the given file and container.

## How it works

- `default.py` is the command run by the key. It stores A and B as properties of the Home window (`abrepeat.a`, `abrepeat.b`).
- `service.py` is a background service. It reads those properties and calls `xbmc.Player().seekTime(A)` when the position reaches B.

## Building

```bash
./build.sh        # → dist/service.abrepeat-<version>.zip
```

## License

GPL-2.0-or-later, see [LICENSE](LICENSE).
