#!/usr/bin/env python3
"""MARBLE DRIVE (SHELVED 2026-11-13: replaced by escapement_ball.py, balls in the escape wheel's own pin gaps).
Originally: a separate ball wheel for the pin-wheel escapement + SECONDS HAND (preview, no G-code unless --gcode).

The pendulum is motor-driven, so the escape wheel only needs enough torque to step 6 deg per second and beat friction.
  - BALL WHEEL: one disc (2 x ply3, screwed) on its own fixed 8 mm axle beside the escape wheel, in the escape
    wheel's 20 mm gap plane. Its rim is a GEAR whose 30 teeth mesh the escape wheel's own 30 M3 pins (1:1, no extra
    parts on the escape wheel), so it turns once a minute, the other way. The tooth flanks are generated from the pin
    path (each tooth is the envelope of a pin), all addendum: action only after the line of centres.
  - BALL HOLES: 12 round holes (one per 5 s) a little bigger than a 3/4" ball. A queued ball at the top, pressing on
    the disc's front face, rolls into each hole as it arrives (self-metering: one ball per hole). Two fixed GUIDES
    clamped on the axle with M8 nuts (front and back, 10 from the disc's centre plane) keep the balls in their holes
    down the descending side; their weight turns the wheel. Near the bottom a 2-layer WEDGE on the back guide pushes
    each ball forward out of its hole onto your return track to the lift.
  - SECONDS HAND: bolted to the escape wheel's front ring on two spokes' M5 (stood off on nuts over the pin nuts),
    balanced by its tail. A fixed DIAL RING (60 ticks, etched numbers) sits behind the hand tip, outside the wheel.

Front view, x right, y up, origin = the anchor (pendulum) arbor, as in escapement_pin.py; z toward the viewer,
z = 0 the middle of the wheels' gap.

    python3 marbles/clock/marble_drive.py            # numbers + marble_drive.scad + views/marble_drive_*.png
    python3 marbles/clock/marble_drive.py --gcode    # also the ply3 cut files (marbles/gcode/)
"""
import argparse
import math
import subprocess
import sys
from pathlib import Path

import numpy as np
import shapely
from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
import escapement_pin as E  # noqa: E402

# --- ball wheel -------------------------------------------------------------------------------------------------
Z = 30                    # teeth: = the escape wheel's pins, so 1:1 (one turn a minute)
PLACE = 135.0             # where the ball wheel sits round the escape wheel (deg, from its centre): upper left, so
                          # its descending (left) side is outboard and it is far from the anchor's arms
RG = E.R * Z / E.N        # pitch radius
C = E.R + RG              # centre distance
R_TIP = 108.0             # tooth tips: about 16 deg of action per tooth for a 12 deg pitch (contact ratio ~1.35)
CLEAR = 0.35              # pin envelope grown by this (backlash)
PLY = 2.63
DISC_LAYERS = 2
DISC_T = DISC_LAYERS * PLY
BALL_D = 19.05            # 3/4" chrome steel
BALL_M = 4 / 3 * math.pi * (BALL_D / 20) ** 3 * 7.83 / 1000      # kg (7.83 g/cm3)
K = 12                    # ball holes: one ball every 60 / K s
R_B = 75.0                # hole centre radius: the balls (to R_B + 9.5) stay outside the escape rings' reach
HOLE_D = 20.0             # ball hole
GUIDE_Z = 10.0            # guides' inner faces from the disc's centre plane (ball half-width 9.525)
FEED = 5.0                # ball enters its hole this far past the top (deg, in the turning direction)
OUT = 165.0               # ... and is out by here (the wedge runs 150..175)
BRG_D = 22.0              # 608 seat
CAP_IN = 15.0             # bearing caps: retain the outer race, clear the inner race / nuts
TIE_R = 114.0             # guide tie bolts (M5 + 20 mm of spacers) outside the teeth
G = 9.81

