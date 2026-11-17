init(); X = _expose()
WALL = 10; redraw(); WALL = 20
X.setplay2()
FRAMES = {}
local function grab(name)
  SC = {}; redraw()
  local ops = {}
  for _, op in ipairs(SC) do
    local parts = {}
    for i, v in ipairs(op) do parts[i] = tostring(v) end
    table.insert(ops, table.concat(parts, "\t"))
  end
  FRAMES[name] = table.concat(ops, "\n")
end
local presses = {midi={3,7}, audio={8,5}, loop={6,3}, quant={12,3}, save={1,2}, drum={5,1}}
for _, pg in ipairs({"midi","audio","loop","quant","drum","save"}) do
  X.setpage(pg); advance(10)
  grab(pg)
  local k = presses[pg]
  X.gk(k[1], k[2], 1); grab(pg .. "_flash"); X.gk(k[1], k[2], 0)
  WALL = WALL + 5
end
-- K1 tap toggles view; K1+K3 does not
local v0 = X.P:get("view")
key(1,1); key(1,0); local v1 = X.P:get("view")
key(1,1); key(3,1); key(3,0); key(1,0); local v2 = X.P:get("view")
print("view", v0, "-> tap", v1, "-> K1+K3", v2)
