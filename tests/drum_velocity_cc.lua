-- nanoPAD2 velocity and X-Y CCs: recorded on the DRUM page, replayed, saved
init(); X = _expose()
local pin = X.CTL.pads_in
X.setpage("drum"); X.setplay2()
key(2,1); key(2,0)                       -- REC pads
-- lane 1 is 16 steps of 1/16 = 384 ticks; hit step 1 soft and step 5 hard
pin.event({type="note_on", ch=10, note=36, vel=55})
advance(24*4)
pin.event({type="note_on", ch=10, note=36, vel=118})
-- an X-Y move on CC 1 at step 9
advance(24*4)
pin.event({type="cc", ch=10, cc=1, val=90})
print("live cc thru", log[#log][1], log[#log][2], "ch", log[#log][3])
print("vel recorded", X.lanes[1].vel[1], X.lanes[1].vel[5])
key(2,1); key(2,0)                       -- REC off
X.CTL.cc_touch = {}                      -- (the test clock doesn't move: release the knob)
-- next pass: the steps replay at the velocities played, the CC replays too
advance(384 - 24*8)
log = {}
advance(24*8 + 1)
local vels, ccs = {}, {}
for _, e in ipairs(log) do
  if e[1] == "on" then table.insert(vels, e[5]) end
  if e[1] == "cc" then table.insert(ccs, e[2] .. "/ch" .. e[3]) end
end
print("replay vels", table.concat(vels, " "), "cc", table.concat(ccs, " "))
-- a grid tap on a recorded step goes back to the fixed velocity
X.gk(5,1,1); X.gk(5,1,0); X.gk(5,1,1); X.gk(5,1,0)
print("after grid toggle step5 vel", X.lanes[1].vel[5], "step", X.lanes[1].steps[5])
-- save, wipe, load: velocity and CC moves come back
X.setpage("save"); X.gk(3,1,1); X.gk(3,1,0); _G.SAVE(3)
X.lanes[1].vel = {}; X.CTL.cc = {}
X.gk(3,2,1); X.gk(3,2,0)
local n = 0 for _ in pairs(X.CTL.cc) do n = n + 1 end
print("after load vel1", X.lanes[1].vel[1], "cc ticks", n)