# --- seconds hand + dial ----------------------------------------------------------------------------------------
HAND_TIP = 123.0
HAND_TAIL = 52.0
HAND_Z = E.GAP / 2 + PLY + 8.0          # hand underside: front ring face + two M5 nuts (over the M3 pin ends)
DIAL_IN, DIAL_OUT = 114.0, 144.0
DIAL_Z = E.GAP / 2 + PLY + 1.0          # dial underside: just in front of the ring plane (outside the wheel)
TICK = (116.0, 121.0, 125.0)            # tick from, 1 s tick to, 5 s tick to
NUM_R, NUM_H = 131.0, 7.0
DIAL_SLOTS = (15.0, 45.0, 75.0)         # M5 slots for your frame, between the numbers: the upper right is the only
                                         # side where a post from behind misses both the ball wheel and the anchor arms
SLOT_R = 139.5

W = E.W                                  # escape wheel centre (anchor frame)
BC = E.polar(C, PLACE, W)                # ball wheel centre


def pin_centres(e):
    """escape pins (anchor frame) with the wheel turned clockwise by e deg"""
    return [E.polar(E.R, 90 - k * E.PITCH - e, W) for k in range(E.N)]


def gear_local():
    """the ball disc's toothed outline in its own frame (centre at the origin, at ball angle 0 <-> escape angle 0):
    the tip circle minus every position of every pin (grown by CLEAR) as the two turn together"""
    cut, a = [], -180.0
    while a < 180.0:
        e = a * Z / E.N
        for p in pin_centres(e):
            q = (p[0] - BC[0], p[1] - BC[1])
            c, s = math.cos(math.radians(-a)), math.sin(math.radians(-a))
            q = (q[0] * c - q[1] * s, q[0] * s + q[1] * c)
            if math.hypot(*q) < R_TIP + 3:
                cut.append(Point(q).buffer(E.PR + CLEAR, 16))
        a += 0.25
    g = Point(0, 0).buffer(R_TIP, 256).difference(unary_union(cut))
    return max(getattr(g, "geoms", [g]), key=lambda q: q.area)


def hole_angles(a):
    """ball hole angles measured from the top in the ball wheel's turning direction (counter-clockwise)"""
    return [(j * 360.0 / K + a) % 360.0 for j in range(K)]


def disc_layer(gear):
    holes = [Point(0, R_B).buffer(HOLE_D / 2, 64)]
    holes = [affinity.rotate(holes[0], j * 360 / K, origin=(0, 0)) for j in range(K)]
    holes.append(Point(0, 0).buffer(BRG_D / 2, 64))
    holes += cap_screws() + layer_screws()
    return gear.difference(unary_union(holes))


def cap_screws():
    return [Point(E.polar(15.5, 90 + 120 * i)).buffer(1.65, 24) for i in range(3)]


def layer_screws():
    """M3 holding the 2 disc layers together, between the ball holes, inside them"""
    return [Point(E.polar(R_B - 22, 90 + 360 / K * (j + 0.5))).buffer(1.65, 24) for j in range(0, K, 2)]


def bearing_cap():
    return Point(0, 0).buffer(20.5, 64).difference(unary_union([Point(0, 0).buffer(CAP_IN / 2, 48)] + cap_screws()))


def arc_band(r0, r1, a0, a1):
    """band between radii r0..r1 from angle a0 to a1 (deg from the top, counter-clockwise)"""
    pts = [E.polar(r1, 90 + a0 + (a1 - a0) * i / 60) for i in range(61)]
    pts += [E.polar(r0, 90 + a1 - (a1 - a0) * i / 60) for i in range(61)]
    return Polygon(pts)


