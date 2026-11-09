#!/usr/bin/env python3
"""Pendulum drive parts: the MARBLE SWITCH rail that rides on the pendulum, and a LIMIT-SWITCH holder for the
door-lock actuator's rail.

MARBLE SWITCH (all layers stand in the swing plane, stacked across it; the outer wall bolts flat to the spine's
side face, into its slot):
  wall | rail rail | low spacer x3 | rail rail | wall
  - the ball (BALL, default a 3/4" steel ball) rides on the inner top edges of the two rail pairs, 8.46 apart
    (3 spacer layers); the walls clear it by 0.35 each side; M5 rods across the walls above the ball close the top
  - rail edge profile z(s): flat by default, CURVE_R > 0 = concave (ball prefers the middle), < 0 = convex (a hump:
    the ball snaps to whichever end is low, a bistable toggle); the ends turn up into soft stops
  - contacts: copper foil tape over the rails' top edges. Side A: the whole length (the +5 V common). Side B: only the
    two END ZONES (ZONE mm from each stop, marked by the small 1.5 mm holes in the B rails). The ball bridges A to a
    B zone: end 1 -> RPWM line, end 2 -> LPWM line (each through its NC limit switch; 1k pull-downs on the IBT-2).
  - clamp: 4 M5 through every layer below the rails (spacer rings not needed: the layers are solid there)

LIMIT HOLDER (lies on the actuator's 2020): ONE switch per holder, cut 2; the second is turned face down so the inner
ends face each other (they can butt). Each slides on the rail (2 M5 into T-nuts) to set the stroke, and has two seats:
0 deg (lever across the rail) and 90 deg (lever along it, head-on to the flag; turn the switch over for -90), each
slotted for a fine trip adjustment. WIP: untested. Switch: the
uxcell mini roller lever (19.9 x 10.7 x 6.4, two 2.4 holes 9.5 apart, M2; roller over the body's end). FLAG: bolts to the actuator rod's eye, rides
between the rollers and ramps onto one at each end of the stroke.

    python3 marbles/clock/pendulum_switch.py                 # mdf3: switch rail layers + limit holder + flag, and a drawing
    python3 marbles/clock/pendulum_switch.py --material ply3 --curve -400
"""
import argparse
import math
import sys
from pathlib import Path

from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import gcode  # noqa: E402

BALL = 19.05
HALF_L = 75.0          # rail runs s = -HALF_L .. HALF_L
ZONE = 18.0            # contact zone length from each end stop
STOP_R = 14.0          # end stops: the edge turns up on this radius ...
STOP_H = 12.0          # ... to this height
M5, MARK = 5.0, 1.5
SPINE_BOLTS_Z = (-28.0, -48.0)   # mount holes (s = 0) into the spine's side slot, below the rail edge

# uxcell mini roller-lever switch (G605 / KW12 size), from the seller's drawing. x along the body from its end
# AWAY from the roller, y up from the body's base (the terminal edge). Two M2 holes, roller at the far end.
SW_L, SW_H, SW_T = 19.9, 10.7, 6.4      # body length, height (base to top), thickness
SW_HOLE_X = (5.2, 14.7)                 # screw holes (9.5 apart, centred on the body)
SW_HOLE_Y = 2.5                         # hole centres above the base
SW_HOLE = 2.4                           # M2 clearance (the switch's own holes are 2.4)
PIN = 3.5                               # terminals stick out below the base
ROLL_X = 5.2 + 14.5                     # roller centre: 14.5 from the first hole = over the body's far end
ROLL_Y, ROLL_D = 15.4, 4.8              # roller centre height when free + diameter: SCALED OFF THE DRAWING (no dims)
SW_ADJ = 4.0                            # screw slot length: trip point +-2
STROKE = 20.0                           # actuator stroke (IGDLA-4: assumed ~20; measure)
ADJ = 6.0                               # plate M5 slot length
FLAG_FLAT = 24.0                        # flag's flat (roller-pressing) edge length
PRESS = 1.5                             # how far the flag pushes a roller in (flag's M4 slot sets it)


def profile(curve_r):
    """rail top edge z(s) as a point list, from s = -HALF_L to HALF_L (end stops included)"""
    pts = []
    n = 300
    flat_end = HALF_L - STOP_R
    for i in range(n + 1):
        s = -HALF_L + 2 * HALF_L * i / n
        z = 0.0 if not curve_r else s * s / (2 * curve_r)
        d = abs(s) - flat_end
        if d > 0:                                        # quarter-circle upturn into the stop
            z += STOP_R - math.sqrt(max(STOP_R ** 2 - d * d, 0.0))
        pts.append((s, z))
    z_end = pts[-1][1]
    return pts, z_end


