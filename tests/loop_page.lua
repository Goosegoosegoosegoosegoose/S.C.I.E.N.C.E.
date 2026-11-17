init(); X = _expose()
-- old tests still pass?
X.setplay()
X.setpage("loop")
local function st(t) return X.state(t) end
-- big button on track 2 strip (x=6,y=3)
X.gk(6,3,1); X.gk(6,3,0); print("press1", st(2), "sel", X.sel(), "pre", sclast("pre_level",2)[3])
X.gk(6,3,1); X.gk(6,3,0); print("press2", st(2), "pre", sclast("pre_level",2)[3], "rec_level", sclast("rec_level",2)[3])
X.gk(6,3,1); X.gk(6,3,0); print("press3", st(2), "rec_level", sclast("rec_level",2)[3])
X.gk(6,3,1); X.gk(6,3,0); print("press4", st(2))
X.gk(6,3,1); X.gk(6,3,0); print("press5", st(2))
-- stop (x=6,y=5) tap: release before hold fires (clock.run stub never fires)
X.gk(6,5,1); X.gk(6,5,0); print("stop", st(2), "level", sclast("level",2)[3])
X.gk(7,4,1); X.gk(7,4,0); print("restart", st(2), "level", sclast("level",2)[3])
-- fader: track 2 col 5 row 4 -> gain 0.5
X.gk(5,4,1); X.gk(5,4,0); print("gain", X.tr(2).gain)
-- rev
X.gk(8,2,1); X.gk(8,2,0); advance(8); print("rev rate", sclast("rate",2)[3])
-- fx tap
X.gk(8,1,1); X.gk(8,1,0); print("fx", X.tr(2).fx, "dry", sclast("post_filter_dry",2)[3])
-- fx hold + E2
X.gk(8,1,1); X.enc(2,5); X.gk(8,1,0); print("fx still on after hold-edit", X.tr(2).fx)
-- undo/redo swap: count copies
local c0 = sccount("buffer_copy_mono")
X.gk(3,8,1); X.gk(3,8,0); print("undo copies", sccount("buffer_copy_mono")-c0, "redo flag", X.tr(2).redo)
X.gk(3,8,1); X.gk(3,8,0); print("redo flag", X.tr(2).redo)
-- page cycling
X.setpage("midi"); for i=1,3 do X.gk(8,7,1); X.gk(8,7,0); print("page", X.page()) end
-- deferred start: stop transport, press big on empty track 3
