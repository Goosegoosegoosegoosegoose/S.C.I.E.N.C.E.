# Changelog

## 2026-11-17 (later): matched to the ZOIA build guide and CV guide
- **Docs:** the CV and Patching Guide, the ZOIA patch build guide and the code walkthrough are now in `docs/`, as markdown and PDF.
- **Hades** now defaults to the **U2MIDI** port on **channel 2** (the Hades' DIP switch 3), not the ZOIA on channel 12. The ZOIA has no MIDI thru.
- **Drums:** both Alecto voices on **channel 10**, notes **36 and 38**, matching the ZOIA patch (CV 1/2 → TRIG, CV 3/4 → VELO).
- **Recorded velocity:** nanoPAD2 hits replay at the velocity you played, so the Alecto's VELO follows your playing. Live pad hits pass their velocity too. A grid tap sets a step back to 80/127.
- **X-Y pad moves:** the nanoPAD2's CCs pass to the ZOIA on the drum channel and are recorded with DRUM page REC, looping over lane 1. Saved in slots and covered by undo.
- **CV guide layouts:** a new *pads* setting, *tuned: all thru*, sends every nanoPAD2 note to the ZOIA on channel 10 for Layout B (tuned pads; not recorded into the lanes). The nanoKEY's mod wheel and pitch bend now pass to its track (Hades MOD out), and a nanoKEY set to channel 10 plays the ZOIA directly.
- Port search skips the Korg controllers and the U2MIDI when picking the TRS port.
- Manual: MIDI wiring with the U2MIDI, audio with the ZOIA inline (out L/R → L6max ch 1/3), ZOIA page matching the build guide, Hades DIP switch and C-1 to C4 range.

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
