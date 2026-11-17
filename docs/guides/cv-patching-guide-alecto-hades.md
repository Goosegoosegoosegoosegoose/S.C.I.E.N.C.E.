# CV and Patching Guide: Dreadbox Alecto and Hades

Nov 10, 2026 · goose

This guide starts from zero and builds up, using the Alecto's patchbay as the worked example and bringing the Hades in as you go. Every fact about ranges and behaviour comes from the two manuals; anything the manuals leave open is marked **try it**.

Patches are written `SOURCE → DESTINATION`, for example `LFO TRI → TUNE 1`.

## Primer: the basics of CV

An analog synth is a set of circuits whose behaviour depends on voltages. Pitch, brightness and loudness are each set by a voltage inside the machine. A knob is simply a way to set one of those voltages by hand.

CV exposes those internal voltages on jacks. An output jack lets you tap a voltage the synth is generating. An input jack lets you feed a voltage in, as if a second hand were on the knob. A patch cable is nothing more than a wire between the two.

That is why one cable can do so many jobs. The cable does not know what it carries. The same LFO voltage makes vibrato at a pitch input, a filter sweep at a filter input and tremolo at an amplifier input. The destination decides the meaning.

Compare this with MIDI. MIDI sends digital messages ("note 60 on"), and the receiving synth decides what to do. CV is the raw electrical signal itself, continuous and instant, with no messages and no channels. The Hades bridges the two: it takes MIDI in and turns it into CV on its output jacks.

### Words you will meet

| Term | Meaning |
| --- | --- |
| Volt (V) | The unit of the signal. Most CV here lives between −5 V and +5 V. |
| Source | Any output: an LFO, an envelope, a clock, a pitch voltage. |
| Destination | Any input: the parameter being controlled. |
| Modulation | A source moving a destination over time. |
| Depth / amount | How far the modulation pushes the parameter. |
| Unipolar | A voltage that only goes one way from zero, such as 0 to 5 V. |
| Bipolar | A voltage that swings both sides of zero, such as −5 to +5 V. |
| Attenuate | Turn a voltage down, like a volume knob for CV. |
| Offset | A steady voltage added on top. A knob position is an offset. |
| Normalled | An internal connection that holds until you plug a cable in. |
| Gate | An on/off voltage that stays high for as long as a note is held. |
| Trigger | A very short pulse that says "now". |
| 1 V/octave | The pitch standard: each extra volt raises pitch one octave. |

## 1. What CV is

Control voltage (CV) is a voltage that turns a knob for you. A patch cable carries that voltage from a jack that makes it to a jack that listens for it.

Three rules cover almost everything:

1. **Outputs send, inputs receive.** A patch always runs from one output to one input.
2. **CV adds to the knob.** The knob sets a starting point; the incoming voltage pushes the value up or down from there. If a patch seems to do nothing, the knob is usually already at one end of its travel.
3. **Nothing happens until something moves.** A steady voltage is just a fixed offset. Modulation comes from voltages that change: LFOs, envelopes, sequencers, your hands.

### First patch (Alecto)

1. Press START so both voices are playing.
2. Patch `LFO TRI → TUNE 1`.
3. Turn the LFO LEVEL up slowly. Voice 1's pitch and brightness now rise and fall on their own.
4. Turn RATE. The LED on the LEVEL knob blinks at the LFO speed.
5. Now move Voice 1's TUNE knob. The wobble stays the same size but happens around a new centre. That is rule 2.

You have just replaced your hand with a voltage. Everything else in this guide is a variation on that.

### Safety rules

- **Never patch an output to another output.** The Hades manual warns this can seriously damage the unit.
- Inputs are forgiving. The Hades manual says its inputs accept up to ±12 V, though voltages beyond the stated range may have no extra effect.
- Both synths use 3.5 mm mono patch cables, so they patch straight into each other.
- The Hades main output is hot: 10 V peak-to-peak at full level, on a 6.3 mm jack. Start with the mixer channel down.

## 2. The kinds of signal

Every jack on both synths carries one of six kinds of signal. Knowing which kind you hold tells you where it can usefully go.

| Kind | What it looks like | Alecto example | Hades example |
| --- | --- | --- | --- |
| Modulation (LFO) | A slow, repeating rise and fall | LFO TRI and SQR outs, 0 to 5 V | LFO out, ±5 V |
| Modulation (envelope) | One rise and fall per note or hit | BEND 1/2 outs, 0 to 5 V | ENV out, 0 to 6.6 V |
| Pitch | A steady voltage per note | TUNE 1/2 ins | 1V/OCT out, CV in |
| Gate / trigger | On/off pulses | TRIG 1/2 ins, START in | GATE in |
| Clock | A steady stream of pulses that sets tempo | CLOCK IN, OUT, RESET | none |
| Audio | The sound itself, a very fast voltage | V 1/2 and MASTER outs | Audio out (6.3 mm) |

### Unipolar and bipolar, with a real example

The Alecto's LFO is unipolar, 0 to 5 V. Patched to TUNE, it only pushes pitch *up* from the knob position. To get a wobble centred where you want it, turn the TUNE knob down a little to compensate.

The Hades LFO is bipolar, ±5 V. Patched to the same TUNE input, it swings pitch equally above and below the knob position. The Alecto's TUNE, TIMBRE and MORPH inputs all accept ±5 V, so both LFOs fit.

### Gates, triggers and level

A gate says "note held"; a trigger says "hit now". Drums want triggers; sustained notes want gates.

