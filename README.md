# apgo

A leader key for Hyprland. Tap Super, then type a few letters to run anything on the desktop.

The name is short for *arpeggio*: the notes of a chord played one after another. `Super+Shift+s` is a chord; `␣ c r` is the same command as an arpeggio, and it reads as a phrase: *capture, region*.

Part of [YOTLAND](https://github.com/nazzacode), a keyboard-driven Linux desktop.

## How it works

- Tap Super on its own (or bind any key to `apgo.open()`). A small pill appears.
- Type letters to walk a menu tree: `o b` opens the browser, `w f` toggles fullscreen.
- Pause and the full panel opens, listing the next keys alphabetically.
- Each entry shows its direct bind, so the menu teaches you the faster chord.
- `/` searches every entry by name and alias. A command that fails shows a red pill.
- Every run is logged. `apgo-stats` shows what you use most, so you can reshape the tree around it.

## Philosophy

Borrowed from Emacs: which-key and the Spacemacs `SPC` leader.

- **Discoverable.** Nothing has to be memorised first; the next choices appear when you hesitate.
- **Mnemonic.** Letters follow meaning: the role key first, then the first letter, then a capital, then the second letter.
- **Teaches chords.** Frequent commands graduate from menu paths to muscle memory.
- **Shaped by use.** The usage log, not guesswork, decides what goes near the root.
- **One file.** The whole menu is `tree.lua`. Save and reload; no rebuild.

## Requirements

- Hyprland 0.56+ with a **Lua** config (`hyprland.lua`). apgo builds its menus as Hyprland submaps.
- [Quickshell](https://quickshell.outfoxxed.me) (`qs`) for the popup.
- Optional: [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell). The popup takes its colours from DMS's `dms-colors.json` and follows its dark/light mode.
- Optional: [keyd](https://github.com/rvaiya/keyd), to make a lone tap of Super the leader (see `extras/`).

## Install

```sh
git clone https://github.com/nazzacode/apgo ~/.config/apgo
```

In `hyprland.lua`:

```lua
-- load the engine; ctx is passed through to tree.lua (add whatever your tree needs)
dofile(os.getenv("HOME") .. "/.config/apgo/apgo.lua")({ terminal = "foot" }).apply({ delay = 250 })

-- leader on Super+Space, and on a lone Super tap if you use extras/keyd.conf
hl.bind("SUPER + space", function() apgo.open() end)
hl.bind("XF86Tools", function() apgo.open() end)

-- start the popup with the session, and let Hyprland blur it
hl.on("hyprland.start", function() hl.exec_cmd("qs -p " .. os.getenv("HOME") .. "/.config/apgo/shell -n -d") end)
hl.layer_rule({ name = "apgo-glass", match = { namespace = "^apgo:.*$" }, blur = true, ignore_alpha = 0.05 })
```

Optional `ctx` keys: `dir` (install path, default: where `apgo.lua` lives), `tree` (path to your tree file), `state_dir` (default `$XDG_STATE_HOME/apgo`).

## The tree

```lua
{ key, desc, kids | action, chord = "M-f", alias = "search words", sticky = true }
```

- `action`: a shell command string, a Lua function, or an `hl.dsp.*` dispatcher.
- `key`: as typed: `"w"`, `"W"`, `"/"`, `"Tab"`, `"space"`, `"Return"`.
- `chord`: the direct bind for the same action, in Emacs notation (`M` = Super, `S` = Shift, `C` = Ctrl, `A` = Alt). Shown as a hint.
- `sticky`: the group stays open after a run (volume, brightness).

`tree.lua` is a small starting menu. `examples/nathanos-tree.lua` is the full tree from the author's desktop (138 entries); it expects helpers from that config, so read it for ideas rather than loading it as is.

## Pieces

| Path | What |
|---|---|
| `apgo.lua` | Engine: tree → Hyprland submaps (`arp`, `arp/w`, …), runs leaves, writes popup data |
| `tree.lua` | Your menu |
| `shell/` | Quickshell popup, plus an optional key sheet (`call apgo sheet`) that reads `$XDG_STATE_HOME/apgo/keys.json` if your config writes one. Draws only; Hyprland owns the keys |
| `bin/apgo-run` | Runs shell leaves; a non-zero exit within 1.5 s shows in the popup and `journalctl -t apgo` |
| `bin/apgo-stats [days]` | Most-used paths from the usage log |
| `extras/keyd.conf`, `extras/keyd.nix` | Lone Super tap → F13 (`XF86Tools`) |

IPC: `qs ipc -p <dir>/shell call apgo search|hide|sheet`. From Lua: `apgo.open()`, `apgo.run("w/f")`.

## Licence

MIT
