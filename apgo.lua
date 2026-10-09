-- apgo · leader-key engine for Hyprland (Lua config). https://github.com/nazzacode/apgo
-- Hyprland submaps own the keys; the Quickshell popup (shell/) only draws, following `submap>>arp/…` events.
-- Loaded by hyprland.lua: dofile(<this>)(ctx).apply(). Tree: ctx.tree or <dir>/tree.lua. Live: edit + reload, no rebuild.
-- ctx: anything your tree needs (passed through), plus optional ctx.dir, ctx.tree, ctx.state_dir.
--
-- Submaps: "arp" = root, "arp/w" = window, "arp/w/x" … Leaves run through A.run(path) so keys, clicks
-- and search share one path: reset submap → action → tell popup (teach chord) · shell failures → popup + notify.
return function(ctx)
  local A = {}
  local HOME = os.getenv("HOME")
  local here = debug and debug.getinfo and (debug.getinfo(1, "S").source or ""):match("^@(.*)/[^/]*$")
  A.dir = ctx.dir or here or (HOME .. "/.config/apgo")
  local SHELL = A.dir .. "/shell"
  local RUN = A.dir .. "/bin/apgo-run"

  local STATE = (function()
    local x = os.getenv("XDG_STATE_HOME")
    return ctx.state_dir or (((x and x ~= "") and x or (HOME .. "/.local/state")) .. "/apgo")
  end)()
  local q = function(s) return "'" .. tostring(s):gsub("'", "'\\''") .. "'" end
  local ipc = function(fn, ...)
    local args = {}
    for _, a in ipairs({ ... }) do args[#args + 1] = q(a) end
    return "qs ipc -p " .. q(SHELL) .. " call apgo " .. fn .. " " .. table.concat(args, " ")
  end
  -- [q]: else pgrep matches the sh -c running this very line and the popup never starts
  A.ensure = "pgrep -f " .. q("[q]uickshell -p " .. SHELL) .. " >/dev/null || qs -p " .. q(SHELL) .. " -d"

  -- typed char → Hyprland key string ("W" → "SHIFT + w", "/" → "slash", ">" → "SHIFT + period")
  local NAME = {
    ["/"] = "slash", [","] = "comma", ["."] = "period", ["["] = "bracketleft", ["]"] = "bracketright",
    ["\\"] = "backslash", ["="] = "equal", ["-"] = "minus", ["`"] = "grave", [";"] = "semicolon", ["'"] = "apostrophe",
  }
  local SHIFTED = { [">"] = "period", ["<"] = "comma", ["?"] = "slash", ["+"] = "equal", ["_"] = "minus", ["~"] = "grave", [":"] = "semicolon" }
  local hkey = function(k)
    if SHIFTED[k] then return "SHIFT + " .. SHIFTED[k] end
    if NAME[k] then return NAME[k] end
    if #k == 1 and k:match("%u") then return "SHIFT + " .. k:lower() end
    return k -- a, 1, Tab, space, Return, BackSpace …
  end

  -- every key a menu may use; unused ones close the menu
  local PRINTABLE = { "space", "Return", "Tab" }
  for c in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do PRINTABLE[#PRINTABLE + 1] = c; PRINTABLE[#PRINTABLE + 1] = c:upper() end
  for c in ("0123456789/,.[]\\=-`;'><?"):gmatch(".") do PRINTABLE[#PRINTABLE + 1] = c end

  -- tree ------------------------------------------------------------------
  -- node = { key, desc, kids | action, chord?, alias?, sticky? }
  -- action: string = shell cmd · function · Hyprland dispatcher (userdata)
  local again = function() if A.last then A.run(A.last) end end
  local tree = dofile(ctx.tree or (A.dir .. "/tree.lua"))(ctx, { ipc = ipc, again = again })
  local isgroup = function(n) return type(n[3]) == "table" and n[3][1] ~= nil and type(n[3][1]) == "table" end

  local index = {} -- "w/f" → node
  local function walk(nodes, prefix)
    for _, n in ipairs(nodes) do
      local p = prefix == "" and n[1] or (prefix .. "/" .. n[1])
      index[p] = n
      if isgroup(n) then walk(n[3], p) end
    end
  end
  walk(tree, "")

  -- run --------------------------------------------------------------------
  A.last = nil
  local act = function(n)
    local a = n[3]
    if type(a) == "string" then hl.exec_cmd(RUN .. " " .. q(n[2]) .. " " .. q(a))
    elseif type(a) == "function" then a()
    else hl.dispatch(a) end
  end

  A.run = function(path, keep)
    local n = index[path]
    if not n or isgroup(n) then return end
    if not keep then hl.dispatch(hl.dsp.submap("reset")) end
    local ok, err = pcall(act, n)
    if path ~= "." then A.last = path end
    -- usage log → data for the menu v2 (what earns a chord, what never gets used): `apgo-stats`
    local log = io.open(STATE .. "/apgo-usage.log", "a")
    if log then log:write(os.date("%Y-%m-%dT%H:%M:%S"), "\t", path, "\t", n[2], "\n"); log:close() end
    if ok then hl.exec_cmd(ipc("ran", path))
    else hl.exec_cmd(ipc("fail", n[2], tostring(err))) end
  end

  A.open = function(path)
    hl.exec_cmd(A.ensure)
    hl.dispatch(hl.dsp.submap(path and path ~= "" and ("arp/" .. path) or "arp"))
  end

  -- submaps ----------------------------------------------------------------
  local function define(name, parent, nodes, sticky)
    local sub = function(n) return name == "arp" and n[1] or (name:sub(5) .. "/" .. n[1]) end
    hl.define_submap(name, function()
      local used = {}
      for _, n in ipairs(nodes) do
        local p = sub(n)
        used[n[1]] = true
        if isgroup(n) then
          hl.bind(hkey(n[1]), hl.dsp.submap("arp/" .. p), { description = "+" .. n[2] })
        else
          hl.bind(hkey(n[1]), function() A.run(p, sticky) end, { description = n[2], repeating = sticky or nil })
        end
      end
      hl.bind("Escape", hl.dsp.submap("reset"))
      if sticky then hl.bind("Return", hl.dsp.submap("reset")) end
      hl.bind("BackSpace", hl.dsp.submap(parent or "reset"))
      if not used["/"] then used["/"] = true; hl.bind("slash", function() hl.dispatch(hl.dsp.submap("reset")); hl.exec_cmd(ipc("search")) end) end
      -- unknown key closes, so you're never trapped. Not `catchall`: in Hyprland it fires alongside
      -- the specific bind, so every key also closed the menu (found 2026-10-05).
      for _, k in ipairs(PRINTABLE) do
        if not used[k] then hl.bind(hkey(k), hl.dsp.submap("reset")) end
      end
    end)
    for _, n in ipairs(nodes) do
      if isgroup(n) then define("arp/" .. sub(n), name, n[3], n.sticky) end
    end
  end

  -- popup data: $XDG_STATE_HOME/apgo/apgo.json
  local str = function(s) return '"' .. tostring(s):gsub('[%c"\\]', function(c) return ("\\u%04x"):format(c:byte()) end) .. '"' end
  local function enc(nodes, prefix)
    local out = {}
    for _, n in ipairs(nodes) do
      local p = prefix == "" and n[1] or (prefix .. "/" .. n[1])
      local f = { '"k":' .. str(n[1]), '"d":' .. str(n[2]), '"p":' .. str(p) }
      if n.chord then f[#f + 1] = '"chord":' .. str(n.chord) end
      if n.alias then f[#f + 1] = '"alias":' .. str(n.alias) end
      if n.sticky then f[#f + 1] = '"sticky":true' end
      if isgroup(n) then f[#f + 1] = '"kids":' .. enc(n[3], p) end
      out[#out + 1] = "{" .. table.concat(f, ",") .. "}"
    end
    return "[" .. table.concat(out, ",") .. "]"
  end

  local write = function(body)
    local x = os.getenv("XDG_STATE_HOME")
    local dir = ctx.state_dir or (((x and x ~= "") and x or (HOME .. "/.local/state")) .. "/apgo")
    local path = dir .. "/apgo.json"
    local f = io.open(path, "r")
    if f then
      local old = f:read("*a"); f:close()
      if old == body then return end
    else
      os.execute("mkdir -p " .. q(dir))
    end
    f = io.open(path .. ".tmp", "w")
    if f then f:write(body); f:close(); os.rename(path .. ".tmp", path) end
  end

  A.apply = function(opts)
    opts = opts or {}
    define("arp", nil, tree)
    write('{"delay":' .. (opts.delay or 500) .. ',"tree":' .. enc(tree, "") .. "}\n")
    apgo = A -- global: popup clicks/search call apgo.run("w/f") via hyprctl dispatch
    return A
  end

  return A
end
