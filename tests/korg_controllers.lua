init(); X = _expose()
local P = X.P
print("keys_in", P:get("keys_in"), "pads_in", P:get("pads_in"), "keys plays", P:get("keys_track"))
print("handlers hooked:", X.CTL.keys_in ~= nil and X.CTL.keys_in.event ~= nil, X.CTL.pads_in ~= nil and X.CTL.pads_in.event ~= nil)
local kin, pin = X.CTL.keys_in, X.CTL.pads_in
-- nanoKEY thru plays track 3 (Hades) on ch 12, even with track 1 selected
log = {}
kin.event({type="note_on", ch=1, note=45, vel=90}); kin.event({type="note_off", ch=1, note=45, vel=0})
for _,e in ipairs(log) do print("keys thru", e[1], e[2], "ch", e[3], e[4]) end
-- record with nanoKEY: select track 3, REC, play a note across ticks
X.setplay(); X.gk(7,8,1); X.gk(7,8,0); X.setpage("midi")
key(2,1); key(2,0)          -- REC (not quantized: launch q off)
kin.event({type="note_on", ch=1, note=45, vel=90}); advance(48); kin.event({type="note_off", ch=1, note=45, vel=0})
key(2,1); key(2,0)
local n = X.tr(3).pattern[1]
print("T3 notes", #X.tr(3).pattern, n and n.pitch, n and n.length, "T1 notes", #X.tr(1).pattern)
X.gk(3,8,1); X.gk(3,8,0); print("undo -> T3 notes", #X.tr(3).pattern)
-- step record with a held grid key on the MIDI page (track 3 selected)
X.gk(5,6,1); kin.event({type="note_on", ch=1, note=50, vel=90}); advance(10); kin.event({type="note_off", ch=1, note=50, vel=0}); X.gk(5,6,0)
print("step rec T3", #X.tr(3).pattern, X.tr(3).pattern[1] and X.tr(3).pattern[1].start)
-- nanoPAD2: live hits
X.setpage("drum"); log = {}
pin.event({type="note_on", ch=10, note=36, vel=60}); pin.event({type="note_on", ch=10, note=38, vel=120}); pin.event({type="note_on", ch=10, note=40, vel=120})
for _,e in ipairs(log) do if e[1]=="on" then print("pad live", e[2], "ch", e[3], "vel", e[5]) end end
-- record pads into lanes
X.setplay2(); key(2,1); key(2,0); print("drum rec", X.CTL.drum_rec)
advance(23)                 -- just before step 2 of lane 1 (1/16 = 24 ticks)
log = {}
pin.event({type="note_on", ch=10, note=36, vel=110})
advance(1)                  -- step 2 arrives: must not double-hit
local ons = 0 for _,e in ipairs(log) do if e[1]=="on" then ons = ons + 1 end end
print("lane1 steps", table.concat(X.lanes[1].steps, ""), "hits around step 2:", ons, "(expect 1)")
advance(24*3+10)            -- mid step 5 -> late hit rounds back to step 5
pin.event({type="note_on", ch=10, note=38, vel=70})
print("lane2 steps", table.concat(X.lanes[2].steps, ""))
key(2,1); key(2,0); print("drum rec off", X.CTL.drum_rec)
X.gk(3,8,1); X.gk(3,8,0); print("undo pass -> lane1", table.concat(X.lanes[1].steps, ""), "lane2", table.concat(X.lanes[2].steps, ""))
redraw(); X.redraw_grid(); print("draw ok")
