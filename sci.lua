-- S.C.I.E.N.C.E.  (sci)
-- South Central Indiana
-- Electro Noise Circuit
-- Experiment
--
-- LinnStrument MPE loops,
-- audio loops, tape mangling
-- and Alecto drums on a grid
--
-- 4 paired tracks: an MPE MIDI
-- loop + an audio loop each,
-- on one shared tape transport
--
-- grid row 8 (both pages):
--   1 rec   2 play   3 undo
--   4 clear (hold 1s)
--   5-8 select track 1-4
--   9-16 loop length 1-8 bars
-- grid row 7 (tape, both pages):
--   1 reverse  3 brake (hold)
--   5 resync   7 flutter
--   8 PAGE (midi/audio/loop)
--   9-16 speed 1/4 .. 2x
--
-- MIDI page, rows 1-6:
--   note editor, selected track
--   tap = add/delete, hold+tap
--   right = length, hold+play
--   LinnStrument = step record
--
-- AUDIO page:
--   rows 1-4 = tracks 1-4
--     (tap to select)
--   row 5, per track (4 keys):
--     rec, audio on, midi on,
--     print midi->audio
--   row 6, per track: level
--
-- LOOP page (505-style,
--   same 4 audio loops), one
--   4-column strip per track:
--   col 1: fader (rows 1-6)
--   cols 2-3: rows 1-2 loop
--     position ring, rows 3-4
--     big REC>DUB>PLAY button,
--     rows 5-6 STOP (hold=clear)
--   col 4: FX, REV, MIDI,
--     PRINT, FOLLOW, FADE
--   hold FX: E2 cutoff E3 res
--
-- QUANT page (live):
--   row 1: launch quantize
--     off/beat/bar/2bar/loop
--   rows 2-5 = tracks 1-4:
--     1-5 note grid off..1/32
--     7-10 strength 25..100%
--     12 APPLY (undoable)
--     14 MIDI on 15 AUDIO on
--     16 audio REC/DUB/PLAY
--   row 6: tape drives
--     1 both 2 MIDI 3 audio
--
-- SAVE page:
--   row 1: slots 1-16 (tap to
--     select; lit = has a save)
--   row 2: 1 SAVE (hold 1s)
--     3 LOAD all   16 DELETE
--     (hold 2s)
--   rows 3-6 = tracks 1-4:
--     1 load MIDI from slot
--     2 load audio from slot
--   saves to dust/data/sci
--
-- DRUM page (Alecto via a
--   ZOIA Euroburo, 2 lanes):
--   rows 1/4: lane 1/2 steps
--     tap = on/off
--     hold ~0.5s = accent
--   rows 2/5: lane length 1-16
--   rows 3/6: cols 1-8 clock
--     division 1/32 1/16 1/16T
--     1/8 1/8T 1/4 1/2 bar
--     13/14 shift left/right
--     16 mute (quantized)
--   row 8: REC = record the
--     nanoPAD2 into the lanes,
--     undo, clear (hold)
--
-- nanoKEY plays and records a
--   chosen track (default 3,
--   the Hades); nanoPAD2 pads
--   play the two Alecto lanes
--
-- K2 rec  K3 play
-- K1+K2 undo  K1+K3 resync
-- E1 flutter  E2 loop length
-- E3 speed  K1+E3 editor pitch

local g = grid.connect()
local mpe_in

local BEND_CENTER = 8192
local TICK = 1/96          -- record/playback resolution, in beats
local UI = {}   -- screen helpers, labels and default ports, kept in one table
local CTL = {      -- nanoKEY / nanoPAD2 input
  keys_in = nil, pads_in = nil,
  drum_rec = false,  -- recording pads into the drum lanes
  rec_snap = false,  -- undo snapshot taken for this recording pass
  skip = {},         -- [lane] = step already played live this pass
  cc = {},           -- [tick] = {[cc] = value}: recorded nanoPAD2 X-Y moves
  cc_touch = {},     -- [cc] = time of the last live move (pauses its replay)
}
local SPEEDS = {1/4, 1/2, 2/3, 3/4, 1, 4/3, 3/2, 2}
local NT = 4               -- tracks
local LEVELS = {0.25, 0.5, 0.75, 1.0}
local A_MAX = 55           -- max audio loop length, seconds
local PAGES = {"midi", "audio", "loop", "quant", "drum", "save"}
-- drum clock divisions: ticks (of 1/96 beat) per step
local DIVS = {
  {name = "1/32", tps = 12}, {name = "1/16", tps = 24}, {name = "1/16T", tps = 16},
  {name = "1/8", tps = 48}, {name = "1/8T", tps = 32}, {name = "1/4", tps = 96},
  {name = "1/2", tps = 192}, {name = "bar", tps = 384},
}
local ACCENT_HOLD = 0.45   -- seconds a step must be held to toggle its accent
local LAUNCH = {0, 1, 4, 8, -1}     -- beats; -1 = loop length
local NGRID = {0, 1, 1/2, 1/4, 1/8} -- note quantize grid in beats (off..1/32)
local NSTR = {0.25, 0.5, 0.75, 1.0}

-- tracks -------------------------------------------------------

local tracks = {}
for t = 1, NT do
  tracks[t] = {
    pattern = {}, history = {}, out = nil,
    midi_on = true,
    -- audio
    has_audio = false, audio_on = true, gain = 1,
    arec = false,          -- audio recording/overdubbing
    replace = false,       -- true while recording over (REC), false = DUB
    rev = false, fx = false, fade = false,
    print = nil,           -- nil, "armed" or "rec"
    a_undo = false,        -- a backup is available
  }
end
local sel = 1              -- selected track
local page = "midi"

local function T() return tracks[sel] end

-- state ---------------------------------------------------------

local current_pass, rec_track = nil, nil
local clear_hold = nil     -- clock id while the clear key is held
local stop_hold = {}       -- [t] = clock id while a LOOP-page STOP is held
local fx_held = nil        -- track whose FX key is held (encoders edit it)
local when_started = {}    -- functions to run once the transport starts
local pending = {}         -- quantized actions: {at = beat, fn, tag}
local pend_tag = {}        -- [tag] = true while an action waits
local launch_q = 1         -- index into LAUNCH
local mdir = 1             -- direction the MIDI loop is moving
local slot = 1             -- selected save slot
local slot_used = {}       -- [n] = true if the slot has a save
local save_hold = nil      -- clock id while SAVE / DELETE is held
local save_msg, save_msg_t = "", 0

-- drums: two step lanes, steps[i] = 0 off, 1 on, 2 accent;
-- vel[i] = the velocity a nanoPAD2 hit recorded there (nil = use the level)
local lanes = {}
for l = 1, 2 do
  local st = {}
  for i = 1, 16 do st[i] = 0 end
  lanes[l] = {steps = st, vel = {}, len = 16, div = 2, mute = false}
end
local drum_tick = 0        -- ticks since the transport started
local drum_pos = {0, 0}    -- step each lane last played (1-based, 0 = none)
local drum_hist = {}       -- undo snapshots
local drum_press = {}      -- ["x,y"] = press time, for hold-to-accent
local drum_out = nil
local drum_step            -- forward declarations, defined on the DRUM page
local drum_undo, drum_clear
local start_play_hook      -- set to start_play once it is defined

local ROWS = 6             -- note editor rows
local pitch_base = 60      -- pitch shown on grid row 6 (the bottom row)
local gheld = {}           -- editor keys currently held, in press order

local live = {}            -- [ch] = note currently being recorded
local held = {}            -- [ch] = true while a live finger is down
local cur = {}             -- [ch] = last seen bend / slide / pressure
local voices = {}          -- notes currently playing back
local busy = {}            -- [out][ch] = output channel in use
local rr = {}              -- [out] = round-robin pointer

local playing, recording, starting = false, false, false
local origin = 0
local bars = 4
local loop_beats = 16

-- tape state
local head = 0             -- tape position in the loop, in beats
local dir = 1              -- 1 forward, -1 reverse
local target = 1           -- speed the tape is heading toward
local speed = 1            -- current (slewed) speed
local eff = 1              -- speed including flutter
local braking = false
local was_braked = false
local flutter_on = false
local wow_ph, flut_ph = 0, 0
local reel_angle = 0
local k1 = false
local page_flash_t = -10   -- when the page last changed (seconds)
local k1_used = false      -- K1 was used as a modifier during this press
local last_key, last_key_t = "", -10   -- name of the last grid key pressed
local tick_n = 0

-- audio state
local a_len = 8            -- current audio loop length, seconds
local apos = {}            -- [voice] = softcut phase
local last_rate = {}

local function now() return clock.get_beats() end
-- round tape positions so notes and head compare exactly
local function snap(x) return math.floor(x * 1e7 + 0.5) / 1e7 end
local function clock_pos() return (now() - origin) % loop_beats end
local function step_len() return loop_beats / 16 end
local function row_pitch(y) return pitch_base + (ROWS - y) end

-- scroll the editor so pitch p is on screen
local function follow_pitch(p)
  if p < pitch_base then pitch_base = p
  elseif p > pitch_base + ROWS - 1 then pitch_base = p - ROWS + 1 end
  pitch_base = util.clamp(pitch_base, 0, 128 - ROWS)
end

local function midi_driven() return params:get("tape_drives") ~= 3 end
local function audio_driven() return params:get("tape_drives") ~= 2 end

local function state(ch)
  if not cur[ch] then cur[ch] = {bend = 0, slide = 0, pressure = 0} end
  return cur[ch]
end

-- MIDI recording -------------------------------------------------

