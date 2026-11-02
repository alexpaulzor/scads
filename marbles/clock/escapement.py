#!/usr/bin/env python3
"""Ball clock escapement: geometry, kinematic check, laser cut files.

A Graham deadbeat escapement whose escape wheel shares its arbor with a
ball wheel. Balls from a hopper drop into the ball wheel's pockets at the
top, ride down the descending side (held in by a guard arc) and fall out at
the guard's end: their weight is the clock's drive. The anchor sits on the
pendulum's arbor, BELOW the escape wheel (the escapement is above the
pendulum's fulcrum). This file cuts an escapement TEST RIG driven by a
string and a small weight; the ball drive comes next (see drive_estimate). Every swing lets the wheels turn half a tooth; one
ball leaves per full swing cycle (2 s), and the arbor turns once a minute
(a seconds hand fits on it).

All dimensions mm, front view, x right, y up, origin = pendulum arbor.
The wheels turn clockwise seen from the front.

    python3 marbles/clock/escapement.py            # check + cut files + previews
    python3 marbles/clock/escapement.py --check    # kinematic check only
"""

import argparse
import math
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent

# ---------------- parameters
BALL = 12.7            # 1/2" steel balls
N = 30                 # escape teeth = ball pockets; 1 rev/min with a seconds pendulum
RW = 70.0              # escape wheel tip radius
SPAN = 7.5             # anchor spans 7.5 teeth (90 deg)
LIFT = 3.0             # anchor rotation during impulse, deg
DROP = 2.0             # free wheel rotation per swing after impulse, deg (1.5 also checks out)
AMP = 4.0              # design pendulum amplitude, deg (each side)
MIN_AMP = LIFT / 2 + 1.0   # below this it stops locking safely
TIP = 0.9              # tooth tip land
UNDERCUT = 0.0         # leading face lean, deg (any lean jammed the exit pallet in the check)
ROOT = 10.0             # tooth depth
BACK = 0.32            # tooth root width, fraction of a pitch (slim teeth leave room for the pallets)
SHEET = 2.63
RP = 84.0              # ball pocket center radius on the ball wheel
POCKET_CLR = 0.4
GUARD_CLR = 0.6
KERF = 0.105            # measured on this stock (marbles/kerf_test.py)
BEARING_D = 22.0        # 608 outer diameter (press fit; tune after a test cut)
ARBOR_D = 8.1           # 8 mm arbor (M8 threaded rod or 8 mm rod) clearance in wheels/anchor
BOB_KG = 1.0            # for the energy estimate only
Q_GUESS = 200           # pendulum quality factor guess (home-built), energy estimate only

D = RW / math.cos(math.radians(SPAN * 360 / N / 2))   # anchor arbor to wheel center
W = (0.0, D)
PITCH = 360.0 / N
WI = RW * math.radians(PITCH / 2 - DROP)              # radial impulse travel at pallets
R0 = math.sqrt(D * D - RW * RW)                        # pivot to tangent points


def polar(r, a_deg, c=(0.0, 0.0)):
    a = math.radians(a_deg)
    return (c[0] + r * math.cos(a), c[1] + r * math.sin(a))


def arc(r, a0, a1, c=(0.0, 0.0), step=0.5):
    n = max(2, int(abs(a1 - a0) / step) + 1)
    return [polar(r, a0 + (a1 - a0) * i / (n - 1), c) for i in range(n)]


# ---------------- escape wheel (clockwise: tips lead clockwise)
def escape_wheel():
    rr = RW - ROOT
    # pts were generated going clockwise per tooth; make one ring in order
    ring = []
    for k in range(N):
        a = 90 - k * PITCH
        tip_w = math.degrees(TIP / RW)
        root_lead_a = a + math.degrees(math.atan(ROOT * math.tan(math.radians(UNDERCUT)) / rr))  # tip overhangs ahead
        ring += [polar(rr, a + PITCH * BACK), polar(RW, a + tip_w), polar(RW, a), polar(rr, root_lead_a)]
    poly = Polygon(ring).buffer(0)
    hole = Point(0, 0).buffer(4.05, 64)
    return affinity.translate(poly.difference(hole), *W)


# ---------------- anchor (on the pendulum arbor at the origin)
# Polar coordinates about the arbor. Near each contact point the escape
# teeth move along the ray at 45 deg (entry: toward the arbor) or 135 deg
# (exit: away from it); the wheel lies at larger angle than 45 / smaller
# than 135, so pallets reach into the tooth gaps from outside. Locking faces
# are arcs about the arbor (deadbeat: no recoil). KAPPA is the lock depth
# (anchor degrees) a pallet already has when the other one drops a tooth.
KAPPA = 1.0
ARM_W = 10.0