Two details from the manuals matter here:

- The Alecto's TRIG inputs are level sensitive. The manual says they respond differently to different trigger levels, so a weaker pulse gives a different hit.
- The Hades GATE input activates at 0.9 V at low gain, and reaches maximum gain at 5 V.

So on both machines, the *height* of a pulse matters as well as its timing.

### Audio is just fast CV

An LFO at 2 Hz and an oscillator at 200 Hz are the same kind of signal at different speeds. You can patch audio into a CV input. Section 5 uses this for metallic and growling tones.

## 3. The Alecto, jack by jack

The Alecto has two identical drum voices, one LFO and a clock section. Each voice runs: two oscillators plus noise and click, into a low-pass filter, a switchable high-pass filter, then the VCA.

It helps to know what the three main knobs do before you modulate them:

- **TUNE** sets the pitch of both oscillators *and* the filter cutoff together. Higher is brighter as well as higher.
- **MORPH** sweeps through five oscillator setups: square alone, triangle alone, two triangles, triangle with FM from VCO 2, saw with FM from VCO 2.
- **TIMBRE** offsets the filter cutoff. In the last three MORPH positions it also detunes VCO 2.

### Inputs

| Jack | Range | What it does | Worth knowing |
| --- | --- | --- | --- |
| TRIG 1/2 | Pulse | Fires that voice's envelopes | Cancels that voice's internal sequencer and disables its TRIG/RST button. Level sensitive. |
| VELO 1/2 | 0 to 5 V | Sets how hard the envelopes hit | Normalled to maximum. CV can only bring it down from full, never above. |
| TUNE 1/2 | ±5 V | Moves the TUNE parameter | The manual does not state 1 V/octave tracking. See section 5. |
| TIMBRE 1/2 | ±5 V | Moves the TIMBRE parameter | Effect depends on the MORPH position. |
| MORPH 1/2 | ±5 V | Moves the MORPH parameter | Sweeps across waveforms and into FM. |

### Outputs

| Jack | Range | What it carries | Worth knowing |
| --- | --- | --- | --- |
| BEND 1/2 | 0 to 5 V | That voice's pitch envelope | Your only envelope outputs. One spike per hit, length set by DECAY. |
| V 1/2 | Audio | That voice alone | Full level, ignores the LEVEL knob. |
| MASTER | Audio | Both voices mixed | Can drive headphones. |
| LFO TRI | 0 to 5 V | Triangle LFO | The LEVEL knob scales this output only. |
| LFO SQR | 0 to 5 V | Square LFO | Always full height. Works as a pulse source. |

The manual lists no internal destination for the LFO, so it does nothing until you patch it.

### Clock

| Jack | What it does | Worth knowing |
| --- | --- | --- |
| CLOCK IN | Replaces the internal clock | With an external clock, TEMPO becomes a divider (/1 to /16) for CLOCK OUT. |
| START | Runs the sequencers while the voltage is high | Stops when it goes low. |
| RESET | Sends both sequencers back to step 1 | Global: always resets both. |
| CLOCK OUT | Sends the clock | Follows TEMPO, or the divided external clock. |

### The sequencer in one paragraph

Each voice has one trigger that repeats every LENGTH steps (2 to 8), at the clock rate divided by 1, 2 or 4. With the clock running, hold TRIG/RST and release it on the step where you want the hit. With the clock stopped, TRIG/RST plays the voice and resets its trigger to step 1. Different lengths drift against each other: 3 against 4 realigns every 12 steps.

## 4. The Hades, jack by jack

The Hades is a one-oscillator bass synth played over MIDI. Its path: oscillator plus two sub-oscillators, into an 18 dB/octave low-pass filter, drive, then the VCA. Three connections are hardwired inside:

- The LFO modulates oscillator pitch (the LFO depth knob).
- The ADS envelope modulates the filter (the envelope level knob).
- The AR envelope opens the VCA.

Patching on the Hades is mostly about breaking or adding to those three.

### Outputs

| Jack | Range | What it carries | Worth knowing |
| --- | --- | --- | --- |
| ENV | 0 to 6.6 V, by the level knob | The filter envelope | Per the manual, plugging in cancels the internal envelope-to-filter link. |
| LFO | ±5 V | The triangle LFO | Per the manual, plugging in cancels the internal LFO-to-oscillator link. |
| MOD | 0 to 5 V | The MIDI mod wheel as a voltage | The mini knob beside it attenuates it. |
| 1V/OCT | 1 V/octave | Pitch of the MIDI note, including pitch bend | Covers 5 octaves. |

Two of these are unusual. On most synths, taking a signal from an output leaves the internal routing alone. On the Hades, tapping ENV or LFO disconnects it from its normal job. This is a feature: it frees the filter and the oscillator from their default modulation.

The manual is inconsistent about the mod wheel. One page says it is reachable only through the MOD jack; the specification page says it is hardwired to the filter. **Try it:** move the mod wheel with nothing patched and listen for the filter.

### Inputs

| Jack | Range | What it controls | Worth knowing |
| --- | --- | --- | --- |
| CV | 1 V/octave, accepts ±12 V | Oscillator pitch | Adds to the MIDI note and the tune knob. |
| GATE | Opens at 0.9 V, full at 5 V | Fires both envelopes | Lets something other than MIDI play notes. |
| VCF | ±5 V | Filter cutoff | Adds to the cutoff knob and envelope. |
| VCA | 0 to 5 V | Amplifier level | Plugging in deactivates the AR envelope. |
| PW | ±5 V | Pulse width | Only audible on the pulse wave. |

