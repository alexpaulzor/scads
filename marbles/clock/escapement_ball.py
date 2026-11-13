#!/usr/bin/env python3
"""BALL-DRIVEN pin wheel (WIP, preview stage): the escape wheel is driven by marbles riding in its own pin gaps.

Alex's layout (2026-11-13):
  - 30 M3 PINS through BOTH rings, 20 mm clear between neighbouring shanks (so a 3/4" ball passes between them), and
    sticking out past the FRONT ring: the ROCKER works on those front ends, in front of the wheel. The gap between the
    rings is left to the balls; nothing of the rocker is in it.
  - POCKETS: one per pin gap. Their bottoms are a FLOOR WALL of 30 flat ply3 segments standing between the rings
    (boxes.py style, no glue): each segment has a 10 mm tab through a slot in each ring, and 5 mm finger tabs that
    interlock with its neighbours end to end, bending 12 deg at each joint (the joints sit under the pins). A ball
    sits on its segment between two pins. Fed at the top just right of 12, it rides the
    descending side pushing on the pin below it, and once past 3 o'clock (gravity now outward) rolls out between the
    pins on its own.
  - RATE: the lift brings 2 balls per 2 s swing and a pocket reaches the top every 2 s, so the wheel takes one of
    them (30 pockets, one ball each) and the other runs on to an OVERFLOW track: the feed chute crosses the top of the
    wheel, a ball drops into the pocket under it if that pocket is empty, otherwise it rolls over the occupied pocket
    and off the far end of the chute.
  - The pendulum pivots at the top, so the ROCKER sits ABOVE the wheel on the pivot (escapement_pin.py's layout turned
    180 deg: same pallet geometry, the wheel still turns clockwise). Its 2020 arms are in front of the pin ends; each
    PALLET is a flat 2 x 3 mm acrylic plate bolted to the back face of its arm (M5 + T-nut in the arm's slot, slotted
    for the lock depth), so only the pallet plates share the plane of the pin ends.
  - SECONDS HAND + DIAL in front of the rocker (on long standoffs off two spokes).

Pallet geometry, pin pattern and the kinematic check come from escapement_pin.py with R set from the pin gap.
Drawing frame: x right, y up, origin = the pendulum pivot (anchor axle), the wheel below it; z toward the viewer,
z = 0 the middle of the wheel's gap.

    python3 marbles/clock/escapement_ball.py           # numbers, kinematic check, escapement_ball.png + views/escapement_ball_*.png
"""
import argparse
import math
import subprocess
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
import escapement_pin as E  # noqa: E402

N = 30
PIN_D = 3.0
PIN_GAP = 20.0                                   # clear between neighbouring pin shanks (Alex)
R = round(N * (PIN_GAP + PIN_D) / (2 * math.pi) + 0.2, 1)    # pin circle radius for that gap
PLY = 2.63
GAP = 20.0                                       # between the rings (the 2020 spokes)
BALL_D = 19.05
BALL_M = 4 / 3 * math.pi * (BALL_D / 20) ** 3 * 7.83 / 1000
BALL_R = R - 1.0                                 # ball centre radius in its pocket (just inside the pin circle)
FLOOR_A = BALL_R - BALL_D / 2                    # floor segments' outer (ball) face: this far from the centre at mid-segment
SIDE_TAB = 10.0                                  # tab through each ring, along the segment
FINGER = 5.0                                     # end-to-end finger tabs: 5 wide (across the gap), 5 long
SLOT_CLR = 0.1                                   # slot over the tab, each way
RING_IN = FLOOR_A - PLY - 7.0                    # ring band reaches in round the floor slots
RIM = 8.0
SPOKE_END = RING_IN - 2.0                        # the 2020 spokes now run out to the ring band (no rocker in the gap)
FEED, OUT = 4.0, 95.0                            # a ball is in its pocket from FEED to about OUT deg clockwise from 12
NUT_T = 2.4 + 0.5                                # M3 nut + washer on the front ring
PAL_Z0 = GAP / 2 + PLY + NUT_T + 0.5             # pallet plates (2 x 3 mm acrylic) from here forward ...
PAL_T = 6.0
ARM_Z0 = PAL_Z0 + PAL_T                          # ... against the arms' back faces
PIN_TIP = ARM_Z0 - 0.3                           # pin ends: through the pallet plane, short of the arms
PAD_L, PAD_W = 40.0, 20.0                        # pallet plate's mounting pad under the arm
ADJ = 4.0                                        # pallet slides +-ADJ along the arm (lock depth)
HAND_TIP, HAND_TAIL = 123.0, 52.0
HAND_Z = ARM_Z0 + 20 + 2 * PLY + 6.0            # in front of the rocker (arms + front hub plate) and the dial
DIAL_IN, DIAL_OUT = 114.0, 144.0
DIAL_Z = ARM_Z0 + 20 + PLY + 1.5
TICK = (116.0, 121.0, 125.0)
NUM_R, NUM_H = 131.0, 7.0
DIAL_SLOTS = (225.0, 270.0, 315.0)              # frame posts from behind: lower half (the rocker is above)
G = 9.81


