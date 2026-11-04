# Marble clock: notes, decisions and task list

This is a shared, editable file. Edit it anywhere (GitHub web editor is fine) on
branch `claude/wire-marble-track`. Claude pulls and re-reads it at the start of
each round, so you don't need to paste changes back. Feel free to:

- tick or delete tasks, add new ones, reorder them
- write corrections inline; mark them with `>>` so they're easy to spot, e.g.
  `>> no, the cheeks should be ...`
- mark anything Claude wrote as wrong with `>> WRONG:` and a note

Claude's own uncertain assumptions are marked **(assumed)**. Please confirm or correct them.

---

## 1. Goal and taste

- **Piece:** a wall-hung ball clock. The frame is a 1 m square of 2020 extrusion, at most 150 mm deep.
  (A 300 mm cube desk toy was the alternative; we chose the wall piece.)
- **Priorities:** clever, pleasing to look at, fun and satisfying to watch matter much more than accurate time.
- **Lift:** a ball lift that is itself a second pendulum, rocking with the clock's rhythm.
- **Materials:** no plastic parts. Wood (laser-cut), 2020 aluminium, steel hardware, steel balls.
  - Polymer V-wheels are the accepted exception: they are bought hardware, not printed parts.
- **Hands and dial are critical.**
- **Balls:** 3/4" chrome steel. 200 ordered.

## 2. Materials, cutting and fit (keep everything parametric)

### Sheet thickness

| stock | thickness to design with | notes |
|---|---|---|
| MDF (current prototypes) | **3.1 mm** | Sold as 1/8". 3.10 with the calipers pressed firmly; up to ~3.2 relaxed or humid. Recorded in cnc_vibes `mdf_3mm` (`thickness_mm: 3.1`). |
| Baltic birch veneer plywood (final) | **2.6 mm** (measured 2.63) | final version |

**Two layers in a 2020 slot:**
- 2 × 2.6 = 5.2 mm fits the 6.2 mm slot opening.
- 2 × 3.1 = 6.2 mm wedges, as you found.
- So a part that later becomes double-layer plywood must be designed with T = 5.2 (two layers) or T = 2.6 (one layer) in mind.

**Every generator takes T as a parameter.**
- `marbles/clock/wheel_box.py --t 2.6` and `--t 5.2` both run and report the narrowest web.
- **Rule:** no web, tab or margin narrower than max(4 mm, T), so a design that works in 3.1 MDF never gets too thin in 2.6 plywood.

### Kerf

- **Value to use:** `KERF = 0.10`.
- **Plywood zig-zag test:** the 11 strips stacked measured 53.73 mm.
  - kerf = (11 × 5 − 53.73) / 11 = **0.1155**
- **The earlier 10-strip reading (48.95) was inconsistent.** It implies the 11th strip is 4.78, versus 5 − 0.1155 ≈ 4.885. Ignore it.
- **Effect of using 0.10 when the true kerf is 0.1155:**
  - each edge is under-compensated by 0.0077 mm
  - outer sizes come out 0.016 mm small; holes 0.016 mm big
  - that's negligible next to the 0.1 mm thickness variation of the MDF
- **MDF:** 0.10 is confirmed by fit, not by a strip test. The tab fit above came out perfect with it.

### Tab and slot fit

- **MDF, verified 2026-11-03 on the first wheel box: PERFECT.**
  - Settings: T = 3.1, kerf 0.10, slots drawn at exactly T (FIT = 0).
  - Result: tabs tight and snug, with no deforming.
  - **Use these for all MDF cuts.**
  - Recorded in the cnc_vibes `mdf_3mm` profile's `fit:` block (`kerf_mm: 0.10`, `slot_extra_mm: 0.0`).
  - `wheel_box.py`, `wheel_box_gcode.py`, `lift_parts.py` and `lift_sieve.py` read thickness, kerf and fit from that profile (`laser_parts.material_fit`).
