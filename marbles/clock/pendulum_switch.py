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

LIMIT HOLDER (lies on the actuator's 2020): two microswitch seats, one each end of the stroke, each with slotted
screw holes (fine trip adjustment); the plate's M5 slots let it slide along the rail. Default switch (--switch kw12):
the uxcell mini roller lever, KW12-3 size (~20 x 10.5, two 2.5 holes 9.5 apart, M2); --switch kw11 for the KW11-3Z. FLAG: clamps to the actuator rod's eye, trips
the rollers.

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

# roller lever microswitches: body length, width (base to body top), screw hole, hole pitch, hole height above base,
# switch-screw slot length. kw12 = the uxcell "mini micro" pack (KW12-3 size, M2 screws; seller figures, measure);
# kw11 = the larger KW11-3Z (M3).
SWITCHES = {"kw12": (20.0, 10.5, 2.4, 9.5, 3.0, 4.0),
            "kw11": (27.8, 15.8, 3.1, 22.2, 5.1, 6.0)}
SW_KIND = "kw12"
SW_L, SW_W, SW_HOLE, SW_PITCH, SW_HOLE_Y, SW_ADJ = SWITCHES[SW_KIND]
STROKE = 20.0          # actuator stroke (IGDLA-4: assumed ~20; measure)
ADJ = 6.0              # slot length for adjustment (both the switch screws and the rail M5)


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


def limit_holder():
    global SW_L, SW_W, SW_HOLE, SW_PITCH, SW_HOLE_Y, SW_ADJ
    SW_L, SW_W, SW_HOLE, SW_PITCH, SW_HOLE_Y, SW_ADJ = SWITCHES[SW_KIND]
    """(x along the rail, y across): two switch seats STROKE + SW_L apart, slotted; M5 slots for the 2020"""
    m5_x = STROKE / 2 + SW_L + SW_ADJ + 5               # end M5 slots: clear of a switch slid fully outward
    length = 2 * (m5_x + 7)
    width = SW_W + 22
    g = box(-length / 2, -width / 2, length / 2, width / 2).buffer(-3, join_style=2).buffer(3, 16)
    cuts = []
    for sx in (-1, 1):
        # switch body sits with its lever toward +y (the rod side); screw slots along x
        cx = sx * (STROKE / 2 + SW_L / 2 + SW_ADJ / 2)
        y = -width / 2 + 4 + SW_HOLE_Y
        for hx in (cx - SW_PITCH / 2, cx + SW_PITCH / 2):
            cuts.append(LineString([(hx - SW_ADJ / 2, y), (hx + SW_ADJ / 2, y)]).buffer(SW_HOLE / 2, 24))
        # M5 slot into the 2020 (y = 0 is the slot line when the plate is centred on the extrusion)
    for mx in (-m5_x, m5_x):
        cuts.append(LineString([(mx, -ADJ / 2), (mx, ADJ / 2)]).buffer(M5 / 2, 32))
    cuts.append(LineString([(-ADJ, 0), (ADJ, 0)]).buffer(M5 / 2, 32))
    return g.difference(unary_union(cuts)), length, width


def flag():
    """trip flag: bolts through the actuator rod's eye (M4 clearance + a slot for reach), wide enough to hit both rollers"""
    g = box(0, 0, 40, 18).buffer(-2, join_style=2).buffer(2, 16)
    cuts = [LineString([(8, 9), (16, 9)]).buffer(2.2, 24)]
    return g.difference(unary_union(cuts))


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
    ap.add_argument("--switch", choices=sorted(SWITCHES), default=SW_KIND, help="limit switch: kw12 (uxcell mini) or kw11")
    ap.add_argument("--stroke", type=float, default=STROKE, help="actuator stroke, mm (measure yours)")
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    globals().update(SW_KIND=a.switch, STROKE=a.stroke)
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
    emit(f"limit_holder_{SW_KIND}_s{STROKE:g}", lh, a.material,
         [f"two {SW_KIND} roller-switch seats for a {STROKE:g} mm stroke, slotted +-{SW_ADJ / 2:g}; M5 slots to the 2020"], a.out)
    emit("limit_flag", flag(), a.material, ["trip flag: M4 through the actuator rod's eye"], a.out, 2)


if __name__ == "__main__":
    main()
