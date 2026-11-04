# Wire marble run

| File | What |
|---|---|
| `marbles.scad`, `marbles2.scad` | Earlier ring / 2020 guide experiments |
| `hybrid.scad` | **Current direction**: plywood back plates + ribs set every position, wire rails roll and wire staples hang it on the pegboard. No solder, no snap fits |
| `wire_bender.scad` | Manual wire straightener + bender on one 2020 beam: V-wheel straighteners, sliding-pivot bend head, stop disc, mandrels |
| `pegwall.scad` | **Modular run on steel pegboard**: hook-on plywood fins, straights, C-turns, wall lift, cut sheets |
| `wire_track.scad` | Rail cross-sections (open, guarded, enclosed tube), tie former, printed snap clips (experimental: the snap lips are necessarily thin) |
| `wire_jig.scad` | Laser-cut wooden solder jig: two-piece (open) or core + outer pieces (tube) stations, half-depth notches, rubber band, no snap |
| `poc_lap_jig.scad` | Wooden solder jig for one lap of the proof-of-concept run: ring base following the curve, every station cut to its height on the slope |
| `spiral_lift.scad` | Rotating-coil lift: winding mandrel, hubs, coupler, bushing, motor mount, top arm, channel clips, feet |
| `poc_layout.py` | Lays out the proof-of-concept run and writes `poc_path.scad` (generated) |
| `poc_run.scad` | Whole proof-of-concept: board, posts, laps, clips, lift; board cut/etch layers |
| `launcher_calc.py` | Feasibility numbers for a spring-launcher lift instead of the coil |

## Hybrid wall (`hybrid.scad`)

Laser-cut 3 mm plywood (every part fits 300 x 300) holds the positions; wire
does the rolling and the hanging.

- **Back plate** lies flat on the steel pegboard; its holes line up with the
  board's.
- **Staples**: wire U-hooks through the back plate into two pegboard holes.
  The top leg hooks up behind the steel, the bottom one stops tipping. Bend
  them on the staple jig (two pins set the 1" bridge, two slots set the leg
  lengths).
- **Supports** are plywood frames glued into the back plate on tabs, each
  with a window the marble rolls through. Every straight support is the same
  part: 16 notches evenly spaced on a ring (22.5 deg, bottom and top center
  left free) so extra wires can make guards, roofs and tunnels, plus a big
  lacing hole below bottom center for feeding wire through. The window is
  a bit bigger than the ring, so each notch is a shallow groove the wire
  drops into.
