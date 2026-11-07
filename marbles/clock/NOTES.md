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
| MDF (current prototypes) | **3.1 mm** | Sold as 1/8". 3.10 with the calipers pressed firmly; up to ~3.2 relaxed or humid. Recorded in cnc_vibes `mdf3` (`thickness_mm: 3.1`). |
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
  - Recorded in the cnc_vibes `mdf3` profile's `fit:` block (`kerf_mm: 0.10`, `slot_extra_mm: 0.0`).
  - `wheel_box.py`, `wheel_box_gcode.py`, `lift_parts.py` and `lift_sieve.py` read thickness, kerf and fit from that profile (`laser_parts.material_fit`).
- **Plywood:** not verified yet. With no `fit:` block, the scripts fall back to kerf 0.10 and FIT 0 and print a note. It probably needs about +0.05 (assumed); task L3.
- **Tabs and fingers are 10 mm wide.** Narrower ones fray MDF corners.
- **M5 holes are exactly 5.0 mm.**

### Laser

- **Driver:** cnc_vibes quickcut through `marbles/laser_parts.py`.
  - `emit_cut` puts a warm-up wiggle at every cut start, and closed loops overlap past their start.
- **MDF recipe:** `mdf3`, 100% power, F500, 2 passes. Use air assist.
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

### Guard rails (2026-11-07, proposed): replace the keepers and wheel boxes

The steel balls bent K_F / K_M across the ball gap and jammed the lift. Mockup: `lift_full.scad` (`show_rails`), with numbers from its RAILS / WHEELS echo lines.
- **R_F** front guard: a 2020 beside F (x 6..26 in lift_full coordinates), its back face in F's front-face plane (where K_F was). Corner brackets sit between F's front face and R_F's side.
- **R_B** back guard: a 2040 (or two 2020s) behind M, 1 mm off M's back face (K_M's plane + RAIL_CLR). Its outer half lines up with F's far face, so a flat tie strip (6 mm) bolts F to it.
- **V-wheels, all on the fixed side.** M carries only S_M and its link pin.
  - 2 back wheels on a 3 mm plate on R_B's inner side, riding M's back groove. They hold M across and push it forward.
  - 2 far wheels on axles between a front cage plate (on R_F) and a back cage plate (on R_B), riding M's far groove. They hold M front to back and push it toward F.
  - Both pairs use eccentric spacers for preload. The sieve edges in the near slots only need clearance now.
- **Mixed option (`FRONT_GUARD = "keeper"`, the default now):**
  - The front guard is a clear 3 mm acrylic K_F (48 × 150) on F's front face. It's held in a 6 mm wood frame with a window over the column; the frame is also the far-wheel cage's front plate.
  - The back keeps the 2040 rail and the back wheels. The axle span drops to 67.6.
  - The back is the side that has to stay a rail: the back wheels ride M's back groove and the cage needs R_B. A back keeper on M would cover that groove.
  - The 10 W blue diode won't cut clear acrylic, so score and snap the rectangle and drill the M5 holes. A clear keeper needs no view slots.
- **Open:**
  - the axle span is 84.6 (M5x90, or 8 mm rod);
  - the back-wheel eccentric gap is only 1.9;
  - R_F hides the column from straight in front.

### Rocking drive

- The whole rig hangs from a pivot at the top and rocks.
- An off-centre cam (r = 10) drives a slot in a front arm.
- M hangs from a fixed link (100 mm), so rocking produces the lift.
- **Design numbers** (from `lift_demo.scad`):
  - stroke 34 = 30 pitch + 2 × 2 drop
  - tilt ±12° (forward / back), **symmetric** so the rig swings smoothly (2026-11-07; was +6° / −18°).
    The stroke depends only on sin(fwd) + sin(back): ±11.93° gives the old 0.4135, ±12° is used.
  - `arm_trim` 0.98805 (stroke 34.0002); cam axle level with the pivot
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

## 5b. MDF stock change (2026-11-04)

