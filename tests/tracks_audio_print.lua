init(); X = _expose()
local function cnt(kind, port) local c=0 for _,e in ipairs(log) do if e[1]==kind and (not port or e[4]==port) then c=c+1 end end return c end
X.setplay()
-- record on track 1 via K2
X.key(2,1); X.key(2,0)
X.on_midi({type="note_on", ch=2, note=60, vel=100})
for i=1,96 do advance(1); X.on_midi({type="channel_pressure", ch=2, val=math.floor(i*127/96)}) end
X.on_midi({type="note_off", ch=2, note=60, vel=0})
X.key(2,1); X.key(2,0)
print("T1 notes", #X.tr(1).pattern, "T2 notes", #X.tr(2).pattern)
-- select track 2 (row 8 key 6), tap a note in editor
X.gk(6,8,1); X.gk(6,8,0)
print("sel", X.sel())
X.gk(5,6,1); X.gk(5,6,0)
print("T2 notes after tap", #X.tr(2).pattern, "pitch", X.tr(2).pattern[1].pitch)
log={}; advance(16*96)
print("loop: note_ons", cnt("on"))
-- mute midi on track 1 via audio page
X.gk(8,7,1); X.gk(8,7,0); print("page", X.page())
X.gk(3,5,1); X.gk(3,5,0)  -- track1 midi on toggle (key 3 of group 1)
print("T1 midi_on", X.tr(1).midi_on)
log={}; advance(16*96); print("loop after mute: note_ons", cnt("on"))
X.gk(3,5,1); X.gk(3,5,0)
-- audio record track 2 (selected): row 8 rec on audio page
X.gk(1,8,1); X.gk(1,8,0)
local r = sclast("rec_level", 2); print("T2 arec", X.tr(2).arec, "rec_level", r and r[3])
advance(96)
X.gk(1,8,1); X.gk(1,8,0)
print("T2 arec off", X.tr(2).arec, "rec_level", sclast("rec_level",2)[3], "has_audio", X.tr(2).has_audio, "undo avail", X.tr(2).a_undo)
-- audio undo
local copies = sccount("buffer_copy_mono")
X.gk(3,8,1); X.gk(3,8,0)
print("audio undo copied", sccount("buffer_copy_mono") - copies, "undo avail now", X.tr(2).a_undo)
-- print track 1: key 4 of group 1 on row 5
X.gk(4,5,1); X.gk(4,5,0)
print("T1 print", X.tr(1).print)
-- run until wrap
local h = X.head(); local n = 0
while X.tr(1).print == "armed" and n < 20*96 do advance(1); n=n+1 end
print("after wrap:", X.tr(1).print, "rec_level", sclast("rec_level",1)[3], "pre", sclast("pre_level",1)[3], "ticks", n)
n=0
while X.tr(1).print == "rec" and n < 20*96 do advance(1); n=n+1 end
print("print done after ticks", n, "(expect 1536)", "midi_on", X.tr(1).midi_on, "has_audio", X.tr(1).has_audio, "rec_level", sclast("rec_level",1)[3])
-- tape follow: half speed -> audio rate
X.set_target(0.5); advance(4*96)
print("rate v1", sclast("rate",1)[3], "speed", X.speed())
X.set_reverse(true); advance(8)
print("rate v1 reversed", sclast("rate",1)[3])
-- clear audio track 2 by hold: simulate do_clear through clock.run stub? call directly via key hold not possible; check loop len
print("a_len", X.alen(), "(4 bars @120 = 8s)")
X.gk(12,8,1); X.gk(12,8,0); print("a_len 8 bars", X.alen())