def guide(front):
    """fixed guide plate (ball frame, unrotated: the wheel's top is +y). Back guide: the stop at the feed point
    and the base of the exit wedge; front guide: starts after the feed, ends before the wedge"""
    a0, a1 = (25.0, 150.0) if front else (-25.0, 178.0)
    band = arc_band(R_B - 11, R_B + 11, a0, a1)
    hub = Point(0, 0).buffer(16, 48)
    arm = LineString([(0, 0), E.polar(R_B, 90 + 90)]).buffer(9, cap_style=2)
    ties = [E.polar(TIE_R, 90 + a) for a in (60.0, 125.0)]
    lugs = [LineString([E.polar(R_B, 90 + a), p]).buffer(7, cap_style=1) for a, p in zip((60.0, 125.0), ties)]
    tab = LineString([E.polar(R_B, 90 + 95), E.polar(TIE_R + 4, 90 + 95)]).buffer(8, cap_style=1)
    g = unary_union([band, hub, arm, tab] + lugs).buffer(3).buffer(-3)
    holes = [Point(0, 0).buffer(4.15, 32)] + [Point(p).buffer(2.65, 24) for p in ties]
    holes.append(Point(E.polar(TIE_R + 2, 90 + 95)).buffer(2.65, 24))      # frame link (stops it turning on the axle)
    return g.difference(unary_union(holes)), ties


def wedge(step):
    """exit wedge layers on the back guide's inner face: step 1 from 150, step 2 from 160 (each 2.63 nearer the disc)"""
    a0 = 150.0 if step == 1 else 160.0
    g = arc_band(R_B - 11, R_B + 11, a0, 178.0)
    return g.difference(unary_union([Point(E.polar(R_B + 7.5, 90 + a)).buffer(1.65, 24) for a in (169.0, 175.0)] +
                                    [Point(E.polar(R_B - 7.5, 90 + a)).buffer(1.65, 24) for a in (169.0, 175.0)]))


def hand():
    """seconds hand (escape-wheel frame, centre at the origin, pointing up = +y): bolted through two spokes' M5
    (one up, one down) into the T-nuts; tail disc sized to put the centre of mass on the axle"""
    m5 = E.spoke_m5()
    body = Polygon([(-9, -m5[-1] - 8), (9, -m5[-1] - 8), (9, m5[-1] + 8), (2, HAND_TIP), (-2, HAND_TIP)])
    hub = Point(0, 0).buffer(16, 48)
    lo, hi, tail = 4.0, 30.0, None
    for _ in range(40):                     # bisect the tail disc radius so the centroid sits on the axle
        r = (lo + hi) / 2
        tail = unary_union([body, hub, LineString([(0, 0), (0, -HAND_TAIL)]).buffer(7, cap_style=2),
                            Point(0, -HAND_TAIL).buffer(r, 48)])
        if tail.centroid.y > 0:
            lo = r
        else:
            hi = r
    holes = [Point(0, 0).buffer(8.0, 48)] + [Point(0, s * r_).buffer(2.65, 24) for s in (1, -1) for r_ in m5]
    return tail.difference(unary_union(holes)), r


def dial():
    """the fixed dial ring (escape-wheel frame): cut outline + etched ticks/numbers as polylines"""
    ring = Point(0, 0).buffer(DIAL_OUT, 256).difference(Point(0, 0).buffer(DIAL_IN, 256))
    slots = [LineString(E.arc(SLOT_R, a - 4, a + 4)).buffer(2.65, cap_style=1)
             for a in DIAL_SLOTS]      # +-4 deg: turn the dial to line the ticks up with the hand
    g = ring.difference(unary_union(slots))
    ticks = []
    for s in range(60):
        a = 90 - 6 * s
        ticks.append([E.polar(TICK[0], a), E.polar(TICK[2] if s % 5 == 0 else TICK[1], a)])
    nums = [(f"{s}", *E.polar(NUM_R, 90 - 6 * s)) for s in range(0, 60, 5)]
    return g, ticks, nums


def to_anchor(g, ang=0.0):
    """ball frame -> anchor frame, the ball wheel turned counter-clockwise by ang"""
    return affinity.translate(affinity.rotate(g, ang, origin=(0, 0)), *BC)