def anchor():
    h, k = LIFT / 2, KAPPA / 2
    ro, ri = R0 + WI / 2, R0 - WI / 2
    # entry (right): locking face = outer arc up to a_tip; impulse ramp from
    # (ro, a_tip) in to (ri, a_tip + LIFT)
    a_tip = 45 - h + k
    a_sh = 45 - AMP - 2.0 - 4.0           # shallow end, joins the arm
    entry = (arc(ro, a_sh, a_tip) + [polar(ri, a_tip + LIFT)] + arc(ri, a_tip + LIFT, a_sh))
    # exit (left): locking face = inner arc down to b_tip; ramp from
    # (ri, b_tip) out to (ro, b_tip - LIFT)
    b_tip = 135 + h - k
    b_sh = 135 + AMP + 2.0 + 4.0
    exitp = (arc(ri, b_sh, b_tip) + [polar(ro, b_tip - LIFT)] + arc(ro, b_tip - LIFT, b_sh))
    pal_e = Polygon(entry).buffer(0)
    pal_x = Polygon(exitp).buffer(0)
    # arms: straight from the hub to each pallet's shallow end, kept clear
    # of the wheel (their edges stay below 45 - AMP / above 135 + AMP)
    arm_e = LineString([(0, 0), polar(R0, a_sh - 2)]).buffer(ARM_W / 2, cap_style=1)
    arm_x = LineString([(0, 0), polar(R0, b_sh + 2)]).buffer(ARM_W / 2, cap_style=1)
    hub = Point(0, 0).buffer(14, 64)
    tail = Polygon([(-7, 0), (7, 0), (7, -60), (-7, -60)])
    anc = unary_union([pal_e, pal_x, arm_e, arm_x, hub, tail]).buffer(0)
    holes = unary_union([Point(0, 0).buffer(4.05, 64), Point(0, -40).buffer(2.6, 32), Point(0, -54).buffer(2.6, 32)])
    return anc.difference(holes), pal_e, pal_x


# ---------------- kinematic check
def simulate(amp=AMP, verbose=True, cycles=2, steps_per_swing=200, grow_w=0.0, grow_a=0.0):
    """Pendulum swings amp*cos(pi t); the wheel (driven clockwise) turns
    until blocked. Reports per swing how far the wheel turned, how much of
    that happened while pushing the anchor (impulse) vs free (drop), any
    recoil, and whether it ran away (a whole tooth with nothing stopping it)."""
    # grow_w / grow_a: oversize (+) or undersize (-) the parts to test cut tolerance
    wheel0 = escape_wheel().buffer(grow_w, join_style=2).intersection(
        Polygon([(-200, -200), (200, -200), (200, D - 10), (-200, D - 10)]))
    anc = anchor()[0].buffer(grow_a, join_style=2)

    def hits(phi, th):
        return (affinity.rotate(wheel0, -phi, origin=W)
                .intersection(affinity.rotate(anc, th, origin=(0, 0))).area > 1e-4)

    def advance(phi, th, maxstep=PITCH):
        if not hits(phi + maxstep, th):
            # check intermediate points too (a pallet could be skipped over)
            for f in (0.25, 0.5, 0.75):
                if hits(phi + maxstep * f, th):
                    break
            else:
                return phi + maxstep, True
        lo, hi = phi, phi + maxstep
        # find the first blocked point by scanning, then bisect
        n = 48
        for j in range(1, n + 1):
            if hits(phi + maxstep * j / n, th):
                hi = phi + maxstep * j / n
                lo = phi + maxstep * (j - 1) / n
                break
        for _ in range(16):
            mid = (lo + hi) / 2
            if hits(mid, th):
                hi = mid
            else:
                lo = mid
        return lo, False

    th = amp
    phi = 0.0
    k = 0
    while hits(phi, th) and k < 200:
        phi += 0.1
        k += 1
    phi, _ = advance(phi, th)
    recoil = 0.0
    runaway = False
    swings = {}
    for i in range(1, 2 * cycles * steps_per_swing + 1):
        t = i / steps_per_swing
        th = amp * math.cos(math.pi * t)
        if hits(phi, th):            # anchor pushed into the wheel: it must back up
            lo, hi = phi - PITCH / 2, phi
            for _ in range(20):
                mid = (lo + hi) / 2
                if hits(mid, th):
                    hi = mid
                else:
                    lo = mid
            recoil = max(recoil, phi - lo)
            phi = lo
        new, free = advance(phi, th)
        if free:
            runaway = True
            break
        d = new - phi
        s = min(int(t - 1e-9), 2 * cycles - 1)
        rec = swings.setdefault(s, [0.0, 0.0, 0.0])
        if d > 1e-4:
            rec[0] += d
            rec[1] = max(rec[1], d)
        phi = new
    if verbose:
        print(f"amplitude {amp:.2f}: {'RUNAWAY' if runaway else 'ok'}, max recoil {recoil:.3f} deg")
        for s in sorted(swings):
            tot, big, _ = swings[s]
            print(f"  swing {s}: wheel {tot:.2f} deg, biggest single step (drop) {big:.2f} deg")
    return runaway, recoil, swings


