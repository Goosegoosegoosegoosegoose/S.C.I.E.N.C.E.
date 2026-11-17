init(); X = _expose(); X.setpage("drum")
local function tap(x,y) WALL = WALL + 0.1; X.gk(x,y,1); WALL = WALL + 0.1; X.gk(x,y,0) end
tap(1,1); tap(5,1); tap(3,5)  -- lane1 steps 1,5; lane2 length 3
X.setplay2()
for _, n in ipairs({0, 30, 100}) do
  advance(n == 0 and 1 or n)
  X.redraw_grid()
  local function col(l) local out={} for y=(l-1)*3+1,(l-1)*3+3 do local r={} for x=1,16 do table.insert(r, string.format("%x", LED[y*100+x] or 0)) end table.insert(out, table.concat(r)) end return table.concat(out," | ") end
  print("L1:", col(1)); print("L2:", col(2))
end