def torque(a):
    """ball wheel torque (N m) at ball angle a: every loaded ball weighs on the descending (left) side"""
    t = 0.0
    for th in hole_angles(a):
        if FEED <= th <= OUT:
            t += BALL_M * G * (R_B / 1000) * math.sin(math.radians(th))
    return t


def mesh_check(gear):
    """push the escape wheel with the ball wheel over 2 pitches: (min, max) lag in deg; constant = continuous action"""
    def overlap(a, e):
        pts = []
        c, s = math.cos(math.radians(-a)), math.sin(math.radians(-a))
        for p in pin_centres(e):
            q = (p[0] - BC[0], p[1] - BC[1])
            q = (q[0] * c - q[1] * s, q[0] * s + q[1] * c)
            if math.hypot(*q) < R_TIP + 4:
                pts.append(q)
        return bool(np.min(shapely.distance(gear, shapely.points(np.array(pts)))) < E.PR)
    e, lags, a = -2.0, [], 0.0
    while a <= 2 * E.PITCH:
        if overlap(a, e):
            lo, hi = e, e + 0.05                    # small steps: the free window is only the backlash wide
            while overlap(a, hi):
                hi += 0.05
            for _ in range(20):
                m = (lo + hi) / 2
                lo, hi = (m, hi) if overlap(a, m) else (lo, m)
            e = hi
        if a > 2:
            lags.append(a * Z / E.N - e)
        a += 0.1
    return min(lags), max(lags)


def clearances(gear):
    """minimum gaps (mm) between the ball wheel and the escapement's parts in the same planes, over the swing"""
    tip = Point(BC).buffer(R_TIP, 256)
    anc = E.anchor_parts()
    sweep = [12 * (i / 6 - 1) for i in range(13)]
    d_anchor = min(affinity.rotate(anc, th, origin=(0, 0)).distance(tip) for th in sweep)
    balls_out = C - (R_B + BALL_D / 2) - E.RING_R                       # balls vs the escape rings (plan)
    spokes_in = C - R_TIP - (E.beam_reach() - 3)                       # teeth vs the escape wheel's 2020 spokes
    return d_anchor, balls_out, spokes_in


def scad_poly(g):
    g = max(getattr(g, "geoms", [g]), key=lambda q: q.area)
    pts = [[round(x, 2), round(y, 2)] for x, y in g.exterior.coords]
    holes = [[[round(x, 2), round(y, 2)] for x, y in r.coords] for r in g.interiors]
    allp = pts + [q for h in holes for q in h]
    paths, k = [list(range(len(pts)))], len(pts)
    for h in holes:
        paths.append(list(range(k, k + len(h))))
        k += len(h)
    return f"polygon(points={allp}, paths={paths});"