# ---------------- escapement test rig
# Two identical plates (front and back, 3 layers each) carry 608 bearings
# for the wheel arbor and the anchor arbor; the escape wheel and the anchor
# turn between them on 8 mm arbors (M8 threaded rod, nuts and washers
# clamp each part). A drum on the back of the wheel arbor takes a string
# and a small weight; the pendulum rod bolts to the anchor's tail below
# the plates. The plates bolt to 2020 extrusion with M5 + T-nuts.
#
# Why no ball wheel yet: balls in pockets driving the escape wheel directly
# would put about 49 mN m on it (11 balls of 8.4 g at 84 mm); a wooden
# clock escapement wants a few mN m. See drive_estimate().
PLATE = (-86.0, -24.0, 86.0, 180.0)                    # x0, y0, x1, y1
GAP_LAYERS = 4                                         # plate-to-plate spacer stack
STANDOFFS = [(-74.0, -12.0), (74.0, -12.0), (-74.0, 168.0), (74.0, 168.0)]
MOUNT = [(-74.0, 60.0), (74.0, 60.0)]
DRUM_R = 10.0
RP_BALLS = 84.0                                        # for the ball-wheel estimate only
EXIT_BALLS = 120


def rounded_rect(x0, y0, x1, y1, r=6.0):
    return Polygon([(x0, y0), (x1, y0), (x1, y1), (x0, y1)]).buffer(-r).buffer(r, 32)


def plate():
    p = rounded_rect(*PLATE)
    holes = [Point(*W).buffer(BEARING_D / 2, 96), Point(0, 0).buffer(BEARING_D / 2, 96)]
    holes += [Point(*m).buffer(2.7, 32) for m in STANDOFFS + MOUNT]
    return p.difference(unary_union(holes))


def spacer():
    return Point(0, 0).buffer(6, 48).difference(Point(0, 0).buffer(2.7, 32))


def drum():
    d = Point(0, 0).buffer(DRUM_R, 96).difference(Point(0, 0).buffer(ARBOR_D / 2, 48))
    return d.difference(Point(DRUM_R - 3, 0).buffer(1.0, 24))       # string anchor hole


def flange():
    return Point(0, 0).buffer(DRUM_R + 6, 96).difference(Point(0, 0).buffer(ARBOR_D / 2, 48))


def seconds_hand():
    h = unary_union([LineString([(0, -18), (0, 62)]).buffer(2.5, cap_style=1), Point(0, 0).buffer(8, 48)])
    return h.difference(Point(0, 0).buffer(ARBOR_D / 2, 48))


def parts():
    return {
        "escape_wheel": (escape_wheel(), 3, "glue 3 together"),
        "anchor": (anchor()[0], 3, "glue 3 together"),
        "plate": (plate(), 6, "two stacks of 3: front and back plate, a 608 in each hole"),
        "spacer": (spacer(), 4 * GAP_LAYERS, f"four stacks of {GAP_LAYERS} between the plates"),
        "drum": (drum(), 3, "glue 3 between two flanges"),
        "flange": (flange(), 2, "either side of the drum"),
        "seconds_hand": (seconds_hand(), 1, ""),
    }


def drive_estimate():
    """Pendulum loss per swing (guessed) vs what the escape wheel torque gives."""
    e_pend = BOB_KG * 9.81 * (9.81 / math.pi ** 2) * (1 - math.cos(math.radians(AMP)))
    loss = math.pi * e_pend / Q_GUESS                        # J per swing
    imp = math.radians(PITCH / 2 - DROP)                     # wheel turn while impulsing
    m = 7.85e-3 * 4 / 3 * math.pi * (BALL / 20) ** 3         # kg per ball
    loaded = [6 + k * PITCH for k in range(int(EXIT_BALLS / PITCH) + 1) if 6 + k * PITCH <= EXIT_BALLS]
    t_balls = sum(m * 9.81 * RP_BALLS / 1000 * math.sin(math.radians(x)) for x in loaded)
    return e_pend, loss, imp, m, len(loaded), t_balls


