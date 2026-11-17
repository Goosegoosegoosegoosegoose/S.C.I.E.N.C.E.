init(); X = _expose()
WALL = 10
redraw()
WALL = 20
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
for _, pg in ipairs({"midi","audio","loop","quant","save","drum"}) do
  X.setpage(pg); advance(10)
  grab(pg)
  X.setflash(); grab(pg .. "_flash"); WALL = WALL + 5
end
-- the real page key should also trigger the flash
X.setpage("midi"); X.gk(8,7,1); X.gk(8,7,0); SC = {}; redraw()
local flashed = false
for _, op in ipairs(SC) do if op[1] == "font_size" and op[2] == 16 then flashed = true end end
print("page key flashes:", flashed, "now on", X.page())