def scad(gear, out, phi=0.0):
    L = ["$fn=32;"]
    def slab(g, z0, t, col):
        L.append(f'color("{col}") translate([0,0,{z0:.2f}]) linear_extrude({t:.2f}) {scad_poly(g)}')
    a = phi * E.N / Z                                      # ball wheel angle for escape angle phi
    # escape wheel: 2 rings, pins, 2020 spokes
    ring = affinity.rotate(E.wheel(), -phi, origin=W)
    for z0 in (E.GAP / 2, -E.GAP / 2 - PLY):
        slab(ring, z0, PLY, "burlywood")
    for p in pin_centres(phi):
        L.append(f'color("silver") translate([{p[0]:.2f},{p[1]:.2f},{-E.GAP / 2 - PLY - 2:.2f}]) cylinder(d=3,h={E.GAP + 2 * PLY + 6:.2f});')
    for i in range(4):
        sp = LineString([E.polar(E.HUB_A, 90 * i - phi, W), E.polar(E.beam_reach() - 3, 90 * i - phi, W)]).buffer(10, cap_style=2)
        slab(sp, -E.GAP / 2, E.GAP, "silver")
    # anchor: hub plates + arms (at rest)
    hub, ie, ix, _ = E.anchor()
    for z0 in (E.GAP / 2, -E.GAP / 2 - PLY):
        slab(hub, z0, PLY, "peru")
    for b in (ie["beam"], ix["beam"], E.ANCHOR_INFO["tail"]):
        slab(b, -E.GAP / 2, E.GAP, "silver")
    for u in (ie, ix):
        slab(u["t"], -3, 6, "#222")
    # ball wheel: disc (2 layers), caps, balls, guides, wedge
    d = to_anchor(disc_layer(gear), a)
    slab(d, -DISC_T / 2, DISC_T, "tan")
    cap = to_anchor(bearing_cap())
    slab(cap, DISC_T / 2, PLY, "peru")
    slab(cap, -DISC_T / 2 - PLY, PLY, "peru")
    for th in hole_angles(a):
        if FEED <= th <= OUT:
            p = E.polar(R_B, 90 + th, BC)
            L.append(f'color("gainsboro") translate([{p[0]:.2f},{p[1]:.2f},0]) sphere(d={BALL_D});')
    gf, ties = guide(True)
    gb, _ = guide(False)
    slab(to_anchor(gf), GUIDE_Z, PLY, "#c9a46a")
    slab(to_anchor(gb), -GUIDE_Z - PLY, PLY, "#c9a46a")
    slab(to_anchor(wedge(1)), -GUIDE_Z, PLY, "#b08850")
    slab(to_anchor(wedge(2)), -GUIDE_Z + PLY, PLY, "#b08850")
    for p in ties:
        q = to_anchor(Point(p))
        L.append(f'color("silver") translate([{q.x:.2f},{q.y:.2f},{-GUIDE_Z - PLY - 1:.2f}]) cylinder(d=5,h={2 * GUIDE_Z + 2 * PLY + 2:.2f});')
    L.append(f'color("silver") translate([{BC[0]:.2f},{BC[1]:.2f},-30]) cylinder(d=8,h=60);')
    L.append(f'color("silver") translate([{W[0]:.2f},{W[1]:.2f},-30]) cylinder(d=8,h=60);')
    # queued balls on the feed chute (just a hint of where the feed comes in)
    for i in range(3):
        p = E.polar(R_B, 90 + FEED - 8, BC)
        L.append(f'color("gainsboro") translate([{p[0] + 4 + 19.5 * i:.2f},{p[1] + 3 + 4 * i:.2f},{DISC_T / 2 + BALL_D / 2 + 0.5:.2f}]) sphere(d={BALL_D});')
    # seconds hand + dial
    h, _ = hand()
    slab(affinity.translate(affinity.rotate(h, -phi, origin=(0, 0)), *W), HAND_Z, PLY, "#8b1a1a")
    dg, ticks, nums = dial()
    slab(affinity.translate(dg, *W), DIAL_Z, PLY, "wheat")
    for t in ticks:
        seg = affinity.translate(LineString(t).buffer(0.6, cap_style=2), *W)
        slab(seg, DIAL_Z + PLY, 0.3, "#333")
    out.write_text(L[0] + "\nrotate([90,0,0]) {   // stand it up: drawing y -> up, z (toward the viewer) -> -y\n" + "\n".join(L[1:]) + "\n}\n")