- **Plywood:** not verified yet. With no `fit:` block, the scripts fall back to kerf 0.10 and FIT 0 and print a note. It probably needs about +0.05 (assumed); task L3.
- **Tabs and fingers are 10 mm wide.** Narrower ones fray MDF corners.
- **M5 holes are exactly 5.0 mm.**

### Laser

- **Driver:** cnc_vibes quickcut through `marbles/laser_parts.py`.
  - `emit_cut` puts a warm-up wiggle at every cut start, and closed loops overlap past their start.
- **MDF recipe:** `mdf_3mm`, 100% power, F500, 2 passes. Use air assist.
- **Validate before cutting:** `cd cnc_vibes/cnc_vibes && python3 cnc.py validate <file>`.
  - Engraves at F5000 get flagged against the unconfirmed 3000 cap.

## 3. Hardware on hand

- **Extrusion:** lots of 2020, both T-slot and V-slot.
  - Slot opening 6.2, inner 11, lip 1.8, centre bore 5 (T) / 4.2 (V).
- **Fasteners:** M5 screws including long ones, T-nuts, M3 bolts.
- **OpenBuilds solid V-wheels (polymer):** 24 OD, 10 wide, 5 bore, 625 bearings. **Chosen for the lift.**
  - Also have steel "W" wheels (V outside, square corner inside).
- **OpenBuilds plates:** 65.5 square, 87 × 88; 7.2 eccentric and 5.1 holes. Various counts and conditions.
- **Bearings and shafts:** 608 skateboard bearings, 8 mm shafts, pillow blocks.
- **Motors:**
  - 12 V Ford F150 windshield wiper motor
  - microwave turntable motor B6326408AP
- **Other:** drag chain (used before), toy marbles, cardboard (prototype guards).

## 4. Pendulum lift: current design

### Geometry

**Coordinates:** a = across, s = swing (+ is front), z = up along the beams.

**Beams:**
- F = fixed beam, at a 0..20.
- M = moving beam, at a 40..60, set 11.6 mm back from F.
- The ball column sits in the 20 mm gap between them.

**Sieves** (300 × 46, 20 mm holes every 30, M5 holes at X 30/90/150/210/270, `lift_sieve.py`):
- S_F bolts to F's back face; its 6 mm edge rides in M's near slot.
- S_M bolts to M's front face; its edge rides in F's near slot.

**Keepers** (300 × 80, M5 rows 10 mm in from each long edge):
- K_F on F's front face; K_M on M's back face.
- They double as the front and back ball guards.

### Rocking drive

- The whole rig hangs from a pivot at the top and rocks.
- An off-centre cam (r = 10) drives a slot in a front arm.
- M hangs from a fixed link (100 mm), so rocking produces the lift.
- **Design numbers** (from `lift_demo.scad`):
  - stroke 34 = 30 pitch + 2 × 2 drop
  - tilt +6° (forward) / −18° (back)
  - `arm_trim` 1.0085
- cam_arm / cam_disc / m_link / link_anchor in `lift_parts.py` are still sized from the animation, **not your real rig**.

### Wheel boxes (replace guide rails G_F/G_M and sliders L_F/L_M)

`marbles/clock/wheel_box.py` is the source of truth. The figures below are its output at T = 3.1.

**Layout:**
- One box near each end of each keeper (box centres at z 60 and 240), 4 in total.
- Boxes on K_F ride M's far V-groove; boxes on K_M (mirrored) ride F's far V-groove.

**Keepers, two kinds:**
- **WK wheel keeper**, one per wheel: 150 × 89.95, so 2 fit along one 300 sheet edge.
  - It is that wheel box's near wall: 40 wide, curving out (r 15) to a lobe (u 31.40..118.60) with the box's tab slots, 2 box bolt holes and a round axle hole.
  - Its beam row (v = 10, u = 15 / 75 / 135) is slots running across, ±1.5.
  - Each wheel is tensioned on its own; no two wheels are coupled.
- **PK plain keeper**: 300 × 40, round M5 at the sieve's pattern (u 30/90/150/210/270, v = 10).
  - Guard or backing wherever no wheel is needed. Quantity as needed.
