# A-B Repeat for Kodi

`service.abrepeat` adds **A-B repeat** (loop a section) to Kodi's built-in player. Kodi has never had this feature natively.

One remote key does all three steps:

| Press | Effect |
|-------|--------|
| 1st | Sets point **A** at the current position |
| 2nd | Sets point **B**, jumps back to A and starts looping |
| 3rd | Clears the loop |

The key works while playing, while paused (with frame stepping as well) and with the OSD open. A/B are cleared automatically when playback starts, stops or ends.

Designed for **Android TV / Google TV / Fire TV** boxes and TVs driven by a remote. It requires Kodi 19 (Matrix) or later and the stock Kodi build, no patches needed. Tested on an Nvidia Shield.

## Installation

### From the Kodi repository (recommended, automatic updates)

1. **Settings → System → Add-ons** → enable **Unknown sources**.
2. **Settings → File manager → Add source** → enter `https://colemar.github.io/kodi-abrepeat/` and name it `colemar`.
3. **Add-ons → Install from zip file** → `colemar` → `repository.colemar-<version>.zip`.
4. **Add-ons → Install from repository → Colemar Repository → Services → A-B Repeat → Install**.

Kodi then updates the add-on automatically when a new version is published.

### From a zip file

1. Download `service.abrepeat-<version>.zip` from [Releases](../../releases).
2. **Settings → System → Add-ons** → enable **Unknown sources**.
3. **Add-ons → Install from zip file** → select the zip.

The zip can come from a USB stick or from any Kodi network source (SMB, NFS, WebDAV…). Updates are manual.

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

## Using a dedicated app button (Netflix, Prime Video, YouTube…)

Most Android TV remotes have app buttons that Android intercepts before Kodi sees them. **Button Mapper** (by flar2, free on the Play Store) can turn such a button into a key Kodi understands. A plain free key (a color button, a spare media key) needs none of this: map it directly with Keymap Editor.

The steps below use the Netflix button of the Nvidia Shield remote (2019+) as the example. Other remotes report different keycodes, but the procedure is the same.

The Shield Netflix button sends `KEYCODE_BUTTON_12` (199). Android intercepts it to launch Netflix (or shows an "Open with…" dialog), and Kodi never receives it.

1. Install **Button Mapper** on the TV device. When asked, enable it as an **Accessibility Service**.
2. **Add Buttons → Add Button**, then press the app button. On the Shield the Netflix button appears as `BUTTON_12 / 199`.
3. Open it, enable **Customize**, then **Single tap → Advanced → Custom keycode (ver 2)**.
   *Ver 2 needs a single adb command. The first "Custom keycode" option needs adb after every reboot.*
4. Grant the permission once over adb, from a PC or from Termux on a phone:

   Enable developer options on the device first (Shield: Settings → Device Preferences → About → press *Build* 7 times). Then turn on **Network debugging** (or ADB/USB debugging) in Developer options.
   ```bash
   pkg install android-tools          # Termux only
   adb connect <device-ip>:5555       # accept the prompt on the TV ("Always allow")
   adb shell pm grant flar2.homebutton android.permission.WRITE_SECURE_SETTINGS
   adb disconnect
   ```
   Use the exact command Button Mapper shows if it differs. Network debugging can be turned off afterwards, and the permission survives reboots.
5. In **Enter key code** type `135` (`KEYCODE_F5`) and confirm.
6. Map F5 in Kodi with Keymap Editor (press the app button when asked) or with the manual keymap above.

Any keycode Kodi does not already use works. See the [Android keycode list](https://buttonmapper.com/keycodes).

## Known limitations

- **Overshoot:** the service polls the position every 50 ms, so the jump back to A happens 0.1–0.3 s after B, depending on seek latency.
- **Seek bar on every jump:** the skin shows its seek bar after each jump. Estuary displays it whenever `Player.DisplayAfterSeek` is true, and an add-on cannot suppress it. Hiding it requires a modified skin (`DialogSeekBar.xml`).
- **Keyframes:** seek accuracy depends on Kodi's seeking for the given file and container.

## How it works

- `default.py` is the command run by the key. It stores A and B as properties of the Home window (`abrepeat.a`, `abrepeat.b`).
- `service.py` is a background service. It reads those properties and calls `xbmc.Player().seekTime(A)` when the position reaches B.

## Building and publishing

```bash
./build.sh          # → dist/service.abrepeat-<version>.zip (release asset)
./make_repo.sh      # → site/ (Kodi repository: index.html, repo/addons.xml, zips)
./make_repo.sh -p   # build and force-push site/ to the gh-pages branch (GitHub Pages)
```

To release a new version: bump `version` in `service.abrepeat/addon.xml`, commit, push, run `./make_repo.sh -p`, then create the GitHub release with `./build.sh` and `gh release create vx.y.z dist/service.abrepeat-x.y.z.zip --target main --title vx.y.z --notes "..."`.

## AI disclosure

This add-on was developed with Claude (Anthropic) as a coding assistant. Claude wrote the Python code, this README, the build/repository scripts and the Kodi repository add-on, based on the author's requirements and design choices. The author tested every version on an Nvidia Shield with Kodi, reported problems and directed the fixes. The code is small (two short Python files) and fully readable in this repository.

## License

GPL-2.0-or-later, see [LICENSE](LICENSE).
