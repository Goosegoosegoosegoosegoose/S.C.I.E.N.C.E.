init(); X = _expose()
for t=1,4 do print("track", t, "out", X.P:get("out_"..t), "ch", X.P:get("ch_lo_"..t).."-"..X.P:get("ch_hi_"..t)) end
print("drum out", X.P:get("drum_out"))
-- thru on track 3 (Hades): note on ch 3 -> ch 12, bend skipped
X.gk(7,8,1); X.gk(7,8,0); print("sel", X.sel())
SENT = {}
X.on_midi({0x92, 40, 100, type="note_on", ch=3, note=40, vel=100})
X.on_midi({0xE2, 0, 70, type="pitchbend", ch=3, val=9000})
X.on_midi({0x82, 40, 0, type="note_off", ch=3, note=40, vel=0})
for _, e in ipairs(SENT) do print("sent", e[1], string.format("%02X", e[2]), e[3], e[4]) end
-- thru on track 1 unchanged
X.gk(5,8,1); X.gk(5,8,0); SENT = {}
X.on_midi({0x92, 40, 100, type="note_on", ch=3, note=40, vel=100})
X.on_midi({0xE2, 0, 70, type="pitchbend", ch=3, val=9000})
for _, e in ipairs(SENT) do print("T1 sent", e[1], string.format("%02X", e[2])) end
-- record + play a Hades note on track 3
X.gk(7,8,1); X.gk(7,8,0); X.setplay()
X.setpage("midi"); X.gk(1,6,1); X.gk(1,6,0)
log = {}; advance(16*96)
for _, e in ipairs(log) do if e[1]=="on" then print("play", e[2], "ch", e[3], e[4]) end end
