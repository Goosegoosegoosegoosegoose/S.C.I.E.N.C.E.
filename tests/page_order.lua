init(); X = _expose()
X.setpage("midi"); local seq = {}
for i=1,6 do X.gk(8,7,1); X.gk(8,7,0); table.insert(seq, X.page()) end
print("cycle from midi:", table.concat(seq, " > "))
