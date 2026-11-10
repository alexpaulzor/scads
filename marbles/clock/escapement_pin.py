#!/usr/bin/env python3
"""PIN-WHEEL deadbeat escapement, sized for soft thin stock (WIP, untested).

Why: the Graham deadbeat in escapement.py needs slim wooden teeth and slim pallets. Here the escape wheel is a
LANTERN wheel: two identical wooden RINGS on opposite faces of 2020 SPOKES (20 apart), with N M3 SCREWS spanning
them as the pins (nut + washers outside). The anchor works in the 20 mm gap and catches the screw shanks, so the
thin wood never has to be stiff and every working contact is steel on the pallet:
  - RINGS: rim with the M3 holes, wood spokes over the beams, an octagon hub with a 608 seat (a 608 in each ring on
    a fixed 8 mm axle). 30 pins: 1 rev/min with a seconds pendulum (the 1 m spine) - a seconds hand fits.
  - 2020 SPOKES: 4 at 90 deg (needed), 4 more at 45 (optional), each butting a flat of the OCTAGON HUB SPACER
    (mdf3 x7 = the gap) round the bearing, ending short of where the anchor sweeps; M5 + T-nuts through the rings.
  - ANCHOR: a thick-armed rocker on the pendulum's arbor (below the wheel), arms spanning 7.5 pins. Deadbeat: the
    locking faces are arcs about the anchor arbor (no recoil), lift on inclined impulse faces.
  - PALLETS: separate blocks bolted to the arm ends through radial SLOTS (adjust the lock depth with a screwdriver),
    cut from black acrylic by default - or faced with brass / steel shim.
The pallet faces come from the classic point-tooth Graham layout, offset by the pin radius (a round pin touching a
pallet face = its centre touching the face grown by the radius), so the geometry stays exact for any pin size.

Front view, x right, y up, origin = the anchor (pendulum) arbor; the wheel is above it and turns clockwise.

    python3 marbles/clock/escapement_pin.py           # kinematic check at several swings + tolerances, cut files, drawing
    python3 marbles/clock/escapement_pin.py --check
"""
import argparse
import math
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import gcode  # noqa: E402

N = 30                 # pins: 1 rev/min on a seconds pendulum
R = 100.0              # pin-centre radius: in from the rim, so the pallet tips stay ~9 inside the rings even at +-12 deg
PIN_D = 3.0            # pins = M3 screws spanning the two wheel rings (nut + washers), the pallets work on the shank
PIN_HOLE = 3.3         # M3 clearance in the rings
SPAN = 9.5             # anchor spans 9.5 pins (114 deg): drops its axle far enough below the wheel that the hub
                       # (2 plates round a stack of 608s, wider than the gap) clears the rings
LIFT = 3.0             # anchor degrees during impulse
DROP = 1.5             # free wheel degrees per beat after impulse
KAPPA = 1.0            # lock depth (anchor degrees) a pallet already has when the other drops
AMP = 12.0             # design swing, deg each side (the check also runs smaller and larger)
ARM_W = 20.0           # anchor arms = 2020 beams between the 2 hub plates
ARM_IN = 13.0          # arm beams start this far from the anchor axle (clear of the 608 stack)
HUB_PLATE_R = 22.0     # anchor hub plate radius round the axle (11 of wood round the 608)
HUB_ARM = 35.0         # the hub plates run this far along each beam (M5 at 19 and 29): short, to clear the rings
TAIL_A = 270.0         # the third beam (the pendulum, or a stub to it) points straight down
RING_R = 144.5         # ring outer radius: 289 across, the most a 292 sheet takes in one piece
RIM = RING_R - R - 1.5  # ring wood outside the pin circle (for a 3 mm pin)
RIM_IN = 12.0          # rim band inside the pin circle
SPOKES = 8            # wood spokes over the 2020 beam spokes (4 at 0/90/180/270; the 45s are optional beams)
SPOKE_W = 20.0         # = the 2020
GAP = 20.0             # the rings sit on opposite faces of the 2020 spokes; at the pins, M3 nuts flare them a little
                       # wider so the anchor's 2020 arms pass between without binding