def configure():
    """point escapement_pin's geometry at this pin circle"""
    E.R, E.PIN_D, E.PR, E.RIM = R, PIN_D, PIN_D / 2, RIM
    E.PITCH = 360.0 / N
    E.D = R / math.cos(math.radians(E.SPAN * E.PITCH / 2))
    E.W = (0.0, E.D)
    E.R0 = math.sqrt(E.D ** 2 - R ** 2)
    E.WI = R * math.radians(E.PITCH / 2 - E.DROP)
    E.RING_R = R + E.PR + RIM


def flip(g):
    """escapement_pin's frame (wheel above the anchor) -> this one (wheel below the pivot)"""
    return affinity.rotate(g, 180, origin=(0, 0))


def pallet_plates(amp_max=12.0):
    """[(plate, arm angle, pad centre radius)] for entry and exit, in escapement_pin's frame: the working pallet plus a
    web to a pad under its arm. The arm is the nearest angle outside the pallet whose plate keeps every non-working
    part out of the pins' path over +-amp_max (the arm itself is in front of the pin ends)"""
    e, x, a_sh, b_sh = E.pallets()
    ring = E.pin_ring()
    sweep = [amp_max * (i / 8 - 1) for i in range(17)]
    out = []
    for pal, a0, side in ((e, a_sh, +1), (x, b_sh, -1)):
        shank = pal.intersection(Polygon([(0, 0), E.polar(400, a0), E.polar(400, a0 + 5 * side)]))
        for k in range(160):
            a_b = a0 - side * 0.5 * k
            for r_pad in (E.R0, E.R0 + 10, E.R0 + 20):
                c = E.polar(r_pad, a_b)
                pad = affinity.rotate(box(c[0] - PAD_L / 2, c[1] - PAD_W / 2, c[0] + PAD_L / 2, c[1] + PAD_W / 2), a_b, origin=c)
                plate = unary_union([pal, unary_union([shank, pad]).convex_hull]).buffer(2).buffer(-2)
                nonwork = plate.difference(pal.buffer(0.3))
                if all(affinity.rotate(nonwork, th, origin=(0, 0)).intersection(ring).area < 1e-3 for th in sweep):
                    slots = [LineString([E.polar(r_pad + s - ADJ, a_b), E.polar(r_pad + s + ADJ, a_b)]).buffer(2.65)
                             for s in (-PAD_L / 4, PAD_L / 4)]
                    out.append((plate.difference(unary_union(slots)), a_b, r_pad))
                    break
            else:
                continue
            break
    return out


def ring(front):
    """one wheel ring (escapement_pin's frame): rim with the 30 pin holes, band under the ledge, 8 wood spokes over
    the 2020s, octagon hub with the 608 seat, M5 along the spokes, the floor segments' tab slots"""
    W = E.W
    rim = Point(W).buffer(E.RING_R, 256).difference(Point(W).buffer(RING_IN, 256))
    spokes = [LineString([W, E.polar(RING_IN + 2, i * 45, W)]).buffer(10, cap_style=2) for i in range(8)]
    hub = affinity.translate(E.OCT, *W).buffer(2, join_style=1)
    g = unary_union([rim, hub] + spokes).buffer(3).buffer(-3)
    holes = [Point(p).buffer(E.PIN_HOLE / 2, 32) for p in pin_centres(0)]
    holes.append(Point(W).buffer(E.BRG_D / 2, 64))
    holes += [Point(E.polar(r, i * 45, W)).buffer(2.65, 32) for i in range(8) for r in spoke_m5()]
    holes += floor_slots()
    return g.difference(unary_union(holes))