### Things the Hades lacks

- No gate output. The MIDI gate stays inside.
- No audio input, so you cannot run the Alecto through the Hades filter.
- No attenuators on its inputs. Depth has to be set at the source.

The LFO range depends on the unit: 15 seconds up to about 1 kHz on early units, 10 seconds up to 50 Hz on serial numbers above 600. Let the oscillator warm up for 5 to 20 minutes before judging its tuning.

## 5. Theory, one step at a time

Each idea below has a patch you can make in under a minute.

### 5.1 Normalling: connections that exist until you break them

A normalled jack has a default signal wired to it internally. Plugging a cable in replaces that default.

- **Alecto VELO** is normalled to maximum. Unplugged, every hit is full strength. Patch `LFO TRI → VELO 1` and hits now follow the LFO's height, giving loud and soft notes.
- **Alecto TRIG** is normalled to the internal sequencer. Patch `LFO SQR → TRIG 2` and Voice 2 ignores the sequencer and fires at the LFO rate instead.
- **Hades VCA** is normalled to the AR envelope. Plug anything in and the AR envelope stops shaping the sound; your voltage is now the volume.
- **Hades ENV and LFO outputs** break their internal links when used (section 4).

Before you patch any jack, ask what it disconnects. That answers most "why did the sound change?" questions.

### 5.2 Depth: how much is too much

Neither synth has attenuators on its inputs, so 5 V arrives as a full 5 V. Depth has to be set at the source. Four sources have a level control:

| Source | Its level control |
| --- | --- |
| Alecto LFO TRI | LFO LEVEL knob |
| Hades ENV | Envelope level knob (0 to 6.6 V) |
| Hades MOD | The mini knob by the jack |
| Hades LFO | **Try it:** check whether the depth knob scales the jack or only the internal vibrato |

Alecto LFO SQR and BEND 1/2 are fixed height as far as the manual says. **Try it:** check whether the BEND knob changes the BEND output or only the internal pitch sweep.

When a fixed source is too strong, use the destination knob to choose which part of the range it sweeps.

### 5.3 Offset and range: aiming the sweep

A parameter has a floor and a ceiling. If knob plus CV goes past either, the modulation flattens out there.

Patch `LFO SQR → MORPH 1`. The square wave jumps between 0 and 5 V, so the voice alternates between two sounds. With MORPH fully up, both land at the ceiling and you hear no change. Turn MORPH down and the two sounds separate. The knob picks the low sound; the CV sets how far above it the high sound sits.

### 5.4 Envelopes as modulation

An envelope is a one-shot shape fired by a trigger or gate. The Alecto's BEND outputs give you each voice's pitch envelope: a spike that falls back to zero over the DECAY time.

Patch `BEND 1 → TIMBRE 1`. Every hit now starts bright and closes down, like a plucked filter. Lengthen DECAY and the sweep stretches with it.

The Hades ENV output is the same idea with more control: attack, decay, sustain and a level knob.

### 5.5 Cross-patching: one voice shaping another

Patch `BEND 2 → TIMBRE 1` (this one is in the Alecto manual). Voice 1's tone changes only when Voice 2 fires at the same moment. With different sequence lengths, those moments move around the bar, so you get accents that shift on their own.

This is the core modular idea: one event becomes a condition for another.

### 5.6 Pitch CV and tracking

Pitch CV follows the 1 V/octave rule, so one semitone is 1/12 V. The Hades 1V/OCT output and CV input both follow it.

This makes pitch the most sensitive destination. A full 5 V envelope into the Hades CV input is a five-octave dive. Great for effects, far too much for vibrato.

The Alecto's TUNE input is described only as controlling the Tune parameter over ±5 V. The manual does not promise 1 V/octave, and TUNE moves the filter along with the pitch. **Try it:** patch `Hades 1V/OCT → TUNE 1`, play octaves and listen. Expect it to follow your playing; do not assume it stays in tune across the keyboard.

### 5.7 Clocks, division and reset

A clock is a stream of pulses. A sequencer advances one step per pulse. Dividing a clock by 2 passes every second pulse, so the pattern runs at half speed. A reset pulse sends a sequencer back to step 1.

On the Alecto these combine into polymeter. Set LENGTH to 3 on Voice 1 and 4 on Voice 2 and the pattern repeats every 12 steps. Set 5 and 7 and it takes 35.

Reset lets you cut that cycle short. Patch `LFO SQR → RESET` with the LFO slow. Both sequencers snap back to step 1 on each LFO cycle. If the LFO is not in time with the clock, the cut point drifts, and the rhythm never quite repeats.

### 5.8 Audio-rate modulation

Speed an LFO up past about 20 Hz and you stop hearing movement and start hearing a new tone. Pitch modulated this way is FM. It adds harmonics, often metallic or bell-like.

The Alecto does this inside: MORPH positions 4 and 5 are VCO 2 modulating VCO 1. You can also do it with cables:

- `V 2 → TUNE 1` uses Voice 2's audio to shake Voice 1's pitch and filter. Turn DRONE on for Voice 2 so the modulator runs continuously.
- On early Hades units, turn the LFO rate all the way up and patch `Hades LFO → Hades VCF` for a growling filter.

Results are hard to predict and change a lot with small knob moves. That is the appeal.

### 5.9 Splitting and combining

