init(); X = _expose()
X.P:set("drum_out", 3)
local P = X.P
X.setpage("drum")
local function tap(x,y) WALL = WALL + 0.1; X.gk(x,y,1); WALL = WALL + 0.1; X.gk(x,y,0) end
local function hold(x,y) X.gk(x,y,1); WALL = WALL + 0.6; X.gk(x,y,0) end
-- lane 1: steps 1,5,9,13 ; step 5 accent
tap(1,1); tap(5,1); tap(9,1); tap(13,1); hold(5,1)
-- lane 2: length 3 (row5 key3), steps 1 only, division 1/8 (row6 key4)
tap(3,5); tap(1,4); tap(4,6)
print("lane1", table.concat(X.lanes[1].steps, ""), "len", X.lanes[1].len, "lane2", table.concat(X.lanes[2].steps,""), "len", X.lanes[2].len, "div", X.lanes[2].div)
RUNNOW = true
X.setplay2(); log = {}
advance(4*96)  -- one bar
local hits = {}
for _,e in ipairs(log) do if e[1]=="on" then table.insert(hits, e[3]..":"..e[2].."@"..e[4]) end end
print("ons in bar:", #hits)
-- check channels and velocity: capture on events with velocity via a custom out
local on1, on2, offs, acc = 0,0,0,0
for _,e in ipairs(log) do
  if e[1]=="on" and e[3]==10 then on1=on1+1 end
  if e[1]=="on" and e[3]==11 then on2=on2+1 end
  if e[1]=="off" then offs=offs+1 end
end
print("ch10 hits", on1, "(expect 4)", "ch11 hits", on2, "(expect 8: len 3 @1/8 = 1 hit per 1.5 beats... )", "offs", offs)
-- mute lane 2 with launch quantize = bar
X.setpage("quant"); X.gk(3,1,1); X.gk(3,1,0); X.setpage("drum")
tap(16,6); print("pending mute", X.pending(), "muted", X.lanes[2].mute)
advance(4*96); print("muted after bar", X.lanes[2].mute)
-- shift lane 1 right
tap(14,3); print("shifted", table.concat(X.lanes[1].steps,""))
-- undo shift, then clear+undo
X.gk(3,8,1); X.gk(3,8,0); print("undo shift", table.concat(X.lanes[1].steps,""))
-- save & load roundtrip
_G.SAVE(2)
X.lanes[1].steps[1] = 0; X.lanes[1].len = 7
X.setpage("save"); X.gk(2,1,1); X.gk(2,1,0); X.gk(3,2,1); X.gk(3,2,0)
print("after load lane1", table.concat(X.lanes[1].steps,""), "len", X.lanes[1].len, "lane2 mute", X.lanes[2].mute)