def rail_layer(curve_r, kind):
    """2D (s, z) outline of one layer. kind: wall_mount | wall | rail_a | rail_b | spacer"""
    edge, z_end = profile(curve_r)
    bottom = -20.0
    ball_c = math.sqrt((BALL / 2) ** 2 - (3 * 2.82 / 2) ** 2)          # ball centre above the edge (8.46 gap)
    top_rod_z = ball_c + BALL / 2 + 1 + M5 / 2
    if kind in ("rail_a", "rail_b"):
        g = Polygon([(-HALF_L, bottom)] + edge + [(HALF_L, bottom)])
    elif kind == "spacer":                               # 4 below the edge: never touches the ball
        g = Polygon([(-HALF_L, bottom)] + [(s, z - 4) for s, z in edge] + [(HALF_L, bottom)])
    else:                                                # walls: up past the top rods
        top = top_rod_z + M5 / 2 + 4
        g = box(-HALF_L, bottom, HALF_L, top)
        if kind == "wall_mount":                         # reaches down over the spine's side face
            g = g.union(box(-14, SPINE_BOLTS_Z[1] - 10, 14, bottom + 1))
        g = g.buffer(-2, join_style=2).buffer(2, 16)
    holes = [Point(s, -12).buffer(M5 / 2, 32) for s in (-HALF_L + 12, -30, 30, HALF_L - 12)]      # clamp bolts
    if kind.startswith("wall"):
        holes += [Point(s, top_rod_z).buffer(M5 / 2, 32) for s in (-HALF_L + 8, -25, 25, HALF_L - 8)]  # top rods
    if kind == "wall_mount":
        holes += [Point(0, z).buffer(M5 / 2, 32) for z in SPINE_BOLTS_Z]
    if kind == "rail_b":                                 # zone marks: where the B foil stops
        for s in (-(HALF_L - ZONE), HALF_L - ZONE):
            holes.append(Point(s, -3).buffer(MARK / 2, 16))
    return g.difference(unary_union(holes))


def roller_x():
    """roller centres at +-this: the flag's flat edge end reaches the roller centre at the end of the stroke"""
    return FLAG_FLAT / 2 + STROKE / 2


HOLD_M5 = (-28.0, -46.0)   # the holder's two M5 into the 2020 (T-nuts slide in the slot: the holder slides on the rail)
B_Y0 = 3.0                 # 90 deg seat: the switch body spans y B_Y0 .. B_Y0 + SW_L


def seats():
    """switch screw-hole centres per orientation, in holder coordinates (x along the rail, x = 0 the INNER end that
    faces the other holder; y across, y = 0 the edge the 0 deg switch's terminals hang over, the 2020 under y 0..20).
      0 deg: base on y = 0, lever toward +y, body x -SW_L..0 so its roller (if the switch lies roller-inward) is
             flush with the inner end. Turn the switch over and the roller sits at the outer end instead.
      90 deg: lever toward +x (the roller meets the flag head-on), base at x = -(roller top), body across the rail.
             Turn the switch over for -90 (the roller moves to the other side of the rail): the holes are symmetric."""
    roll_top = ROLL_Y + ROLL_D / 2
    s0 = [(-SW_L + hx, SW_HOLE_Y) for hx in SW_HOLE_X]
    s90 = [(-roll_top + SW_HOLE_Y, B_Y0 + hx) for hx in SW_HOLE_X]
    return s0, s90, roll_top


def limit_holder():
    """ONE switch per holder; cut 2 and turn one over (face down) so the two inner ends face each other and can butt.
    Each switch seat is slotted along x (trip point +-SW_ADJ/2); two M5 holes on the rail centreline."""
    s0, s90, roll_top = seats()
    x0 = HOLD_M5[1] - 7
    y1 = B_Y0 + SW_L + 1.5
    g = box(x0, -3, 0, y1).buffer(-3, join_style=2).buffer(3, 16)        # -3: wood under the 0 deg screw holes
    cuts = [LineString([(x - SW_ADJ / 2, y), (x + SW_ADJ / 2, y)]).buffer(SW_HOLE / 2, 24) for x, y in s0 + s90]
    cuts += [Point(mx, 10).buffer(M5 / 2, 32) for mx in HOLD_M5]
    return g.difference(unary_union(cuts)), -x0, y1 + 3


