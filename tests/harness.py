"""A small simulated norns for testing sci.lua without hardware.

It fakes the norns APIs sci uses (clock, params, midi, grid, screen,
softcut, audio, util, tab), loads sci.lua with a few test hooks added,
and then runs a test script written in Lua.

    pip install lupa
    python3 tests/harness.py sci.lua tests/korg_controllers.lua

Test scripts call init(), then _expose() to reach the script's internals.
Useful globals while a test runs:
    advance(n)  move the clock n ticks (96 ticks = 1 beat)
    log         MIDI notes/bends/CC/pressure sent: {"on", note, ch, port, vel}
    SENT        raw messages sent with :send() (thru)
    sc          every softcut call; sclast(name, voice), sccount(name)
    LED         grid LEDs after a redraw: LED[y*100 + x]
    SC          screen calls from the last redraw
    WALL        wall-clock seconds returned by util.time()
    RUNNOW      when true, clock.run runs its function at once
    FS          files written by tab.save / buffer_write_mono

A test fails if it raises a Lua error; values are printed for checking.
"""
import sys
import lupa

MOCK = r'''
log = {}; sc = {}; SENT = {}; LED = {}; SC = {}; FS = {}; outs = {}
WALL = 0
local beats = 0
clock = {
  get_beats = function() return beats end,
  get_beat_sec = function() return 0.5 end,          -- 120 bpm
  run = function(f) if RUNNOW then f() end return 1 end,
  sync = function() end, cancel = function() end, sleep = function() end,
}
function advance(n) for i = 1, n do beats = beats + 1/96; _tick() end end

util = {
  clamp = function(x, a, b) return math.max(a, math.min(b, x)) end,
  file_exists = function(p) return FS[p] ~= nil end,
  make_dir = function() end,
  time = function() return WALL end,
}
_path = {data = "/data/"}
local function deep(t)
  if type(t) ~= "table" then return t end
  local o = {}
  for k, v in pairs(t) do o[k] = deep(v) end
  return o
end
tab = {save = function(t, p) FS[p] = deep(t) end, load = function(p) return deep(FS[p]) end}
os.remove = function(p) FS[p] = nil end
os.rename = function(a, b) FS[b] = FS[a]; FS[a] = nil end

local P = {}
params = {
  add_separator = function() end, add_group = function() end,
  add_option = function(s, id, n, o, d) P[id] = d end,
  add_number = function(s, id, n, lo, hi, d) P[id] = d end,
  add_control = function(s, id, n, cs) P[id] = cs.default end,
  set_action = function(s, id, f) f(P[id]) end,
  bang = function() end,
  get = function(s, id) return P[id] end,
  set = function(s, id, v) P[id] = v end,
  delta = function(s, id, d) P[id] = P[id] + d end,
  write = function(s, p) FS[p] = true end,
}
controlspec = {new = function(a, b, c, d, def) return {default = def} end}

local function mkout(name) return {
  name = name,
  pitchbend = function(s, v, ch) table.insert(log, {"pb", v, ch, name}) end,
  cc = function(s, cc, v, ch) table.insert(log, {"cc", v, ch, name}) end,
  channel_pressure = function(s, v, ch) table.insert(log, {"at", v, ch, name}) end,
  note_on = function(s, n, v, ch) table.insert(log, {"on", n, ch, name, v}) end,
  note_off = function(s, n, v, ch) table.insert(log, {"off", n, ch, name}) end,
  send = function(s, d) table.insert(SENT, {name, d[1], d[2], d[3]}) end,
} end
midi = {
  vports = {
    {name = "LinnStrument MIDI"}, {name = "Electra Controll 1"},
    {name = "Electra Controll 2"}, {name = "Electra Controll 3"},
    {name = "ttymidi"}, {name = "nanoKEY2"}, {name = "nanoPAD2"},
  },
  connect = function(i) outs[i] = outs[i] or mkout("port" .. i) return outs[i] end,
  to_msg = function(d) return d end,   -- tests pass already-decoded messages
}
grid = {connect = function() return {
  all = function() LED = {} end,
  led = function(s, x, y, v) LED[y * 100 + x] = v end,
  refresh = function() end,
} end}
metro = {init = function() return {start = function() end} end}
screen = setmetatable({}, {__index = function(_, k)
  return function(...) table.insert(SC, {k, ...}) end end})
audio = setmetatable({}, {__index = function() return function() end end})
softcut = setmetatable({}, {__index = function(_, k) return function(...)
  local a = {...}
  table.insert(sc, {k, a[1], a[2], a[3], a[4], a[5], a[6]})
  if k == "buffer_write_mono" then FS[a[1]] = true end
end end})
function sclast(name, v)
  for i = #sc, 1, -1 do local e = sc[i]; if e[1] == name and e[2] == v then return e end end
end
function sccount(name)
  local c = 0
  for _, e in ipairs(sc) do if e[1] == name then c = c + 1 end end
  return c
end
'''

EXPOSE = '''function _expose() return {
  on_midi = on_midi, gk = function(...) g.key(...) end, key = key, enc = enc,
  tr = function(t) return tracks[t] end, sel = function() return sel end,
  page = function() return page end, setpage = function(p) page = p end,
  head = function() return head end, setplay = function() playing = true end,
  setplay2 = function() playing = true; drum_tick = 0 end,
  set_reverse = set_reverse, set_target = set_target,
  brake = function(b) braking = b end, speed = function() return speed end,
  alen = function() return a_len end, state = a_state,
  pending = function() return #pending end, now = now, P = params,
  CTL = CTL, outs = outs, lanes = lanes, redraw_grid = grid_redraw,
  setflash = function() page_flash_t = util.time() end,
} end
SAVE = function(n) save_slot(n) end
DEL = function(n) delete_slot(n) end
-- init ---'''


def load(script_path):
    """Return a Lua runtime with the mocks and sci.lua (plus test hooks) loaded."""
    L = lupa.LuaRuntime()
    L.execute(MOCK)
    src = open(script_path).read()
    for marker in ("local function ticker()", "-- init ---"):
        if marker not in src:
            raise SystemExit(f"harness: can't find '{marker}' in {script_path}")
    src = src.replace("local function ticker()",
                      "function _tick() tape_tick() end\nlocal function ticker()", 1)
    src = src.replace("-- init ---", EXPOSE, 1)
    L.execute(src)
    return L


def run(script_path, test_path):
    L = load(script_path)
    L.execute(open(test_path).read())
    return L


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: python3 tests/harness.py sci.lua tests/<test>.lua")
    run(sys.argv[1], sys.argv[2])
