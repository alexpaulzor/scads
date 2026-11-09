#!/usr/bin/env python3
"""PIN-WHEEL deadbeat escapement, sized for soft thin stock (WIP, untested).

Why: the Graham deadbeat in escapement.py needs slim wooden teeth and slim pallets. Here the escape wheel is a
LANTERN-style disc carrying N steel PINS (rod, nails or smooth bolt shanks) on a big circle, so every working contact
is a steel pin on a pallet, and nothing in wood has to be thin:
  - ESCAPE WHEEL: a spoked disc (2 laminated layers) with N pin holes; the pins stand out of its front face into the
    anchor's plane. 30 pins: 1 rev/min with a seconds pendulum (the 1 m spine), so a seconds hand fits its arbor.
  - ANCHOR: a thick-armed rocker on the pendulum's arbor (below the wheel, as in escapement.py), its arms spanning
    7.5 pins. Deadbeat: the locking faces are arcs about the anchor arbor (no recoil), lift on inclined impulse faces.
  - PALLETS: separate blocks bolted to the arm ends through radial SLOTS (adjust the lock depth with a screwdriver),
    cut from a harder material than the anchor (black acrylic by default) - or face them with brass / steel shim.
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
R = 130.0              # pin-centre radius (wheel ~280 across: fits a 292 sheet)
PIN_D = 4.0            # steel pin diameter
SPAN = 7.5             # anchor spans 7.5 pins (90 deg): the classic Graham proportion
LIFT = 3.0             # anchor degrees during impulse
DROP = 1.5             # free wheel degrees per beat after impulse
KAPPA = 1.0            # lock depth (anchor degrees) a pallet already has when the other drops
AMP = 8.0              # design swing, deg each side (the check also runs smaller and larger)
ARM_W = 16.0           # anchor arm width (soft wood: wide)
RIM = 9.0              # wheel rim wood outside the pin circle
RIM_IN = 12.0          # rim band inside the pin circle
SPOKES = 6
SPOKE_W = 14.0
HUB_R = 22.0
ARBOR_D = 8.1          # 8 mm arbor
PAL_BOLT = 3.2         # M3 pallet bolts
PAL_ADJ = 3.0          # pallet slot length (radial adjustment)
SHEET = (300.0, 292.0)

PITCH = 360.0 / N
D = R / math.cos(math.radians(SPAN * PITCH / 2))       # anchor arbor to wheel centre
W = (0.0, D)
R0 = math.sqrt(D * D - R * R)                          # anchor arbor to the tangent points (pallet radius)
WI = R * math.radians(PITCH / 2 - DROP)                # radial impulse travel at the pallets
PR = PIN_D / 2


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
    a_tip = 45 - h + k
    a_sh = 45 - amp - 6.0
    entry = arc(ro, a_sh, a_tip) + [polar(ri, a_tip + LIFT)] + arc(ri, a_tip + LIFT, a_sh)
    b_tip = 135 + h - k
    b_sh = 135 + amp + 6.0
    exitp = arc(ri, b_sh, b_tip) + [polar(ro, b_tip - LIFT)] + arc(ro, b_tip - LIFT, b_sh)
    e = Polygon(entry).buffer(0).buffer(-PR, join_style=1)
    x = Polygon(exitp).buffer(0).buffer(-PR, join_style=1)
    return e, x, a_sh, b_sh


def pallet_block(pal, a_end, side):
    """a pallet block: the working shape plus a tail running back along the arm with 2 radial slots"""
    tail_a = a_end - side * 7.0                          # tail extends away from the wheel along the circle
    tail = Polygon(arc(R0 + 8, a_end + side * 1.0, tail_a) + arc(R0 - 8, tail_a, a_end + side * 1.0))
    g = unary_union([pal, tail]).buffer(1.0).buffer(-1.0)
    slots, centres = [], []
    for da in (2.0, 5.5):
        a = a_end - side * da
        c0, c1 = polar(R0 - PAL_ADJ / 2, a), polar(R0 + PAL_ADJ / 2, a)
        slots.append(LineString([c0, c1]).buffer(PAL_BOLT / 2, 24))
        centres.append(polar(R0, a))
    return g.difference(unary_union(slots)), centres


def anchor(amp=AMP):
    """(anchor body, entry block, exit block): the body = hub + 2 wide arms ending under the pallet blocks' tails,
    with M3 holes at the slot centres; a crutch tail down to the pendulum"""
    e, x, a_sh, b_sh = pallets(amp)
    eb, ec = pallet_block(e, a_sh, +1)
    xb, xc = pallet_block(x, b_sh, -1)
    arm_e = LineString([(0, 0), polar(R0, a_sh - 6.0)]).buffer(ARM_W / 2, cap_style=1)
    arm_x = LineString([(0, 0), polar(R0, b_sh + 6.0)]).buffer(ARM_W / 2, cap_style=1)
    pad_e = Polygon(arc(R0 + 8, a_sh - 1.0, a_sh - 8.5) + arc(R0 - 8, a_sh - 8.5, a_sh - 1.0))
    pad_x = Polygon(arc(R0 + 8, b_sh + 1.0, b_sh + 8.5) + arc(R0 - 8, b_sh + 8.5, b_sh + 1.0))
    hub = Point(0, 0).buffer(20, 64)
    tail = box(-9, -70, 9, 0)
    body = unary_union([arm_e, arm_x, pad_e, pad_x, hub, tail]).buffer(2).buffer(-2)
    holes = [Point(0, 0).buffer(ARBOR_D / 2, 48)] + [Point(c).buffer(PAL_BOLT / 2, 24) for c in ec + xc]
    holes += [Point(0, y).buffer(2.6, 24) for y in (-45, -60)]           # crutch / pendulum bolts
    body = body.difference(unary_union(holes))
    # window the arms (lighter, and you can see through them)
    for a in (a_sh - 6.0, b_sh + 6.0):
        win = LineString([polar(32, a), polar(R0 - 22, a)]).buffer(ARM_W / 2 - 5, cap_style=1)
        body = body.difference(win)
    return body, eb, xb, (e, x)


def wheel():
    """the escape wheel disc: rim with the pin holes, spokes, hub"""
    rim = Point(W).buffer(R + PR + RIM, 128).difference(Point(W).buffer(R - PR - RIM_IN, 128))
    spokes = [LineString([W, polar(R, 90 - i * 360 / SPOKES + 30, W)]).buffer(SPOKE_W / 2) for i in range(SPOKES)]
    g = unary_union([rim, Point(W).buffer(HUB_R, 64)] + spokes).buffer(3).buffer(-3)
    holes = [Point(polar(R, 90 - k * PITCH, W)).buffer(PR, 32) for k in range(N)]
    holes += [Point(W).buffer(ARBOR_D / 2, 48)] + [Point(polar(14, 45 + 90 * i, W)).buffer(1.6, 16) for i in range(4)]
    return g.difference(unary_union(holes))


# ---------------------------------------------------------------- kinematic check (as escapement.simulate)
def simulate(amp=AMP, cycles=2, steps=240, grow_w=0.0, grow_a=0.0, design_amp=AMP, verbose=True):
    """the pendulum swings amp * cos(pi t) (one beat per unit t); the wheel, driven clockwise, turns until a pin is
    stopped. Reports per beat the wheel's advance and biggest free step (drop), the worst recoil, and runaway."""
    e, x = anchor(design_amp)[3]
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
    cuts = [gcode.Polyline([(x - x0, y - y0) for x, y in r.coords], True) for r in gk.interiors]
    cuts.append(gcode.Polyline([(x - x0, y - y0) for x, y in gk.exterior.coords], True))
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
    ap.add_argument("--wood", default="ply3")
    ap.add_argument("--pallet-material", default="acrylic3")
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    report()
    print("kinematic check:")
    for amp in (LIFT / 2 + KAPPA / 2 + 1.0, 3.0, AMP, AMP + 4.0):
        simulate(amp)
    for gw, ga in ((0.15, 0.0), (-0.15, 0.0), (0.0, 0.15), (0.0, -0.15)):
        simulate(AMP, cycles=1, grow_w=gw, grow_a=ga)
    if a.check:
        return
    body, eb, xb, _ = anchor()
    emit("esc_pin_wheel", wheel(), a.wood, [f"{N} pin holes d{PIN_D:g} on r {R:g} (test the press fit first); 2 layers glued"],
         a.out, 2)
    emit("esc_pin_anchor", body, a.wood, [f"anchor body, arms span {SPAN:g} pins; 3 layers glued; M3 holes for the pallet blocks"],
         a.out, 3)
    emit("esc_pin_pallet_entry", eb, a.pallet_material, ["entry (right) pallet block: radial slots for the lock depth"], a.out)
    emit("esc_pin_pallet_exit", xb, a.pallet_material, ["exit (left) pallet block: radial slots for the lock depth"], a.out)


if __name__ == "__main__":
    main()
