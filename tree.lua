-- apgo tree · a small starting menu. Shown alphabetically; order here is free.
-- Entry: { key, desc, kids | action, chord = "M-f", alias = "search words", sticky = true }
--   action: "shell command" (failures show in the popup) · Lua function · hl.dsp.* dispatcher
--   key: as typed ("w", "W", "/", "Tab", "space", "Return")
--   chord: the direct bind for the same action, Emacs notation (M = Super). The popup teaches it.
-- ctx = whatever you passed to apgo from hyprland.lua. A full real-world tree: examples/nathanos-tree.lua
return function(ctx, h)
  local dsp = hl.dsp
  local term = ctx.terminal or "foot"

  return {
    { "Return", "terminal", term, chord = "M-RET" },
    { ".", "repeat last", h.again },

    { "o", "open", {
      { "b", "browser", "xdg-open https://", alias = "web" },
      { "f", "files", "nautilus --new-window", alias = "file manager" },
      { "t", "terminal", term },
    } },

    { "w", "window", {
      { "f", "fullscreen", dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), chord = "M-f" },
      { "v", "float", dsp.window.float({ action = "toggle" }), chord = "M-v" },
      { "q", "close", dsp.window.close(), chord = "M-q" },
      { "h", "focus left", dsp.focus({ direction = "left" }), chord = "M-h" },
      { "l", "focus right", dsp.focus({ direction = "right" }), chord = "M-l" },
    } },

    { "Tab", "workspace", {
      { "Tab", "last workspace", dsp.focus({ workspace = "previous" }), chord = "M-TAB" },
      { "n", "next", dsp.focus({ workspace = "r+1" }) },
      { "p", "previous", dsp.focus({ workspace = "r-1" }) },
    } },

    { "m", "media", {
      { "space", "play / pause", "playerctl play-pause" },
      { "n", "next", "playerctl next" },
      { "v", "volume", {
        { "k", "louder", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" },
        { "j", "quieter", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" },
      }, sticky = true },
    } },

    { "q", "session", {
      { "l", "lock", "loginctl lock-session" },
      { "s", "suspend", "systemctl suspend", alias = "sleep" },
      { "R", "reboot", "systemctl reboot" }, -- capitals for destructive actions
    } },
  }
end