def front_drawing(gear, path):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, (ax, ax2) = plt.subplots(1, 2, figsize=(15, 8), gridspec_kw=dict(width_ratios=[2.2, 1]))
    def draw(g, **kw):
        for p in getattr(g, "geoms", [g]):
            ax.fill(*p.exterior.xy, **kw)
            for r in p.interiors:
                ax.fill(*r.xy, color="w")
    draw(affinity.translate(dial()[0], *W), color="wheat", alpha=.6)
    draw(E.wheel(), color="burlywood", alpha=.7)
    for p in pin_centres(0):
        ax.add_patch(plt.Circle(p, 1.5, color="k"))
    draw(E.anchor_parts(), color="silver", alpha=.9)
    draw(to_anchor(disc_layer(gear)), color="tan", alpha=.8)
    draw(to_anchor(guide(False)[0]), color="#c9a46a", alpha=.35)
    for th in hole_angles(0):
        if FEED <= th <= OUT:
            ax.add_patch(plt.Circle(E.polar(R_B, 90 + th, BC), BALL_D / 2, color="gray"))
    h, _ = hand()
    draw(affinity.translate(h, *W), color="#8b1a1a", alpha=.8)
    ax.annotate("feed (queued ball\npresses on the disc)", E.polar(R_B, 90 + FEED, BC), (BC[0] + 40, BC[1] + 140),
                arrowprops=dict(arrowstyle="->"), fontsize=8)
    ax.annotate("exit (wedge pushes\nthe ball forward)", E.polar(R_B, 90 + 168, BC), (BC[0] - 190, BC[1] - 150),
                arrowprops=dict(arrowstyle="->"), fontsize=8)
    ax.set_aspect("equal")
    ax.set_title("front view: escape wheel + ball wheel (1:1 mesh on the pins) + seconds hand and dial", fontsize=9)
    angs = np.linspace(0, 360 / K, 121)
    ax2.plot(angs, [torque(x) for x in angs])
    ax2.set_xlabel("ball wheel angle within one hole pitch (deg)")
    ax2.set_ylabel("torque on the escape wheel, N m (1:1)")
    ax2.set_title(f"{K} balls/min, {R_B:g} mm lever", fontsize=9)
    ax2.grid(alpha=.3)
    plt.tight_layout()
    plt.savefig(path, dpi=100)