- **One output to several inputs is safe.** Use a passive multiple or stackable cables. Both synths have few outputs, so this is the most useful accessory you can buy.
- **Two outputs into one input needs a mixer.** A splitter used backwards joins two outputs together, which the Hades manual forbids.

## 6. Tips and tricks

### Alecto

- **CLICK passes through the filter.** Its tone follows TIMBRE, so modulating TIMBRE also changes the attack.
- **ATTACK switch on** gives slow attacks: bass notes and cymbal swells instead of drum hits.
- **DRONE on** removes the VCA envelope. The voice sounds continuously and becomes a drone, a bass oscillator or a modulation source.
- **V 1/2 outputs ignore LEVEL.** Send each voice to its own mixer channel for separate EQ and effects.
- **Hold TRIG/RST while running** to mute a voice. It comes back on the step where you let go.
- **Stop, then tap TRIG/RST** to reset that voice's trigger to step 1 and start a fresh pattern.
- **With an external clock,** TEMPO divides CLOCK OUT from /1 to /16. The manual suggests patching that divided `CLOCK OUT → RESET` for rhythmic variation.
- **Cowbell:** the manual gives the classic 808 pair as 540 Hz and 800 Hz. Set TUNE and TIMBRE by ear to that ratio.
- **Two LEDs tell you a lot.** The START button blinks at the tempo; each TRIG/RST LED shows that voice's decay time.
- **HPF switch:** middle is off, down is 100 Hz, up is 300 Hz. Use it to keep a snare or hat out of the kick's range.

### Hades

- **Warm it up** for 5 to 20 minutes. The tune knob should sit near 12 o'clock when in tune.
- **Note priority** is set from the lowest C on your MIDI keyboard: C with F# for low, C with G# for last, C with A# for high.
- **The d / d/r switch** chooses whether the decay knob also sets release.
- **Drive works best on low notes,** per the manual.
- **Pitch bend travels through the 1V/OCT output** (one octave up or down), so anything following that jack bends too.
- **The mod wheel is a free CV source.** Any MIDI controller or sequencer that sends mod wheel (CC 1) gives you a hand-controlled or programmed 0 to 5 V at the MOD jack, with its own attenuator.

### Both

- **The Alecto has no MIDI; the Hades has no clock.** The Hades can act as the Alecto's MIDI-to-CV converter (patches C4 and C5), and the Alecto can act as the Hades' sequencer clock (C3).
- **Sync to a MIDI rig, try it:** program short mod-wheel pulses (CC 1 at 127, then 0) in a sequencer and patch `Hades MOD → Alecto CLOCK IN`. Each pulse should advance the Alecto one step.
- **Change one cable at a time** and listen before adding the next.
- **Photograph patches you like.** Neither synth stores anything.

## 7. Patches to try

Each patch lists the cables, the settings, what to listen for and the idea it teaches. They run from easy to involved.

### Alecto alone

**A1. Wobble tom** (modulation, offset)

- Cable: `LFO TRI → TUNE 1`
- Settings: MORPH 1 low, DECAY medium, LFO LEVEL at half, RATE slow.
- Listen: each hit lands on a different pitch. Speed RATE up until the pitch moves *within* a hit.

**A2. Dynamics** (normalling)

- Cable: `LFO TRI → VELO 2`
- Settings: LFO LEVEL full, RATE slow and out of time with the tempo.
- Listen: Voice 2 swells and fades like a drummer playing ghost notes. Lower LEVEL and the whole voice gets quieter, because VELO can only reduce.

**A3. Two drums from one voice** (range, section 5.3)

- Cable: `LFO SQR → MORPH 1`
- Settings: MORPH 1 fully down, RATE slow.
- Listen: the voice alternates between a square-wave hit and an FM hit.

**A4. Plucked filter** (envelope as modulation)

- Cable: `BEND 1 → TIMBRE 1`
- Settings: TIMBRE 1 low, DECAY medium to long.
- Listen: a bright snap at the start of each hit that closes down.

