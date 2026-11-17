init(); X = _expose()
local function cnt(kind) local c=0 for _,e in ipairs(log) do if e[1]==kind then c=c+1 end end return c end
local function first_on() for i,e in ipairs(log) do if e[1]=="on" then return i end end end
X.setplay()
X.setpage("quant")
-- launch quantize = bar (row1 key3)
X.gk(3,1,1); X.gk(3,1,0)
advance(30)  -- mid-beat
-- track 1 audio big button (row2 col16) should wait for the bar
X.gk(16,2,1); X.gk(16,2,0)
print("pending", X.pending(), "state", X.state(1))
local n=0 while X.state(1)=="empty" and n<1000 do advance(1); n=n+1 end
print("fired after ticks", n, "beat", X.now(), "state", X.state(1))
-- press again and cancel before it fires
X.gk(16,2,1); X.gk(16,2,0); print("pending", X.pending())
X.gk(16,2,1); X.gk(16,2,0); print("cancelled pending", X.pending(), "state", X.state(1))
-- note quantize: put a note off-grid on track 1 via MIDI page tap? use direct pattern
local tr = X.tr(1)
table.insert(tr.pattern, {start=1.1, length=0.5, pitch=60, vel=100, curve={{t=0,bend=0,slide=64,pressure=0}}})
X.gk(4,2,1); X.gk(4,2,0) -- grid 1/8 (key 4) for track1 ... index 4 = 1/16 actually
print("qgrid", X.P:get("qgrid_1"), "qstr", X.P:get("qstr_1"))
X.gk(3,2,1); X.gk(3,2,0) -- 1/8 = 0.5 beats
-- run a loop and see the note-on time relative to loop
log={}; local starts={}
for i=1,16*96 do advance(1); for _,e in ipairs(log) do if e[1]=="on" and not starts[1] then starts[1]=X.head() end end end
print("note fired at head", starts[1], "(expect ~1.0 not 1.1)")
-- 50% strength
X.gk(8,2,1); X.gk(8,2,0); print("qstr", X.P:get("qstr_1"))
-- apply + undo
X.gk(12,2,1); X.gk(12,2,0); print("applied start", tr.pattern[1].start)
X.setpage("midi"); X.gk(3,8,1); X.gk(3,8,0); print("undo start", tr.pattern[1].start)
-- tape drives audio only: MIDI head should move at 1x while tape at half
X.setpage("quant"); X.gk(1,1,1); X.gk(1,1,0)
X.gk(3,6,1); X.gk(3,6,0); print("tape_drives", X.P:get("tape_drives"))
X.set_target(0.5); advance(4*96)
local h0 = X.head(); advance(96); print("midi head moved", X.head()-h0, "(expect 1 beat)", "audio rate", sclast("rate",2)[3])
X.gk(2,6,1); X.gk(2,6,0); advance(8); print("MIDI only -> audio rate", sclast("rate",2)[3])
local h1 = X.head(); advance(96); print("midi head moved", X.head()-h1, "(expect 0.5)")