def flag():
    """trip flag, lying flat at the rollers' height: a bar whose -y edge presses the rollers (flat FLAG_FLAT long,
    30 deg ramps at the ends so the rollers climb on), and an arm to the rod eye with an M4 slot along y (sets PRESS)."""
    h = 8.0                                              # bar depth (y)
    ramp = (PRESS + 2) / math.tan(math.radians(30))
    bar = Polygon([(-FLAG_FLAT / 2, 0), (FLAG_FLAT / 2, 0), (FLAG_FLAT / 2 + ramp, PRESS + 2),
                   (FLAG_FLAT / 2 + ramp, h), (-FLAG_FLAT / 2 - ramp, h), (-FLAG_FLAT / 2 - ramp, PRESS + 2)])
    arm = box(-7, h - 1, 7, h + 24)
    g = bar.union(arm).buffer(-1, join_style=2).buffer(1, 16)
    slot = LineString([(0, h + 7), (0, h + 18)]).buffer(2.2, 24)
    return g.difference(slot)


def emit(name, g, mat, notes, out_dir, copies=1):
    T, kerf, _ = gcode.fit(mat)
    job = gcode.job(mat)
    gk = g.buffer(kerf / 2, join_style=2)
    x0, y0, x1, y1 = gk.bounds
    if x1 - x0 < y1 - y0:
        from shapely import affinity
        gk = affinity.rotate(gk, 90, origin=(0, 0))
        x0, y0, x1, y1 = gk.bounds
    cuts = [gcode.Polyline([(x - x0, y - y0) for x, y in r.coords], True) for r in gk.interiors]
    cuts.append(gcode.Polyline([(x - x0, y - y0) for x, y in gk.exterior.coords], True))
    cuts = gcode.order(cuts)
    stem = gcode.name(name, x1 - x0, y1 - y0, mat)
    lines = gcode.preamble(job, title=f"{stem} -- marbles/clock/pendulum_switch.py: cut {copies}",
                           notes=notes + [f"{mat}: T {T}, kerf {kerf}; X0 Y0 = bottom-left"])
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(out_dir / f"{stem}.gcode", lines)
    print(f"{p.name}: cut {copies}, {len(cuts)} cuts")
    return p


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--material", default="mdf3")
    ap.add_argument("--curve", type=float, default=0.0, help="rail curvature radius: 0 flat, >0 concave, <0 convex")
    ap.add_argument("--stroke", type=float, default=STROKE, help="actuator stroke, mm (measure yours)")
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    globals().update(STROKE=a.stroke)
    T = gcode.fit(a.material)[0]
    if abs(T - 2.82) > 0.3:
        print(f"note: layer counts assume ~2.82 sheet; {a.material} is {T}: check the ball clearances")
    tag = "flat" if not a.curve else (f"concave{abs(a.curve):g}" if a.curve > 0 else f"convex{abs(a.curve):g}")
    parts = [("pswitch_wall_mount", "wall_mount", 1), ("pswitch_wall", "wall", 1),
             ("pswitch_rail_a_" + tag, "rail_a", 2), ("pswitch_rail_b_" + tag, "rail_b", 2),
             ("pswitch_spacer_" + tag, "spacer", 3)]
    for name, kind, n in parts:
        emit(name, rail_layer(a.curve, kind), a.material,
             [f"marble switch layer '{kind}', rail profile {tag}; stack: wall_mount | rail_a x2 | spacer x3 | rail_b x2 | wall"],
             a.out, n)
    lh, L, W = limit_holder()
    emit("limit_holder_single", lh, a.material,
         ["ONE uxcell mini roller switch per holder: cut 2, turn one face down so the inner ends face each other",
          f"seats: 0 deg (lever across the rail) and 90 deg (lever along it; turn the switch over for -90); M2 slots +-{SW_ADJ / 2:g}",
          "two M5 on the rail centreline: slide along the 2020 to set the stroke"], a.out, 2)
    emit("limit_flag", flag(), a.material, [f"trip flag: flat {FLAG_FLAT:g}, 30 deg ramps; M4 slot to the rod eye"], a.out, 2)


if __name__ == "__main__":
    main()
