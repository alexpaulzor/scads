# Wire marble run

| File | What |
|---|---|
| `marbles.scad`, `marbles2.scad` | Earlier ring / 2020 guide experiments |
| `wire_track.scad` | Snap clips (open, guarded, enclosed tube), laser solder jig, tie former |
| `spiral_lift.scad` | Rotating-coil lift: winding mandrel, hubs, coupler, bushing, motor mount, top arm, channel clips, feet |
| `poc_layout.py` | Lays out the proof-of-concept run and writes `poc_path.scad` (generated) |
| `poc_run.scad` | Whole proof-of-concept: board, posts, laps, clips, lift; board cut/etch layers |
| `launcher_calc.py` | Feasibility numbers for a spring-launcher lift instead of the coil |

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
1. Print one clip and a short mandrel segment first; tune `grip_ratio`/`lip_clr`
   and `mandrel_k` (coil springback) before printing in bulk.
2. Board, feet, posts, bushing, motor mount, coupler, rod.
3. Wind the coil, fit both hubs, check it spins true; add lift post, channel
   clips, channel rails, top arm.
4. Bend laps against the etched template, clip them to the posts, tune slope
   by sliding clips on the posts.
5. Once it runs, solder ties and pull the clips.

Measure before trusting: N20 motor dimensions, `mandrel_k`, laser `kerf`.
The board is exactly the laser's 300 mm Y travel; cut it slightly smaller or
in two pieces if the machine can't reach the edges.

## Launcher (alternative lift)

Steel balls can close a circuit across two rails in the launch lane. Those two
rails must be held only by plastic clips (no soldered ties, which would short
them). The ball contact can't reliably carry motor current: let it switch a
logic-level MOSFET gate (plus a pull-down resistor and a flyback diode). Run
`launcher_calc.py` to size the spring and cam for a given rise.