BRG_D = 22.0           # 608 skate bearing seat (one in each ring, on a fixed 8 mm axle)
HUB_A = 25.0           # hub = octagon, flats this far from the centre: every 2020 spoke (8 x 20 wide) butts a flat
SPOKE_M5 = None        # M5 into T-nuts along each spoke: spread over the beam's length (set from beam_reach())
ARBOR_D = 8.1          # 8 mm anchor arbor
# pallet = an upside-down T of 3 mm acrylic, held in the arm's SIDE T-slot (no glue, no drilled-hole alignment):
#   its BAR lies in the slot on the slot floor and stands a hair proud of the face; its STEM comes out of the slot (on the
#   gap's centre plane) and carries the working faces. A ply3 CLAMP strip lies on the arm's face over the bar: the stem
#   passes through its 3 mm centre slot, and an M5 at each end into a T-nut in the same slot presses the bar onto the floor.
SLOT_D = 6.0           # 2020 T-slot depth, face to floor (lib/t2020beam.scad: notch 6 x 6)
BAR_H = 6.3            # the T's bar: just over the slot depth, so the clamp bears on it
BAR_L = 30.0           # the bar's length along the arm
STEM_W = 12.0          # the stem's width where it leaves the slot (through the clamp)
CLAMP_T = 2.63         # ply3
CLAMP_SLOT = 3.1       # for the 3 mm stem
CLAMP_END = 9.0        # clamp beyond each end of the bar: the M5 sits here
ADJ_TRAVEL = 4.0       # slide the T (with the clamp loosened) this far each way along the arm to set the lock depth
HUB_CLR = 4.0          # the anchor hub plates keep at least this far from the rings over the swing
SHEET = (300.0, 292.0)

PITCH = 360.0 / N
BETA = SPAN * PITCH / 2                                # the pallets sit at anchor angles BETA and 180 - BETA
D = R / math.cos(math.radians(SPAN * PITCH / 2))       # anchor arbor to wheel centre
W = (0.0, D)
R0 = math.sqrt(D * D - R * R)                          # anchor arbor to the tangent points (pallet radius)
WI = R * math.radians(PITCH / 2 - DROP)                # radial impulse travel at the pallets
PR = PIN_D / 2
OCT = Polygon([(HUB_A / math.cos(math.radians(22.5)) * math.cos(math.radians(22.5 + 45 * i)),
                HUB_A / math.cos(math.radians(22.5)) * math.sin(math.radians(22.5 + 45 * i))) for i in range(8)])


def polar(r, a_deg, c=(0.0, 0.0)):
    a = math.radians(a_deg)
    return (c[0] + r * math.cos(a), c[1] + r * math.sin(a))


def arc(r, a0, a1, c=(0.0, 0.0), step=0.4):
    n = max(2, int(abs(a1 - a0) / step) + 1)
    return [polar(r, a0 + (a1 - a0) * i / (n - 1), c) for i in range(n)]


def pins(phi=0.0, grow=0.0):
    """the pins as circles, wheel turned clockwise by phi"""
    return unary_union([Point(polar(R, 90 - k * PITCH - phi, W)).buffer(PR + grow, 32) for k in range(N)])


def pallets(amp=AMP):
    """(entry, exit) working shapes in anchor coordinates: the point-tooth Graham pallets shrunk by the pin radius.
    Entry (right, ~45 deg): pins move toward the arbor; locking face = its outer arc. Exit (left, ~135 deg): pins move
    away; locking face = its inner arc."""
    h, k = LIFT / 2, KAPPA / 2
    ro, ri = R0 + WI / 2, R0 - WI / 2
    a_tip = BETA - h + k
    a_sh = BETA - amp - 6.0
    entry = arc(ro, a_sh, a_tip) + [polar(ri, a_tip + LIFT)] + arc(ri, a_tip + LIFT, a_sh)
    b_tip = 180 - BETA + h - k
    b_sh = 180 - BETA + amp + 6.0
    exitp = arc(ri, b_sh, b_tip) + [polar(ro, b_tip - LIFT)] + arc(ro, b_tip - LIFT, b_sh)
    e = Polygon(entry).buffer(0).buffer(-PR, join_style=1)
    x = Polygon(exitp).buffer(0).buffer(-PR, join_style=1)
    return e, x, a_sh, b_sh


ANCHOR_INFO = {}


def pin_ring():
    return Point(W).buffer(R + PR + 0.5, 256).difference(Point(W).buffer(R - PR - 0.5, 256))


def arm_beam(a, r_end):
    return LineString([polar(ARM_IN, a), polar(r_end, a)]).buffer(ARM_W / 2, cap_style=2)


