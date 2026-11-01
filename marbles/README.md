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
- **Hook-in ribs** (`hy_part="rib"`): a bumpy D, flat back on the steel, no
  back plate. A tab on the back goes into a pegboard hole, locked by a wire
  **omega** (feet flared behind the steel, legs either side of the tab,
  bridge in a J slot above the tab). The legs pull toward the hole center,
  so the J's stem rises going in (stretching the omega) and hooks back down
  toward the tab; the bridge snaps into the tip. Lacing positions are holes
  between the marble and the board, grooves on the outer curve, plus one
  open channel above 3 o'clock for slipping wire in sideways. 10 tab
  heights 2.54 mm apart. Omega wire about 1.6 mm max (16 ga steel).
- **Demo sheet** (`hy_part="sheet"` + `"sheet_etch"`, 300 x 295): 30 ribs =
  three cycles of the 10 tab heights, each cycle an experiment group
  (A/B/C: J lip 0.5/0.8/1.1 mm, groove depth 0.35/0.5/0.65 mm); the
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

```bash
openscad -o hybrid.png marbles/hybrid.scad                                 # echoes the checks
openscad -o mod0.svg -D 'hy_part="module"' -D 'hy_mod=0' marbles/hybrid.scad   # one module's parts
openscad -o jigs.svg -D 'hy_part="jigs"' marbles/hybrid.scad               # staple jig + C forms
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
