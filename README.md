# ALTIMIT Mine OS

A launcher HUD for Wayland desktops modeled after the **ALTIMIT MINE OS** desktop from *.hack//G.U.*, built with [Quickshell](https://quickshell.org) (QML / Qt Quick) and a real-time 3D carousel rendered with QtQuick3D.

> [!NOTE]
> This is an unofficial fan project. It is not affiliated with, endorsed by, or associated with Bandai Namco Entertainment or CyberConnect2 in any way. No files were extracted from the games; every asset was recreated from scratch.

> [!IMPORTANT]
> **AI disclosure.** The original project, [dotHack-firefox-newtab](https://github.com/guiarnaldo/dotHack-firefox-newtab), was written by hand in HTML/CSS years ago, together with all of its artwork. This Quickshell / Qt 6 version was translated from that code by AI; I only made some tweaks to make it look cool.

## Requirements

| Component | Notes |
|---|---|
| Wayland compositor with `zwlr_layer_shell_v1` | Hyprland, niri, Sway, river, KDE Plasma, etc. GNOME (Mutter) does **not** implement layer-shell |
| Quickshell | Tested against 0.3.x |
| Qt 6 QtQuick3D QML module | Arch: `qt6-quick3d` · Fedora: `qt6-qtquick3d` · Debian/Ubuntu: `qml6-module-qtquick3d` |
| Qt ≥ 6.7 | Required for `font.variableAxes` (variable font width) |
| Fonts (optional) | [Archivo](https://fonts.google.com/specimen/Archivo) and [M PLUS 1p](https://fonts.google.com/specimen/M+PLUS+1p). Missing fonts fall back to the system `sans-serif` |

## Installation

```bash
git clone https://github.com/guiarnaldo/dotHack-quickshell ~/.config/quickshell/altimit
cd ~/.config/quickshell/altimit
cp apps.example.json apps.json
```

The `cp` step is **required on first install**. `apps.json` is the live configuration and is listed in `.gitignore`, so local changes are never overwritten by `git pull`. `apps.example.json` is the tracked reference. Check it after updates for new options.

## Usage

```bash
qs -c altimit -d                         # start the shell daemonized
qs -c altimit ipc call altimit toggle    # open / close
qs -c altimit ipc call altimit options   # open the HUD with the options panel raised
qs -c altimit ipc call altimit wifi      # open the options panel directly on Wi-Fi
qs -c altimit ipc call altimit bluetooth # open the options panel directly on Bluetooth
qs -c altimit ipc call altimit background # open the options panel directly on BG Setting
qs -c altimit ipc call altimit mail      # open the HUD on the Mail Station
```

Notifications are shown at the top-right corner of the screen. Hovering a popup pauses its timer, the × button hides it, and clicking it runs the sender's default action (or opens the mail in the Mail Station when there is none). Hidden popups stay in the Mail Station inbox until deleted. To test:

```bash
notify-send "Mail Station" "There are important unread mails in Mail Station." -i mail-unread
```

Hyprland example:

```ini
exec-once = qs -c altimit -d
exec-once = wl-paste --watch cliphist store   # clipboard history for the Mail Station Outbox
bind = SUPER, SPACE, exec, qs -c altimit ipc call altimit toggle
```

| Input | Action |
|---|---|
| `←` `→` / `↑` `↓` / mouse wheel | Rotate the carousel |
| `Enter` / `Space` / click on selector | Launch the selected entry |
| `Esc` | Close |

## Configuration

`apps.json`:

```json
{
  "hintBar": true,
  "wallpaper": "AltimitMineOs.jpg",
  "font": "Archivo",
  "fontWidth": 125,
  "hintFont": "M PLUS 1p",
  "apps": [
    { "title": "The World", "desktop": "firefox", "icon": "theworld2.png" },
    { "title": "Mail Station", "icon": "mail2.png", "command": ["xdg-open", "https://mail.google.com"] }
  ]
}
```

### Global options

| Key | Type | Default | Description |
|---|---|---|---|
| `hintBar` | bool | `true` | Show the grey hint bar at the bottom |
| `wallpaper` | string | `""` | Default wallpaper, used for screens without a BG Setting assignment and for `000 Default`. Relative to `assets/`, absolute, or `~/`-prefixed. Empty or omitted gives a transparent background |
| `wallpaperDir` | string | `""` | Folder listed by the Background option (`~/` allowed) |
| `desktopWallpaper` | bool | `true` | Draw the desktop wallpaper on every screen (layer-shell `Background`). Disable to use an external wallpaper daemon |
| `font` | string | `"Archivo"` | Font family for the info box |
| `fontWidth` | number | `125` | `wdth` axis for variable fonts, in percent. `125` gives Archivo Expanded. Ignored by static fonts |
| `hintFont` | string | `"M PLUS 1p"` | Font family for the hint bar |
| `notifications` | bool | `true` | Run the built-in notification daemon (top-right popups). Disable it when using mako, dunst, swaync or another daemon, since only one can own `org.freedesktop.Notifications` |
| `notificationHistory` | bool | `true` | Keep notifications in the Mail Station after their popup closes (also across Quickshell reloads). When `false`, closing a popup discards the notification |
| `clipboardHistory` | bool | `true` | Show the [cliphist](https://github.com/sentriz/cliphist) history in the Mail Station Outbox. Needs `cliphist` and `wl-clipboard`, with `wl-paste --watch cliphist store` running |
| `notificationScreen` | string | `""` | Monitor that shows the notification popups, by output name (`hyprctl monitors` lists them, e.g. `DP-1`, `HDMI-A-1`). Empty or unknown names leave the choice to the compositor (on Hyprland, the focused monitor) |
| `notificationTimeout` | number | `6` | Seconds a popup stays on screen when the sender does not set a timeout. Critical notifications stay until closed |
| `options` | string[] | `["wifi", "bluetooth", "background"]` | Categories shown in the options panel, in this order. Valid values: `wifi`, `bluetooth`, `background`. Remove an entry to hide it |
| `apps` | array | `[]` | Carousel entries, in order |

### App entries

| Key | Type | Description |
|---|---|---|
| `title` | string | Name shown in the info box. Defaults to the desktop entry name |
| `description` | string | Info box text. Defaults to the desktop entry comment |
| `icon` | string | Carousel icon (relative to `assets/`, absolute, or a URL) |
| `iconBox` | string | Info box icon. Defaults to `icon` |
| `desktop` | string | Desktop entry to launch |
| `command` | string[] | Command to run instead of the desktop entry |
| `options` | bool | Open the options panel instead of launching anything |
| `mail` | bool | Open the Mail Station (notification inbox) instead of launching anything. Shows a `NEW` badge on the icon while there are unread notifications |

### Mail Station

The Mail Station opens on the folder screen (Inbox, Outbox, Address). The Inbox lists every notification kept by the built-in daemon, newest first. The Outbox ("Send greeting card.") lists the clipboard history from cliphist: the Type column shows `Text` or `Image` and the Preview pane shows the full text or the image of the selected entry. `Enter` or a double click copies it back to the clipboard without leaving the list. Address is decorative and always empty. While the Mail Station is open its own footer replaces the HUD hint bar. Sender is the app name, Subject is the notification title and `NEW` marks unread ones. Opening a mail shows the notification image (or the sender's icon when there is none), the body and the notification's actions.

| Input | Action |
|---|---|
| `←` `→` / mouse wheel | Choose a folder (folder screen) |
| `Enter` / double click | Open the folder, read the selected mail (Outbox: copy the selected entry), or run the default action (open mail) |
| `↑` `↓` / `PgUp` `PgDn` / mouse wheel | Move the selection (inbox) or scroll the mail |
| `1`–`9` / click | Run the matching action of the open mail |
| `Del` | Delete the selected or open mail (Outbox: remove the entry from cliphist) |
| `Shift` + `Del` | Delete every mail (Inbox only) |
| `Esc` | Back one level: mail → inbox → folders → carousel |

A top-level array (legacy format) is still accepted and is treated as `apps` with all other options at their defaults.

### Wallpaper

The wallpaper is optional. Without one, the HUD background is transparent and the desktop stays visible behind the carousel.

`apps.example.json` points to `assets/AltimitMineOs.jpg`. To get the original look, place an image at that path, or set `wallpaper` in `apps.json` to any other image. If the configured file does not exist, the background is transparent as well (Qt logs a `Cannot open` warning).

## Contributing

Format every QML file before committing and pushing:

```bash
qmlformat -i -n *.qml
```

`-i` rewrites the files in place and `-n` normalizes attribute order (id, properties, signals, functions, child objects) according to the QML Coding Conventions. `qmlformat` ships with Qt Declarative (`qt6-declarative` on Arch, `qt6.qtdeclarative` on NixOS).

## License

Released under the [MIT License](LICENSE). This covers the source code and the hand-drawn assets in `assets/`. It does not grant any rights to *.hack//G.U.* or any other Bandai Namco Entertainment / CyberConnect2 intellectual property referenced by this project.

## Credits

- Original concept, UI design and trademarks: *.hack//G.U.* Bandai Namco Entertainment / CyberConnect2. Referenced here for non-commercial fan purposes only.
- Fonts (not bundled): [Archivo](https://fonts.google.com/specimen/Archivo) by Omnibus-Type and [M PLUS 1p](https://fonts.google.com/specimen/M+PLUS+1p) by M+ Fonts Project, both under the SIL Open Font License.