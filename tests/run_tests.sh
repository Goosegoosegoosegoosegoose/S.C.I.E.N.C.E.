#!/bin/sh
# Run every test in tests/ against sci.lua in the simulated norns.
# Needs Python 3 and lupa:  pip install lupa
cd "$(dirname "$0")/.." || exit 1

python3 -I -c "
import lupa
src = open('sci.lua').read()
L = lupa.LuaRuntime()
err = L.eval('function(s) local f, e = load(s, \"sci\") return e end')(src)
if err: raise SystemExit('syntax: ' + err)
print('syntax ok')
" || exit 1

fail=0
for t in tests/*.lua; do
  if out=$(python3 tests/harness.py sci.lua "$t" 2>&1); then
    echo "ok    $t"
  else
    echo "FAIL  $t"
    echo "$out" | tail -5
    fail=1
  fi
done
exit $fail