- **As drawn:** two WKs end to end on each beam (box centres at z 75 and 225), 4 wheels.
  - Arrange WKs and PKs however testing shows.
  - Both kinds mount flat on the beam face. Stacking a WK on top of a PK would move its box out by one sheet thickness, which the script doesn't model yet.
- The sieve-pattern spacing doesn't matter for keepers bolted with T-nuts into the beam slot, since those can sit anywhere along it.

**Parts per box, 4 + the keeper lobe:**
- **FC far cheek ×1 (32.95 × 87.20):** beyond the wheel. The keeper lobe and the far cheek carry the axle at both ends.
- **TB top/bottom ×2 (23.95 × 41.40)** and **BK back ×1 (41.40 × 79.20):**
  - They tab through the keeper and the far cheek; they're the compression struts.
  - They are one sheet thickness longer than before, because they now reach the keeper itself.
  - TB and BK finger-joint at the back corners: 3 fingers of 11.73 along the 35.20 inside depth.
- The box is open toward the beam the wheel rides (open side at a = 62.00, 2 mm off M's far face).

**Hardware:**
- Long M5 bolts run keeper → far cheek, with a plain nut outside. No captive nuts.
  - 2 per box, plus the axle.
- Bolt length: keeper outer face to far cheek outer face = 41.40, plus a 4.7 nut = 46.10. Use **M5×50**.
  - T = 2.6: 44.60 → M5×45.
  - Double 2.6 (5.2): 52.40 → M5×55.
  - The script picks the length.

**Wheel position:**
- Axle at a = 69.85 (9.85 from the beam face, taken from the 39.7 c-c of the OpenBuilds 65.5 plate). Rim reaches a = 57.85.
- **Along the axle (s):** two nuts locked on either side of the bearing's inner race (nut A, nut B).
  - Free space either side: 16.60 (keeper side) / 8.60 at T = 3.1.
  - Use shims or washers that touch only the inner race (assumed 1 mm).
- **Wheel tension (a):** loosen that WK's slotted screws (v = 10), slide the WK and its box until the wheel seats, then tighten.
  - At full slide the open side sits 60.50..63.50 from M's far face (60).
  - The far cheek's edge reaches 55.50 (the S_M/K_M bolt heads end at 54.25).

**Thinnest wood:** 4.00 mm in the WK and the far cheek at T = 3.1 and 2.6, and 5.20 at 5.2. That meets the min-web rule.

**Still true (same as the old guide rails):**
- Swing-direction loads reach F through K_F, bending it across the ball gap; the same applies to K_M.
- The near-slot sieve edges still slide, and they are the only stop against F and M squeezing together.

### Later (not now)

- **Viewing cutouts** in keepers, guards and boxes so the balls show. Respect the min-web rule.
- **Final material:** 2.6 plywood; each part single- or double-layer. Decide per part.

## 5. Ideas raised (not chosen yet, keep in mind)

**Lifts:**
- Ferris wheel
- a motorised toothed gear at the bottom
- gears acting as Ferris-wheel lifts
- balls riding inside a gear
- drag chain with a top pulley scoop (abandoned)
- counterweighting the oscillating panels
- a lift on a microwave-motor camshaft (wooden camshaft), spanning 1 m with 60 × 300 pieces and opposed assemblies with a fixed tunnel piece
- a 1:10 centre-driven wooden gear

**Escapement and pendulum:**
- Ball escapement at the top of a 1 s pendulum, above the fulcrum, releasing to alternate sides.
- Graham deadbeat (`escapement.py`; simulated).
  - Balls driving the escape arbor directly are about 10× too strong at a 4° swing.
  - At about a 30° swing, roughly 1 ball per tick matches the energy.
- Wide swing, ±30°.
- The escapement hooks onto a screw.

**Gears:**
- cylinder-pin gears
- 2 plywood copies held with M3 bolts
- 8 mm shafts in pillow blocks, or just an 8 mm hole

**Display:**
- a full 60-ball rail rather than separate 5s and 1s rails
- engraved numbers 30 mm tall
- a 2020 tipper rail with wood sides
- a double-stack or two-lane parallel tipper to keep it short
- a seconds rail too

**Fun:**
- an overflow track for excess balls
- switches
- balls riding down a tube
- balls riding on the pendulum itself
- a gallery of Rube Goldberg / marble-run mechanisms to pick from

**Motor:** F150 wiper motor (12 V) or the microwave motor.

**Related earlier project:** wire-rail hook ribs and plywood spoke rails on pegboard, in `marbles/hybrid.scad` (separate track).

---

## 6. Tasks

### Pendulum lift (now)

- [x] **L1** Wheel-box concept: keeper is the near wall, plus far cheek + top/bottom + back, open toward the beam.
- [x] **L2 (MDF)** Kerf 0.10 confirmed by the perfect tab fit. Plywood: re-confirm 0.10 when we switch.
- [x] **L3 (MDF)** Tab fit is perfect at T = 3.1, kerf 0.10, FIT 0.
- [ ] **L3b (plywood)** Tab-fit coupon in 2.6 plywood; add a `fit:` block to its profile.
- [ ] **L4** Check that the far faces of F and M are V-slot (wheels don't seat in T-slot). Swap beams if needed.
- [x] **L5** G-code for one WK + its box (`wheel_box_set.gcode`) and for the PK (`plain_keeper.gcode`). Validated; the box set is cut.
- [ ] **L6** Cut and dry-fit one box on a V-slot offcut with a polymer wheel. Check:
  - groove engagement (the 9.85 assumption)
  - enough keeper-slot travel (±1.5) to seat and tension the wheels
  - room for nuts A/B and a wrench through the open side
  - bolt lengths
- [ ] **L7** Cut 4 WK wheel keepers + 4 boxes, and plain keepers (PK) as needed.
- [ ] **L8** Assemble the slide. Hand-cycle and note:
  - friction and rattle
  - whether the near-slot sieve edges rub (the squeeze stop)
  - wheel noise
- [ ] **L9** If rattle or rub is a problem, design a squeeze-direction stop (e.g. a small roller), or change the sieve-edge depth.
- [ ] **L10** Measure the real rig:
  - pivot location
  - M's link anchor point
  - where the cam can sit
  - top/bottom clearances
  
  Write them into this file.
- [ ] **L11** Re-size cam_arm, cam_disc, m_link and link_anchor (`lift_parts.py`) to the real geometry. Re-check stroke 34, tilt +6/−18 and the link solve.
- [ ] **L12** Cut and fit the cam/link parts. Hand-crank test: every ball steps up one hole per turn, with no jams or double-feeds.
- [ ] **L13** Tune the hand-off drop (2 mm each way), the tilt angles, and the forward/back roll timing.
- [x] **2026-11-04:** The lift works by hand with one wheel box per side, the top pivot on pillow blocks, and M hung by a chain + turnbuckle.
- [ ] **L10a** Chain length and swing: measure d, h, L, e and the two tilts; use the tuner page (https://claude.ai/artifact/4cPu2Bs5Xj2CbjY5Lb4qQ5).
  - Stroke ≈ d × (sin tilt1 + sin tilt2); target = pitch + 2 × drop.
  - The chain and turnbuckle only place the stroke (registration).
- [ ] **L14** Bottom pickup: how balls enter the first hole (feed chute or ramp from the clock's return).
  - **Your design (2026-11-04):**
    - The bottom hopper feeds a short fixed chute ending in a wire catch. The catch holds exactly one ball in a known spot, with the rest queued behind it by gravity.
    - The swinging rig carries a wire hook that snags that one ball as it passes and drops it into a short chute on the rig.
    - That chute queues a few balls for the bottom sieve hole.
  - **Details to settle (Claude's suggestions):**
    - Put the pickup near one end of the swing, or make the hook a one-way hinged finger, so the hook doesn't hit the next ball on the return pass.
    - Pushing the ball sideways off an open-sided cradle may be easier than lifting it.
    - What happens when the rig's queue is full: overflow path, or a hook that misses when the queue backs up.
    - Drop height and noise into the rig chute.
    - Run both chutes parallel to the pivot axle.
  - Ideas:
    - Run feed and exit tracks **parallel to the pivot axle**, so rocking only banks them and never changes their slope.
    - Bottom moves most: either a short queue ramp riding on F into a window in the guard at the bottom hole, fed from a fixed spout over a catch mouth wider than the bottom's swing, or pivot the lift at the bottom instead.
    - Keep the queue short so it doesn't press on M.
    - The holes themselves meter one ball per cycle.
- [ ] **L15** Top dispense: exit chute from the top hole onto a track, into a hopper.
  - Ideas: a window in the guard at the top hole on the side the last hand-off rolls toward, then a short chute on the rig (parallel to the axle) dropping onto a fixed track.
  - The top is near the pivot, so it barely moves.
- [ ] **L16** Hopper with an overflow track for excess balls (and maybe a "full" switch).
- [ ] **L17** Front/back guards: keepers as guards; check that nothing can escape anywhere along the travel.
- [ ] **L18** Balance and counterweight for the rocking rig, so the drive torque is even.
- [ ] **L19** Motor drive for the lift (wiper or microwave motor):
  - mount
  - speed (balls per minute vs the clock's demand)
  - gearing or belt
  - power supply
  - a hand-crank fallback
- [ ] **L20** Make the lift's rock read as a pendulum: amplitude and period that look good next to the clock pendulum.
- [ ] **L21** Update the animation (`lift_rig.scad` / `lift_demo.scad`) to the real layout and the wheel boxes (deferred).
- [ ] **L22** Viewing cutouts in keepers, guards and boxes (later; keep min web ≥ max(4, T)).
- [ ] **L23** Plywood version: run every lift generator at T = 2.6 / 5.2 and decide single vs double layer per part.
- [ ] **L24** Photo or video of the working lift; record the final numbers here.

### Clock milestones (after the lift)

- [ ] **M1 Frame:** 1 m square 2020 frame, wall mount and French cleat, ≤150 mm depth. Layout of every subsystem in the frame.
- [ ] **M2 Pendulum:** 1 s period, wide ±30° swing. Bob, rod, suspension (spring or knife edge), beat adjustment, rating nut.
- [ ] **M3 Escapement:**
  - deadbeat test rig with a string weight
  - then a ball-driven version (1 ball per tick at about a 30° swing)
  - ball release to alternating sides
  - escapement at the top or on the pendulum
- [ ] **M4 Gear train:**
  - ratios (seconds → minutes → hours)
  - tooth form (cylinder-pin vs involute)
  - 2-layer plywood gears with M3, 8 mm shafts and pillow blocks or plain holes
  - 1:10 stages
  - backlash and friction tests
- [ ] **M5 Hands and dial (critical):**
  - dial layout and engraving
  - hand shapes and balance
  - motion works (12:1)
  - setting the time
  - legibility from across a room
- [ ] **M6 Counting rails:**
  - full 60-ball tipper rail (2020 + wood sides), double-stack or two-lane
  - seconds rail, minutes, hours
  - engraved 30 mm numbers
  - tipping/dump mechanics and reset timing
- [ ] **M7 Ball distribution:**
  - hopper at the top
  - tracks to the escapement and rails
  - return to the lift's bottom pickup
  - overflow/excess path
  - ball count budget (200 balls)
- [ ] **M8 Lift integration:**
  - lift rate vs consumption
  - lift drive timing with the clock
  - motor control (constant speed? switch-triggered?)
  - noise
- [ ] **M9 Fun features:**
  - balls ride on the pendulum
  - ride down a tube
  - balls inside a gear
  - switches or bells
  - the mechanism gallery (pick 2–3)
- [ ] **M10 Materials pass:** convert everything to 2.6 plywood (single/double layers), finish (sanding, sealing, colour), aluminium cleanup.
- [ ] **M11 Tuning:** run in, timekeeping test over a day and a week, adjust, reduce noise.
- [ ] **M12 Docs:** README / build notes, cut list, BOM, assembly order, photos.