def spoke_m5():
    a, b = E.HUB_A + 8, SPOKE_END - 8
    return (round(a, 1), round((a + b) / 2, 1), round(b, 1))


def gap_angles():
    """pocket (pin gap) centre angles in escapement_pin's frame, wheel at 0"""
    return [90 - (k + 0.5) * E.PITCH for k in range(N)]


def floor_slots():
    """one slot per segment in each ring: tangential, over the segment's side tab"""
    out = []
    for a in gap_angles():
        c = E.polar(FLOOR_A - PLY / 2, a, E.W)
        r = box(-SIDE_TAB / 2 - SLOT_CLR, -PLY / 2 - SLOT_CLR, SIDE_TAB / 2 + SLOT_CLR, PLY / 2 + SLOT_CLR)
        out.append(affinity.translate(affinity.rotate(r, a - 90, origin=(0, 0)), *c))
    return out


def seg_len():
    """joint to joint, measured on the segment's mid-thickness"""
    return 2 * (FLOOR_A - PLY / 2) * math.tan(math.radians(E.PITCH / 2))


def floor_segment():
    """flat pattern of one floor segment (cut 30): u along the segment (joint to joint = seg_len), v across the gap
    (0..GAP); side tabs through the rings; at each end a square-wave edge: 5 mm fingers past the joint line where the
    neighbour has notches, and the other way round, so all 30 are identical"""
    L, t = seg_len(), PLY
    body = box(-L / 2, 0, L / 2, GAP)
    lanes_a = [(0, FINGER), (2 * FINGER, 3 * FINGER)]          # left-end fingers / right-end notches
    lanes_b = [(FINGER, 2 * FINGER), (3 * FINGER, 4 * FINGER)] # right-end fingers / left-end notches
    cut = [box(-L / 2, v0, -L / 2 + FINGER, v1) for v0, v1 in lanes_b] + [box(L / 2 - FINGER, v0, L / 2, v1) for v0, v1 in lanes_a]
    add = [box(-L / 2 - FINGER, v0, -L / 2, v1) for v0, v1 in lanes_a] + [box(L / 2, v0, L / 2 + FINGER, v1) for v0, v1 in lanes_b]
    tabs = [box(-SIDE_TAB / 2, -t, SIDE_TAB / 2, 0), box(-SIDE_TAB / 2, GAP, SIDE_TAB / 2, GAP + t)]
    return unary_union([body.difference(unary_union(cut))] + add + tabs)


def pin_centres(phi):
    return [E.polar(R, 90 - k * E.PITCH - phi, E.W) for k in range(N)]


def pockets(phi):
    """ball centres (this frame) of the loaded pockets, wheel turned clockwise by phi"""
    Wd = (0.0, -E.D)
    out = []
    for k in range(N):
        th = (k * E.PITCH + E.PITCH / 2 + phi) % 360          # pocket angle clockwise from 12 (this frame)
        if FEED <= th <= OUT:
            out.append(E.polar(BALL_R, 90 - th, Wd))
    return out


def torque_every(step_pockets=1):
    """(min, max, mean) wheel torque, N m, with a ball in every step_pockets-th pocket"""
    vals = []
    span = E.PITCH * step_pockets
    for i in range(int(span * 10)):
        p = i / 10
        s = sum(math.sin(math.radians(th)) for th in (FEED + p + span * j for j in range(N)) if th <= OUT)
        vals.append(BALL_M * G * BALL_R / 1000 * s)
    return min(vals), max(vals), sum(vals) / len(vals)


def hand():
    m5 = spoke_m5()
    body = Polygon([(-9, -m5[-1] - 8), (9, -m5[-1] - 8), (9, m5[-1] + 8), (2, HAND_TIP), (-2, HAND_TIP)])
    hub = Point(0, 0).buffer(16, 48)
    lo, hi = 4.0, 30.0
    for _ in range(40):
        r = (lo + hi) / 2
        g = unary_union([body, hub, LineString([(0, 0), (0, -HAND_TAIL)]).buffer(7, cap_style=2), Point(0, -HAND_TAIL).buffer(r, 48)])
        lo, hi = (r, hi) if g.centroid.y > 0 else (lo, r)
    holes = [Point(0, 0).buffer(8.0, 48)] + [Point(0, s * q).buffer(2.65, 24) for s in (1, -1) for q in m5[1:]]
    return g.difference(unary_union(holes)), r