def frame(a_beam, side):
    """unit vectors along the arm and across it, toward the pallet's side"""
    u = (math.cos(math.radians(a_beam)), math.sin(math.radians(a_beam)))
    n = (-side * u[1], side * u[0])
    return u, n


def at(u, n, s_, t):
    return (u[0] * s_ + n[0] * t, u[1] * s_ + n[1] * t)


def rect(u, n, s0, s1, t0, t1):
    return Polygon([at(u, n, s0, t0), at(u, n, s1, t0), at(u, n, s1, t1), at(u, n, s0, t1)])


def t_pallet(pal, a_beam, a_sh, side):
    """the T pallet on an arm at a_beam: bar in the side slot nearest the pallet, stem out to the working shape.
    Returns dict(t=the T part, clamp=clamp outline in the wheel plane (for clearance), u_c=bar centre along the arm,
    r_b=where the arm may end, m5=[clamp screw points on the arm])"""
    u, n = frame(a_beam, side)
    start = pal.intersection(Polygon([(0, 0), polar(400, a_sh), polar(400, a_sh + side * 3.0)]))
    c = start.centroid
    u_c = c.x * u[0] + c.y * u[1]                                  # bar centred under the pallet's root
    s0, s1 = u_c - BAR_L / 2, u_c + BAR_L / 2
    bar = rect(u, n, s0, s1, 10 - SLOT_D, 10 - SLOT_D + BAR_H)
    stem_root = rect(u, n, u_c - STEM_W / 2, u_c + STEM_W / 2, 10 - SLOT_D + BAR_H - 0.01, 10 + BAR_H - SLOT_D + CLAMP_T + 1.5)
    stem = unary_union([stem_root, start]).convex_hull
    t = unary_union([bar, stem, pal]).buffer(0.8).buffer(-0.8)
    clamp_foot = rect(u, n, s0 - CLAMP_END - 3, s1 + CLAMP_END + 3, 10, 10 - SLOT_D + BAR_H + CLAMP_T)
    m5 = [at(u, n, s0 - CLAMP_END + 2, 10), at(u, n, s1 + CLAMP_END - 2, 10)]
    return dict(t=t, clamp=clamp_foot, u_c=u_c, r_b=s1 + CLAMP_END + 6, m5=m5)


def clamp_part():
    """the clamp strip, flat (x along the arm, y across the arm's face): 3.1 slot for the stem (+ travel), M5 each end"""
    L = BAR_L + 2 * CLAMP_END + 6
    g = box(-L / 2, -10, L / 2, 10).buffer(-2, join_style=2).buffer(2, join_style=1)
    sl = LineString([(-(STEM_W / 2 + ADJ_TRAVEL), 0), (STEM_W / 2 + ADJ_TRAVEL, 0)]).buffer(CLAMP_SLOT / 2, cap_style=2)
    holes = [Point(sx * (BAR_L / 2 + CLAMP_END - 2), 0).buffer(2.65, 32) for sx in (-1, 1)]
    return g.difference(unary_union([sl] + holes))


def anchor(amp=AMP, amp_max=12.0):
    """(hub plate, entry U, exit U, (entry, exit working shapes)). The anchor is 2 identical HUB PLATES sandwiching
    three 2020 beams (two arms up to the pallets, one down to the pendulum) round a stack of 608s on the fixed axle.
    The arms pass through the wheel's gap; each carries a T pallet clamped in its side slot. The arm angles are the
    nearest to the pallets that keep the beams, clamps and T's (all but the working faces) out of the pins' path over
    a +-amp_max swing, with the hub plates clear of the rings."""
    e, x, a_sh, b_sh = pallets(amp)
    ring = pin_ring()
    disc = Point(W).buffer(RING_R, 256)
    sweep = [amp_max * (i / 8 - 1) for i in range(17)]
    out = {}
    for name, pal, a0, side in (("entry", e, a_sh, +1), ("exit", x, b_sh, -1)):
        for k in range(120):
            a_b = a0 - side * 0.5 * k
            ub = t_pallet(pal, a_b, a0, side)
            r_b = ub["r_b"]
            beam = arm_beam(a_b, r_b)
            nonwork = unary_union([beam, ub["clamp"], ub["t"].difference(pal.buffer(0.3))])
            overlay = LineString([(0, 0), polar(HUB_ARM, a_b)]).buffer(ARM_W / 2 + 3, cap_style=1)   # the hub plate's arm
            if all(affinity.rotate(nonwork, th, origin=(0, 0)).intersection(ring).area < 1e-3 for th in sweep) and \
                    min(affinity.rotate(overlay, th, origin=(0, 0)).distance(disc) for th in sweep) >= HUB_CLR:
                out[name] = dict(ub, a=a_b, r_b=r_b, beam=beam)
                break
    a_be, a_bx = out["entry"]["a"], out["exit"]["a"]
    hub = unary_union([Point(0, 0).buffer(HUB_PLATE_R, 64)] +
                      [LineString([(0, 0), polar(HUB_ARM, a)]).buffer(ARM_W / 2 + 3, cap_style=1) for a in (a_be, a_bx, TAIL_A)])
    hub = hub.buffer(4).buffer(-4)
    holes = [Point(0, 0).buffer(BRG_D / 2, 64)] + [Point(polar(r, a)).buffer(2.5, 32) for a in (a_be, a_bx, TAIL_A) for r in (19, 29)]
    hub = hub.difference(unary_union(holes))
    ANCHOR_INFO.update(out, tail=arm_beam(TAIL_A, 90.0))
    return hub, out["entry"], out["exit"], (e, x)


