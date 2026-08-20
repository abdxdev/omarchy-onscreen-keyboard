# On-Screen Keyboard

![Preview](https://raw.githubusercontent.com/abdxdev/omarchy-onscreen-keyboard/refs/heads/main/preview.png)

A clickable QWERTY keyboard panel for the Omarchy Quattro bar. Types
directly into whatever window currently has focus, using `wtype`.

Declared as a standalone `panel` + `bar-widget` plugin (not a nested
bar-popover) so it's fully independent of the bar's normal
click-away-closes-popouts behavior — it only opens or closes when you
click the bar icon or the panel's own close button.

## Requirements

- `wtype` (`sudo pacman -S wtype`) — injects keystrokes into the
  focused window.
- Hyprland + `hyprctl` — before every keypress the plugin runs
  `hyprctl dispatch focuscurrentorlast` to reclaim focus on the real
  target window first. This works around a known Hyprland quirk where
  clicking a layer-shell surface can leave `hyprctl`'s notion of the
  "current" window pointed at nothing real, even with the panel's
  `keyboardFocus` set to `None`.

## Install

```sh
omarchy plugin add https://github.com/abdxdev/omarchy-onscreen-keyboard.git --enable
```

## Usage

Click the keyboard icon in the bar to open or close the keyboard.
Click the ✕ in the panel to close it, or click the bar icon again.

- **Shift** applies to the next key only, then resets.
- **Caps** toggles and stays on until pressed again.
- **Ctrl / Alt / Super** arm a one-shot modifier combo for the next
  key press (e.g. Ctrl then C sends Ctrl+C).

## Configure

```sh
omarchy bar move io.github.abdxdev.onscreen-keyboard --section right
```

## Remove

```sh
omarchy plugin remove io.github.abdxdev.onscreen-keyboard
```
