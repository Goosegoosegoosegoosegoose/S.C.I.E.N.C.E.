# Changelog

## 2026-11-17
- **nanoKEY input.** Plays and records a chosen track (default track 3, the Hades), with thru on that track's channel and step record through a held grid key.
- **nanoPAD2 input.** Pads 36 and 38 play the two Alecto lanes live. REC on the DRUM page records hits to the nearest step, and hard hits become accents. A hit just before a step plays only once. Undo removes the whole pass.
- **SAVE is now the last page** (MIDI → AUDIO → LOOP → QUANT → DRUM → SAVE).
- Published to GitHub with the manual and the test simulator.

## 2026-11-15
- **Guide view** on the norns screen: page tabs, a cheat sheet for each page, and the name of the last grid key pressed. A tap of K1 alone switches between the guide and the reels.
- **Track defaults** for the Nymphes (track 1), Micromonsta 2 (track 2, Electra port 2) and Hades (track 3, TRS port, channel 12, mono). Ports are found by name.
- **Thru to a mono track** moves your notes onto its channel and leaves out pitch bend.
- Fix: stayed under Lua's 200 top-level locals limit, which the norns would otherwise refuse to load.
- Manual: MIDI & CV and audio wiring pages, L6max channel plan, ZOIA patch recipe.

## 2026-11-10
- **DRUM page:** two trigger lanes for the Alecto via the ZOIA Euroburo, with tap toggle, hold for accent, per-lane length and clock (polymeter), shift, mute, undo and saves. A moving bar of light shows each lane's step.
- **Renamed** mpecap → **sci** (S.C.I.E.N.C.E.). Old saves migrate on first run.
- Fix: the grid redraw is defined after the page functions, so the LOOP, QUANT, SAVE and DRUM pages no longer error when opened.

## 2026-11-06
- **LOOP page** (RC-505 style), **QUANT page** (launch quantize, note quantize, tape drives MIDI and/or audio) and **SAVE page** (16 slots of MIDI and audio).
- Audio undo swaps with a backup, so pressing undo again is redo.

## 2026-10-31
- **4 paired MIDI + audio tracks**, AUDIO page, print MIDI to audio.
- **Tape transport:** varispeed, reverse, brake, flutter, resync.
- **Grid note editor** with tap, length and step record. Clear needs a hold, and undo brings a clear back.

## 2026-10-12
- First version (**mpecap**): MPE capture and replay with overdub, undo and clock-synced loops.
