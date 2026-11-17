init(); X = _expose()
local function tap(x,y) WALL = WALL + 0.1; X.gk(x,y,1); WALL = WALL + 0.1; X.gk(x,y,0) end
X.setplay2()
for _, pg in ipairs({"midi","audio","loop","quant","save","drum"}) do
  X.setpage(pg)
  for i=1,3 do advance(20); X.redraw_grid(); redraw() end
  -- press every key on rows 1-6 and redraw (exercise handlers)
  for y=1,6 do for x=1,16 do tap(x,y) end end
  X.redraw_grid(); redraw()
  print("page ok", pg)
end
-- encoders and keys
for n=1,3 do enc(n,1); enc(n,-1) end
key(1,1); key(2,1); key(2,0); key(3,1); key(3,0); key(1,0)
key(2,1); key(2,0); key(3,1); key(3,0)
X.redraw_grid(); redraw(); print("keys/encs ok")
