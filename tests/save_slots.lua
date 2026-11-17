P0 = nil
init(); X = _expose()
X.P:set("clock_tempo", 120)
X.setplay()
-- make content: track1 midi note via grid, track 2 audio recording
X.setpage("midi"); X.gk(3,6,1); X.gk(3,6,0)
X.setpage("loop"); X.gk(6,3,1); X.gk(6,3,0); advance(96); X.gk(6,3,1); X.gk(6,3,0); X.gk(6,3,1); X.gk(6,3,0)
print("before save: T1 notes", #X.tr(1).pattern, "T2 audio", X.tr(2).has_audio, X.state(2))
-- go to save page
X.setpage("save")
X.gk(3,1,1); X.gk(3,1,0)  -- slot 3
-- SAVE needs hold; clock.run is a stub, so call through exposed save
_G.SAVE(3)
print("slot3 used", FS["/data/mpecap/slot03/session.data"] ~= nil, "t2 wav", FS["/data/mpecap/slot03/t2.wav"], "t1 wav", FS["/data/mpecap/slot03/t1.wav"])
-- wipe current
X.tr(1).pattern = {}; X.tr(2).has_audio = false
-- load all (row2 key3)
local reads0 = sccount("buffer_read_mono")
X.gk(3,2,1); X.gk(3,2,0)
print("after load: T1 notes", #X.tr(1).pattern, "T2 audio", X.tr(2).has_audio, "reads", sccount("buffer_read_mono")-reads0)
-- per-track midi load into track 1 then undo on midi page
X.tr(1).pattern = {}
X.gk(1,3,1); X.gk(1,3,0); print("T1 midi from slot", #X.tr(1).pattern)
X.setpage("midi"); X.gk(3,8,1); X.gk(3,8,0); print("undo T1 midi load", #X.tr(1).pattern)
-- load empty slot message
X.setpage("save"); X.gk(5,1,1); X.gk(5,1,0); X.gk(3,2,1); X.gk(3,2,0)
_G.DEL(3); print("deleted slot3", FS["/data/mpecap/slot03/session.data"] == nil)
