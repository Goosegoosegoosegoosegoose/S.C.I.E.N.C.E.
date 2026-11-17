init(); X = _expose(); X.P:set("drum_out", 3); X.setpage("drum")
local function tap(x,y) WALL = WALL + 0.1; X.gk(x,y,1); WALL = WALL + 0.1; X.gk(x,y,0) end
local function hold(x,y) X.gk(x,y,1); WALL = WALL + 0.6; X.gk(x,y,0) end
tap(1,1); hold(3,1)   -- hold on an off step: accent (turns it on)
RUNNOW = true; X.setplay2(); log = {}; advance(96)
for _,e in ipairs(log) do if e[1]=="on" then print("note", e[2], "ch", e[3], "vel", e[5], "port", e[4]) end end