def anchor_parts():
    """everything of the anchor that sits in the wheel's gap (for clearance checks and drawings)"""
    anchor()
    i, x = ANCHOR_INFO["entry"], ANCHOR_INFO["exit"]
    return unary_union([i["beam"], x["beam"], i["clamp"], x["clamp"], i["t"], x["t"]])


def hub_ring_clearance(amp_max=12.0):
    """how far the anchor hub plates (outside the gap) stay from the rings' edge over the swing"""
    hub = anchor()[0]
    disc = Point(W).buffer(RING_R, 256)
    return min(affinity.rotate(hub, th, origin=(0, 0)).distance(disc) for th in [amp_max * (i / 6 - 1) for i in range(13)])


def wheel():
    """one of the TWO wheel rings (identical; they sit on opposite faces of the 2020 spokes): rim with the M3 pin
    holes, 8 wood spokes over the beams (the 45-degree ones only matter if you fit those beams), an octagon hub with
    the bearing seat, M5 along each spoke into T-nuts"""
    rim = Point(W).buffer(R + PR + RIM, 128).difference(Point(W).buffer(R - PR - RIM_IN, 128))
    spokes = [LineString([W, polar(R, i * 360 / SPOKES, W)]).buffer(SPOKE_W / 2, cap_style=2) for i in range(SPOKES)]
    hub = affinity.translate(OCT, *W).buffer(2, join_style=1)
    g = unary_union([rim, hub] + spokes).buffer(3).buffer(-3)
    holes = [Point(polar(R, 90 - k * PITCH, W)).buffer(PIN_HOLE / 2, 32) for k in range(N)]
    holes.append(Point(W).buffer(BRG_D / 2, 64))
    holes += [Point(polar(r, i * 360 / SPOKES, W)).buffer(2.5, 32) for i in range(SPOKES) for r in spoke_m5()]
    return g.difference(unary_union(holes))


def spoke_m5():
    """M5 per spoke, 8 in from each end of the beam (a third one in the middle if the beam is long enough)"""
    global SPOKE_M5
    if SPOKE_M5 is None:
        a, b = HUB_A + 8, beam_reach() - 3 - 8
        n = 3 if b - a >= 36 else 2
        SPOKE_M5 = tuple(round(a + (b - a) * i / (n - 1), 1) for i in range(n))
    return SPOKE_M5


def tip_margin(amp_max=12.0):
    """how far inside the rings' edge the pallets' working tips (both ends of each impulse face, where a pin is
    caught and released) stay over the whole swing. While a pin is locked the contact sits on that pin, at R."""
    h, k = LIFT / 2, KAPPA / 2
    ro, ri = R0 + WI / 2, R0 - WI / 2
    a_tip, b_tip = BETA - h + k, 180 - BETA + h - k
    pts = [polar(ro - PR, a_tip), polar(ri - PR, a_tip + LIFT), polar(ri + PR, b_tip), polar(ro + PR, b_tip - LIFT)]
    far = 0.0
    for i in range(25):
        th = amp_max * (i / 12 - 1)
        for p in pts:
            q = affinity.rotate(Point(p), th, origin=(0, 0))
            far = max(far, math.dist(W, (q.x, q.y)))
    return RING_R - far


