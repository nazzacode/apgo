-- apgo tree · { key, desc, kids | action, chord = "M-f", alias = "search words", sticky = true }
-- action: "shell cmd" (failures reported) · function · hl.dsp.* dispatcher
-- key: as typed ("w", "W", "/", "Tab", "space", "Return"). Shown alphabetically; order here is free.
-- chord: the faster direct bind, Emacs notation (M = Super). Taught in the popup.
-- ctx = helpers from hyprland.lua (tab_move, tab_all, cycle_layout, reset_gaps, cheat_toggle, terminal, scratch)
return function(ctx, h)
  local dsp = hl.dsp
  local dms = function(t, f) return "dms ipc call " .. t .. " " .. (f or "toggle") end
  local app = function(id) return "gtk-launch " .. id end
  local edit = function(p) return "code " .. p end
  local layout = function(l) return function() hl.config({ general = { layout = l } }) end end
  local vault = "obsidian://open?vault=Documents"

  return {
    { "space", "launcher", dms("spotlight"), chord = "M-d", alias = "run apps" },
    { "Return", "terminal", ctx.terminal, chord = "M-RET", alias = "alacritty shell" },
    { ".", "repeat last", h.again },

    { "Tab", "workspace", {
      { "Tab", "last workspace", dsp.focus({ workspace = "previous" }), chord = "M-TAB" },
      { "o", "overview", dms("hypr", "toggleOverview"), chord = "M-o" },
      { "r", "rename", dms("workspace-rename", "open"), chord = "M-S-n", alias = "name" },
      { "m", "move to next monitor", dsp.workspace.move({ monitor = "r" }), chord = "M-C-." },
    } },

    { "a", "ai", {
      { "c", "claude", app("webapp-claude"), alias = "chat" },
      { "g", "chatgpt", app("webapp-chatgpt") },
      { "d", "dictate", "voxtype record toggle", chord = "M-s", alias = "voice voxtype" },
    } },

    { "c", "capture", {
      { "r", "region", "dms screenshot region", chord = "M-S-s", alias = "screenshot" },
      { "w", "window", "dms screenshot window", chord = "C-Print", alias = "screenshot" },
      { "s", "screen", "dms screenshot full", chord = "S-Print", alias = "screenshot" },
      { "c", "colour picker", dms("color-picker"), alias = "color" },
    } },

    { "d", "display", {
      { "w", "pick wallpaper", "wallpick", chord = "M-w" },
      { "]", "next wallpaper", "livewall next" },
      { "W", "wallpaper off", "livewall off" },
      { "p", "pause wallpaper", "livewall pause" },
      { "P", "resume wallpaper", "livewall resume" },
      { "b", "brightness", { -- DMS: DDC on desktop monitor, backlight on laptop (brightnessctl only sees LEDs here)
        { "k", "brighter", dms("brightness", "increment 5 ''") },
        { "j", "dimmer", dms("brightness", "decrement 5 ''") },
      }, sticky = true },
    } },

    { "h", "help", {
      { "k", "key cheat sheet", ctx.cheat_toggle, chord = "M-/" },
      { "d", "DMS key list", dms("keybinds", "toggle nathanos") },
    } },

    { "l", "layout", {
      { "d", "dwindle", layout("dwindle") },
      { "m", "master", layout("master") },
      { "c", "centred", layout("lua:centred") },
      { "s", "scrolling", layout("scrolling") },
      { "\\", "cycle", ctx.cycle_layout, chord = "M-\\" },
      { "g", "gaps reset", ctx.reset_gaps, chord = "M-C-0" },
      { "r", "resize mode", dsp.submap("resize"), chord = "M-r" },
    } },

    { "m", "media", {
      { "space", "play / pause", "playerctl play-pause" },
      { "n", "next", "playerctl next" },
      { "p", "previous", "playerctl previous" },
      { "m", "mute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" },
      { "M", "mute mic", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", alias = "microphone" },
      { "o", "next output", dms("audio", "cycleoutput"), alias = "speakers headphones device" },
      { "v", "volume", {
        { "k", "louder", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" },
        { "j", "quieter", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" },
      }, sticky = true },
    } },

    { "n", "notes", {
      { "c", "quick capture", dms("notepad"), alias = "notepad scratch" },
      { "t", "nathanOS tasks", edit(os.getenv("HOME") .. "/Documents/projects/nathanOS/tasks.md") },
    } },

    { "o", "open", {
      { "/", "search all apps", dms("spotlight"), chord = "M-d", alias = "find launcher" },
      { "a", "anki", app("anki") },
      { "b", "browser", "flatpak run app.zen_browser.zen", alias = "zen firefox web" },
      { "C", "calendar", app("webapp-google-calendar") },
      { "c", "vscode", app("code"), alias = "code editor" },
      { "e", "emacs", app("emacsclient") },
      { "f", "files", "nautilus --new-window", chord = "M-e", alias = "nautilus" },
      { "g", "gmail", app("webapp-gmail"), alias = "mail" },
      { "l", "linear", app("webapp-linear") },
      { "m", "maps", app("webapp-google-maps") },
      { "o", "onshape", app("webapp-onshape"), alias = "cad" },
      { "n", "obsidian", app("obsidian"), alias = "notes" },
      { "p", "pocket casts", app("webapp-pocket-casts"), alias = "podcasts" },
      { "r", "reader", app("webapp-reader"), alias = "readwise reading articles" },
      { "s", "spotify", app("spotify"), alias = "music" },
      { "S", "syncthing", app("webapp-syncthing") },
      { "T", "translate", app("webapp-google-translate") },
      { "v", "vivaldi", app("vivaldi-stable"), alias = "web" },
      { "w", "whatsapp", app("webapp-whatsapp") },
    } },

    { "q", "session", {
      { "l", "lock", dms("lock", "lock"), chord = "M-ESC" },
      { "s", "suspend", "systemctl suspend", alias = "sleep" },
      { "m", "power menu", dms("powermenu"), chord = "M-S-ESC" },
      { "R", "reboot", "systemctl reboot", alias = "restart" },     -- capitals: destructive
      { "P", "power off", "systemctl poweroff", alias = "shutdown" },
      { "E", "log out", dsp.exit(), alias = "exit hyprland" },
    } },

    { "s", "shell", {
      { "n", "notifications", dms("notifications"), chord = "M-n" },
      { "c", "control centre", dms("control-center"), chord = "M-p", alias = "quick settings" },
      { "d", "dashboard", dms("dash") },
      { "p", "processes", ctx.terminal .. " -e btop", alias = "btop top" },
      { "v", "clipboard", dms("clipboard"), chord = "M-S-v" },
    } },

    { "t", "toggles", {
      { "b", "bluetooth", "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on" },
      { "w", "wifi", "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on" },
      { "d", "do not disturb", "dms ipc call notifications toggleDoNotDisturb", alias = "dnd" },
      { "n", "night light", dms("night"), alias = "blue light" },
      { "i", "idle inhibit", dms("inhibit"), alias = "caffeine keep awake" },
      { "B", "bar", dms("bar"), alias = "panel" },
      { "t", "dark / light", dms("theme"), chord = "M-S-t", alias = "dark mode light mode theme" },
    } },

    { "x", "scratch", { -- T48, hypr/scratch.lua
      { "x", "scratch layer", ctx.scratch.toggle, chord = "M-,", alias = "show hide" },
      { "s", "window into / out of scratch", ctx.scratch.in_out, chord = "M-S-," },
      { "d", "drop-down terminal", ctx.scratch.term, chord = "M-S-RET", alias = "quake" },
      { "t", "terminal into scratch", ctx.scratch.scratch_term, alias = "new shell" },
      { "c", "slot: centre", ctx.scratch.to("c") },
      { "h", "slot: left", ctx.scratch.to("l") },
      { "l", "slot: right", ctx.scratch.to("r") },
      { "k", "slot: top", ctx.scratch.to("t") },
      { "j", "slot: bottom", ctx.scratch.to("b") },
    } },

    { "w", "window", {
      { "h", "focus left", dsp.focus({ direction = "left" }), chord = "M-h" },
      { "j", "focus down", dsp.focus({ direction = "down" }), chord = "M-j" },
      { "k", "focus up", dsp.focus({ direction = "up" }), chord = "M-k" },
      { "l", "focus right", dsp.focus({ direction = "right" }), chord = "M-l" },
      { "H", "move left", ctx.tab_move("left"), chord = "M-S-h" },
      { "J", "move down", ctx.tab_move("down"), chord = "M-S-j" },
      { "K", "move up", ctx.tab_move("up"), chord = "M-S-k" },
      { "L", "move right", ctx.tab_move("right"), chord = "M-S-l" },
      { "f", "fullscreen", dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), chord = "M-f" },
      { "m", "maximise", dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), chord = "M-m" },
      { "v", "float", dsp.window.float({ action = "toggle" }), chord = "M-v" },
      { "p", "pin", dsp.window.pin() },
      { "c", "centre", dsp.window.center(), chord = "M-c" },
      { "q", "close", dsp.window.close(), chord = "M-q" },
      { "x", "kill (force)", dsp.window.kill() },
      { ">", "send to next monitor", dsp.window.move({ monitor = "r", follow = false }), chord = "M-S-." },
      { "u", "urgent / last window", dsp.focus({ urgent_or_last = true }), chord = "M-u" },
      { "t", "tabs on / off", ctx.tab_all, chord = "M-t", alias = "group" },
      { "]", "next tab", dsp.group.next(), chord = "M-]" },
      { "[", "previous tab", dsp.group.prev(), chord = "M-[" },
      { "i", "tab into left", dsp.window.move({ into_or_create_group = "left" }), chord = "M-i" },
      { "o", "pop out of tabs", dsp.window.move({ out_of_group = true }), chord = "M-S-o" },
    } },

    { ",", "config", {
      { "h", "edit hyprland.lua", edit(os.getenv("HOME") .. "/.config/nixos/dotfiles/hypr/hyprland.lua") },
      { "k", "edit leader tree", edit(os.getenv("HOME") .. "/.config/nixos/dotfiles/apgo/tree.lua") },
      { "n", "edit nixos", edit(os.getenv("HOME") .. "/.config/nixos") },
      { "r", "reload hyprland", "hyprctl reload", chord = "M-S-r" },
      { "s", "DMS settings", dms("settings") },
    } },
  }
end