def dial():
    ring_ = Point(0, 0).buffer(DIAL_OUT, 256).difference(Point(0, 0).buffer(DIAL_IN, 256))
    slots = [LineString(E.arc(139.5, a - 4, a + 4)).buffer(2.65, cap_style=1) for a in DIAL_SLOTS]
    ticks = [[E.polar(TICK[0], 90 - 6 * s), E.polar(TICK[2] if s % 5 == 0 else TICK[1], 90 - 6 * s)] for s in range(60)]
    nums = [(f"{s}", *E.polar(NUM_R, 90 - 6 * s)) for s in range(0, 60, 5)]
    return ring_.difference(unary_union(slots)), ticks, nums


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


def build(phi=0.0, th=0.0):
    """everything in this frame: dict name -> list of (geometry, z0, thickness, colour)"""
    Wd = (0.0, -E.D)
    parts = []
    def add(g, z0, t, col):
        parts.append((g, z0, t, col))
    rot = lambda g: affinity.rotate(flip(g), -phi, origin=Wd)                   # noqa: E731
    add(rot(ring(False)), -GAP / 2 - PLY, PLY, "burlywood")
    add(rot(ring(True)), GAP / 2, PLY, "burlywood")
    for i in range(4):
        sp = LineString([E.polar(E.HUB_A, 90 * i, E.W), E.polar(SPOKE_END, 90 * i, E.W)]).buffer(10, cap_style=2)
        add(rot(sp), -GAP / 2, GAP, "silver")
    plates = pallet_plates()
    hub_r = E.HUB_PLATE_R
    arms, pads = [], []
    for plate, a_b, r_pad in plates:
        arms.append(LineString([E.polar(E.ARM_IN, a_b), E.polar(r_pad + PAD_L / 2 + 8, a_b)]).buffer(10, cap_style=2))
    tail = LineString([E.polar(E.ARM_IN, E.TAIL_A), E.polar(90, E.TAIL_A)]).buffer(10, cap_style=2)
    hub = unary_union([Point(0, 0).buffer(hub_r, 64)] +
                      [LineString([(0, 0), E.polar(E.HUB_ARM, a)]).buffer(13, cap_style=1) for a in [p[1] for p in plates] + [E.TAIL_A]])
    hub = hub.buffer(4).buffer(-4).difference(Point(0, 0).buffer(E.BRG_D / 2, 64))
    sw = lambda g: affinity.rotate(flip(g), th, origin=(0, 0))                   # noqa: E731
    for plate, _, _ in plates:
        add(sw(plate), PAL_Z0, PAL_T, "#222")
    for a in arms + [tail]:
        add(sw(a), ARM_Z0, 20, "silver")
    add(sw(hub), ARM_Z0 - PLY, PLY, "peru")
    add(sw(hub), ARM_Z0 + 20, PLY, "peru")
    h, _ = hand()
    add(affinity.translate(affinity.rotate(h, -phi, origin=(0, 0)), *Wd), HAND_Z, PLY, "#8b1a1a")
    dg, ticks, nums = dial()
    add(affinity.translate(dg, *Wd), DIAL_Z, PLY, "wheat")
    for t in ticks:
        add(affinity.translate(LineString(t).buffer(0.6, cap_style=2), *Wd), DIAL_Z + PLY, 0.3, "#333")
    pins = [flip(Point(p)) for p in pin_centres(0)]
    pins = [affinity.rotate(p, -phi, origin=Wd) for p in pins]
    return parts, pins, plates