- **Hook rib** (`hrib_2d`, one size): a bumpy D, hung like a pegboard hook:
  a plywood hook (lip drops 1/4" behind the steel) in one hole and a
  straight peg in the hole 1" below, both through a 1" x 2" **backer plate**
  that sits flush on the steel and stops the rib swinging side to side.
  The backer's top edge stops just under the hook tongue (no closed slot
  for the hook), so nothing sits above the pivot when you tilt the rib to
  hook in. Two short rib tabs between hook and peg go into the backer only,
  and a horizontal **crossmember** (1" x 10 mm) half-laps with the rib
  (half-depth slot in the rib's back edge, matching notch in the
  crossmember's front edge) and tabs into the backer, square to both.
  The backer runs from just under the hook tongue to 4 mm below the peg
  slot. Glue rib,
  backer and crossmember into one piece, then tilt, hook, swing down.
  Lacing holes between the marble and the board,
  grooves on the outer curve, and a 45 deg opening from 3 o'clock up
  (three lacing positions wide) for winding wire in.
  (The older omega-clip rib and its 10 tab heights are still in the file
  but no longer cut.)
- **Hook and peg** are one constant-width stroke each, nearly the hole
  (6.35 - 0.3 mm), the hook bending up behind the steel. The rib has no
  material above the hook tongue: there it swung into the steel as the rib
  tilted in. `python3 marbles/hook_fit_check.py` simulates the tilt-in
  (rib + backer vs the steel, any tilt and slide) and says whether the
  hung position connects to off-the-board. Passes for steel up to 1.2 mm;
  measure yours and set `panel_t`.
- **Rail end loop**: the rail passes through the end rib in a notch,
  U-turns just past the far face, comes back through the neighboring
  lacing groove, and a last fold (in place, pliers) turns the very end up
  to touch the rail. `loop_guide` bends only the U: put the wire end in the
  stop slot, wrap the long leg 180 deg round the tongue. Its numbers are
  echoed as `end_loop` (wire from the U's start to the end, and from the
  rib's far face to the end). Glue 2-3 cut copies into a stack for a
  stiffer tongue.
- **Plywood spoke rails** (no wire): each rail is a flat strip in a plane
  through the marble path's center line, at a clock angle, so the marble
  rolls on its cut face. `rail_rib` (same hook, peg, backer, crossmember)
  has 8 radial slots, every 45 deg; each rail has slanted notches on its
  outer edge that meet them egg-crate style, so the rolling edge is
  unbroken. Ribs hang vertically and the track slopes, so notches and rib
  slots are computed for the slope (`rl_cols` columns per `rl_rows` inch
  of drop, default 4:1 = 14 deg). Default rails: -45 and +45 to roll on,
  +90 outside guard. Insert each rail from inside the window, outward into
  the slots. The notches lean, so a rail seats one way round (etched arrow
  downhill); if it won't, turn it over.
- **Demo sheet** (`hy_part="sheet"` + `"sheet_etch"`, 300 x 295): 30 ribs =
  three cycles of the 10 tab heights, each cycle an experiment group
  (A/B/C: arc opening 0.9/1.2/1.5 mm, groove depth 0.35/0.5/0.65 mm); the
  uppermost board-side hole steps through 5 sizes. Leftover strip on the
  right carries the omega form slot, omega length slot and wire
  straightness slot (cut into the scrap, no outline of their own).
- **Straight rails zig-zag**: each wire leaves a support on the 2nd notch
  out from bottom center, arrives at the next one on the 3rd, passes through
  the wide notch, runs across the far face to the narrow notch and sets off
  again. The marble sinks as the gauge opens, so level wire still rolls. A
  wire starts by poking through the first support (tail bent down) and ends
  by wrapping the last one and poking back through (tail bent down). The
  supports are the bending jig; one wire per side per module.
- **C-turn rails** are wrapped around a 3-layer plywood form, then threaded
  through framed ribs.

- **A la carte G-code** (`python3 marbles/laser_parts.py` writes
  `marbles/gcode/`, which is git-ignored): one file per part, etch first then
  cut, zeroed at the bottom-left corner of the part's cut outline. Parts:
  `hook_rib`, `hook_rib_test` (two lacing holes at test sizes, each
  engraved with its clearance), `backer`, `crossmember`, `loop_guide`, `rail_rib`, `rail_m45`, `rail_p45`, `rail_p90`, `straightness` (200 mm rail
  gauge slot for scrap, at least 1/2" from any edge). Recipes come from
  `cnc_vibes/material_profiles/laser_materials.yaml` (default
  `ply3`; `--material` to change). Kerf is the 0.1 mm
  guess in hybrid.scad.
- **One set from scrap** (`python3 marbles/laser_set.py`): rib, crossmember
  and backer in one row, `gcode/hook_rib_set.gcode`.
- **Kerf test** (`python3 marbles/kerf_test.py` writes
  `marbles/gcode/kerf_test.gcode`): one zig-zag cut makes 10 lines 5 mm
  apart, with the turnarounds outside the strip area, then a box cut 5 mm
  outside the outer lines frees 11 strips, each 5 mm minus one kerf. Stack
  10 and measure: kerf = (50 - stack) / 10. Put the result in `kerf` in
  hybrid.scad.

```bash
python3 marbles/laser_parts.py                                   # regenerate all G-code
openscad -o hybrid.png marbles/hybrid.scad                                 # echoes the checks
openscad -o mod0.svg -D 'hy_part="module"' -D 'hy_mod=0' marbles/hybrid.scad   # one module's parts
openscad -o jigs.svg -D 'hy_part="jigs"' marbles/hybrid.scad               # staple jig + C forms
```

## Ball clock (`clock/escapement.py`)

Wall clock idea: a seconds pendulum (994 mm) regulates everything, steel
balls (1/2") are the drive weight, a motor lift refills a hopper, and
rolling-ball counting rails show the time.

So far: a Graham deadbeat escapement, 30-tooth escape wheel (1 rev/min,
seconds hand on its arbor) with the anchor on the pendulum arbor BELOW it
(the escapement sits above the pendulum's fulcrum). `escapement.py` runs a
kinematic check (pendulum swings, wheel driven until something stops it)
at 3, 4 and 5 deg amplitude and fails if the wheel runs away, recoils or
doesn't advance half a tooth per swing; it also passed with parts 0.15 mm
over/undersize. Then it writes a TEST RIG: two plates with 608 bearings,
escape wheel, anchor, spacers, a string drum and a seconds hand
(`gcode/clock_*.gcode`, with the copies to cut in each header).

Drive is still open: balls in an 84 mm pocket wheel straight on the escape
arbor give about 10x the torque the pendulum needs, so the ball wheel will
turn slower and drive the escape wheel through a step-up train.

```bash
python3 marbles/clock/escapement.py           # check, cut files, preview (needs shapely)
python3 marbles/clock/escapement.py --check   # check only
```

## Pegboard wall (`pegwall.scad`)

Modular run for 1" grid steel pegboard: two 13 x 30 hole panels side by
side. Everything on the board hangs from laser-cut plywood **fins**: a plate
standing straight out from the board with a hook tongue + lip in one hole
and an anti-tip pin in the hole below. Push it in level, let it drop, and it
locks; lift and pull to remove. Each fin carries a two-piece rail station
(comb + banded keeper), so the fins hold the track on the wall and double as
the solder jig: solder ties between fins in place, or don't.

Modules meet at ports (marble center 1.5" off the board, x on a half column,
y on a 1/4" grid); each module starts 0.5 mm below the port it enters by.

- **straight**: open 2-rail, any length, drops in 1/4" steps
- **C-turn**: enclosed 4-rail half loop in the board's plane; drops one level
  and reverses. All C-turns are the same part (a left one is a right one
  turned around), built in one flat jig (`wall_part="cturn_jig"`).
- **lift**: wire-coil spiral lift standing in front of the board on
  half-lapped collars; its channel rails bend over into the top level.

The default layout is 10 switchback levels with the lift up the left side.
`pegwall.scad` checks that no two fins want the same hole and that the
C-turns keep the marble in.

```bash
openscad -o wall.png marbles/pegwall.scad                                    # echoes the checks
openscad -o hook_test.svg -D 'wall_part="hook_test"' marbles/pegwall.scad    # cut this first
openscad -o fins0.svg      -D 'wall_part="fins"' -D 'sheet=0' marbles/pegwall.scad   # sheets 0..N-1
openscad -o fins0_etch.svg -D 'wall_part="fins_etch"' -D 'sheet=0' marbles/pegwall.scad
openscad -o cjig_base.svg   -D 'wall_part="cturn_jig_base"'   marbles/pegwall.scad
openscad -o cjig_pieces.svg -D 'wall_part="cturn_jig_pieces"' marbles/pegwall.scad
```

Fin labels (etch layer) give the column and hook row, counted from the
bottom-left hole as c0 r0. Measure before cutting in bulk: `peg_hole_d`,
`peg_sheet_t`, plywood `sheet_th`, and `kerf` are guesses; the hook test
coupon has three tongue sizes to try in your panel.

## Proof-of-concept run

A spiral lift in the middle of a 300 mm board raises marbles to the top; the
track then spirals down counter-clockwise around the board in stacked
rounded-square laps clipped to 4 corner posts, and rolls back into the lift.

```bash
python3 marbles/poc_layout.py                      # prints laps, slope, clearance, wire, clip counts
openscad -o run.png marbles/poc_run.scad           # echoes clip counts too
openscad -o board_cut.svg  -D 'poc_part="board_cut"'  marbles/poc_run.scad
openscad -o board_etch.svg -D 'poc_part="board_etch"' marbles/poc_run.scad   # 1:1 bending template
openscad -o hub.stl -D 'lift_part="hub"' marbles/spiral_lift.scad            # etc, see file header
openscad -o clip.stl -D 'part="saddle"' -D 'style="rail3"' -D 'mount="side_post"' \
    -D 'tab_a=90' -D 'post_d=4' marbles/wire_track.scad                      # corner clip
```

Change height with `--z-exit` (and `z_exit` in `spiral_lift.scad`; `poc_run.scad`
asserts they match). Taller runs just add laps and coil turns.

Build order:
1. Cut a short straight `wire_jig.scad` set and print one mandrel segment
   first; check the rail fit and `kerf`, and tune `mandrel_k` (coil springback).
2. Board, feet, posts, bushing, motor mount, coupler, rod.
3. Wind the coil, fit both hubs, check it spins true; add lift post, channel
   clips, channel rails, top arm.
4. Bend a lap against the etched template, lay it in `poc_lap_jig.scad` (all
   laps share the plan), roll marbles on it with the keepers off, then band
   the keepers on and solder ties between stations.
5. Mount the laps on the posts. The printed clips in the assembly stand in
   for however you attach them (soldered tabs to brass posts, for example).

Measure before trusting: N20 motor dimensions, `mandrel_k`, laser `kerf`.
The board is exactly the laser's 300 mm Y travel; cut it slightly smaller or
in two pieces if the machine can't reach the edges.

## Wooden solder jig

Each station's pieces meet along lines through the rail centers, so each
rail sits in two half-depth notches and nothing has to flex. Put the comb (or
bottom piece) in the base board, lay the rails in, add the keeper (or core and
outer pieces), and band it. Solder ties midway between stations. Combs alone,
keepers off, are a test stand you can roll marbles on.

```bash
openscad -o jig.svg      -D 'jig_part="straight_laser"' -D 'style="open2"' marbles/wire_jig.scad
openscad -o jig_etch.svg -D 'jig_part="straight_etch"'  -D 'style="open2"' marbles/wire_jig.scad
openscad -o lap_base.svg   -D 'lap_part="base"'   marbles/poc_lap_jig.scad
openscad -o lap_pieces.svg -D 'lap_part="pieces"' marbles/poc_lap_jig.scad
```

## Launcher (alternative lift)

Steel balls can close a circuit across two rails in the launch lane. Those two
rails must be held only by plastic clips (no soldered ties, which would short
them). The ball contact can't reliably carry motor current: let it switch a
logic-level MOSFET gate (plus a pull-down resistor and a flyback diode). Run
`launcher_calc.py` to size the spring and cam for a given rise.