The new supplier's MDF measures **2.82** (better quality). The `mdf3` profile is now 2.82; the old 3.1 stock is `mdf3old`, which keeps its verified fit.
- Kerf 0.10 / slot = thickness are carried over, **not yet verified on the new batch**. Cut a tab-fit coupon first.
- The cut recipe (F500 x2) is carried over too; the thinner stock may sever in 1 pass.
- The feeder's GAP (3 spacer layers) is now 8.46 instead of 9.3. CHECK is clean. The front-keeper → back-keeper bolt is now 30.08 long.
- Every mdf3 file was regenerated at 2.82. The 3.1-mm versions are in `marbles/gcode/_old_mdf31/` (local only). Parts already cut from the old stock won't mate with new-stock slots.

## 5c. Feeder back keeper trimmed (2026-11-05)

On the first feeder the back keeper rubbed and bound on the keeper on the other beam (M), so Alex cut about 20 mm off its long inner edge. Nothing needed that strip; it only looked necessary because the other beam and its keeper weren't being considered.
- `feeder.scad`: `BK_X0` 6 → 26. The back keeper is now 75 wide (was 95): `feeder_back_keeper_141x76_mdf3.gcode`.
- CHECK is clean: 7.5 of wood from the beam bolt holes to the new edge, and the back-gap spacers still sit fully on wood. One of the three view slots dropped off with the strip.
- **Lesson:** model the other beam's keeper (K_M) in the feeder assembly, so that clearance is checked instead of discovered on the machine.
- **Z axis (same day):** Z only moved down, and Z homing drove down toward the bed. `$3=5` and `$23=3` were correct. Swapping the X and Z motors ran smoothly both ways, so no part was dead on its own. Alex is replacing the controller board. Z isn't needed for laser cutting.

## 6. Tasks

**The live roadmap is now `ROADMAP.md`** (P/T/C items with status and open questions, 2026-11-05). The L/M lists below are history.


### Pendulum lift (now)