def polylines(geom):
    gs = [geom] if geom.geom_type == "Polygon" else list(geom.geoms)
    out = []
    for g in gs:
        for ring in [g.exterior] + list(g.interiors):
            out.append(list(ring.coords))
    return out


def write_gcode(name, geom, note, copies, outdir):
    sys.path.insert(0, str(HERE.parent))
    from laser_parts import emit_cut, load_profile, preamble
    s2g, motion, mat, job = load_profile("plywood_veneer_3ply_3mm", 1000, None)
    g = geom.buffer(KERF / 2, join_style=1)          # kept part grows, its holes shrink
    x0, y0, x1, y1 = g.bounds
    loops = [[(x - x0, y - y0) for x, y in pl] for pl in polylines(g)]
    loops.sort(key=lambda pl: abs(Polygon(pl).area))  # holes first, outline last
    cuts = [s2g.Polyline(pl, True) for pl in loops]
    lines = [f"; clock {name} -- marbles/clock/escapement.py; cut {copies}" + (f", {note}" if note else ""),
             f"; X0 Y0 = bottom-left of the part; {x1 - x0:.2f} x {y1 - y0:.2f} mm; kerf {KERF}", ";"]
    lines += preamble(s2g, job)
    for i, c in enumerate(cuts, 1):
        lines += emit_cut(s2g, motion, c, i, len(cuts), job)
    lines += s2g._footer()
    outdir.mkdir(parents=True, exist_ok=True)
    (outdir / f"clock_{name}.gcode").write_text("\n".join(lines))
    return x1 - x0, y1 - y0


def preview(path, th=0.0, phi=0.0):
    from PIL import Image, ImageDraw
    S = 4
    x0, y0, x1, y1 = PLATE[0] - 10, PLATE[1] - 50, PLATE[2] + 10, PLATE[3] + 10
    im = Image.new("RGB", (int((x1 - x0) * S), int((y1 - y0) * S)), "white")
    d = ImageDraw.Draw(im)
    pp = lambda x, y: ((x - x0) * S, (y1 - y) * S)
    def draw(geom, col, w=2):
        for pl in polylines(geom):
            d.line([pp(*q) for q in pl], fill=col, width=w)
    draw(plate(), (160, 160, 160), 1)
    draw(affinity.rotate(escape_wheel(), -phi, origin=W), (40, 40, 40))
    draw(affinity.rotate(anchor()[0], th, origin=(0, 0)), (200, 30, 30))
    d.text((10, 10), "front view: grey = plate, black = escape wheel, red = anchor (pendulum bolts to its tail)", fill="black")
    im.save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="kinematic check only")
    ap.add_argument("--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    print(f"anchor arbor to wheel arbor {D:.2f} mm; pallets at {R0:.2f} mm; impulse travel {WI:.2f} mm")
    ok = True
    for amp in (3.0, AMP, 5.0):
        run, rec, sw = simulate(amp, verbose=False)
        tots = [round(sw[k][0], 2) for k in sorted(sw)]
        good = (not run) and rec < 0.05 and all(abs(t - PITCH / 2) < 0.35 for t in tots[1:])
        ok &= good
        print(f"check amplitude {amp} deg: {'OK' if good else 'FAIL'} (wheel per swing {tots}, recoil {rec:.3f} deg)")
    e_pend, loss, imp, m, n, t_balls = drive_estimate()
    print(f"pendulum: about {loss * 1000:.2f} mJ lost per swing (guess: {BOB_KG} kg bob, Q {Q_GUESS}, {AMP} deg); "
          f"escape torque to replace it, no friction: {loss / imp * 1000:.1f} mN m")
    print(f"balls driving the escape arbor directly: {n} x {m * 1000:.2f} g at {RP_BALLS:.0f} mm = {t_balls * 1000:.1f} mN m "
          f"-> {t_balls * imp * 1000:.2f} mJ per swing")
    print(f"test drum r={DRUM_R:.0f} mm: 5-15 mN m needs {5e-3 / 9.81 / (DRUM_R / 1000) * 1000:.0f}-{15e-3 / 9.81 / (DRUM_R / 1000) * 1000:.0f} g on the string")
    if a.check:
        sys.exit(0 if ok else 1)
    for name, (geom, copies, note) in parts().items():
        w, h = write_gcode(name, geom, note, copies, a.out)
        print(f"clock_{name}.gcode: {w:.2f} x {h:.2f} mm, cut {copies}" + (f" ({note})" if note else ""))
    preview(HERE.parent / "gcode" / "clock_preview.png")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