def scad(out, phi=0.0):
    parts, pins, _ = build(phi)
    L = ["$fn=32;", "rotate([90,0,0]) {"]
    for g, z0, t, col in parts:
        L.append(f'color("{col}") translate([0,0,{z0:.2f}]) linear_extrude({t:.2f}) {scad_poly(g)}')
    seg = floor_segment()
    Wd = (0.0, -E.D)
    for a in gap_angles():
        ang = math.radians(a + 180 - phi)                         # this frame (flipped), wheel turned by phi
        n = (math.cos(ang), math.sin(ang))
        tt = (-n[1], n[0])
        o = (Wd[0] + n[0] * (FLOOR_A - PLY), Wd[1] + n[1] * (FLOOR_A - PLY))
        L.append(f'color("peru") multmatrix([[{tt[0]:.4f},0,{n[0]:.4f},{o[0]:.3f}],[{tt[1]:.4f},0,{n[1]:.4f},{o[1]:.3f}],'
                 f'[0,1,0,{-GAP / 2:.3f}],[0,0,0,1]]) linear_extrude({PLY}) {scad_poly(seg)}')
    z_head = -GAP / 2 - PLY - 2
    for p in pins:
        L.append(f'color("silver") translate([{p.x:.2f},{p.y:.2f},{z_head:.2f}]) cylinder(d={PIN_D},h={PIN_TIP - z_head:.2f});')
        L.append(f'color("dimgray") translate([{p.x:.2f},{p.y:.2f},{GAP / 2 + PLY:.2f}]) cylinder(d=6.2,h=2.4,$fn=6);')
    for c in pockets(phi):
        L.append(f'color("gainsboro") translate([{c[0]:.2f},{c[1]:.2f},0]) sphere(d={BALL_D});')
    Wd = (0.0, -E.D)
    # feed: a short queue coming in from the right at the top, between the rings
    for i in range(3):
        c = E.polar(BALL_R + BALL_D + 2, 90 - FEED - 6, Wd)
        L.append(f'color("gainsboro") translate([{c[0] + 21 * i:.2f},{c[1] + 6 * i:.2f},0]) sphere(d={BALL_D});')
    # one ball leaving past 3 o'clock
    c = E.polar(BALL_R + 16, 90 - OUT - 8, Wd)
    L.append(f'color("gainsboro") translate([{c[0]:.2f},{c[1]:.2f},0]) sphere(d={BALL_D});')
    L.append(f'color("silver") translate([0,0,-40]) cylinder(d=8,h={HAND_Z + 50:.2f});')
    L.append(f'color("silver") translate([{Wd[0]},{Wd[1]},-40]) cylinder(d=8,h={HAND_Z + 50:.2f});')
    L.append("}")
    out.write_text("\n".join(L) + "\n")