- [x] **L1** Wheel-box concept: keeper is the near wall, plus far cheek + top/bottom + back, open toward the beam.
- [x] **L2 (MDF)** Kerf 0.10 confirmed by the perfect tab fit. Plywood: re-confirm 0.10 when we switch.
- [x] **L3 (MDF)** Tab fit is perfect at T = 3.1, kerf 0.10, FIT 0.
- [x] **L3b (plywood)** (marked done with L1–L4, 2026-11-04) Tab-fit coupon in 2.6 plywood; add a `fit:` block to its profile.
- [x] **L4** Check that the far faces of F and M are V-slot (wheels don't seat in T-slot). Swap beams if needed.
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
- [ ] **L11** Re-size cam_arm, cam_disc, m_link and link_anchor (`lift_parts.py`) to the real geometry. Re-check stroke 34, tilt ±12 and the link solve.
- [ ] **L12** Cut and fit the cam/link parts. Hand-crank test: every ball steps up one hole per turn, with no jams or double-feeds.
- [ ] **L13** Tune the hand-off drop (2 mm each way), the swing amplitude (keep it symmetric), and the forward/back roll timing.
- [x] **2026-11-04:** The lift works by hand with one wheel box per side, the top pivot on pillow blocks, and M hung by a chain + turnbuckle.
- [ ] **L10a** Chain length and swing: measure d, h, L, e and the swing (one symmetric amplitude); use the tuner page (https://claude.ai/artifact/4cPu2Bs5Xj2CbjY5Lb4qQ5).
  - Stroke ≈ d × 2 sin(tilt) for a symmetric swing; target = pitch + 2 × drop.
  - The chain and turnbuckle only place the stroke (registration).
- [x] **L14a** Spider-tunnel to feeder-port adapter: `tunnel_flange` in `feeder.scad` → `feeder_tunnel_flange_54x54_mdf3.gcode` (2026-11-04).
  - Same outline and 8 bolt holes as the trough cap. Bolts on the port in place of the trough.
  - A 20 bore with a notch per straight wire, so the wires pass through into the port and can't rotate. The tunnel's last ring bears on the flange.
  - CHECKs: wires reach 8.82 of the port's 10 half-width; 5.3 of wood from the notches to the bolt holes; rings clear beam F by 13.9.
  - View it with `-D port_fit="tunnel"`. A ring-pocket collar layer was dropped: only 3.25 of wood to the bolts, and not needed.
- [ ] **L14b** Pendulum pickup: wire fishhook grabber + hopper wire track with sloped triangle ends. See `PICKUP_LOG.md` §1 (the user's concept, 2026-11-04).
- [ ] **L14** Bottom pickup: how balls enter the first hole (feed chute or ramp from the clock's return).
  - **Your design (2026-11-04):**
    - The bottom hopper feeds a short fixed chute ending in a wire catch. The catch holds exactly one ball in a known spot, with the rest queued behind it by gravity.
    - The swinging rig carries a wire hook that snags that one ball as it passes and drops it into a short chute on the rig.
    - That chute queues a few balls for the bottom sieve hole.
  - **Feed funnel FF (from your sketch, cut file made 2026-11-04):** `marbles/clock/feed_funnel.py` → `feed_funnel.gcode`, 92 × 140.
    - It sits in the sieve's plane under S_F. Its 4 ball holes continue S_F's 30 pitch.
    - A J channel, 21 wide, runs from the top of the outer column down into the bottom hole.
    - A 20 mm bottom band carries 3 × M5 into a short 2020. Beam M5 holes sit where they clear the channel.
    - Still to design: the lever-finger catch at the channel mouth and the crossover funnel. Your sketch asks whether the same part could also work at the top.
    - The channel only steers the ball within the plate's plane. Like the sieve column, it needs a guard on each face within about a ball radius (9.5) of the plate, or the ball tips off the 3.1 mm edge.
  - **Feed keeper FK ×2** (`feed_keeper.gcode`): same 92 × 140 outline and M5 holes as the funnel (beam holes at x 36, y 80/110; band holes at y 10, x 16/46/76), no ball holes or channel. One goes on each face of the funnel to keep the balls in its plane.
  - **Feeder lessons (2026-11-04, from you):**
    - A keeper bolted on the beam's far face sits 20 mm from the funnel, too far: balls slip off the channel. At least one keeper must sit in the beam's side slots instead, about 8.4 mm off the funnel's face.
    - **The neck where the feeder joins the sieve must be ≥ 10 mm, preferably more.** The current funnel's is 6 mm: the strip left of the bottom hole, set by the sieve's 46 width and the 30 mm hole line.
  - **Render of Claude's understanding:** `marbles/views/views_feedrig.py` (views 5a–5d).
    - F ends above the channel.
    - Front keeper in F's side-slot plane (s 8.4..11.5).
    - Back keeper on 8.4 spacers.
    - Short 2020 behind the band.
  - **Side-entry feeder box (v2, `feeder_box.py` → `feeder_box.gcode`, 2026-11-04):**
    - Funnel with a closed channel top (19.50 bridge over the pocket, so the neck problem is gone).
    - Front keeper in F's side-slot plane carries the **port**; back keeper; outer wall + top wall tabbed through both keepers.
    - Keepers 20 apart inside, funnel centred, 8.45 off each.
    - **Port = standard interface:** 20 × 20 opening, a 10 mm tab slot at each side where a 20-inside duct's walls land, 4 × M5 at ±17.
    - The back keeper has the same pattern without the opening.
    - Use the same port for the catch / side loader and for the top exit.
    - **Revised (your call):** the 3 bottom-band M5 holes for a short 2020 are gone. A bottom wall (BW), tabbed through both keepers, now closes the box under the outer part; the funnel's bottom edge tabs into it.
    - One G-code per part, longest side on X, named with the bbox rounded up: `feeder_<part>_<W>x<H>.gcode`.
    - **Revised again (your call): spacer walls instead of through-walls.**
      - Each gap (funnel ↔ front keeper, funnel ↔ back keeper) gets its own 8.45-deep walls: outer, top and bottom. They are tabbed into the funnel and into that keeper, so the keeper slots match the funnel's.
      - Front and back walls share lines through the funnel, so load goes straight through to the funnel and its M5 bolts into F.
      - Their tabs alternate on a shared 10 mm grid, so no funnel slot takes tabs from both sides.
      - The funnel no longer tabs into anything.
      - **Fixed (2026-11-04):**
        - The port M5 holes now go through all three plates. The outer walls run the full height right beside the port's outer bolts.
        - An inner back wall sits beside the two beam bolts, so they clamp onto wood instead of an empty gap.
        - To make it all fit: the funnel and keepers are 4 mm wider (96), the port moved to (68, 108) with M5 at ±18, and the channel runs straight down from the pocket before it curves.
        - Every wall has at least one tab; the thinnest wood is 4.0.
  - **Feeder assembly, now one editable OpenSCAD file (2026-11-04): `marbles/clock/feeder.scad`.**
    - Parameters at the top; walls and their tab positions are an editable list.
    - The beam bolts' heads sit on the funnel's back face, and the back keeper has access holes over them. No spacer is needed on those bolts.
    - The console prints a CHECK report: each wall's clearance from the channel, ball holes, bolts, bolt heads and F, plus the wood around every tab slot. WARN lines need fixing.
    - G-code: `python3 marbles/clock/feeder_scad_gcode.py`. It refuses to write if CHECK has WARN lines; thickness, kerf and fit come from the material profile.
    - This supersedes `feeder_box.py`.
    - **Revised (your call): no side walls.** Spacers on M5 through-bolts hold the three layers apart.
      - The bolts pass through all three: the 4 port bolts plus 4 more, listed in `EXTRA_BOLTS`.
      - Gap = 3 × T = 9.3, so laser-cut 10 mm ring spacers stack 3 per gap (48 for 8 bolts); or use bought standoffs of length `GAP`.
      - The port moved to x 70 so the inner port bolts' spacers clear F.
      - **Beam bolts (your call):** no oversized access holes. The 2 beam bolts go through the back keeper, a spacer stack in the back gap and the funnel into F, so both plates bolt to the beam together. That makes 54 ring spacers.
      - **Spacer room (your call):** 13 mm kept clear around every spacer, so your ~10 mm plastic spacers and 1/2" ones both fit. To make room: the port moved to x 73 with bolts at ±19, and the plates are 99 wide.
  - **Trough (2026-11-04):** open top, 20 inside; 25 outside the front keeper including the cap, so bolts from the cap to the front keeper stay short.
    - The cap is 53 square with all 8 port-bolt holes: 4 corners plus 4 mid-sides at ±20 from the port centre.
    - The front keeper also has the mid-side holes, except the bottom one: its nut would sit over the ball channel.
    - Bolt lengths, plates + spacers + nut:
      - front keeper → back keeper: 32.6
      - cap → front keeper: 32.8
      - cap → back keeper: 57.6
  - **Short plain keeper SK:** 150 × 40 (`short_keeper.gcode`).
    - M5 every 3/4" (19.05) on the row 10 mm from one edge.
    - The standard 60 mm spacing on the row 10 mm from the other edge.
  - **Short pieces (`short_parts.py`, 2026-11-04):** sieves and keepers 3 / 4 / 5 holes long (90 / 120 / 150).
    - Sieve: M5 in the first and last gap.
    - Keeper: 40 wide, 3/4" M5 row at y 10, plus the sieve's M5 positions at y 30.
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

### Wire tube track (2026-11-04)

- [ ] **W1** Ring jig + spacing spiders (`marbles/clock/ring_jig.py` → `ring_jig.gcode`).
  - Ring ID = bore 20 + 2 × wire (2.05) = 24.10, OD 28.20; wire cut length π × 26.15 = 82.15.
  - Jig: base + top + core, with a groove one wire wide and a 15 mm iron hole on the joint.
  - Spiders: notches for the straight wires at 45/135/225/315°, M5 centre, 15° tick marks.
  - The etch recipe for MDF is borrowed from birch3 and is **unverified on MDF**.
- [ ] **W2** Make a test length of tube track; check the 3/4" ball rolls through straight, curved and twisted runs without pinching.
- [ ] **W3** Pick the straight-wire count and angles; re-run with `--angles`.
- [ ] **W4** Standard connectors / end fittings so tube sections plug into features modularly.

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
