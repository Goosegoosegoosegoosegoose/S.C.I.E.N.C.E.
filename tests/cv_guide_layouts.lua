-- CV guide section 11: nanoKEY mod wheel/bend thru, nanoKEY on ch 10, tuned pads
init(); X = _expose()
local kin, pin = X.CTL.keys_in, X.CTL.pads_in
SENT = {}
kin.event({type="cc", ch=1, cc=1, val=100})          -- mod wheel -> Hades track (ch 2)
kin.event({type="pitchbend", ch=1, val=12000})
for _, e in ipairs(SENT) do print("keys ctl", e[1], string.format("%X", e[2]), e[3], e[4]) end
SENT = {}; log = {}
kin.event({type="note_on", ch=10, note=40, vel=90})  -- nanoKEY on the drum channel
kin.event({type="note_off", ch=10, note=40, vel=0})
for _, e in ipairs(SENT) do print("keys ch10", e[1], string.format("%X", e[2]), e[3], e[4]) end
print("hades got none", #log == 0)
X.P:set("pad_mode", 2); SENT = {}; log = {}
pin.event({type="note_on", ch=10, note=38, vel=77})  -- tuned pad: straight thru, no lane hit
pin.event({type="note_on", ch=10, note=47, vel=64})
for _, e in ipairs(SENT) do print("tuned pad", e[1], string.format("%X", e[2]), e[3], e[4]) end
print("lane hits", #log)
