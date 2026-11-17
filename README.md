# S.C.I.E.N.C.E.

**South Central Indiana Electro Noise Circuit Experiment**: a norns + grid instrument, short name **sci**.

sci records LinnStrument MPE performances as editable loops, with every note's bend, slide and pressure kept. It pairs each MIDI loop with an audio loop, and mangles both on a Reels-style tape transport. It also has an RC-505-style looper page, a performance page for quantize, two trigger lanes for a Dreadbox Alecto, and save slots.

> Status: tested in a simulated norns (see [Testing](#testing)), not yet on hardware. Expect a tweak or two on first run.

## What it does

- **4 paired tracks.** Each track has an MPE MIDI loop and an audio loop (softcut), on one shared loop length.
- **Tape transport.** Varispeed (¼× to 2×), reverse, brake (tape stop with a pitch dive), flutter and resync. It can drive the MIDI, the audio or both, so you can mangle one and keep the other in time.
- **6 grid pages**, cycled with row 7 key 8:
  - **MIDI:** note editor (tap add/delete, hold+tap length, hold+play step record)
  - **AUDIO:** record, overdub, print MIDI→audio, levels
  - **LOOP:** RC-505-style strips (REC → DUB → PLAY, STOP, fader, FX, reverse, fade)
  - **QUANT:** launch quantize, note quantize, which part the tape drives
  - **DRUM:** two polymetric trigger lanes for the Alecto, with accents
  - **SAVE:** 16 slots of MIDI and audio
- **Controllers.** LinnStrument (MPE), Korg nanoKEY (plays a chosen track, the Hades by default) and nanoPAD2 (plays and records the drum lanes).
- **On-screen guide.** Page tabs, a cheat sheet for the current page, and the name of every grid key you press.

## Install

Copy `sci.lua` to `dust/code/sci/sci.lua` on the norns (maiden, SMB or a USB stick), then pick **sci** from SELECT.

From a norns terminal you can clone the repo instead. The folder name `sci` keeps the menu tidy:

```
cd ~/dust/code && git clone https://github.com/Goosegoosegoosegoosegoose/S.C.I.E.N.C.E. sci
```

Saves live in `dust/data/sci`. Saves from the older `mpecap` script are moved there on first run.

## The rig it was built for

| Part | Role |
|---|---|
| LinnStrument 200 | MPE input |
| norns shield XL Pro + 16×8 grid | runs sci |
| Electra One Mini | routes norns → Nymphes (host Port 1) and Micromonsta 2 (host Port 2) |
| Dreadbox Nymphes, Micromonsta 2 | MPE synths (tracks 1, 2) |
| Dreadbox Hades | mono bass (track 3), via a U2MIDI (USB → 5-pin DIN) on channel 2 (DIP switch 3 on) |
| ZOIA Euroburo | ch 10 notes 36/38 → TRIG and VELO for the Alecto; bit crusher + aliaser inline on both synths |
| Dreadbox Alecto | drums (DRUM page), audio through ZOIA in R |
| Korg nanoKEY / nanoPAD2 | extra input |
| Zoom L6max | mixer; ZOIA out L/R on ch 1/3, AUX 1 feeds the norns |

Every port, channel and note is a PARAMS setting, so other gear works too. The wiring matches the ZOIA build guide and the Alecto/Hades CV guide.

## Docs

- [`docs/sci-manual.pdf`](docs/sci-manual.pdf) is the full manual (13 pages): wiring, ZOIA patch recipe, quick start, every grid page, PARAMS, troubleshooting, and a walkthrough of the code.
- [`docs/source/sci-manual.html`](docs/source/sci-manual.html) is the manual's source. Print it to PDF from a browser in landscape Letter.
- [`docs/sci-code-walkthrough.pdf`](docs/sci-code-walkthrough.pdf) explains what each section of `sci.lua` does.

### Rig guides

- **CV and Patching Guide: Dreadbox Alecto and Hades** ([markdown](docs/guides/cv-patching-guide-alecto-hades.md) · [PDF](docs/guides/cv-patching-guide-alecto-hades.pdf)): CV basics, the Alecto patchbay, the Hades, patches between them, a ZOIA crash course, and the nanoPAD2/nanoKEY layouts that sci supports.
- **ZOIA Euroburo Patch Build: norns sci to Alecto and Hades** ([markdown](docs/guides/zoia-euroburo-patch-build.md) · [PDF](docs/guides/zoia-euroburo-patch-build.pdf)): the cable list, MIDI plan, and a module-by-module build of the ZOIA patch sci's defaults are set up for.

The sci manual's wiring and ZOIA pages match these guides. Where they differ, the guides win: they're written from the Dreadbox, Empress and Korg manuals.
- [`CHANGELOG.md`](CHANGELOG.md) is the build history.

## Testing

`tests/harness.py` is a small simulated norns. It fakes clock, params, MIDI, grid, screen, softcut and files, runs `sci.lua` in a real Lua interpreter, and plays test scripts against it.

```
pip install lupa
./tests/run_tests.sh
```

Each test prints what it checked (notes sent, LED states, saved data). A test fails if the script raises an error. Run a single one with:

```
python3 tests/harness.py sci.lua tests/korg_controllers.lua
```

One thing to keep in mind when editing `sci.lua`: Lua allows at most 200 local names at the top level of a file. sci is at about 190, so group new helpers into a table (as `UI` and `CTL` do) rather than adding more top-level locals.

## Credits

Inspired by **Reels** (norns tape script) and the **BOSS RC-505mk2** workflow. No code from either is used.