**A5. Moving accents** (cross-patching; from the manual's Accented Bass & Hat)

- Cable: `BEND 2 → TIMBRE 1`
- Settings: Voice 1 as a square-wave kick (MORPH down), Voice 2 as a hat (VCO/WN toward noise, HPF up). LENGTH 4 on Voice 1, 3 on Voice 2.
- Listen: the kick brightens only when the hat lands with it. Change the LENGTH values to move the accents.

**A6. Free-running voice** (breaking the sequencer)

- Cable: `LFO SQR → TRIG 2`
- Settings: start the sequencer for Voice 1; set RATE by ear.
- Listen: Voice 2 plays at the LFO rate, unrelated to the tempo. Slow rates give sparse off-grid hits; fast rates give rolls.

**A7. Self-cutting pattern** (reset)

- Cable: `LFO SQR → RESET`
- Settings: LENGTH 5 and 7, RATE slow.
- Listen: the long 35-step cycle gets chopped at shifting points.

**A8. Ring and clang** (audio-rate modulation)

- Cable: `V 2 → TUNE 1`
- Settings: Voice 2 DRONE on, LEVEL 2 down so you hear only Voice 1 at MASTER. Sweep TUNE 2.
- Listen: Voice 1 turns metallic and bell-like. Turn DRONE off and the clang appears only when both voices hit together.

### Hades alone

Play these from a MIDI keyboard or controller.

**H1. Pulse-width movement** (redirecting a hardwired source)

- Cable: `LFO → PW`
- Settings: pulse wave selected, LFO rate slow.
- Listen: the tone thickens and thins. The vibrato stops, because the LFO output cancels its link to the oscillator.

**H2. Filter wobble**

- Cable: `LFO → VCF`
- Settings: cutoff around the middle, some resonance.
- Listen: a classic wobble bass. Rate sets the wobble speed.

**H3. Filter follows the keyboard** (pitch CV as modulation)

- Cable: `1V/OCT → VCF`
- Listen: high notes get brighter and low notes darker, so the tone stays even across the keyboard.

**H4. Mod wheel as a filter pedal** (attenuation)

- Cable: `MOD → VCF`
- Settings: start with the mini knob low and raise it.
- Listen: the mod wheel opens the filter. The mini knob sets how far. Move the cable to PW or VCA to reassign the wheel.

**H5. Zap bass** (pitch sensitivity, section 5.6)

- Cable: `ENV → CV`
- Settings: envelope level very low, attack at minimum, short decay.
- Listen: each note dives in pitch, like a kick. Raise the level a little at a time; full level is over six octaves. The filter envelope is cancelled, so set cutoff by hand.

**H6. Sustained amp envelope** (replacing a normal)

- Cable: `ENV → VCA`
- Listen: the ADS envelope now shapes volume in place of the AR, giving you a sustain level. The filter stays where the cutoff knob puts it.

**H7. Self-playing bass** (LFO as a clock)

- Cable: `LFO → GATE`
- Listen: the LFO fires the envelopes on every cycle, so the Hades repeats its note at the LFO rate.

### Alecto and Hades together

Run both into your mixer and patch between them with 3.5 mm cables.

**C1. Kick opens the bass filter** (one instrument's envelope shaping another)

- Cable: `Alecto BEND 1 → Hades VCF`
- Settings: Voice 1 as a kick. Hades cutoff low, a held or sequenced bass note.
- Listen: the bass snaps bright on every kick, then closes. Alecto DECAY 1 sets how long it stays open.

**C2. Bass that only speaks with the drum** (external amp control)

- Cable: `Alecto BEND 2 → Hades VCA`
- Settings: the AR envelope is now off, so the Hades needs no held note. Set its pitch with the tune knob or the last MIDI note.
- Listen: a bass stab on every Voice 2 hit, following Voice 2's polymetric pattern. It is a third drum voice with a filter and drive.

**C3. Alecto clocks the bass** (gate from a pulse source)

- Cable: `Alecto LFO SQR → Hades GATE`
- Listen: the Hades envelopes fire at the Alecto LFO rate. Choose the pitch over MIDI.
- Try it: use `Alecto CLOCK OUT → Hades GATE` to lock the bass to the drum tempo. Clock pulses may be short, giving plucky notes; lengthen the Hades release to taste.

**C4. Play the Alecto from MIDI** (the Hades as a MIDI-to-CV converter)

- Cables: `Hades 1V/OCT → Alecto TUNE 1`, `Hades MOD → Alecto MORPH 1`
- Settings: Voice 1 DRONE on for a playable synth voice, or off for percussion whose pitch follows your notes.
- Listen: your notes move Voice 1's pitch and brightness; the mod wheel sweeps it from clean to FM. Tracking may not be exact (section 5.6).

**C5. Trigger a drum from the keyboard** (envelope as trigger; try it)

- Cable: `Hades ENV → Alecto TRIG 1`
- Settings: Hades envelope attack at minimum, level up. Set the Hades cutoff by hand, as its filter envelope is cancelled.
- Listen: every MIDI note should fire Voice 1 along with the bass. Because TRIG is level sensitive, the envelope level knob should change how hard the drum hits.

**C6. One clock for everything** (a closed loop between the two)

- Cables: `Hades LFO → Alecto CLOCK IN`, `Alecto CLOCK OUT → Hades GATE`
- Settings: the Hades LFO rate is now the tempo. The Alecto TEMPO knob divides the clock going back to the Hades.
- Listen: drums at the LFO rate, with a bass note every 1 to 16 clock steps depending on TEMPO.
- Try it: a triangle is a soft-edged clock. If the Alecto does not follow it reliably, use patch C3 instead.

**C7. A second LFO for the Hades** (borrowing a source)

- Cable: `Alecto LFO TRI → Hades PW` (or `→ Hades VCF`)
- Listen: pulse-width or filter movement, with depth on the Alecto LFO LEVEL knob. The Hades keeps its own LFO for vibrato.

**C8. Drum-driven filter growl** (audio-rate modulation across instruments)

- Cable: `Alecto V 2 → Hades VCF`
- Settings: Hades resonance up. Voice 2 DRONE on for a constant growl, off for a burst on each hit.
- Listen: a rough, vocal edge on the bass that changes as you sweep TUNE 2.

### A full patch to finish

Five cables, no multiples needed, each output and input used once:

1. `Hades LFO → Alecto CLOCK IN` sets the tempo.
2. `Alecto CLOCK OUT → Hades GATE` fires the bass at a division of it.
3. `Alecto BEND 1 → Hades VCF` opens the bass filter on every kick.
4. `Alecto LFO TRI → Alecto TIMBRE 2` slowly changes the second drum.
5. `Hades MOD → Alecto MORPH 1` puts the kick's character on your mod wheel.

Set LENGTH to 3 and 4, press START, and play bass notes over MIDI. Then remove one cable at a time to hear what each was doing.

## 8. Troubleshooting and quick reference

### When a patch does not behave

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| The cable does nothing | The destination knob is already at the end the CV pushes toward | Turn the knob toward the middle or the opposite end |
| Alecto voice stopped following the sequencer | A cable is in its TRIG input | Unplug it; TRIG overrides the sequencer and the button |
| Alecto voice got quieter | A low voltage is in VELO | Raise the source level or unplug |
| Hades vibrato disappeared | A cable is in the LFO output | Expected; unplug to restore it |
| Hades filter envelope disappeared | A cable is in the ENV output | Expected; set cutoff by hand or unplug |
| Hades drones, or goes silent, regardless of notes | A cable is in the VCA input, so the AR envelope is off | The patched voltage is now the volume |
| Pitch jumps wildly | A full-height source is in a pitch input | Use a source with a level control (section 5.2) |
| PW cable has no effect | A wave other than pulse is selected | Switch the oscillator to pulse |
| Hades is out of tune | Not warmed up | Wait 5 to 20 minutes, then set the tune knob |
| Modulation only goes one way | The source is unipolar (Alecto LFO, BEND, Hades ENV and MOD) | Lower the destination knob to recentre |

### Every source and where it fits

| Source | Range | Has a level control | Good destinations |
| --- | --- | --- | --- |
| Alecto LFO TRI | 0 to 5 V | Yes | TUNE, TIMBRE, MORPH, VELO; Hades VCF, PW, VCA |
| Alecto LFO SQR | 0 to 5 V | No | TRIG, RESET, START, MORPH; Hades GATE |
| Alecto BEND 1/2 | 0 to 5 V | Not stated | TIMBRE, MORPH, VELO of the other voice; Hades VCF, VCA, CV |
| Alecto CLOCK OUT | Pulses | TEMPO divides it under external clock | RESET; Hades GATE |
| Alecto V 1/2 | Audio | No | TUNE or TIMBRE of the other voice; Hades VCF |
| Hades LFO | ±5 V | Try the depth knob | Hades PW, VCF, GATE; Alecto TUNE, TIMBRE, MORPH, CLOCK IN |
| Hades ENV | 0 to 6.6 V | Yes | Hades VCA, CV, PW; Alecto TRIG, VELO, TIMBRE, MORPH |
| Hades MOD | 0 to 5 V | Yes | Anything; the most flexible source you have |
| Hades 1V/OCT | 1 V/octave | No | Hades VCF; Alecto TUNE |

The Hades ENV output can reach 6.6 V, slightly above the 5 V ranges the Alecto manual lists. Keep the envelope level knob below full when patching it to the Alecto.

## 9. Adding the Komorebi

The Komorebi chorus/flanger joins the rig two ways: as an audio effect on one synth, and as a CV partner with three patch points. The jack details below come from a [product listing](https://www.woodbrass.com/de-at/chorus-flanger-phaser-dreadbox-komorebi-chorus-p377311.html), not the Komorebi manual, so the ranges of RATE and LFO out are **try it**.

### Its patch points

| Jack | Direction | What it does |
| --- | --- | --- |
| STATIC | Input, ±5 V | Moves the delay time, the same thing the Static knob sets |
| RATE | Input | Moves the speed of the pedal's LFO |
| LFO | Output | Sends the pedal's LFO to other gear |

The pedal's knobs set the centre point; incoming CV pushes away from it. Turn the LFO/Static balance toward Static to hear the STATIC patches clearly.

### Audio hookup

The Komorebi is mono, with 6.3 mm in and out.

- **On the bass:** Hades out to Komorebi in, then Komorebi out to wherever the Hades went before. Keep the Hades level knob lowish so the pedal does not overload.
- **On the drums:** `Alecto V 2 → Komorebi` for flanged hats or snare, leaving the kick clean on V 1.
- **With the ZOIA:** Komorebi before the crusher gives gritty chorus; after it, the chorus smooths the grit.

### Patches to try

**K1. A third LFO** (borrowing a source)

- Cable: `Komorebi LFO → Hades VCF` (or `→ Hades PW`)
- Listen: the filter moves in step with the chorus sweep.

**K2. Drums that follow the chorus**

- Cable: `Komorebi LFO → Alecto TIMBRE 2` (or `→ MORPH 2`)
- Listen: Voice 2 changes tone in time with the chorus on the bass.

**K3. Breathing chorus** (modulating a modulator)

- Cable: `Alecto LFO TRI → Komorebi RATE`
- Listen: the chorus speeds up and slows down. The Alecto LFO LEVEL knob sets how much.

**K4. Kick-triggered flange** (envelope as modulation)

- Cable: `Alecto BEND 1 → Komorebi STATIC`
- Listen: every kick jolts the delay time, so the sound in the pedal gets a flange zap on each hit.

**K5. Mod-wheel flanger** (attenuated hand control)

- Cable: `Hades MOD → Komorebi STATIC`
- Listen: the mod wheel sweeps the flanger by hand; the mini knob sets the depth. A sequencer sending CC 1 can automate it.

**K6. Flange per note**

- Cable: `Hades ENV → Komorebi STATIC`
- Listen: a sweep on every note, shaped by the envelope knobs. The Hades filter envelope is cancelled, so set cutoff by hand.

**K7. Two-tone comb**

- Cable: `Alecto LFO SQR → Komorebi STATIC`
- Listen: the comb tone jumps between two settings at the LFO rate.

The Komorebi's LFO jack is an output. Like every output, it only ever goes to an input.

## 10. ZOIA Euroburo crash course

The ZOIA is a whole modular synth inside one box. Everything in sections 1 to 5 still applies; the only change is that most of the cables are virtual, and you draw them on a button grid. Steps follow the [Euroburo manual for firmware 2.30](https://empresseffects.com/cdn/shop/files/ZEBU_Manual_2_dot_30.pdf).

### The jacks

| Jacks | How many | What they do |
| --- | --- | --- |
| Audio in | 2 (L, R) | Bring sound in. Each has an input pad of 0, -6 or -12 dB. |
| Audio out | 2 (L, R) | Send sound out. The headphone jack carries a copy. |
| CV in | 4 | Real voltages in, from the Alecto or Hades |
| CV out | 4 | Real voltages out, to the Alecto, Hades or Komorebi |
| MIDI in and out | 1 each, 3.5 mm TRS | Type A wiring; the included dongles convert to 5-pin DIN |

Every jack has its own button beside it. Those buttons are always on the grid, whatever page you are on, and you connect to them like any other module.

The ZOIA has no USB MIDI. A USB controller such as the nanoPAD2 cannot plug into it directly; it needs a USB host in between. In this rig, that is norns.

### Five ideas that make it click

1. **A module is a row of buttons.** Each button is one input, output or setting. An LFO, for example, shows buttons for rate and output.
2. **Holding two buttons draws a cable.** Output to input, the same rule as the hardware.
3. **Every cable has an attenuator.** Turn the knob just after connecting to set how much passes. This is what the Alecto and Hades lack.
4. **Inside, CV runs from 0 to 1.** Each CV jack converts that to real volts on a range you choose: 0 to 5 V, 0 to 10 V or -5 to 5 V. Pick 0 to 5 V for the Alecto's VELO and the Hades VCA; pick -5 to 5 V for TUNE, TIMBRE, MORPH and the Hades VCF.
5. **Nothing passes by default.** An empty patch is silent. Audio must be wired from audio in to audio out.

### Buttons you will use constantly

| To do this | Press |
| --- | --- |
| Place a module | An empty grid button, then category, module, options, "Done?" |
| Connect | Hold both buttons together |
| Connect across pages | First button, Page Left or Right, second button |
| Change a value | The button, then turn the knob |
| Change a module's options | Select it, then Edit |
| Remove something | Delete |
| Undo a mistake | Undo |
| Learn what a button does | Help |
| Bypass audio | Hold Shift and press an audio in or out button |
| Store the patch | Save (to internal memory) |

### Module categories

| Category | Examples | Hardware it replaces |
| --- | --- | --- |
| Interface | Midi Notes In, Midi CC In, Midi Clock In, audio and CV I/O | A MIDI-to-CV converter |
| Control | LFO, ADSR, Sequencer, Clock Divider, Random, Sample and Hold, Quantizer, Slew Limiter | Modulation modules |
| Audio | Oscillator, VCA, filters, Audio Balance, Bit Crusher, Aliaser | Voices and utilities |
| Analysis | Env Follower, Onset Detector, Pitch Detector | Turns sound into CV |
| Effects | Delays, reverbs, distortion | Pedals |

### First three ZOIA patches

Each takes two or three modules. Build them on an empty patch slot.

**Z1. ZOIA LFO to the Alecto** (an extra modulation source)

1. Place an **LFO**.
2. Connect LFO output to the **CV out 1** button. Set CV out 1 to -5 to 5 V.
3. Patch a cable from ZOIA CV out 1 to Alecto TUNE 1.
4. Turn the connection strength to set the depth. Compare this with section 5.2: depth control on every cable.

**Z2. Alecto drives the ZOIA** (CV in)

1. Patch Alecto BEND 1 to ZOIA CV in 1. Set CV in 1 to 0 to 5 V.
2. Place an **LFO** and connect the **CV in 1** button to its rate.
3. Connect the LFO to CV out 1, and cable that to Hades VCF.
4. Listen: every kick speeds up the filter wobble.

**Z3. Audio through the crusher**

This is page 2 of the [ZOIA build guide](https://claude.ai/artifact/8qHfCVDmiuCyWeQVQyjy62): audio in, Bit Crusher, Aliaser, Audio Balance, audio out.

### Habits that save time

- **Name your pages** (Page Left or Right to open the list, then Edit). "MIDI", "FX" and "Mod" make a patch readable months later.
- **Save after every working step.** Save stores to internal memory, not the SD card.
- **Watch DSP usage** in the config menu (Shift and Config) once a patch grows.
- **Change one connection at a time,** exactly as with the hardware.

## 11. Putting the ZOIA in the rig with the nanoPAD2 and nanoKEY

The ZOIA sits between norns and the Alecto. It turns pad notes into Alecto voltages, and it can carry both synths' audio for the crusher. The full cable list and module-by-module build are in the [ZOIA build guide](https://claude.ai/artifact/8qHfCVDmiuCyWeQVQyjy62); this section covers how to play it.

### The signal path

1. The nanoPAD2 and nanoKEY plug into norns over USB.
2. The sci script records and replays them. It sends bass notes on channel 2 to the Hades, and drum notes on channel 10 out of the shield's TRS MIDI jack.
3. The ZOIA receives channel 10 and turns it into voltages on its four CV outs.
4. Those cables play the Alecto.

The nanoPAD2 cannot skip norns: it is USB only, and the ZOIA has TRS MIDI only.

### The CV out budget

The ZOIA has four CV outs, and the Alecto needs two of them for triggers. The other two are yours to spend. Each layout below spends them differently. Build each as its own ZOIA patch, and store a matching nanoPAD2 scene for it.

| Layout | CV out 1 | CV out 2 | CV out 3 | CV out 4 |
| --- | --- | --- | --- | --- |
| A. Dynamic kit | TRIG 1 | TRIG 2 | VELO 1 | VELO 2 |
| B. Tuned pads | TRIG 1 | TRIG 2 | TUNE 1 | TUNE 2 |
| C. Pads plus X-Y | TRIG 1 | TRIG 2 | MORPH 1 | TIMBRE 2 |

### Layout A: dynamic kit

This is the build in the ZOIA guide.

- Pad 1 sends note 36 and fires Voice 1. Pad 2 sends note 38 and fires Voice 2.
- How hard you hit sets how hard the drum hits, through the VELO inputs.
- Good for: grooves with ghost notes and accents.

### Layout B: tuned pads

Sixteen pads become eight pitches of each drum: toms, congas, bass notes, cowbells.

- Pads 1 to 8 send notes 36 to 43 and play Voice 1. Pads 9 to 16 send notes 44 to 51 and play Voice 2. Set the pad notes in the Korg Kontrol Editor.
- On the ZOIA, change each Midi Notes In's low and high note to cover its eight notes. Connect its **note out** to CV out 3 or 4 instead of velocity out, and set those jacks to -5 to 5 V.
- Turn each note-out connection's strength to set the spacing between pads. The Alecto's TUNE is not promised to follow 1 V/octave (section 5.6), so tune by ear: aim for a scale, or for fifths and octaves.
- Remember TUNE moves the filter too, so higher pads are also brighter.

  In sci, set PARAMS → controllers → pads to **tuned: all thru**. Every pad note then goes to the ZOIA on channel 10. These hits play live but are not recorded into the DRUM lanes, which hold one note per voice. Set it back to **kit: lanes** for Layouts A and C.

### Layout C: pads plus X-Y

The pads play, and the X-Y pad shapes the sound while you play.

- On the ZOIA, place two **Midi CC In** modules, channel 10, one per X-Y axis. Connect them to CV out 3 and 4, set to -5 to 5 V.
- Patch CV out 3 to Alecto MORPH 1 and CV out 4 to TIMBRE 2.
- X sweeps the kick from square-wave thump to FM clang. Y opens and closes the second voice.
- The X-Y axes often default to CC 1 and CC 2. Check yours in the Korg Kontrol Editor and set the X-Y channel to 10.
- sci records the moves along with the hits, so a sweep becomes part of the loop.

### nanoPAD2 features worth using

- **Roll.** Press ROLL, touch the X-Y pad, then hold a pad. The note repeats; X sets the speed and Y the velocity. On the Alecto this gives snare rolls and hi-hat runs. In Layout A, Y fades the roll in and out through VELO.
- **Flam.** Press FLAM, touch the X-Y pad, then hit a pad for a doubled hit.
- **Gate arpeggiator.** Repeats pads in time while you touch the X-Y pad; X sets the note spacing.
- **Scenes.** Store one scene per layout, so switching layouts is a scene change on the pad plus a patch change on the ZOIA.

While ROLL is on, the X-Y pad sends no CC, so Layout C's X-Y sweeps pause.

### The nanoKEY

The nanoKEY plays the Hades bass on channel 2, through sci. Three things are worth setting up:

- **Mod wheel.** If the nanoKEY sends CC 1, the Hades MOD jack outputs it as 0 to 5 V. Patch `Hades MOD → Alecto MORPH 2` or `→ Komorebi STATIC`, and the keyboard now shapes the drums or the flanger.
- **1V/OCT.** Patch `Hades 1V/OCT → ZOIA CV in 1` and connect it to the bass crusher's crushed bits. Low notes stay clean; high notes crunch.
- **Keys on the drum channel.** Set the nanoKEY to channel 10 and its keys play the Alecto through the same ZOIA patch. In Layout B it becomes a melodic drum keyboard.
- sci passes the mod wheel and pitch bend through to the Hades track live, and sends nanoKEY notes on channel 10 straight to the ZOIA. Neither is recorded into a loop.

### Three patches that tie it together

**R1. Kick pumps the bass**

- On the ZOIA, place an **Env Follower** on the Alecto's audio input. Connect it to a **VCA** in the bass chain, at a negative strength or through a CV Invert.
- Listen: the bass ducks on every kick, like sidechain compression.

**R2. Kick crushes the bass**

- Cable: `Alecto BEND 1 → ZOIA CV in 1`, connected to the bass chain's crushed bits.
- Listen: the bass gets dirtier on each kick.

**R3. X-Y plays the effects**

- In any layout, add Midi CC In modules for the X-Y CCs and connect them to the crusher's crushed bits and the Aliaser's alias amount.
- Listen: the X-Y pad becomes a crush performance control, recorded by sci.

### Sources

Dreadbox Alecto Product Manual, version 1.0.0, and Dreadbox Hades User's Manual, as uploaded. Patches marked **try it** rely on behaviour the manuals do not spell out.

Sections 10 and 11 also use the [ZOIA Euroburo manual, firmware 2.30](https://empresseffects.com/cdn/shop/files/ZEBU_Manual_2_dot_30.pdf), the [ZOIA module index](https://empresseffects.com/ZOIA-module-index), and the Korg nanoPAD2 [parameter guide](https://people.carleton.edu/~jellinge/m208w14/pdf/nanoPAD2_PG_E1.pdf) for Roll, Flam, Gate Arp and X-Y settings.
