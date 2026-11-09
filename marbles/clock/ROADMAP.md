# Ball clock roadmap: parts, tests, code

Started 2026-11-05. One row per discrete thing to design, test or write.
- **IDs:** P = part to design, T = test / calibration / experiment, C = code (tools, simulators).
  Numbering starts at 100 so the parts already built can be given low numbers later.
- **Status:** `ready` (designed, waiting to be cut), `unblocked` (Claude can start now),
  `in design`, `needs input` (Alex's answer needed, question in the row), `done`.
- **Other docs:** history and lessons in `NOTES.md`; pickup concept in `PICKUP_LOG.md`.

## The vision (Alex, 2026-11-05)

- **Clock face backboard:** a large clock face is the backboard, with big **hour, minute and (ideally) seconds hands**.
- **Ball display:** the clock runs at **one ball per second**. Each unit's balls fill an arc of a ring, **from 12 o'clock
  clockwise up to that unit's hand**:
  - hours nearest the centre
  - minutes in the middle
  - seconds on the outside
- **Holes, not stacks:** balls needn't stack touching. Each can sit in a **hole in a ring of cut pieces**, and the ring
  rotates on time and keeps them in order.
  - Touching, minutes and seconds would both need 60 balls per turn, so the same radius. The ways out are below.
- **Rollover:** when the seconds ring reaches 12 again with 60 balls in it, **one ball goes to the minutes ring and the
  rest return** to the tracks and the lift's hopper. Minutes → hours works the same way.
- **Rings as gears and lifts:** a **3-layer ring**: two outer walls 20 apart, with a centre plate in which the balls sit in
  holes or slots. **Curved slots** in the centre plate let a ball roll out at a chosen point in the rotation.
- **Wire parts:** Alex is good at making wire parts **when there's a bending jig**: switches, flippers, hooks.
  **Long free lengths of wire track are the problem:** they deform when handled and are hard to straighten.
  So build track as short jigged segments with solid couplers.
- **Switches:** route each marble along a different path. The moving part is a soldered wire piece.

### Ring radii for 3/4" balls (19.05), worked out 2026-11-05

These are centre radii, i.e. to the balls' centres; a band is a ring's inner and outer edge.

| Arrangement | Radius |
|---|---|
| 12 balls touching (hours) | **36.8** (band 27.3–46.3) |
| 24 balls touching | 73.0 |
| 60 balls touching, one row (minutes OR seconds) | **182.0** (band 172.5–191.5) |
| 60 minutes as a **zigzag**, 2 rows of 30 alternating, each ball touching its neighbours | rows **91.1 / 107.1** (band 81.6–116.6) |
| 60 seconds in **12 groups of 5**, 1-ball gap between groups | **218.3** |
| ... 2-ball gap | 254.7 |
| ... 3-ball gap | 291.1 |

**Example layout with no hole-rings:**
- hours: 12 touching, r 36.8
- minutes: zigzag, r 91.1 / 107.1
- seconds: 60 touching, r 182.0, or groups of 5 at r 218.3

Face diameter: about 2 × (191.5 + rim) ≈ **415+**, or about 485+ with groups of 5.
**The laser bed is 400 × 600**, so the face and the outer ring must be cut in segments.
With hole-rings, any radius ≥ these minimums works.

## Parts already built (to number later)
lift sieves and keepers (3–10 holes), wheel boxes, feeder box (funnel, keepers, spacers, trough), dispenser wire
interface (tunnel flange + relief), compact D ring jig + mandrel, fit coupon, escapement test-rig parts (`escapement.py`).

## Table

| ID | Item | Status | Notes / blocking questions |
|---|---|---|---|
| **P1xx** | **Lift and ball handling** | | |
| P100 | Dispenser (upside-down feeder + wire interface) | ready | All files in the feeder-box zip (mdf3). Cut after T100/T101. |
| P101 | Pickup grabber: fishhook wire fingers on the pendulum (`PICKUP_LOG.md` §1) | needs input | 12 or 14 ga? How many fingers? Needs the rig measurements (T105): where the swing ends relative to the hopper track. |
| P102 | Hopper-output wire track with sloped triangle end, holding one waiting ball | needs input | Same as P101; also how one ball is released at a time. |
| P103 | Bottom catch hopper: collects every returning ball, feeds P102 | needs input | Capacity (ball budget ~200?), where in the frame (P403). |
| P104 | Overflow / excess-ball path | unblocked after P403 | |
| P105 | Lift drive: cam / link / anchor resized to the real rig (old L11–L12) | needs input | Needs T105 measurements. |
| P106 | Lift guards and counterweight (old L14–L18 leftovers) | later | |
| **P2xx** | **Wire track, switches, jigs** | | |
| P200 | **Jigged track segments:** short straight and curved spider-tunnel segments, each built on a jig, joined by solid couplers so no long loose wire is handled | in design | What segment length is comfortable to handle? What curve radii do the routes need? (Depends on P403.) |
| P201 | Curve-bending jig for tunnel straights (bends 4 wires together around a former at a set radius) | unblocked after P200 radii | Needs T108 (smallest clean bend radius of 12 ga). |
| P202 | Segment coupler / mount: a flange like the tunnel flange, joining segments or fixing them to the backboard | unblocked | Reuses the tunnel-flange profile (bore + notches + stitch holes). |
| P203 | Track → ring entry: drops one ball into a ring hole at 12 o'clock | in design (with P300) | |
| P204 | **Switch / diverter:** a soldered wire flipper on a pivot sends each ball one of two ways | needs input | What decides the path? Alternate every ball (toggle), ball-triggered, or set by the clock state (e.g. rollover)? |
| P205 | Bending jig for the P204 flipper | after P204 | |
| P206 | Bending jig for the P101 fishhook fingers | after P101 | |
| P207 | **Spiral run** (`spiral_run.py`): one-cut pull-down spiral on 300×300 stock, pitch 12.7, entry flange on a 2020 post | **WIP v3 (2026-11-09)** | v3: the cut just stops after the laps; a **separate centre guide** (`spiral_centre_guide_*`, optional 2nd copy as the spacer) lies on the solid centre and channels the ball from the last lap into the exit bore (90° curl, tightest turn r 22). The v2 one-piece curl is rejected. Open: does the step at the last lap clear the guide (needs > 1.9 (ply3) to 2.3 (birch3) mm for one layer, 4.5 to 5.3 mm for two); which material (first cuts tonight); Alex has notes and ideas still to add. |
| **P3xx** | **Clock display (rings, rollover, hands, face)** | | |
| P300 | **Seconds ring:** 60 positions, turns 6° per second | needs input | Touching at r 182, or groups of 5 at r 218/255, or hole-ring at any r? Driven straight from the escape arbor (`escapement.py` turns once a minute) or advanced by each ball? |
| P301 | **Minutes ring:** 60 positions | needs input | Zigzag (r 91.1 / 107.1), or hole-ring? Advanced by the ball arriving from the seconds rollover, or geared? |
| P302 | **Hours ring:** 12 positions (r 36.8 touching) | needs input | 12 or 24? At the 12th hour, do all of them return? |
| P303 | Ring loaders at 12 o'clock (one per ring) | in design | Tied to P203. |
| P304 | **Rollover / dump:** seconds full → 1 ball to minutes, 59 return; minutes → hours; hours → all return | in design | Mechanism idea: a second slotted plate that opens the holes, or curved slots (P305). Which ball goes on: the 60th (last arrival)? |
| P305 | **3-layer ring gear** (2 walls 20 apart + centre plate with ball holes and curved release slots): the building block for P300–P304 and for ring lifts | unblocked | Generic parametric SCAD (C104) can start now; the radius and hole count come from P300–P302. |
| P306 | Hands: hour / minute / seconds, large and balanced | needs input | Is a ring its own hand (a pointer fixed to it), or a separate hand on an arbor? |
| P307 | **Clock face / backboard** with numerals | needs input | Overall diameter (≈415–490+, so segmented: the bed is 400 wide), material (ply3?), numeral style. Numerals can be etched on ply3 (its etch recipe is calibrated). |
| P308 | Ring support at the face centre: concentric arbors, or large rings riding on rim rollers (V-wheels like the lift's) | in design | Rim rollers suit big light rings; to confirm with P300. |
| P309 | Ring advance / drive: ratchet + pawl per ball, escapement-driven, or geared (old M4) | needs input | Depends on P300/P301 answers. |
| **P4xx** | **Timebase and structure** | | |
| P400 | Pendulum: the 48" 2020 bar, ±30° swing (old M2) | in design | **2026-11-05 maths:** top pivot, bare bar: 1.809 s full period (2.215 s in the heavy-bob limit). A 1 s FULL period is impossible with a 48" bar (needs L_eq 0.2485 m; a centre pivot is at best 1.566 s). **Centre pivot works** for a *seconds* pendulum (1 s per swing, 2 s full period, L_eq 0.994 m) if the bob is at the bottom and the bar weighs ~1.89 × the bob, and it can share the discs' axis. A bare bar pivoted at its centre doesn't swing (balanced). Alex: centre pivot on the face axis? |
| P401 | Ball metering escapement + **seconds disc** (old M3) | **decided 2026-11-08: seconds disc** | Alex loves the seconds-disc idea: the 30-tooth escape wheel (`escapement.py`, 1 rev/min) becomes the seconds disc, stepped one notch per half-swing by the motor-driven pendulum; balls are metered for the display, not used to keep time. To do: update `escapement.py` for 3/4" balls, pallets for the real swing amplitude. |
| P410 | **Pendulum drive:** 12 V door-lock actuator (IGDLA-4) through a spring / elastic link, IBT-2 (BTS7960) bridge | in design | **2026-11-08 plan (no microcontroller):** R_EN + L_EN tied to 5 V; marble end A -> NC limit switch (opens at the end of that stroke) -> RPWM; end B -> its limit -> LPWM; 1k pull-downs on RPWM / LPWM. Held high = 100 %; both low = brake. EN-only switching can't work on the IBT-2 (the other half-bridge floats). Watch for buzz at a limit (spring pulls it back past the trip point). Fixed-rate microcontroller mode kept as a fallback. |
| P402 | Gear train (old M4), only if the rings are geared: 60:1 and 12:1 | needs input | Depends on P309. |
| P403 | Frame (1 m square 2020, ≤150 deep, wall cleat) + layout of every subsystem (old M1) | unblocked for a first sketch | Fixes the routes for P200/P104. Needs the face diameter (P307). |
| **T1xx** | **Tests and calibration** | | |
| T100 | mdf3 fit coupon on the new 2.82 batch | needs Alex | Which slot (1–5) is snug → the profile's fit block. |
| T101 | mdf3 cut recipe F700 × 3 on the new batch | needs Alex | Same cut as T100. Scorch → F800; needs a knife → F600. |
| T102 | ply3 fit coupon (never measured; L3b was ticked without it) | needs Alex | `fit_coupon.py --material ply3` |
| T103 | Laser mode: send `$32` after a job | needs Alex | Our files send `$32=1`, but the dump showed 0. |
| T104 | Controller board replacement, then Z re-check (`$3`/`$23`, `Pn:` with the switch pressed, ±10 mm jogs, `$HZ`) | needs Alex | |
| T105 | Measure the real lift rig: pivot, link anchor, cam spot, clearances, chain d/h/L/e, the swing amplitude, symmetric (old L10/L10a) | needs Alex | Unblocks P101, P102, P105. |
| T106 | Hand-crank lift test and tuning (old L12/L13) | after P105 | |
| T107 | Ring loading test: does a ball drop reliably into a moving hole at 12 o'clock? | unblocked after C104 | Small test ring. |
| T108 | 12 ga bend test: smallest clean tunnel-curve radius; spring-back of the fishhook fingers | needs Alex | A bending jig for it can be made now. |
| T109 | acrylic3 (black) test square; mdf6 calibration | low priority | |
| T110 | Escapement test rig (string weight), parts already in `escapement.py` | needs input | Cut and run it now, or wait for the display design? |
| T111 | Dispenser wire interface assembly check (32 mm stitched wire ends, bends in the relief slots) | after P100 | |
| T112 | Back-plate trim on the first dispenser plate (`back_keeper_trim_142x122_mdf3.gcode`) | needs Alex | Re-sent after the long-line fix. |
| **C1xx** | **Code, tools and simulators** | | |
| C100 | cncctl (Xbox controller pendant) | dropped | Alex ordered a proper pendant (2026-11-06). |
| C101 | Split marbles/ into its own repo with cnc_vibes as a submodule (`SPLIT_REPO.md`) | needs Alex | Create an empty GitHub repo; this session can't. |
| C102 | Model M's keeper (K_M) in `feeder.scad` so the back-keeper clearance is checked | needs input | K_M's position and size at the feeder's height (or derive it from `wheel_box.py`?). |
| C103 | **Display simulator:** ring fill, rollover timing, ball budget, radius calculator (the table above), animated | unblocked | |
| C104 | **Parametric ring generator** (P305) in SCAD with a CHECK report + G-code export | unblocked | |
| C105 | Frame files: a laser-off trace of each job's outline | optional | |
| C107 | Face sketch (`face_sketch.py`): 48\" frame, seconds 12×5 + 2-ball gaps (r 254.7), minutes 60 touching (r 182.0), hours r 109.3, pendulum in front | done | Quick visual only. |
| C108 | **Cut-order optimizer for quickcut** (TSP, e.g. OR-tools routing / CP-SAT, or a greedy + 2-opt heuristic): least laser-off travel between cuts, while keeping **middle-out** (every hole or inner cut before the outline that contains it, so loose pieces don't shift); also pick each loop's start point. Today's rule is a global smallest-area-first sort, safe but travel-heavy on multi-part sheets | done (first version) | Estimate 2026-11-06: ~1 day for a pure-Python heuristic with tests; +0.5 day for an optional OR-tools backend. Payoff on `feeder_sheet_300x291`: travel is 13.0 m ≈ 4.3 min of a ~34 min job (F3000 rapids), so at most a few minutes saved there; more on many-small-part sheets. |
| C109 | **One laser emitter core: quickcut** (handoff: `cnc_vibes/HANDOFF_quickcut_consolidation.md`, incl. the branch audit). Today quickcut is only partly shared. jigsawzall and orpot import its `motion` helpers (decimate, warmup_wiggle), arcfit and grbl_model, but each has its own preamble, material loader, cut/etch/raster emission and footer. cam.py/laser_cam.py, cnc_calibrate, the lessons and scads `laser_parts.py` have theirs too. Move the union into quickcut (preamble, M3-static + warmup cuts, etch, raster, park, frame, line-length limit, material loader returning the full record, cut ordering incl. jigsawzall's chain/nearest-safe ordering and C108) behind one `write_gcode()` that frames + validates; make every emitter call it | unblocked | Estimate 2026-11-06: 2-3 days, phased emitter by emitter. jigsawzall (1332-line emitter) is the bulk. Its test suite already has 51 failures + 8 errors, which have to be sorted first to tell regressions apart. |
| C106 | Remove the old 3-layer ring jig (`ring_jig.py`) | done | Deleted 2026-11-06 with its viewer; the compact D jig replaces it. |

## Parked ideas (from the whole project; pick from these later)
- **Lifts:** Ferris wheel; a motorised gear lift; gears as Ferris-wheel lifts; balls riding inside a gear; a microwave-motor
  camshaft lift; ring lifts built from P305.
- **Escapement:** a ball escapement above the fulcrum, releasing to alternate sides; the escapement hooking onto a screw.
- **Display:** a 60-ball tipper rail; engraved 30 mm numbers; a double-stack or two-lane tipper.
- **Fun:** balls riding on the pendulum, down a tube, inside a gear; bells; switches; an overflow track; a gallery of
  Rube Goldberg mechanisms; a viewing cutout in every guard.
- **Motor:** F150 wiper motor (12 V) or the microwave motor.

## WIP log (2026-11-09)

Saved mid-stream; nothing here is tested yet. Alex has notes and ideas still to add.
- **P207 spiral v3:** sheet + separate centre guide + entry and exit flanges, all in ply3 / mdf3 / birch3 (`spiral_run.py`).
- **P410 pendulum drive:** `pendulum_switch.py`: marble switch rail (layer stack, copper-foil contacts, `--curve`), trip flag,
  and `limit_holder_single` (one uxcell mini roller switch per holder, cut 2, one turned face down; 0° and 90° seats,
  switch turned over for -90°; slides on the actuator's 2020). Switch geometry from the uxcell drawing; the roller's
  free height is scaled off the picture. Actuator stroke still assumed 20 mm.
- **P207, 2026-11-09 later:** 10 mm drop per lap (each strip's edge at the next ball's centre height), held by 4
  `spiral_stair_<angle>` arms (an X under the sheet, each bolted along a 2020; the beams can't cross at the centre:
  the exit tunnel goes down there). Edge beam now ON TOP of the sheet. `spiral_entry_guide` (180 deg, on ~8-10 mm
  spacers over 3 new frame holes) keeps the first lap's ball on until the strip has dropped. Shelf slope 0.66 deg on
  the first lap, 1.56 deg on the last: may be too shallow for a slow ball (test). OPEN: the entry flange as drawn
  stands where the beam now is; how do balls arrive along the top rail? The centre's four supports differ by ~2 mm
  from a flat plane (shim).
- **P207 lamination (2026-11-09):** plan: 3 spiral sheets glued in shape. `spiral_form.py` = the glue-up form: 24
  small hollow stair holders (8 rays x 3, each 3 identical mdf3 layers glued), on 2 sheets; per-ray heights printed
  and in `spiral_form.png`. Untested.