def emit_all(gear, out_dir):
    from laser_parts import gcode
    T, kerf, _ = gcode.fit("ply3")
    job = gcode.job("ply3")
    ejob = gcode.job("ply3", recipe="etch", feed_mm_per_min=3000, power_percent=60)   # as spiral_base.py (estimate)

    def one(name, g, copies, note, etches=()):
        gk = g.buffer(kerf / 2, join_style=2)
        x0, y0, x1, y1 = gk.bounds
        cuts = []
        for pg in getattr(gk, "geoms", [gk]):
            cuts += [gcode.Polyline([(x - x0, y - y0) for x, y in r.coords], True) for r in pg.interiors]
            cuts.append(gcode.Polyline([(x - x0, y - y0) for x, y in pg.exterior.coords], True))
        cuts = gcode.order(cuts)
        stem = gcode.name(name, x1 - x0, y1 - y0, "ply3")
        lines = gcode.preamble(job, title=f"{stem} -- marbles/clock/marble_drive.py: cut {copies}",
                               notes=[note, f"ply3: T {T}, kerf {kerf}; X0 Y0 = bottom-left"], etch=ejob if etches else None)
        ets = gcode.order([gcode.Polyline([(x - x0, y - y0) for x, y in pl], False) for pl in etches])
        for i, e in enumerate(ets, 1):
            lines += gcode.etch(e, ejob, i, len(ets))
        for i, c in enumerate(cuts, 1):
            lines += gcode.cut(c, job, i, len(cuts))
        p = gcode.write(out_dir / f"{stem}.gcode", lines)
        mins = sum(LineString(c.points).length * job.passes for c in cuts) / job.feed_mm_per_min
        print(f"  {p.name}: cut {copies}, ~{mins:.0f} min each")

    one("mdrive_ball_disc", disc_layer(gear), DISC_LAYERS,
        f"ball wheel disc, {Z} teeth on the escape pins (1:1), {K} ball holes d{HOLE_D:g} on r{R_B:g}, 608 seat; 2 layers, M3 together")
    one("mdrive_bearing_cap", bearing_cap(), 2, "608 retainer, one each face of the disc (3 x M3 through both disc layers)")
    one("mdrive_guide_front", guide(True)[0], 1, "front guide: clamp on the 8 mm axle with M8 nuts, 10 in front of the disc's centre plane")
    one("mdrive_guide_back", guide(False)[0], 1, "back guide: as the front, behind; carries the exit wedge")
    one("mdrive_wedge_1", wedge(1), 1, "exit wedge layer 1 (on the back guide's inner face, M3)")
    one("mdrive_wedge_2", wedge(2), 1, "exit wedge layer 2 (on layer 1)")
    h, _ = hand()
    one("mdrive_seconds_hand", h, 1, "seconds hand: M5 through two spokes' holes into the T-nuts, on 2 nuts each over the pin ends")
    import sys as _s
    _s.path.insert(0, str(Path("/home/user/cnc_vibes/cnc_calibrate")))
    from spiral_cal import _label_strokes
    dg, ticks, nums = dial()
    strokes = []
    for text, x, y in nums:
        strokes += _label_strokes(text, x, y, NUM_H)
    chains = gcode.fuse_touching([[(x1, y1), (x2, y2)] for x1, y1, x2, y2 in strokes], tol=0.05)
    ets = [list(t) for t in ticks] + [[tuple(q) for q in ch] for ch in chains if len(ch) > 1]
    one("mdrive_dial", dg, 1, "fixed seconds dial ring behind the hand tip; M5 slots +-4 deg to line it up", etches=ets)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--gcode", action="store_true")
    ap.add_argument("--no-render", action="store_true")
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    gear = gear_local()
    lo, hi = mesh_check(gear)
    ts = [torque(x) for x in np.linspace(0, 360 / K, 241)]
    d_anchor, balls_out, spokes_in = clearances(gear)
    h, tail_r = hand()
    print(f"ball wheel: {Z} teeth (pitch r {RG:g}, tips r {R_TIP:g}) on the escape wheel's {E.N} pins, centre distance {C:g}, "
          f"at {PLACE:g} deg from the escape centre; turns 1 per {60 * Z / E.N:g} s the other way")
    print(f"  mesh: escape-wheel lag {lo:.2f}..{hi:.2f} deg while pushed over 2 pitches (constant = the teeth hand over without a gap)")
    print(f"  {K} holes d{HOLE_D:g} on r{R_B:g} -> {K * E.N / Z:g} balls/min; ball {BALL_M * 1000:.1f} g; torque at the escape wheel "
          f"{min(ts):.3f}..{max(ts):.3f} N m, mean {sum(ts) / len(ts):.3f}")
    print(f"  clearances: teeth vs anchor parts over +-12 deg {d_anchor:.1f}; balls vs escape rings (plan) {balls_out:.1f}; "
          f"teeth vs escape 2020 spokes {spokes_in:.1f}")
    print(f"seconds hand: tip r {HAND_TIP:g}, tail disc r {tail_r:.1f} at {HAND_TAIL:g} (balanced on the axle); dial ring "
          f"{2 * DIAL_IN:g}..{2 * DIAL_OUT:g} across")
    front_drawing(gear, HERE / "marble_drive.png")
    out = HERE / "marble_drive.scad"
    scad(gear, out)
    if not a.no_render:
        views = HERE.parent / "views"
        cx, cy = (W[0] + BC[0]) / 2, (W[1] + BC[1]) / 2
        for n, cam in (("front", f"{cx},-1050,{cy - 20},{cx},0,{cy - 20}"), ("iso", f"{cx + 560},-920,{cy + 300},{cx},0,{cy + 10}"),
                       ("left", f"{cx - 620},-560,{cy + 200},{cx - 50},0,{cy + 20}")):
            subprocess.run(["xvfb-run", "-a", "openscad", "-o", str(views / f"marble_drive_{n}.png"), f"--camera={cam}",
                            "--imgsize=1400,1050", "--projection=p", "--colorscheme=Tomorrow", str(out)], check=True, capture_output=True)
    if a.gcode:
        emit_all(gear, a.out)


if __name__ == "__main__":
    main()