def hub_spacer():
    """the octagon spacer in the gap round the bearing: every spoke's inner end butts one of its flats"""
    return OCT.difference(Point(0, 0).buffer(BRG_D / 2, 64))


def beam_reach(amp_max=12.0):
    """how far out (from the wheel centre) the 2020 spokes may run: clear of the pallets and the anchor in the gap"""
    parts = anchor_parts()
    near = min(affinity.rotate(parts, th, origin=(0, 0)).distance(Point(W)) for th in [amp_max * (i / 6 - 1) for i in range(13)])
    return near


# ---------------------------------------------------------------- kinematic check (as escapement.simulate)
def simulate(amp=AMP, cycles=2, steps=240, grow_w=0.0, grow_a=0.0, design_amp=AMP, verbose=True):
    """the pendulum swings amp * cos(pi t) (one beat per unit t); the wheel, driven clockwise, turns until a pin is
    stopped. Reports per beat the wheel's advance and biggest free step (drop), the worst recoil, and runaway."""
    e, x = pallets(design_amp)[:2]
    pal = unary_union([e, x]).buffer(grow_a, join_style=2)
    pal_area = pal.area

    def hits(phi, th):
        return pins(phi, grow_w).intersection(affinity.rotate(pal, th, origin=(0, 0))).area > 1e-4

    def advance(phi, th, maxstep=PITCH):
        n = 64
        for j in range(1, n + 1):
            if hits(phi + maxstep * j / n, th):
                lo, hi = phi + maxstep * (j - 1) / n, phi + maxstep * j / n
                for _ in range(16):
                    mid = (lo + hi) / 2
                    lo, hi = (lo, mid) if hits(mid, th) else (mid, hi)
                return lo, False
        return phi + maxstep, True

    th, phi, k = amp, 0.0, 0
    while hits(phi, th) and k < 400:
        phi += 0.1
        k += 1
    phi, _ = advance(phi, th)
    recoil, runaway, beats = 0.0, False, {}
    for i in range(1, 2 * cycles * steps + 1):
        t = i / steps
        th = amp * math.cos(math.pi * t)
        if hits(phi, th):
            lo, hi = phi - PITCH / 2, phi
            for _ in range(20):
                mid = (lo + hi) / 2
                lo, hi = (lo, mid) if hits(mid, th) else (mid, hi)
            recoil = max(recoil, phi - lo)
            phi = lo
        new, free = advance(phi, th)
        if free:
            runaway = True
            break
        d = new - phi
        s = min(int(t - 1e-9), 2 * cycles - 1)
        rec = beats.setdefault(s, [0.0, 0.0])
        if d > 1e-4:
            rec[0] += d
            rec[1] = max(rec[1], d)
        phi = new
    if verbose:
        print(f"  swing +-{amp:g} deg (pallets for +-{design_amp:g}), pins {grow_w:+.2f}, pallets {grow_a:+.2f}: "
              f"{'RUNAWAY' if runaway else 'ok'}, recoil {recoil:.3f} deg; per beat: "
              + ", ".join(f"{tot:.2f} (drop {big:.2f})" for tot, big in (beats[s] for s in sorted(beats))))
    return runaway, recoil, beats


def report():
    e, x, a_sh, b_sh = pallets()
    print(f"PIN WHEEL: {N} pins d{PIN_D:g} on r {R:g} (disc {2 * (R + PR + RIM):.0f} across), pitch {PITCH:g} deg = "
          f"{2 * R * math.sin(math.radians(PITCH / 2)):.1f} mm; anchor arbor {D:.1f} below the wheel centre, pallets at r {R0:.1f}")
    print(f"pallet working width {WI - PIN_D:.2f} mm (impulse travel {WI:.2f} less the pin), lift {LIFT:g}, drop {DROP:g}, "
          f"lock {KAPPA:g} deg = {R0 * math.radians(KAPPA):.2f} mm at the pallets; arms {ARM_W:g} wide")