def drawing(path, phi=0.0):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    parts, pins, plates = build(phi)
    fig, ax = plt.subplots(figsize=(10, 12))
    order = ["burlywood", "peru", "silver", "#222", "wheat"]
    for col in order:
        for g, z0, t, c in parts:
            if c != col or t < 1:
                continue
            for p in getattr(g, "geoms", [g]):
                ax.fill(*p.exterior.xy, color=c, alpha=.55 if c in ("silver", "wheat") else .8, lw=0)
                for r in p.interiors:
                    ax.fill(*r.xy, color="w")
    Wd = (0.0, -E.D)
    for r_ap, ls in ((FLOOR_A, "-"), (FLOOR_A - PLY, "-")):
        vr = r_ap / math.cos(math.radians(E.PITCH / 2))
        vs = [E.polar(vr, a + 180 - phi + E.PITCH / 2, Wd) for a in gap_angles()]
        ax.plot(*zip(*(vs + vs[:1])), ls, color="saddlebrown", lw=1)
    for p in pins:
        ax.add_patch(plt.Circle((p.x, p.y), PIN_D / 2, color="k"))
    for c in pockets(phi):
        ax.add_patch(plt.Circle(c, BALL_D / 2, color="gray", alpha=.9))
    ax.plot([0], [0], "k+", ms=14)
    ax.annotate("pendulum pivot = rocker axle", (0, 0), (40, 40), arrowprops=dict(arrowstyle="->"), fontsize=8)
    ax.annotate("feed: one ball per pin gap", E.polar(BALL_R, 90 - FEED - 6, Wd), (120, -60),
                arrowprops=dict(arrowstyle="->"), fontsize=8)
    ax.annotate("rolls out past 3 o'clock", E.polar(BALL_R + 14, 90 - OUT - 6, Wd), (150, -E.D - 120),
                arrowprops=dict(arrowstyle="->"), fontsize=8)
    ax.set_aspect("equal")
    ax.set_title(f"ball-driven pin wheel: {N} pins on r {R:g} ({PIN_GAP:g} clear between), rocker above on the pivot, "
                 f"pallet plates on the arms' back faces (front of the pin ends)", fontsize=8)
    plt.tight_layout()
    plt.savefig(path, dpi=100)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--no-render", action="store_true")
    a = ap.parse_args()
    configure()
    pitch = 2 * math.pi * R / N
    print(f"pin wheel: {N} M3 pins on r {R:g}: pitch {pitch:.2f}, {pitch - PIN_D:.2f} clear between shanks; rings "
          f"{2 * E.RING_R:g} across; rocker axle (pivot) {E.D:.1f} above the wheel centre, wheel top {E.D - E.RING_R:.1f} below it")
    L = seg_len()
    print(f"pockets: floor of {N} segments, ball face {FLOOR_A:.2f} from the centre, ball centre r {BALL_R:g}; segment "
          f"{L:.2f} joint to joint ({L + 2 * FINGER:.1f} over the fingers) x {GAP:g} (+{PLY:g} tabs), {E.PITCH:g} deg bend at each joint; "
          f"a ball rides from {FEED:g} to ~{OUT:g} deg past 12, then rolls out")
    for n, lab in ((1, "every pocket"), (2, "every 2nd"), (4, "every 4th")):
        lo, hi, mean = torque_every(n)
        print(f"  torque with a ball in {lab} ({N / n:g} balls/min): {lo:.3f}..{hi:.3f} N m, mean {mean:.3f}")
    print(f"pins: M3 from the back ring's outer face to z {PIN_TIP:.1f} (front ring face at {GAP / 2 + PLY:.2f}): "
          f"shank {PIN_TIP + GAP / 2 + PLY:.1f} long -> M3 x 35, nut + washer on the front ring")
    plates = pallet_plates()
    for (plate, a_b, r_pad), nm in zip(plates, ("entry", "exit")):
        x0, y0, x1, y1 = plate.bounds
        print(f"  {nm} pallet plate {x1 - x0:.0f} x {y1 - y0:.0f}, 2 x acrylic3; arm (2020) at {a_b:.1f} deg in "
              f"escapement_pin's frame ({(a_b + 180) % 360:.1f} here), pad at r {r_pad:.1f} from the pivot, z {PAL_Z0:.1f}..{ARM_Z0:.1f}")
    print("kinematic check (escapement_pin's simulator, this pin circle):")
    for amp in (E.LIFT / 2 + E.KAPPA / 2 + 1.0, 8.0, E.AMP):
        E.simulate(amp)
    for gw, ga in ((0.15, 0.0), (-0.15, 0.0), (0.0, 0.15), (0.0, -0.15)):
        E.simulate(E.AMP, cycles=1, grow_w=gw, grow_a=ga)
    h, tail_r = hand()
    print(f"seconds hand: tip r {HAND_TIP:g}, tail disc r {tail_r:.1f} at {HAND_TAIL:g}, at z {HAND_Z:.1f} on standoffs "
          f"off the spokes' outer M5 (r {spoke_m5()[1]:g}, {spoke_m5()[2]:g}); dial {2 * DIAL_IN:g}..{2 * DIAL_OUT:g} across at z {DIAL_Z:.1f}")
    drawing(HERE / "escapement_ball.png")
    out = HERE / "escapement_ball.scad"
    scad(out)
    if not a.no_render:
        views = HERE.parent / "views"
        cy = -E.D / 2 - 40
        for n, cam in (("front", f"0,-1250,{cy},0,0,{cy}"), ("iso", f"520,-950,{cy + 330},0,0,{cy}"),
                       ("side", f"-700,-420,{cy + 120},0,0,{cy}")):
            subprocess.run(["xvfb-run", "-a", "openscad", "-o", str(views / f"escapement_ball_{n}.png"), f"--camera={cam}",
                            "--imgsize=1400,1050", "--projection=p", "--colorscheme=Tomorrow", str(out)], check=True, capture_output=True)


if __name__ == "__main__":
    main()