-- each note keeps a curve of snapshots, timed in tape time
-- relative to its own start
local function add_point(ch)
  local n = live[ch]
  if not n then return end
  local c = cur[ch]
  local p = {t = n.el, bend = c.bend, slide = c.slide, pressure = c.pressure}
  local last = n.curve[#n.curve]
  if p.t <= last.t then
    p.t = last.t
    n.curve[#n.curve] = p   -- same moment: keep only the latest values
  else
    table.insert(n.curve, p)
  end
end

local function commit(ch)
  local n = live[ch]
  if not n then return end
  live[ch] = nil
  local tr = n.track
  n.length = snap(math.max(n.el, TICK))
  if n.rev then
    -- recorded while the tape ran backwards: the note's end is where
    -- the head is now, and its gesture runs the other way on tape
    n.start = head
    local flipped = {}
    for i = #n.curve, 1, -1 do
      local p = n.curve[i]
      table.insert(flipped, {t = n.length - p.t, bend = p.bend,
        slide = p.slide, pressure = p.pressure})
    end
    flipped[1].t = 0
    n.curve = flipped
  end
  n.start = snap(n.start)
  n.el, n.rev, n.track = nil, nil, nil
  if tr == T() then
    -- if nothing is on the editor yet, bring the new note into view
    local any = false
    for _, q in ipairs(tr.pattern) do
      if q.pitch >= pitch_base and q.pitch < pitch_base + ROWS then any = true end
    end
    if not any then follow_pitch(n.pitch) end
  end
  table.insert(tr.pattern, n)
  if n.step then
    -- step-recorded from a held grid key: its own undo step
    n.step = nil
    table.insert(tr.history, {kind = "pass", notes = {n}})
  elseif current_pass and tr == rec_track then
    table.insert(current_pass, n)
  end
end

local function new_live(ch, c, m, start, rev, step, tr)
  live[ch] = {
    track = tr or T(), start = start, el = 0, rev = rev, step = step,
    pitch = m.note, vel = m.vel,
    curve = {{t = 0, bend = c.bend, slide = c.slide, pressure = c.pressure}},
  }
end

local function on_midi(data)
  local m = midi.to_msg(data)
  if not m.ch then return end
  local out = T().out
  if params:get("thru") == 2 and out then
    local lo, hi = params:get("ch_lo_" .. sel), params:get("ch_hi_" .. sel)
    if lo == hi then
      -- mono track (e.g. the Hades): move your playing onto its one
      -- channel, and leave out pitch bend, which a mono synth would
      -- read on a different scale
      if m.type ~= "pitchbend" and data[1] >= 0x80 and data[1] < 0xF0 then
        local d2 = {}
        for i, b in ipairs(data) do d2[i] = b end
        d2[1] = (data[1] & 0xF0) | (lo - 1)
        out:send(d2)
      end
    else
      out:send(data)
    end
  end
  local ch = m.ch
  local c = state(ch)

  if m.type == "note_on" and m.vel > 0 then
    held[ch] = true
    local gk = (page == "midi") and gheld[#gheld] or nil
    if gk then
      -- step record: the note lands on the held grid key's step,
      -- at the pitch you played, with its whole gesture
      gk.used = true
      new_live(ch, c, m, (gk.x - 1) * step_len(), false, true)
      follow_pitch(m.note)
    elseif recording and playing then
      new_live(ch, c, m, head, mdir < 0, false)
    end
  elseif m.type == "note_off" or m.type == "note_on" then
    held[ch] = nil
    if live[ch] and live[ch].pitch == m.note then commit(ch) end
  elseif m.type == "pitchbend" then
    c.bend = m.val - BEND_CENTER
    add_point(ch)
  elseif m.type == "cc" and m.cc == params:get("slide_cc") then
    c.slide = m.val
    add_point(ch)
  elseif m.type == "channel_pressure" then
    c.pressure = m.val
    add_point(ch)
  end
end

-- nanoKEY: a plain (non-MPE) keyboard that plays one track
local function keys_track()
  local k = params:get("keys_track")
  return (k == 5) and sel or k
end

-- a decoded message rebuilt as raw bytes on channel ch
CTL.msg = function(m, ch)
  local c = (ch or 1) - 1
  if m.type == "note_on" then return {0x90 + c, m.note, m.vel}
  elseif m.type == "note_off" then return {0x80 + c, m.note, 0}
  elseif m.type == "cc" then return {0xB0 + c, m.cc, m.val}
  elseif m.type == "pitchbend" then
    local v = (m.val or 8192)
    return {0xE0 + c, v % 128, math.floor(v / 128)}
  end
  return {}
end

CTL.on_keys = function(data)
  local m = midi.to_msg(data)
  local t = keys_track()
  local tr = tracks[t]
  local lo = params:get("ch_lo_" .. t)
  -- nanoKEY set to the drum channel: its keys play the ZOIA / Alecto directly
  if m.ch == params:get("drum_ch_1") then
    if drum_out and (m.type == "note_on" or m.type == "note_off" or m.type == "cc") then
      drum_out:send(CTL.msg(m, m.ch))
    end
    return
  end
  -- mod wheel and pitch bend pass through to the track's synth (Hades MOD out)
  if m.type == "cc" or m.type == "pitchbend" then
    if params:get("thru") == 2 and tr.out then tr.out:send(CTL.msg(m, lo)) end
    return
  end
  if m.type ~= "note_on" and m.type ~= "note_off" then return end
  local on = (m.type == "note_on" and m.vel > 0)
  if params:get("thru") == 2 and tr.out then
    if on then tr.out:note_on(m.note, m.vel, lo) else tr.out:note_off(m.note, 0, lo) end
  end
  local id = "k" .. m.note       -- keyed apart from the LinnStrument's channels
  if on then
    local c = {bend = 0, slide = params:get("grid_slide"), pressure = params:get("grid_pressure")}
    local gk = (page == "midi" and t == sel) and gheld[#gheld] or nil
    if gk then
      gk.used = true
      new_live(id, c, m, (gk.x - 1) * step_len(), false, true, tr)
      follow_pitch(m.note)
    elseif recording and playing and rec_track == tr then
      new_live(id, c, m, head, mdir < 0, false, tr)
    end
  elseif live[id] then
    commit(id)
  end
end

-- MIDI playback ---------------------------------------------------

local function alloc(t)
  local out = tracks[t].out
  if not out then return nil end
  busy[out] = busy[out] or {}
  rr[out] = rr[out] or 0
  local lo = params:get("ch_lo_" .. t)
  local hi = math.max(lo, params:get("ch_hi_" .. t))
  local span = hi - lo + 1
  for i = 0, span - 1 do
    local ch = lo + (rr[out] + i) % span
    if not busy[out][ch] and not held[ch] then
      rr[out] = (ch - lo + 1) % span
      busy[out][ch] = true
      return ch, out
    end
  end
  return nil -- out of channels: drop the note
end

-- semitone shift from tape speed (only if pitch follow is on)
local function tape_semis()
  if params:get("pitch_follow") == 1 or not midi_driven() then return 0 end
  return 12 * math.log(math.max(eff, 1/16)) / math.log(2)
end

local function bend_value(raw, semis)
  local in_r, out_r = params:get("in_bend"), params:get("out_bend")
  local st = raw / BEND_CENTER * in_r + semis
  local v = st / out_r * BEND_CENTER + BEND_CENTER
  return util.clamp(math.floor(v + 0.5), 0, 16383)
end

-- sample-and-hold lookup of the curve at note time nt
local function seek(v, nt)
  local cv = v.note.curve
  if v.rev then
    while v.idx > 1 and cv[v.idx].t > nt do v.idx = v.idx - 1 end
  else
    while v.idx < #cv and cv[v.idx + 1].t <= nt do v.idx = v.idx + 1 end
  end
  return cv[v.idx]
end

local function send_state(v, p, semis, force)
  local cc = params:get("slide_cc")
  local b = bend_value(p.bend, semis)
  if force or b ~= v.b then v.out:pitchbend(b, v.ch); v.b = b end
  if force or p.slide ~= v.s then v.out:cc(cc, p.slide, v.ch); v.s = p.slide end
  if force or p.pressure ~= v.p then
    v.out:channel_pressure(p.pressure, v.ch); v.p = p.pressure
  end
end

local function start_voice(t, n, rev)
  local ch, out = alloc(t)
  if not ch then return end
  local v = {note = n, ch = ch, out = out, el = 0, rev = rev,
             idx = rev and #n.curve or 1}
  local p = seek(v, rev and n.length or 0)
  send_state(v, p, tape_semis(), true)
  out:note_on(n.pitch, n.vel, ch)
  table.insert(voices, v)
end

local function end_voice(i)
  local v = voices[i]
  v.out:note_off(v.note.pitch, 0, v.ch)
  busy[v.out][v.ch] = nil
  table.remove(voices, i)
end

local function all_off()
  for i = #voices, 1, -1 do end_voice(i) end
end

local function advance_voices(d)
  local semis = tape_semis()
  for i = #voices, 1, -1 do
    local v = voices[i]
    v.el = v.el + d
    local n = v.note
    if v.el >= n.length then
      end_voice(i)
    else
      local nt = v.rev and (n.length - v.el) or v.el
      send_state(v, seek(v, nt), semis, false)
    end
  end
end

local function in_span(x, a, b)
  -- is x in (a, b] on a loop of length loop_beats, moving forward a->b
  if a <= b then return x > a and x <= b end
  return x > a or x <= b
end

-- where a note starts after the track's (non-destructive) quantize
local function q_start(t, n)
  local gi = params:get("qgrid_" .. t)
  local grid_b = NGRID[gi]
  if grid_b == 0 then return n.start end
  local strength = NSTR[params:get("qstr_" .. t)]
  local target_s = math.floor(n.start / grid_b + 0.5) * grid_b
  return snap((n.start + (target_s - n.start) * strength) % loop_beats)
end

local function trigger_notes(prev, now_head)
  for t, tr in ipairs(tracks) do
    if tr.midi_on then
      for _, n in ipairs(tr.pattern) do
        local s0 = q_start(t, n)
        if mdir > 0 then
          if in_span(s0, prev, now_head) then start_voice(t, n, false) end
        else
          -- running backwards: a note begins (reversed) when the head
          -- reaches its end; span (now_head, prev] in forward terms
          local e = snap((s0 + n.length) % loop_beats)
          if in_span(e, now_head, prev) then start_voice(t, n, true) end
        end
      end
    end
  end
end

-- audio (softcut) -------------------------------------------------
-- voice t plays track t. tracks 1-2 live in buffer 1, 3-4 in buffer 2.
-- each track has a loop region and a backup region (for undo).

local function a_buf(t) return (t <= 2) and 1 or 2 end
local function a_start(t) return 1 + ((t - 1) % 2) * 175 end
local function a_backup(t) return a_start(t) + 58 end
local function a_temp(t) return a_start(t) + 116 end

local function a_level(t)
  local tr = tracks[t]
  softcut.level_slew_time(t, tr.fade and params:get("fade_time") or 0.03)
  softcut.level(t, tr.audio_on and tr.gain or 0)
end

local function a_filter(t)
  local tr = tracks[t]
  softcut.post_filter_dry(t, tr.fx and 0 or 1)
  softcut.post_filter_lp(t, tr.fx and 1 or 0)
  softcut.post_filter_fc(t, params:get("cutoff_" .. t))
  softcut.post_filter_rq(t, params:get("rq_" .. t))
end

-- run fn now if the transport is rolling, otherwise once it starts
local function when_playing(fn)
  if playing then fn() else table.insert(when_started, fn) end
end

local function a_follows(t) return params:get("follow_" .. t) == 2 end

local function a_rate(t)
  if not playing then return 0 end
  local r = (a_follows(t) and audio_driven()) and (eff * dir) or 1
  if tracks[t].rev then r = -r end
  return r
end

local function a_place(t)
  -- put voice t where the tape head is
  softcut.position(t, a_start(t) + (head / loop_beats) * a_len)
end

local function a_set_loop()
  a_len = math.min(loop_beats * clock.get_beat_sec(), A_MAX)
  for t = 1, NT do
    softcut.loop_start(t, a_start(t))
    softcut.loop_end(t, a_start(t) + a_len)
  end
end

local function a_backup_now(t)
  softcut.buffer_copy_mono(a_buf(t), a_buf(t), a_start(t), a_backup(t),
    a_len + 0.1, 0)
  tracks[t].a_undo = true
end

local function a_rec(t, on, replace)
  local tr = tracks[t]
  if on then
    a_backup_now(t)
    softcut.pre_level(t, replace and 0 or params:get("overdub"))
    softcut.rec_level(t, 1)
    tr.has_audio = true
    tr.replace = replace and true or false
    if not tr.audio_on then tr.audio_on = true; a_level(t) end
  else
    softcut.rec_level(t, 0)
    softcut.pre_level(t, 1)
  end
  tr.arec = on
end

-- undo swaps the loop with its backup, so pressing again is redo
local function a_undo(t)
  local tr = tracks[t]
  if not tr.a_undo or tr.arec or tr.print then return end
  local b, d = a_buf(t), a_len + 0.1
  softcut.buffer_copy_mono(b, b, a_start(t), a_temp(t), d, 0)
  softcut.buffer_copy_mono(b, b, a_backup(t), a_start(t), d, 0.005)
  softcut.buffer_copy_mono(b, b, a_temp(t), a_backup(t), d, 0)
  tr.has_audio = true
  tr.redo = not tr.redo
end

local function a_clear(t)
  local tr = tracks[t]
  if tr.arec then a_rec(t, false) end
  tr.print = nil
  if not tr.has_audio then return end
  a_backup_now(t)
  softcut.buffer_clear_region_channel(a_buf(t), a_start(t), a_len + 0.1)
  tr.has_audio = false
end

local function a_toggle_rec(t)
  local tr = tracks[t]
  if tr.print then return end
  if tr.arec then a_rec(t, false)
  else when_playing(function() a_rec(t, true, false) end) end
end

-- 505-style states
local function a_state(t)
  local tr = tracks[t]
  if tr.print then return "print" end
  if tr.arec then return tr.replace and "rec" or "dub" end
  if not tr.has_audio then return "empty" end
  return tr.audio_on and "play" or "stop"
end

-- the big button: REC -> DUB (or PLAY) -> PLAY -> DUB -> PLAY ...
local function a_big(t)
  local tr = tracks[t]
  local st = a_state(t)
  if st == "print" then return end
  if st == "empty" then
    when_playing(function() a_rec(t, true, true) end)
  elseif st == "rec" then
    if params:get("rec_action") == 1 then
      -- REC -> DUB: keep recording, now layering
      tr.replace = false
      softcut.pre_level(t, params:get("overdub"))
    else
      a_rec(t, false)
    end
  elseif st == "dub" then
    a_rec(t, false)
  elseif st == "play" then
    a_rec(t, true, false)
  elseif st == "stop" then
    tr.audio_on = true
    a_level(t)
  end
end

local function a_stop(t)
  local tr = tracks[t]
  if tr.print then return end
  if tr.arec then a_rec(t, false) end
  tr.audio_on = false
  a_level(t)
end

local function a_toggle_print(t)
  local tr = tracks[t]
  if tr.print then
    if tr.print == "rec" then a_rec(t, false) end
    tr.print = nil
  else
    if tr.arec then a_rec(t, false) end
    tr.midi_on = true
    tr.print = "armed"   -- starts on the next lap
    if not playing then start_play_hook() end
  end
end

-- called whenever the tape head wraps around the loop
local function on_wrap()
  for t, tr in ipairs(tracks) do
    -- re-align following audio only when one tape drives both
    if a_follows(t) and midi_driven() and audio_driven() then a_place(t) end
    if tr.print == "armed" then
      a_rec(t, true, true)
      tr.print = "rec"
    elseif tr.print == "rec" then
      a_rec(t, false)
      tr.print = nil
      if params:get("print_mute") == 2 then tr.midi_on = false end
    end
  end
end

local function a_update_rates(force)
  for t = 1, NT do
    local r = a_rate(t)
    if force or math.abs(r - (last_rate[t] or -99)) > 0.002 then
      softcut.rate(t, r)
      last_rate[t] = r
    end
  end
end

local function a_init()
  audio.level_adc_cut(1)
  audio.level_cut(1)
  softcut.buffer_clear()
  for t = 1, NT do
    softcut.enable(t, 1)
    softcut.buffer(t, a_buf(t))
    softcut.pan(t, 0)
    softcut.level_input_cut(1, t, 0.5)
    softcut.level_input_cut(2, t, 0.5)
    softcut.loop(t, 1)
    softcut.fade_time(t, 0.01)
    softcut.rate_slew_time(t, 0.03)
    softcut.level_slew_time(t, 0.03)
    softcut.recpre_slew_time(t, 0.005)
    softcut.rec(t, 1)          -- always "recording", silently (level 0)
    softcut.rec_level(t, 0)
    softcut.pre_level(t, 1)
    softcut.play(t, 1)
    softcut.rate(t, 0)
    softcut.phase_quant(t, 1/30)
    a_level(t)
    a_filter(t)
  end
  a_set_loop()
  for t = 1, NT do a_place(t) end
  softcut.event_phase(function(v, p) apos[v] = p end)
  softcut.poll_start_phase()
end

-- tape motion -------------------------------------------------------

local function slew_speed()
  local tgt = braking and 0 or target
  local dt = clock.get_beat_sec() * TICK
  if braking or speed < 0.05 or (speed < tgt and speed < target * 0.98
      and was_braked) then
    -- tape stop / spin up: a linear ramp, like a motor
    was_braked = true
    local step = math.max(target, 0.25) * dt / params:get("brake_time")
    if speed > tgt then speed = math.max(tgt, speed - step)
    else speed = math.min(tgt, speed + step) end
    if speed == tgt and not braking then was_braked = false end
    return
  end
  local slew = params:get("slew")
  local k = (slew <= 0) and 1 or (1 - math.exp(-dt / slew))
  speed = speed + (tgt - speed) * k
  if math.abs(tgt - speed) < 0.001 then speed = tgt end
end

local function update_flutter()
  if not flutter_on then eff = speed; return end
  local dt = clock.get_beat_sec() * TICK
  local depth = params:get("flutter") / 100   -- percent
  wow_ph = wow_ph + dt * 2 * math.pi * 0.55
  flut_ph = flut_ph + dt * 2 * math.pi * 6.3
  local w = 0.7 * math.sin(wow_ph) + 0.25 * math.sin(flut_ph)
    + 0.05 * (math.random() * 2 - 1)
  eff = math.max(0, speed * (1 + depth * w))
end

local function run_pending()
  if #pending == 0 then return end
  local t_now = now()
  for i = #pending, 1, -1 do
    local p = pending[i]
    if t_now >= p.at - 1e-6 then
      table.remove(pending, i)
      pend_tag[p.tag] = nil
      p.fn()
    end
  end
end

local function tape_tick()
  tick_n = tick_n + 1
  run_pending()
  if playing and drum_step then drum_step() end
  slew_speed()
  update_flutter()
  if tick_n % 4 == 0 then a_update_rates(false) end
  local d = TICK * eff                   -- tape distance this tick
  reel_angle = reel_angle + d * dir * 2
  -- the MIDI loop rides the tape unless the tape only drives audio
  if not midi_driven() then d = TICK end
  mdir = midi_driven() and dir or 1
  for _, n in pairs(live) do n.el = n.el + d end
  if not playing or d <= 0 then
    advance_voices(0)
    return
  end
  local prev = head
  head = snap((head + d * mdir) % loop_beats)
  if (mdir > 0 and head < prev) or (mdir < 0 and head > prev) then on_wrap() end
  trigger_notes(prev, head)
  advance_voices(d)
end

local function ticker()
  while true do
    clock.sync(TICK)
    tape_tick()
  end
end

-- transport ---------------------------------------------------------

local function start_play()
  if playing or starting then return end
  starting = true
  clock.run(function()
    clock.sync(1)            -- start on the next beat
    origin = now()
    mdir = midi_driven() and dir or 1
    head = snap(((mdir > 0) and -0.0001 or 0.0001) % loop_beats)
    a_set_loop()
    for t = 1, NT do a_place(t) end
    playing, starting = true, false
    drum_tick = 0
    drum_pos = {0, 0}
    a_update_rates(true)
    local fns = when_started
    when_started = {}
    for _, fn in ipairs(fns) do fn() end
  end)
end
start_play_hook = start_play

local function stop_rec()
  if not recording then return end
  recording = false
  for ch in pairs(live) do commit(ch) end
  if current_pass and #current_pass == 0 then table.remove(rec_track.history) end
  current_pass, rec_track = nil, nil
end

local function start_rec()
  if recording then return end
  rec_track = T()
  current_pass = {}
  table.insert(rec_track.history, {kind = "pass", notes = current_pass})
  recording = true
  start_play()
end

local function stop_play()
  stop_rec()
  when_started = {}
  pending, pend_tag = {}, {}
  CTL.drum_rec, CTL.skip = false, {}
  playing = false
  all_off()
  for t, tr in ipairs(tracks) do
    if tr.arec then a_rec(t, false) end
    tr.print = nil
  end
  a_update_rates(true)
end

local function midi_undo()
  local tr = T()
  if recording then return end
  local last = table.remove(tr.history)
  if not last then return end
  if last.kind == "quant" then
    for _, o in ipairs(last.olds) do o.n.start = o.s end
  elseif last.kind == "delete" then
    table.insert(tr.pattern, last.note)
  elseif last.kind == "length" then
    last.note.length = last.old
  elseif last.kind == "clear" then
    -- bring the whole cleared loop back, with its own undo history
    tr.pattern = last.pattern
    tr.history = last.history
  else
    local gone = {}
    for _, n in ipairs(last.notes) do gone[n] = true end
    for i = #tr.pattern, 1, -1 do
      if gone[tr.pattern[i]] then table.remove(tr.pattern, i) end
    end
  end
end

local function midi_clear()
  local tr = T()
  if recording and rec_track == tr then stop_rec() end
  if #tr.pattern == 0 then return end
  -- clearing is itself undoable
  tr.history = {{kind = "clear", pattern = tr.pattern, history = tr.history}}
  tr.pattern = {}
end

-- launch quantize: run fn on the next beat/bar/loop boundary
local function quantized(tag, fn)
  local q = LAUNCH[launch_q]
  if q == -1 then q = loop_beats end
  if q == 0 or not playing then fn(); return end
  if pend_tag[tag] then
    -- pressing again while waiting cancels
    for i = #pending, 1, -1 do
      if pending[i].tag == tag then table.remove(pending, i) end
    end
    pend_tag[tag] = nil
    return
  end
  local rel = now() - origin
  local at = origin + (math.floor(rel / q + 1e-6) + 1) * q
  table.insert(pending, {at = at, fn = fn, tag = tag})
  pend_tag[tag] = true
end

-- make a track's quantize permanent (undoable)
local function apply_quant(t)
  local tr = tracks[t]
  if NGRID[params:get("qgrid_" .. t)] == 0 then return end
  local olds = {}
  for _, n in ipairs(tr.pattern) do
    table.insert(olds, {n = n, s = n.start})
    n.start = q_start(t, n)
  end
  table.insert(tr.history, {kind = "quant", olds = olds})
end

-- page-aware actions
local function do_rec()
  if page == "drum" then
    -- REC on the DRUM page records the nanoPAD2 into the lanes
    CTL.drum_rec = not CTL.drum_rec
    CTL.rec_snap = false
    if CTL.drum_rec and not playing then start_play() end
    return
  end
  local t = sel
  if page == "audio" then
    quantized("arec" .. t, function() a_toggle_rec(t) end)
    if not playing then start_play() end
  elseif page == "loop" or page == "quant" then
    quantized("big" .. t, function() a_big(t) end)
    if not playing then start_play() end
  else
    quantized("mrec", function()
      if recording then stop_rec() else start_rec() end
    end)
  end
end

local function do_undo()
  if page == "drum" then drum_undo()
  elseif page == "midi" then midi_undo() else a_undo(sel) end
end

local function do_clear()
  if page == "drum" then drum_clear()
  elseif page == "midi" then midi_clear() else a_clear(sel) end
end

local function select_track(t)
  if t == sel then return end
  if recording then stop_rec() end
  sel = t
  -- show the new track's notes in the editor
  local tr = T()
  if #tr.pattern > 0 then
    local lo = 127
    for _, n in ipairs(tr.pattern) do lo = math.min(lo, n.pitch) end
    pitch_base = util.clamp(lo, 0, 128 - ROWS)
  end
end

local function set_bars(b)
  bars = util.clamp(b, 1, 8)
  loop_beats = bars * 4
  head = head % loop_beats
  a_set_loop()
end

local function set_reverse(on) dir = on and -1 or 1 end
local function set_target(s) target = util.clamp(s, 1/16, 4) end

local function resync()
  dir, target, speed, braking, was_braked = 1, 1, 1, false, false
  if playing then
    head = clock_pos()
    for t = 1, NT do if a_follows(t) then a_place(t) end end
  end
end

-- note editing --------------------------------------------------------

local function col_of(n) return math.floor(n.start / step_len() + 1e-6) + 1 end

local function note_at(x, y)
  local p = row_pitch(y)
  local pat = T().pattern
  for i = #pat, 1, -1 do
    local n = pat[i]
    if n.pitch == p and col_of(n) == x then return n end
  end
  return nil
end

local function add_note(x, y, steps)
  local n = {
    start = snap((x - 1) * step_len()),
    length = snap(steps * step_len()),
    pitch = row_pitch(y),
    vel = params:get("grid_vel"),
    curve = {{t = 0, bend = 0, slide = params:get("grid_slide"),
              pressure = params:get("grid_pressure")}},
  }
  table.insert(T().pattern, n)
  table.insert(T().history, {kind = "pass", notes = {n}})
end

local function delete_note(n)
  local pat = T().pattern
  for i = #pat, 1, -1 do
    if pat[i] == n then table.remove(pat, i) end
  end
  table.insert(T().history, {kind = "delete", note = n})
end

local function set_length(n, steps)
  table.insert(T().history, {kind = "length", note = n, old = n.length})
  n.length = snap(steps * step_len())
end

local NAMES = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}
local function note_name(p)
  return NAMES[p % 12 + 1] .. (math.floor(p / 12) - 1)
end

-- grid ------------------------------------------------------------------

local function speed_index()
  local best, bi = math.huge, 5
  for i, s in ipairs(SPEEDS) do
    local d = math.abs(math.log(target / s))
    if d < best then best, bi = d, i end
  end
  return bi, best < 0.01
end

local function draw_midi_page()
  -- editor background: C rows glow faintly
  for y = 1, ROWS do
    if row_pitch(y) % 12 == 0 then
      for x = 1, 16 do g:led(x, y, 1) end
    end
  end
  if playing then
    local x = math.floor(head / loop_beats * 16) + 1
    for y = 1, ROWS do g:led(x, y, 3) end
  end
  -- notes in view: bright start, dimmer tail
  local st = step_len()
  for _, n in ipairs(T().pattern) do
    local y = ROWS - (n.pitch - pitch_base)
    if y >= 1 and y <= ROWS then
      local x = col_of(n)
      local cols = math.max(1, math.floor(n.length / st + 0.5))
      for k = 1, math.min(cols, 16) - 1 do
        g:led((x - 1 + k) % 16 + 1, y, 5)
      end
      if x <= 16 then
        g:led(x, y, util.clamp(math.floor(n.vel / 127 * 7) + 8, 8, 15))
      end
    end
  end
  for _, k in ipairs(gheld) do g:led(k.x, k.y, 15) end
end

local function draw_audio_page(blink)
  for t, tr in ipairs(tracks) do
    -- rows 1-4: one row per track, with its playhead
    local bg = tr.has_audio and 3 or 1
    if t == sel then bg = bg + 2 end
    for x = 1, 16 do g:led(x, t, bg) end
    if playing and apos[t] and a_len > 0 then
      local x = math.floor((apos[t] - a_start(t)) / a_len * 16) + 1
      if x >= 1 and x <= 16 then
        local lvl = tr.has_audio and 12 or 5
        if tr.arec or tr.print == "rec" then lvl = blink and 15 or 9 end
        g:led(x, t, lvl)
      end
    end
    -- row 5: rec, audio on, midi on, print
    local x0 = (t - 1) * 4
    g:led(x0 + 1, 5, tr.arec and (blink and 15 or 9) or (tr.has_audio and 5 or 2))
    g:led(x0 + 2, 5, tr.audio_on and 10 or 2)
    g:led(x0 + 3, 5, tr.midi_on and 10 or 2)
    local pl = 3
    if tr.print == "armed" then pl = blink and 12 or 4
    elseif tr.print == "rec" then pl = 15 end
    g:led(x0 + 4, 5, pl)
    -- row 6: level
    for i = 1, 4 do
      g:led(x0 + i, 6, LEVELS[i] <= tr.gain + 0.01 and (t == sel and 9 or 6) or 1)
    end
  end
end

local function editor_key(x, y, z)
  if z == 1 then
    -- length gesture: a key already held further left in this row
    for _, k in ipairs(gheld) do
      if k.y == y and k.x < x then
        k.used = true
        local n = note_at(k.x, y)
        if n then set_length(n, x - k.x + 1)
        else add_note(k.x, y, x - k.x + 1) end
        table.insert(gheld, {x = x, y = y, used = true})
        return
      end
    end
    table.insert(gheld, {x = x, y = y, used = false})
  else
    for i, k in ipairs(gheld) do
      if k.x == x and k.y == y then
        table.remove(gheld, i)
        if not k.used then
          -- plain tap: toggle a note
          local n = note_at(x, y)
          if n then delete_note(n) else add_note(x, y, 1) end
        end
        break
      end
    end
  end
end

local function audio_key(x, y, z)
  if z == 0 then return end
  if y <= NT then select_track(y); return end
  local t = math.floor((x - 1) / 4) + 1
  local i = (x - 1) % 4 + 1
  local tr = tracks[t]
  if y == 5 then
    if i == 1 then
      quantized("arec" .. t, function() a_toggle_rec(t) end)
      if not playing then start_play() end
    elseif i == 2 then
      quantized("aon" .. t, function() tr.audio_on = not tr.audio_on; a_level(t) end)
    elseif i == 3 then
      quantized("mon" .. t, function() tr.midi_on = not tr.midi_on end)
    elseif i == 4 then
      a_toggle_print(t)
      if not playing then start_play() end
    end
  elseif y == 6 then
    tr.gain = LEVELS[i]
    a_level(t)
  end
end

-- LOOP page (505-style) -------------------------------------------

local RING = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}  -- clockwise over 2x2 cells

local function draw_loop_page(blink, fast)
  for t, tr in ipairs(tracks) do
    local x0 = (t - 1) * 4
    local st = a_state(t)
    -- fader: column 1, bottom row = quietest
    for y = 1, 6 do
      local v = (7 - y) / 6
      g:led(x0 + 1, y, v <= tr.gain + 0.01 and (t == sel and 10 or 6) or 1)
    end
    -- position ring (rows 1-2, cols 2-3)
    for _, c in ipairs(RING) do g:led(x0 + 2 + c[1], 1 + c[2], 1) end
    if playing and tr.has_audio and apos[t] and a_len > 0 then
      local f = ((apos[t] - a_start(t)) / a_len) % 1
      local c = RING[math.floor(f * 4) + 1]
      if c then g:led(x0 + 2 + c[1], 1 + c[2], tr.audio_on and 12 or 5) end
    end
    -- big button (rows 3-4, cols 2-3)
    local b = 1
    if st == "rec" or st == "print" then b = fast and 15 or 3
    elseif st == "dub" then b = blink and 15 or 7
    elseif st == "play" then b = 12
    elseif st == "stop" then b = 4 end
    for dx = 0, 1 do for dy = 0, 1 do g:led(x0 + 2 + dx, 3 + dy, b) end end
    -- stop (rows 5-6, cols 2-3)
    local s = tr.has_audio and 5 or 2
    if stop_hold[t] then s = fast and 15 or 4 end
    for dx = 0, 1 do for dy = 0, 1 do g:led(x0 + 2 + dx, 5 + dy, s) end end
    -- column 4: FX, REV, MIDI, PRINT, FOLLOW, FADE
    local x = x0 + 4
    g:led(x, 1, (tr.fx or fx_held == t) and 12 or 2)
    g:led(x, 2, tr.rev and 12 or 2)
    g:led(x, 3, tr.midi_on and 10 or 2)
    local pl = 2
    if tr.print == "armed" then pl = blink and 12 or 4
    elseif tr.print == "rec" then pl = 15 end
    g:led(x, 4, pl)
    g:led(x, 5, a_follows(t) and 8 or 2)
    g:led(x, 6, tr.fade and 8 or 2)
  end
end

local function loop_key(x, y, z)
  local t = math.floor((x - 1) / 4) + 1
  local c = (x - 1) % 4 + 1
  local tr = tracks[t]
  -- STOP: press stops, hold 1s clears
  if (c == 2 or c == 3) and y >= 5 then
    if z == 1 then
      select_track(t)
      quantized("stop" .. t, function() a_stop(t) end)
      stop_hold[t] = clock.run(function()
        clock.sleep(1)
        stop_hold[t] = nil
        a_clear(t)
      end)
    elseif stop_hold[t] then
      clock.cancel(stop_hold[t])
      stop_hold[t] = nil
    end
    return
  end
  -- FX key: tap toggles, hold lets E2/E3 edit the filter
  if c == 4 and y == 1 then
    if z == 1 then
      fx_held = t
      tr.fx_moved = false
    else
      if fx_held == t then
        if not tr.fx_moved then tr.fx = not tr.fx end
        fx_held = nil
      end
      a_filter(t)
    end
    return
  end
  if z == 0 then return end
  select_track(t)
  if c == 1 then
    tr.gain = (7 - y) / 6
    a_level(t)
  elseif y >= 3 and y <= 4 then
    quantized("big" .. t, function() a_big(t) end)
    if not playing then start_play() end
  elseif c == 4 then
    if y == 2 then tr.rev = not tr.rev; a_update_rates(true)
    elseif y == 3 then
      quantized("mon" .. t, function() tr.midi_on = not tr.midi_on end)
    elseif y == 4 then a_toggle_print(t)
    elseif y == 5 then
      params:set("follow_" .. t, a_follows(t) and 1 or 2)
      a_place(t); a_update_rates(true)
    elseif y == 6 then tr.fade = not tr.fade; a_level(t)
    end
  end
end

-- DRUM page ---------------------------------------------------------

local function drum_snapshot()
  local snap_l = {cc = {}}
  for t, ev in pairs(CTL.cc) do
    local e = {}
    for c, v in pairs(ev) do e[c] = v end
    snap_l.cc[t] = e
  end
  for l, ln in ipairs(lanes) do
    local st, ve = {}, {}
    for i = 1, 16 do st[i] = ln.steps[i]; ve[i] = ln.vel[i] or 0 end
    snap_l[l] = {steps = st, vel = ve, len = ln.len, div = ln.div, mute = ln.mute}
  end
  return snap_l
end

local function drum_restore(snap_l)
  CTL.cc = {}
  for t, ev in pairs(snap_l.cc or {}) do
    local e = {}
    for c, v in pairs(ev) do e[c] = v end
    CTL.cc[tonumber(t)] = e
  end
  for l = 1, 2 do
    local src = snap_l[l]
    if src then
      for i = 1, 16 do
        lanes[l].steps[i] = src.steps[i] or 0
        local v = src.vel and src.vel[i] or 0
        lanes[l].vel[i] = (v > 0) and v or nil
      end
      lanes[l].len = util.clamp(src.len or 16, 1, 16)
      lanes[l].div = util.clamp(src.div or 2, 1, #DIVS)
      lanes[l].mute = src.mute or false
    end
  end
end

-- remember the state before an edit, so undo can step back
local function drum_edit()
  table.insert(drum_hist, drum_snapshot())
  if #drum_hist > 64 then table.remove(drum_hist, 1) end
end

drum_undo = function()
  local last = table.remove(drum_hist)
  if last then drum_restore(last) end
end

drum_clear = function()
  drum_edit()
  for l = 1, 2 do
    for i = 1, 16 do lanes[l].steps[i] = 0 end
    lanes[l].vel = {}
  end
  CTL.cc = {}
end

local function drum_hit(l, accent, live_vel)
  if not drum_out then return end
  local ch = params:get("drum_ch_" .. l)
  local note = params:get("drum_note_" .. l)
  -- a pad played live keeps its own velocity (the Alecto's VELO follows it)
  local vel = live_vel or (accent and params:get("drum_vel_acc") or params:get("drum_vel"))
  local out = drum_out
  out:note_on(note, vel, ch)
  clock.run(function()
    clock.sleep(params:get("drum_gate") / 1000)
    out:note_off(note, 0, ch)
  end)
end

-- ticks in the CC loop: lane 1's length x its division
CTL.cc_len = function()
  return lanes[1].len * DIVS[lanes[1].div].tps
end

-- called once per tick while the transport plays
drum_step = function()
  for l, ln in ipairs(lanes) do
    local tps = DIVS[ln.div].tps
    if drum_tick % tps == 0 then
      local i = math.floor(drum_tick / tps) % ln.len + 1
      drum_pos[l] = i
      local v = ln.steps[i]
      if CTL.skip[l] == i then
        CTL.skip[l] = nil          -- already played live from a pad
      elseif v > 0 and not ln.mute then
        drum_hit(l, v == 2, ln.vel[i])
      end
    end
  end
  -- recorded X-Y moves loop over lane 1's length, on lane 1's channel
  local ev = CTL.cc[drum_tick % CTL.cc_len()]
  if ev and drum_out then
    local now = util.time()
    for c, v in pairs(ev) do
      local touched = CTL.cc_touch[c]
      if not touched or now - touched > 0.25 then
        drum_out:cc(c, v, params:get("drum_ch_1"))
      end
    end
  end
  drum_tick = drum_tick + 1
end

local function drum_shift(l, d)
  drum_edit()
  local ln = lanes[l]
  local old, oldv = {}, {}
  for i = 1, ln.len do old[i] = ln.steps[i]; oldv[i] = ln.vel[i] end
  for i = 1, ln.len do
    ln.steps[i] = old[(i - 1 - d) % ln.len + 1]
    ln.vel[i] = oldv[(i - 1 - d) % ln.len + 1]
  end
end

-- nanoPAD2: two pads play the Alecto lanes; while the DRUM page's REC
-- is on, each hit is written to the nearest step of its lane
CTL.on_pads = function(data)
  local m = midi.to_msg(data)
  if m.type == "cc" then
    -- X-Y pad and knobs: pass through to the ZOIA on the drum channel,
    -- and record them while the DRUM page's REC is on
    if drum_out then drum_out:cc(m.cc, m.val, params:get("drum_ch_1")) end
    CTL.cc_touch[m.cc] = util.time()
    if CTL.drum_rec and playing then
      if not CTL.rec_snap then
        drum_edit()
        CTL.rec_snap = true
      end
      local t = math.max(drum_tick - 1, 0) % CTL.cc_len()
      CTL.cc[t] = CTL.cc[t] or {}
      CTL.cc[t][m.cc] = m.val
    end
    return
  end
  if params:get("pad_mode") == 2 then
    -- tuned pads: every note goes straight to the ZOIA on the drum channel
    if drum_out and (m.type == "note_on" or m.type == "note_off") then
      drum_out:send(CTL.msg(m, params:get("drum_ch_1")))
    end
    return
  end
  if m.type ~= "note_on" or m.vel == 0 then return end
  local l = (m.note == params:get("pad_note_1")) and 1
    or (m.note == params:get("pad_note_2")) and 2 or nil
  if not l then return end
  local accent = m.vel >= params:get("pad_accent")
  drum_hit(l, accent, m.vel)
  if not (CTL.drum_rec and playing) then return end
  local ln = lanes[l]
  local tps = DIVS[ln.div].tps
  local now_t = math.max(drum_tick - 1, 0)
  local nearest = math.floor(now_t / tps + 0.5)
  local i = nearest % ln.len + 1
  if nearest * tps > now_t then CTL.skip[l] = i end  -- hit early: don't play it twice
  if not CTL.rec_snap then
    drum_edit()
    CTL.rec_snap = true
  end
  local v = accent and 2 or 1
  if ln.steps[i] < v then ln.steps[i] = v end
  ln.vel[i] = math.max(ln.vel[i] or 0, m.vel)   -- replays at the velocity you played
end

local function draw_drum_page(blink, fast)
  for l, ln in ipairs(lanes) do
    local y0 = (l - 1) * 3
    -- a dim bar of light marks the lane's current step across its 3 rows
    local bar_x = (playing and drum_pos[l] > 0) and drum_pos[l] or nil
    local function put(x, y, v)
      if x == bar_x then v = math.max(v, 1) end
      g:led(x, y, v)
    end
    -- steps
    for i = 1, 16 do
      local v = 0
      if i <= ln.len then
        local st = ln.steps[i]
        v = (st == 2) and 15 or (st == 1 and 8 or 0)
        if i == bar_x and st > 0 then v = 15 end
        if ln.mute and st > 0 then v = math.min(v, 4) end
      end
      put(i, y0 + 1, v)
    end
    -- length
    for i = 1, 16 do put(i, y0 + 2, i < ln.len and 3 or (i == ln.len and 12 or 0)) end
    -- division, shift, mute
    local m = ln.mute and 2 or 10
    if pend_tag["dmute" .. l] then m = fast and 15 or 0 end
    for i = 1, 16 do
      local v = 0
      if i <= #DIVS then v = (i == ln.div) and 12 or 3
      elseif i == 13 or i == 14 then v = 3
      elseif i == 16 then v = m end
      put(i, y0 + 3, v)
    end
  end
end

local function drum_key(x, y, z)
  local l = (y <= 3) and 1 or 2
  local r = (y - 1) % 3 + 1
  local ln = lanes[l]
  if r == 1 then
    -- step: tap toggles, hold toggles accent
    local id = x .. "," .. y
    if z == 1 then
      drum_press[id] = util.time()
    elseif drum_press[id] then
      local held_for = util.time() - drum_press[id]
      drum_press[id] = nil
      if x > ln.len then return end
      drum_edit()
      ln.vel[x] = nil   -- a grid edit goes back to the fixed velocities
      if held_for >= ACCENT_HOLD then
        ln.steps[x] = (ln.steps[x] == 2) and 1 or 2
      else
        ln.steps[x] = (ln.steps[x] > 0) and 0 or 1
      end
    end
    return
  end
  if z == 0 then return end
  if r == 2 then
    drum_edit()
    ln.len = x
  elseif r == 3 then
    if x <= #DIVS then
      drum_edit()
      ln.div = x
    elseif x == 13 then drum_shift(l, -1)
    elseif x == 14 then drum_shift(l, 1)
    elseif x == 16 then
      quantized("dmute" .. l, function() ln.mute = not ln.mute end)
    end
  end
end

-- SAVE page ---------------------------------------------------------

local SAVE_DIR = _path.data .. "sci/"
local OLD_DIR = _path.data .. "mpecap/"   -- saves from before the rename
local function slot_dir(n) return SAVE_DIR .. string.format("slot%02d/", n) end
local function slot_file(n) return slot_dir(n) .. "session.data" end

local function msg(m) save_msg, save_msg_t = m, now() end

local function scan_slots()
  for n = 1, 16 do slot_used[n] = util.file_exists(slot_file(n)) end
end

local function copy_pattern(pat)
  local out = {}
  for _, n in ipairs(pat) do
    local c = {start = n.start, length = n.length, pitch = n.pitch, vel = n.vel, curve = {}}
    for _, p in ipairs(n.curve) do
      table.insert(c.curve, {t = p.t, bend = p.bend, slide = p.slide, pressure = p.pressure})
    end
    table.insert(out, c)
  end
  return out
end

local function save_slot(n)
  if recording then stop_rec() end
  for t, tr in ipairs(tracks) do
    if tr.arec then a_rec(t, false) end
    tr.print = nil
  end
  util.make_dir(slot_dir(n))
  local data = {
    version = 1, bars = bars, tempo = params:get("clock_tempo"), a_len = a_len,
    tracks = {},
  }
  for t, tr in ipairs(tracks) do
    data.tracks[t] = {
      pattern = copy_pattern(tr.pattern), midi_on = tr.midi_on,
      has_audio = tr.has_audio, audio_on = tr.audio_on, gain = tr.gain,
      rev = tr.rev, fx = tr.fx, fade = tr.fade,
    }
    local wav = slot_dir(n) .. "t" .. t .. ".wav"
    if tr.has_audio then
      softcut.buffer_write_mono(wav, a_start(t), a_len, a_buf(t))
    elseif util.file_exists(wav) then
      os.remove(wav)
    end
  end
  data.drums = drum_snapshot()
  tab.save(data, slot_file(n))
  params:write(slot_dir(n) .. "params.pset")
  slot_used[n] = true
  msg("saved slot " .. n)
end

local function read_slot(n)
  if not slot_used[n] then msg("slot " .. n .. " is empty"); return nil end
  local data = tab.load(slot_file(n))
  if not data or not data.tracks then msg("slot " .. n .. " unreadable"); return nil end
  return data
end

-- load one track's MIDI from a slot into track t (undoable)
local function load_track_midi(n, src, t, data)
  data = data or read_slot(n)
  if not data then return end
  local s = data.tracks[src]
  local tr = tracks[t]
  if recording and rec_track == tr then stop_rec() end
  tr.history = {{kind = "clear", pattern = tr.pattern, history = tr.history}}
  tr.pattern = copy_pattern(s.pattern or {})
  tr.midi_on = s.midi_on ~= false
end

-- load one track's audio from a slot into track t (undo restores)
local function load_track_audio(n, src, t, data)
  data = data or read_slot(n)
  if not data then return end
  local s = data.tracks[src]
  local tr = tracks[t]
  if tr.arec then a_rec(t, false) end
  tr.print = nil
  a_backup_now(t)
  local wav = slot_dir(n) .. "t" .. src .. ".wav"
  softcut.buffer_clear_region_channel(a_buf(t), a_start(t), A_MAX)
  if s.has_audio and util.file_exists(wav) then
    softcut.buffer_read_mono(wav, 0, a_start(t), math.min(data.a_len or a_len, A_MAX), 1, a_buf(t))
    tr.has_audio = true
  else
    tr.has_audio = false
  end
  tr.audio_on = s.audio_on ~= false
  tr.gain = s.gain or tr.gain
  a_level(t)
  if data.a_len and math.abs(data.a_len - a_len) > 0.01 then
    msg("T" .. t .. " audio was " .. string.format("%.1fs", data.a_len)
      .. ", loop is " .. string.format("%.1fs", a_len))
  end
end

local function load_slot(n)
  local data = read_slot(n)
  if not data then return end
  if recording then stop_rec() end
  -- restore tempo and length first so audio lines up
  if data.tempo then params:set("clock_tempo", data.tempo) end
  bars = util.clamp(data.bars or bars, 1, 8)
  loop_beats = bars * 4
  head = head % loop_beats
  a_len = math.min(data.a_len or a_len, A_MAX)
  for t = 1, NT do
    softcut.loop_start(t, a_start(t))
    softcut.loop_end(t, a_start(t) + a_len)
  end
  for t = 1, NT do
    load_track_midi(n, t, t, data)
    load_track_audio(n, t, t, data)
    local s = data.tracks[t]
    tracks[t].rev, tracks[t].fx, tracks[t].fade = s.rev or false, s.fx or false, s.fade or false
    a_filter(t)
  end
  if data.drums then
    drum_edit()
    drum_restore(data.drums)
  end
  a_update_rates(true)
  msg("loaded slot " .. n)
end

local function delete_slot(n)
  if not slot_used[n] then return end
  for t = 1, NT do os.remove(slot_dir(n) .. "t" .. t .. ".wav") end
  os.remove(slot_dir(n) .. "params.pset")
  os.remove(slot_file(n))
  os.remove(slot_dir(n))
  slot_used[n] = false
  msg("deleted slot " .. n)
end

local function draw_save_page(blink, fast)
  for n = 1, 16 do
    local l = slot_used[n] and 6 or 1
    if n == slot then l = slot_used[n] and 15 or 8 end
    g:led(n, 1, l)
  end
  local holding = save_hold ~= nil
  g:led(1, 2, holding and (fast and 15 or 4) or 10)
  g:led(3, 2, slot_used[slot] and 10 or 2)
  g:led(16, 2, slot_used[slot] and 4 or 1)
  for t = 1, NT do
    g:led(1, t + 2, slot_used[slot] and 7 or 1)
    g:led(2, t + 2, slot_used[slot] and 7 or 1)
    -- what the current tracks hold
    g:led(4, t + 2, #tracks[t].pattern > 0 and 4 or 0)
    g:led(5, t + 2, tracks[t].has_audio and 4 or 0)
  end
end

local function save_key(x, y, z)
  if y == 2 and (x == 1 or x == 16) then
    -- SAVE needs a 1 s hold, DELETE a 2 s hold
    if z == 1 then
      local n = slot
      save_hold = clock.run(function()
        clock.sleep(x == 1 and 1 or 2)
        save_hold = nil
        if x == 1 then save_slot(n) else delete_slot(n) end
      end)
    elseif save_hold then
      clock.cancel(save_hold)
      save_hold = nil
    end
    return
  end
  if z == 0 then return end
  if y == 1 then slot = x; return end
  if y == 2 and x == 3 then load_slot(slot); return end
  local t = y - 2
  if t >= 1 and t <= NT then
    select_track(t)
    -- loads the same-numbered track from the slot into this track
    if x == 1 then load_track_midi(slot, t, t); msg("T" .. t .. " MIDI from slot " .. slot)
    elseif x == 2 then load_track_audio(slot, t, t) end
  end
end

-- QUANT page --------------------------------------------------------

local function draw_quant_page(blink, fast)
  -- row 1: launch quantize
  for i = 1, #LAUNCH do g:led(i, 1, i == launch_q and 15 or 4) end
  if #pending > 0 then g:led(16, 1, fast and 15 or 0) end
  -- rows 2-5: one per track
  for t, tr in ipairs(tracks) do
    local y = t + 1
    local gi, si = params:get("qgrid_" .. t), params:get("qstr_" .. t)
    for i = 1, 5 do g:led(i, y, i == gi and 15 or (t == sel and 4 or 2)) end
    for i = 1, 4 do g:led(6 + i, y, i <= si and (gi > 1 and 10 or 4) or 1) end
    g:led(12, y, (gi > 1 and #tr.pattern > 0) and 6 or 1)
    local function pl(tag, on)
      if pend_tag[tag] then return fast and 15 or 2 end
      return on and 10 or 2
    end
    g:led(14, y, pl("mon" .. t, tr.midi_on))
    g:led(15, y, pl("aon" .. t, tr.audio_on))
    local st = a_state(t)
    local b = ({empty = 1, rec = fast and 15 or 3, print = fast and 15 or 3,
      dub = blink and 15 or 7, play = 12, stop = 4})[st] or 1
    if pend_tag["big" .. t] then b = fast and 15 or 0 end
    g:led(16, y, b)
  end
  -- row 6: what the tape drives
  local td = params:get("tape_drives")
  for i = 1, 3 do g:led(i, 6, i == td and 15 or 4) end
end

local function quant_key(x, y, z)
  if z == 0 then return end
  if y == 1 then
    if x <= #LAUNCH then launch_q = x end
    return
  end
  if y == 6 then
    if x <= 3 then
      params:set("tape_drives", x)
      a_update_rates(true)
    end
    return
  end
  local t = y - 1
  if t < 1 or t > NT then return end
  local tr = tracks[t]
  select_track(t)
  if x <= 5 then params:set("qgrid_" .. t, x)
  elseif x >= 7 and x <= 10 then params:set("qstr_" .. t, x - 6)
  elseif x == 12 then apply_quant(t)
  elseif x == 14 then
    quantized("mon" .. t, function() tr.midi_on = not tr.midi_on end)
  elseif x == 15 then
    quantized("aon" .. t, function() tr.audio_on = not tr.audio_on; a_level(t) end)
  elseif x == 16 then
    quantized("big" .. t, function() a_big(t) end)
    if not playing then start_play() end
  end
end

local function grid_redraw()
  g:all(0)
  local blink = math.floor(now() * 2) % 2 == 0

  local fast = math.floor(now() * 6) % 2 == 0
  if page == "midi" then draw_midi_page()
  elseif page == "audio" then draw_audio_page(blink)
  elseif page == "loop" then draw_loop_page(blink, fast)
  elseif page == "quant" then draw_quant_page(blink, fast)
  elseif page == "save" then draw_save_page(blink, fast)
  else draw_drum_page(blink, fast) end

  -- tape row
  g:led(1, 7, dir < 0 and 15 or 3)
  g:led(3, 7, braking and 15 or 3)
  g:led(5, 7, (dir > 0 and target == 1 and not braking) and 6 or 3)
  g:led(7, 7, flutter_on and 12 or 3)
  g:led(8, 7, ({midi = 2, audio = 5, loop = 8, quant = 11, drum = 13, save = 15})[page])
  local si, exact = speed_index()
  for i = 1, 8 do
    local lvl = (i == 5) and 4 or 2
    if i == si then lvl = exact and 15 or 9 end
    g:led(8 + i, 7, lvl)
  end

  -- transport row
  local rec_on = (page == "midi") and recording or T().arec
  if page == "drum" then rec_on = CTL.drum_rec end
  g:led(1, 8, rec_on and (blink and 15 or 8) or 4)
  g:led(2, 8, playing and 15 or 4)
  local can_undo = (page == "midi") and (#T().history > 0) or T().a_undo
  if page == "drum" then can_undo = #drum_hist > 0 end
  g:led(3, 8, can_undo and 8 or 2)
  local has = (page == "midi") and (#T().pattern > 0) or T().has_audio
  if page == "drum" then
    has = false
    for l = 1, 2 do for i = 1, 16 do if lanes[l].steps[i] > 0 then has = true end end end
  end
  g:led(4, 8, clear_hold and (blink and 15 or 4) or (has and 4 or 2))
  for t, tr in ipairs(tracks) do
    local lvl = (#tr.pattern > 0 or tr.has_audio) and 5 or 2
    if t == sel then lvl = 15 end
    g:led(4 + t, 8, lvl)
  end
  for b = 1, 8 do
    g:led(8 + b, 8, b < bars and 6 or (b == bars and 15 or 2))
  end

  g:refresh()
end

-- a short name for any grid key on the current page, shown on screen
UI.SPEED_NAMES = {"1/4x", "1/2x", "2/3x", "3/4x", "1x", "4/3x", "3/2x", "2x"}
UI.LAUNCH_NAMES = {"off", "beat", "bar", "2 bars", "loop"}
UI.GRID_NAMES = {"off", "1/4", "1/8", "1/16", "1/32"}

function UI.key_label(x, y)
  if y == 7 then
    if x == 1 then return "REVERSE"
    elseif x == 3 then return "BRAKE (hold)"
    elseif x == 5 then return "RESYNC 1x"
    elseif x == 7 then return "FLUTTER on/off"
    elseif x == 8 then return "PAGE (next)"
    elseif x >= 9 then return "speed " .. UI.SPEED_NAMES[x - 8] end
    return "unused"
  elseif y == 8 then
    if x == 1 then return page == "drum" and "REC pads (nanoPAD2)" or "REC"
    elseif x == 2 then return "PLAY / stop"
    elseif x == 3 then return "UNDO"
    elseif x == 4 then return "CLEAR (hold 1s)"
    elseif x <= 8 then return "select track " .. (x - 4)
    else return "loop " .. (x - 8) .. (x == 9 and " bar" or " bars") end
  end
  if page == "midi" then
    return "note " .. note_name(row_pitch(y)) .. " step " .. x
  elseif page == "audio" then
    if y <= NT then return "select track " .. y end
    local t, i = math.floor((x - 1) / 4) + 1, (x - 1) % 4 + 1
    if y == 5 then
      return "T" .. t .. " " .. ({"audio REC", "audio on/off", "MIDI on/off", "PRINT"})[i]
    end
    return "T" .. t .. " level " .. math.floor(LEVELS[i] * 100) .. "%"
  elseif page == "loop" then
    local t, c = math.floor((x - 1) / 4) + 1, (x - 1) % 4 + 1
    local p = "T" .. t .. " "
    if c == 1 then return p .. "fader " .. math.floor((7 - y) / 6 * 100 + 0.5) .. "%" end
    if c == 4 then
      return p .. ({"FX (hold+E2/E3)", "REVERSE", "MIDI on/off", "PRINT",
        "FOLLOW tape", "FADE in/out"})[y]
    end
    if y <= 2 then return p .. "position ring" end
    if y <= 4 then return p .. "REC>DUB>PLAY" end
    return p .. "STOP (hold=clear)"
  elseif page == "quant" then
    if y == 1 then
      if x <= #LAUNCH then return "launch q: " .. UI.LAUNCH_NAMES[x] end
      if x == 16 then return "waiting light" end
      return "unused"
    elseif y == 6 then
      return x <= 3 and ("tape drives " .. ({"both", "MIDI", "audio"})[x]) or "unused"
    end
    local p = "T" .. (y - 1) .. " "
    if x <= 5 then return p .. "note grid " .. UI.GRID_NAMES[x]
    elseif x >= 7 and x <= 10 then return p .. "strength " .. (x - 6) * 25 .. "%"
    elseif x == 12 then return p .. "APPLY quantize"
    elseif x == 14 then return p .. "MIDI on/off"
    elseif x == 15 then return p .. "audio on/off"
    elseif x == 16 then return p .. "REC>DUB>PLAY" end
    return "unused"
  elseif page == "save" then
    if y == 1 then return "slot " .. x .. (slot_used[x] and " (saved)" or " (empty)") end
    if y == 2 then
      if x == 1 then return "SAVE (hold 1s)"
      elseif x == 3 then return "LOAD all"
      elseif x == 16 then return "DELETE (hold 2s)" end
      return "unused"
    end
    local p = "T" .. (y - 2) .. " "
    if x == 1 then return p .. "load MIDI"
    elseif x == 2 then return p .. "load audio"
    elseif x == 4 then return p .. "has MIDI"
    elseif x == 5 then return p .. "has audio" end
    return "unused"
  elseif page == "drum" then
    local l = (y <= 3) and 1 or 2
    local r = (y - 1) % 3 + 1
    local p = "L" .. l .. " "
    if r == 1 then return p .. "step " .. x .. " (hold=acc)" end
    if r == 2 then return p .. "length " .. x end
    if x <= #DIVS then return p .. "clock " .. DIVS[x].name
    elseif x == 13 then return p .. "shift left"
    elseif x == 14 then return p .. "shift right"
    elseif x == 16 then return p .. "MUTE" end
    return "unused"
  end
  return ""
end

g.key = function(x, y, z)
  if z == 1 then
    last_key = "r" .. y .. " k" .. x .. " " .. UI.key_label(x, y)
    last_key_t = util.time()
  end
  if y <= ROWS then
    if page == "midi" then editor_key(x, y, z)
    elseif page == "audio" then audio_key(x, y, z)
    elseif page == "loop" then loop_key(x, y, z)
    elseif page == "quant" then quant_key(x, y, z)
    elseif page == "save" then save_key(x, y, z)
    else drum_key(x, y, z) end
    return
  end
  if y == 7 then
    if x == 3 then braking = (z == 1); return end
    if z == 0 then return end
    if x == 1 then set_reverse(dir > 0)
    elseif x == 5 then resync()
    elseif x == 7 then flutter_on = not flutter_on
    elseif x == 8 then
      local i = 1
      for k, p in ipairs(PAGES) do if p == page then i = k end end
      page = PAGES[i % #PAGES + 1]
      page_flash_t = util.time()
      if page == "save" then scan_slots() end
      gheld = {}
      fx_held = nil
    elseif x >= 9 then set_target(SPEEDS[x - 8])
    end
    return
  end
  if y == 8 and x == 4 then
    -- clear needs a 1 second hold, so a stray tap can't wipe the loop
    if z == 1 then
      clear_hold = clock.run(function()
        clock.sleep(1)
        clear_hold = nil
        do_clear()
      end)
    elseif clear_hold then
      clock.cancel(clear_hold)
      clear_hold = nil
    end
    return
  end
  if z == 0 then return end
  if x == 1 then do_rec()
  elseif x == 2 then
    if playing then stop_play() elseif not starting then start_play() end
  elseif x == 3 then do_undo()
  elseif x >= 5 and x <= 8 then select_track(x - 4)
  elseif x >= 9 then set_bars(x - 8)
  end
end

-- norns UI ------------------------------------------------------------

function key(n, z)
  if n == 1 then
    if z == 1 then
      k1, k1_used = true, false
    else
      k1 = false
      -- a tap of K1 on its own switches between guide and reels
      if not k1_used then params:set("view", params:get("view") == 1 and 2 or 1) end
    end
    return
  end
  if k1 then k1_used = true end
  if z == 0 then return end
  if n == 2 then
    if k1 then do_undo() else do_rec() end
  elseif n == 3 then
    if k1 then resync()
    elseif playing then stop_play()
    elseif not starting then start_play() end
  end
end

function enc(n, d)
  if k1 then k1_used = true end
  if fx_held and (n == 2 or n == 3) then
    local t = fx_held
    tracks[t].fx_moved = true
    if not tracks[t].fx then tracks[t].fx = true end
    if n == 2 then params:delta("cutoff_" .. t, d)
    else params:delta("rq_" .. t, -d) end
    a_filter(t)
    return
  end
  if n == 1 then
    params:delta("flutter", d)
    flutter_on = params:get("flutter") > 0
  elseif n == 2 then
    set_bars(bars + d)
  elseif n == 3 then
    if k1 then
      pitch_base = util.clamp(pitch_base + d, 0, 128 - ROWS)
    else
      set_target(target * 2 ^ (d / 12))
    end
  end
end

function UI.draw_reel(cx, cy, r, ang)
  screen.level(6)
  screen.circle(cx, cy, r)
  screen.stroke()
  screen.level(2)
  screen.circle(cx, cy, 3)
  screen.fill()
  screen.level(10)
  for i = 0, 2 do
    local a = ang + i * 2 * math.pi / 3
    screen.move(cx + math.cos(a) * 4, cy + math.sin(a) * 4)
    screen.line(cx + math.cos(a) * (r - 2), cy + math.sin(a) * (r - 2))
    screen.stroke()
  end
end

UI.boot_t = nil

UI.TABS = {
  {id = "midi", label = "MIDI"}, {id = "audio", label = "AUD"},
  {id = "loop", label = "LOOP"}, {id = "quant", label = "QNT"},
  {id = "drum", label = "DRUM"}, {id = "save", label = "SAVE"},
}
UI.PAGE_INFO = {
  midi = {"MIDI", "note editor"},
  audio = {"AUDIO", "4 tracks + controls"},
  loop = {"LOOP", "505-style strips"},
  quant = {"QUANT", "launch + quantize"},
  save = {"SAVE", "16 save slots"},
  drum = {"DRUM", "2 trigger lanes"},
}

-- tabs across the top: the grid's current page is highlighted
-- what rows 1-6 do on each page (4 lines, kept short for the screen)
UI.GUIDE = {
  midi = {"tap: add/delete note", "hold+tap right: length",
    "hold+play: step record", "K1+E3 pitch  E3 speed"},
  audio = {"1-4: tap = select track", "5: rec aud midi print x4",
    "6: level 25-100% x4", "print: midi>audio 1 lap"},
  loop = {"one 4-col strip/track", "c1 fader  c2-3 rows3-4", "  REC>DUB>PLAY, 5-6 STOP",
    "c4 fx rev mid prt fol fad"},
  quant = {"1: off beat bar 2bar loop", "2-5 T1-4: 1-5 grid,", "  7-10 str 12 apply",
    "  14 mid 15 aud 16 rec"},
  save = {"1: pick slot 1-16", "2: k1 SAVE(hold) k3 LOAD", "   k16 DELETE (hold)",
    "3-6 T1-4: k1 midi k2 aud"},
  drum = {"1/4: steps, hold=accent", "2/5: length 1-16", "3/6: clock 1-8",
    "  13/14 shift 16 mute"},
}
UI.ROW78 = {"7: rev brk sync flut PAGE", "8: rec play undo clr T1-4"}

-- the page's status in one line
function UI.info_line()
  local tr = T()
  if fx_held then
    return "T" .. fx_held .. " FX cut " .. math.floor(params:get("cutoff_" .. fx_held))
      .. " res " .. string.format("%.2f", params:get("rq_" .. fx_held))
  elseif page == "midi" then
    return "T" .. sel .. " midi " .. bars .. "b " .. #tr.pattern .. "n "
      .. note_name(pitch_base) .. "-" .. note_name(pitch_base + ROWS - 1)
  elseif page == "drum" then
    local function d(l)
      local ln = lanes[l]
      return ln.len .. "/" .. DIVS[ln.div].name .. (ln.mute and "m" or "")
    end
    return "DRUM 1:" .. d(1) .. "  2:" .. d(2)
  elseif page == "save" then
    if now() - save_msg_t < 6 and save_msg ~= "" then return save_msg end
    return "SAVE slot " .. slot .. (slot_used[slot] and " (saved)" or " (empty)")
  elseif page == "quant" then
    return "QUANT " .. UI.LAUNCH_NAMES[launch_q] .. "  T" .. sel .. " "
      .. UI.GRID_NAMES[params:get("qgrid_" .. sel)] .. (#pending > 0 and "  wait" or "")
  elseif page == "loop" then
    return "T" .. sel .. " LOOP " .. bars .. "b " .. string.upper(a_state(sel))
  end
  local s = tr.print == "armed" and "print next lap"
    or tr.print == "rec" and "printing"
    or (tr.has_audio and "audio" or "empty")
  return "T" .. sel .. " AUDIO " .. bars .. "b " .. s
end

function UI.draw_tabs()
  local w = 21
  for i, tb in ipairs(UI.TABS) do
    local x = (i - 1) * w + 1
    if tb.id == page then
      screen.level(15)
      screen.rect(x, 0, w - 1, 8)
      screen.fill()
      screen.level(0)
    else
      screen.level(3)
    end
    screen.move(x + (w - 1) / 2, 6)
    screen.text_center(tb.label)
  end
end

-- big page name for a moment after switching
function UI.draw_page_flash()
  local info = UI.PAGE_INFO[page]
  screen.level(0)
  screen.rect(4, 12, 120, 32)
  screen.fill()
  screen.level(15)
  screen.rect(4, 12, 120, 32)
  screen.stroke()
  screen.font_size(16)
  screen.move(64, 30)
  screen.text_center(info[1])
  screen.font_size(8)
  screen.level(6)
  screen.move(64, 40)
  screen.text_center(info[2])
end

function redraw()
  screen.clear()
  if UI.boot_t == nil then UI.boot_t = util.time() end
  if util.time() - UI.boot_t < 2.5 then
    screen.level(15)
    screen.move(64, 26)
    screen.text_center("S.C.I.E.N.C.E.")
    screen.level(5)
    screen.move(64, 40)
    screen.text_center("south central indiana")
    screen.move(64, 50)
    screen.text_center("electro noise circuit experiment")
    screen.update()
    return
  end
  screen.line_width(1)
  screen.font_size(8)
  UI.draw_tabs()
  local tr = T()
  local st = playing and (dir < 0 and "<<REV" or "PLAY>") or "stop"
  local rec_on = (page == "midi") and recording or tr.arec
  if page == "drum" then rec_on = CTL.drum_rec end
  -- bottom line: the last grid key pressed, for a few seconds, else page status
  local bottom = (util.time() - last_key_t < 3) and last_key or UI.info_line()

  if params:get("view") == 1 then
    -- guide view
    screen.level(15)
    screen.move(0, 16)
    screen.text(st .. (rec_on and " REC" or "") .. "  T" .. sel)
    screen.move(128, 16)
    screen.text_right(string.format("%.2fx", speed) .. (braking and " brk" or "")
      .. (flutter_on and " ~" or ""))
    screen.level(8)
    for i, line in ipairs(UI.GUIDE[page]) do
      screen.move(0, 16 + i * 8)
      screen.text(line)
    end
    screen.level(4)
    screen.move(0, 56)
    screen.text(UI.ROW78[math.floor(util.time() / 3) % 2 + 1])
    screen.level((util.time() - last_key_t < 3) and 15 or 6)
    screen.move(0, 63)
    screen.text(bottom)
  else
    -- reels view
    UI.draw_reel(30, 25, 12, reel_angle)
    UI.draw_reel(98, 25, 12, reel_angle * 0.8)
    screen.level(4)
    screen.move(30, 41); screen.line(98, 41); screen.stroke()
    if playing then
      local x = 30 + math.floor(head / loop_beats * 68)
      screen.level(15)
      screen.move(x, 38); screen.line(x, 44); screen.stroke()
    end
    screen.level(15)
    screen.move(0, 52)
    screen.text(st .. (rec_on and "  REC" or ""))
    screen.move(128, 52)
    screen.text_right(string.format("%.2fx", speed) .. (braking and " brk" or ""))
    screen.level((util.time() - last_key_t < 3) and 15 or 5)
    screen.move(0, 62)
    screen.text(bottom)
  end
  if util.time() - page_flash_t < 1.2 then UI.draw_page_flash() end
  screen.update()
end

-- init ------------------------------------------------------------------

function init()
  local names = {}
  for i = 1, #midi.vports do
    names[i] = i .. ": " .. (midi.vports[i].name or "none")
  end

  params:add_separator("S.C.I.E.N.C.E.")
  params:add_option("midi_in", "LinnStrument in", names, 1)
  params:set_action("midi_in", function(i)
    if mpe_in then mpe_in.event = nil end
    mpe_in = midi.connect(i)
    mpe_in.event = on_midi
  end)
  params:add_option("thru", "thru (hear live)", {"off", "on"}, 2)

  -- Korg nanoKEY / nanoPAD2 (found by name; "none" if not plugged in)
  local ports = {"none"}
  for i = 1, #names do ports[i + 1] = names[i] end
  local function find_korg(pattern)
    for i = 1, #midi.vports do
      if string.find(string.lower(midi.vports[i].name or ""), pattern) then return i + 1 end
    end
    return 1
  end
  local function hook(id, field, handler)
    params:set_action(id, function(i)
      if CTL[field] then CTL[field].event = nil; CTL[field] = nil end
      -- never take over the LinnStrument's port
      if i > 1 and (i - 1) ~= params:get("midi_in") then
        CTL[field] = midi.connect(i - 1)
        CTL[field].event = handler
      end
    end)
  end
  params:add_group("controllers", 7)
  params:add_option("keys_in", "nanoKEY in", ports, find_korg("nanokey"))
  hook("keys_in", "keys_in", CTL.on_keys)
  params:add_option("keys_track", "nanoKEY plays",
    {"track 1", "track 2", "track 3", "track 4", "selected track"}, 3)
  params:add_option("pads_in", "nanoPAD2 in", ports, find_korg("nanopad"))
  hook("pads_in", "pads_in", CTL.on_pads)
  params:add_number("pad_note_1", "pad note: lane 1", 0, 127, 36)
  params:add_number("pad_note_2", "pad note: lane 2", 0, 127, 38)
  params:add_number("pad_accent", "accent from velocity", 1, 127, 100)
  params:add_option("pad_mode", "pads", {"kit: lanes", "tuned: all thru"}, 1)
  params:add_number("in_bend", "LinnStrument bend range", 1, 96, 48)
  params:add_number("out_bend", "synth bend range", 1, 96, 48)
  params:add_number("slide_cc", "slide (Y) cc", 0, 127, 74)

  -- default ports, found by name where possible:
  --   track 1 Nymphes   -> Electra Controller 1 (Mini host Port 1)
  --   track 2 Micromonsta 2 -> Electra Controller 2 (Mini host Port 2)
  --   track 3 Hades     -> the U2MIDI (USB to 5-pin DIN), channel 2, mono
  --   (the Hades' internal DIP switch 3 sets it to channel 2)
  local function find_port(pattern, fallback)
    for i = 1, #midi.vports do
      local n = string.lower(midi.vports[i].name or "")
      if string.find(n, pattern) then return i end
    end
    return math.min(fallback, math.max(#names, 1))
  end
  local e1 = find_port("electra.*1", 2)
  local u2 = nil
  for i = 1, #midi.vports do
    local n = string.lower(midi.vports[i].name or "")
    if string.find(n, "u2midi") or string.find(n, "cme") then u2 = i; break end
  end
  local e2 = find_port("electra.*2", e1)
  -- the shield's TRS MIDI port: the first device that isn't the Electra,
  -- the LinnStrument or an empty slot (check it in PARAMS)
  UI.TRS_PORT = nil
  for i = 1, #midi.vports do
    local n = string.lower(midi.vports[i].name or "")
    if n ~= "" and n ~= "none" and not string.find(n, "electra")
        and not string.find(n, "linn") and not string.find(n, "nano")
        and not string.find(n, "u2midi") and not string.find(n, "cme") then
      UI.TRS_PORT = i
      break
    end
  end
  UI.TRS_PORT = UI.TRS_PORT or math.min(3, math.max(#names, 1))
  UI.TRACK_PORT = {e1, e2, u2 or UI.TRS_PORT, e1}
  UI.TRACK_CH = {{2, 7}, {2, 7}, {2, 2}, {2, 7}}

  for t = 1, NT do
    params:add_group("track " .. t, 8)
    params:add_option("out_" .. t, "synth out", names, UI.TRACK_PORT[t])
    params:set_action("out_" .. t, function(i)
      all_off()
      tracks[t].out = midi.connect(i)
    end)
    params:add_number("ch_lo_" .. t, "first member ch", 1, 16, UI.TRACK_CH[t][1])
    params:add_number("ch_hi_" .. t, "last member ch", 1, 16, UI.TRACK_CH[t][2])
    params:add_option("follow_" .. t, "audio follows tape", {"no", "yes"}, 2)
    params:add_control("cutoff_" .. t, "fx cutoff",
      controlspec.new(40, 16000, "exp", 0, 1200, "Hz"))
    params:add_control("rq_" .. t, "fx resonance (rq)",
      controlspec.new(0.05, 2, "exp", 0, 0.6, ""))
    params:add_option("qgrid_" .. t, "note quantize",
      {"off", "1/4", "1/8", "1/16", "1/32"}, 1)
    params:add_option("qstr_" .. t, "quantize strength",
      {"25%", "50%", "75%", "100%"}, 4)
  end

  params:add_separator("grid notes")
  params:add_number("grid_vel", "velocity", 1, 127, 100)
  params:add_number("grid_pressure", "pressure", 0, 127, 0)
  params:add_number("grid_slide", "slide (Y)", 0, 127, 64)

  params:add_separator("audio")
  params:add_control("overdub", "overdub keeps (old level)",
    controlspec.new(0, 1, "lin", 0.01, 1, ""))
  params:add_option("print_mute", "mute midi after print", {"no", "yes"}, 2)
  params:add_option("rec_action", "LOOP rec action", {"REC>DUB", "REC>PLAY"}, 1)
  params:add_control("fade_time", "LOOP fade time (s)",
    controlspec.new(0.05, 8, "lin", 0.05, 1.5, "s"))

  params:add_separator("drums (Alecto)")
  params:add_option("drum_out", "drum out", names, UI.TRS_PORT)
  params:set_action("drum_out", function(i) drum_out = midi.connect(i) end)
  params:add_number("drum_ch_1", "voice 1 channel", 1, 16, 10)
  params:add_number("drum_note_1", "voice 1 note", 0, 127, 36)
  params:add_number("drum_ch_2", "voice 2 channel", 1, 16, 10)
  params:add_number("drum_note_2", "voice 2 note", 0, 127, 38)
  params:add_number("drum_vel", "velocity", 1, 127, 80)
  params:add_number("drum_vel_acc", "accent velocity", 1, 127, 127)
  params:add_number("drum_gate", "trigger length (ms)", 1, 200, 15)

  params:add_separator("screen")
  params:add_option("view", "screen view (K1 tap)", {"guide", "reels"}, 1)

  params:add_separator("tape")
  params:add_option("tape_drives", "tape drives", {"MIDI+audio", "MIDI only", "audio only"}, 1)
  params:add_option("pitch_follow", "speed bends pitch", {"off", "on"}, 2)
  params:add_control("slew", "varispeed slew (s)",
    controlspec.new(0, 2, "lin", 0.01, 0.15, "s"))
  params:add_control("brake_time", "brake time (s)",
    controlspec.new(0.05, 4, "lin", 0.01, 0.8, "s"))
  params:add_number("flutter", "flutter depth (%)", 0, 10, 1)
  params:bang()

  a_init()
  -- carry saves over from the old mpecap name, once
  if not util.file_exists(SAVE_DIR) and util.file_exists(OLD_DIR) then
    os.rename(OLD_DIR, SAVE_DIR)
  end
  util.make_dir(SAVE_DIR)
  scan_slots()
  clock.run(ticker)
  local m = metro.init(function()
    grid_redraw()
    redraw()
  end, 1/30)
  m:start()
end

function cleanup()
  all_off()
  softcut.poll_stop_phase()
end