def emit(name, g, mat, notes, out_dir, copies=1):
    T, kerf, _ = gcode.fit(mat)
    job = gcode.job(mat)
    gk = g.buffer(kerf / 2, join_style=2)
    x0, y0, x1, y1 = gk.bounds
    cuts = []
    for pg in getattr(gk, "geoms", [gk]):                  # loose pieces (bracket inner layers) are cut too
        cuts += [gcode.Polyline([(x - x0, y - y0) for x, y in r.coords], True) for r in pg.interiors]
        cuts.append(gcode.Polyline([(x - x0, y - y0) for x, y in pg.exterior.coords], True))
    cuts = gcode.order(cuts)
    stem = gcode.name(name, x1 - x0, y1 - y0, mat)
    lines = gcode.preamble(job, title=f"{stem} -- marbles/clock/escapement_pin.py: cut {copies}",
                           notes=notes + [f"{mat}: T {T}, kerf {kerf}; X0 Y0 = bottom-left"])
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(out_dir / f"{stem}.gcode", lines)
    mins = sum(LineString(c.points).length * job.passes for c in cuts) / job.feed_mm_per_min
    print(f"{p.name}: cut {copies}, {len(cuts)} cuts, ~{mins:.0f} min each")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--pin", type=float, default=PIN_D, help="working pin diameter (4 = an M3 screw in a 3/4 mm sleeve)")
    ap.add_argument("--wood", default="ply3")
    ap.add_argument("--pallet-material", default="acrylic3")
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    globals().update(PIN_D=a.pin, PR=a.pin / 2)
    report()
    print("kinematic check:")
    for amp in (LIFT / 2 + KAPPA / 2 + 1.0, 8.0, AMP):
        simulate(amp)
    for gw, ga in ((0.15, 0.0), (-0.15, 0.0), (0.0, 0.15), (0.0, -0.15)):
        simulate(AMP, cycles=1, grow_w=gw, grow_a=ga)
    if a.check:
        return
    hub, eb, xb, _ = anchor()
    reach = beam_reach()
    ie, ix = eb, xb
    print(f"rings {2 * RING_R:g} across: the pallets' working tips stay {tip_margin():.1f} inside the rings' edge over a +-12 deg swing; "
          f"ring band outside the pin circle {RING_R - R:.1f}")
    print(f"wheel spokes (2020): {HUB_A:g} to {reach - 3:.1f} from the centre (the anchor comes to {reach:.1f} at +-12 deg): "
          f"length {reach - 3 - HUB_A:.0f}; M3 x 30-35 screws as the pins (nuts flare the rings a little at the pins)")
    print(f"anchor: axle {D:.1f} below the wheel centre; hub plates clear the rings by {hub_ring_clearance():.1f} at +-12 deg; arms (2020) at "
          f"{ie['a']:.1f} / {ix['a']:.1f} deg, {ARM_IN:g} to {ie['r_b']:.1f} from the axle = {ie['r_b'] - ARM_IN:.0f} long; tail {TAIL_A:g}; "
          f"3 x 608 stacked between the plates")
    emit("esc_pin_ring", wheel(), a.wood,
         [f"one of 2 rings: {N} M3 holes on r {R:g}, 608 seat d{BRG_D:g}, 8 spokes 20 wide over the 2020s (M5 at {spoke_m5()})",
          f"rings on opposite faces of the 2020 spokes; 3 x 608 stacked at the hub, or the octagon spacer x7"], a.out, 2)
    emit("esc_pin_hub_spacer", hub_spacer(), "mdf3",
         [f"OPTIONAL octagon round the wheel's bearings, flats {HUB_A:g} from the centre: cut 7, or stack 608s instead"], a.out, 7)
    emit("esc_pin_anchor_plate", hub, a.wood,
         [f"anchor hub plate: 608 seat, M5 along the 3 beams (arms {ie['a']:.1f} / {ix['a']:.1f} deg, tail {TAIL_A:g}); cut 2, one each side"], a.out, 2)
    for nm, ub in (("entry", eb), ("exit", xb)):
        emit(f"esc_pin_pallet_{nm}", ub["t"], a.pallet_material,
             [f"{nm} pallet: upside-down T, bar {BAR_L:g} x {BAR_H:g} sits on the floor of the arm's side T-slot, the stem carries the "
              f"working faces; slide along the slot (+-{ADJ_TRAVEL:g}) to set the lock depth"], a.out, 1)
    emit("esc_pin_pallet_clamp", clamp_part(), a.wood,
         [f"pallet clamp (cut 2, one per arm): lies on the arm's face over the T's bar, the stem through the {CLAMP_SLOT:g} slot; "
          f"M5 each end into T-nuts in the same slot"], a.out, 2)


if __name__ == "__main__":
    main()
