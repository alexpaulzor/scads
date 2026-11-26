#!/usr/bin/env python3
"""Clock train, PIN-WHEEL version (option B): every sun is a pin wheel (2.05 wire pins held between TWO ply discs, the
ends bent over on the discs' outer faces), every planet a laminated ply gear (2 layers) with teeth cut as the envelope
of the pins, so each mesh is wood on steel and a planet can float along the pins without losing the mesh.

Differential suns, as before: carrier in, sun A fixed, sun B out, out / carrier = 1 - ZA*PB / (PA*ZB).
Both stages share A = 72 (one carrier design) and the same output sun (60 pins at pitch 2*pi): sun B gets pitch 2*pi,
sun A the pitch that keeps the centre distance.

Stack along the rod, one stage (back -> front):
  back carrier | bend room | sun A back disc | gap: planet A (2 layers) | sun A front disc | bend room x2 |
  sun B back disc | gap: planet B (2 layers) | sun B front disc | front carrier
The planet's gear A (2 layers) and gear B (2 layers) are clamped by ONE M3 bolt + nuts round a bought spacer (which
passes the two middle discs inside their rims); that bolt is the planet's shaft, turning in holes in both carriers.
Everything else that only holds parts apart is a bought M3 spacer too (SP_* below).

    python3 marbles/clock/clock_pins.py   # numbers + clock_pins_profiles.scad (used by clock_train.scad)
"""
import math
from pathlib import Path

from shapely import affinity
from shapely.geometry import Point
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
T = 2.63                  # ply3
PIN = 2.05                # wire
PIN_HOLE = 2.2            # holes for the wire in the discs and planets
PIN_CLR = 0.15            # extra radius round each pin when cutting the planet teeth
RIM = 2.5                 # disc web outside the pin holes
BEND = 2.05               # a bent-over pin end stands this proud of its disc face
A = 72.0
STAGES = {"minute": dict(ZA=59, PA=12, ZB=60, PB=12, N=3), "hour": dict(ZA=55, PA=12, ZB=60, PB=12, N=3)}
CB = 3.0                  # back carrier to sun A back disc: room for the bent pin ends
# bought M3 spacers (lengths): everything that only holds parts apart is a spacer on an M3 bolt, not cut ply
SP_SUN = 8.0              # between a sun's two discs (round a planet gear: 2 layers + 1.37 each side)
SP_HUB = 15.0             # planet: gear A front face to gear B back face, round the planet's M3 bolt
SP_CAGE = 40.0            # back carrier to front carrier (tie standoffs between the planets)
SP_D = 7.0                # spacer outside diameter (as drawn; the planet hub spacer must pass inside the disc rims)
G = SP_SUN
M = SP_HUB - SP_SUN       # sun A front disc to sun B back disc: two rows of bent ends (2 x 2.05) + clearance
FG = SP_CAGE - (CB + 4 * T + 2 * G + M)   # sun B front disc to front carrier
HUB_R = SP_D / 2
TIP_W = 0.8               # planet tooth tip width (sets the addendum)


def pitch(Z, P, which):
    """circular pitch of sun A or B: B gets 2*pi, A keeps the centre distance."""
    return 2 * math.pi * A / (Z + P)


def sun(Z, p):
    R = Z * p / (2 * math.pi)
    return dict(Z=Z, p=p, R=R, rim=R + PIN_HOLE / 2 + RIM)


def planet_profile(P, Z, p, steps=900):
    """planet (P teeth) cut by the pins of a Z-pin wheel at pitch p: blank disc minus every pin position through
    one planet turn. Tip radius = largest that leaves TIP_W of land on the tip."""
    r, R = P * p / (2 * math.pi), Z * p / (2 * math.pi)
    pin = Point(0, 0).buffer(PIN / 2 + PIN_CLR, 32)
    cut = []
    span = 2 * math.pi * r / R + 2 * math.pi / Z
    for i in range(steps + 1):
        t = -span / 2 + span * i / steps          # wheel turn
        beta = -t * R / r                         # planet turn (external mesh)
        j0 = round(-t * Z / (2 * math.pi))
        for j in range(j0 - 3, j0 + 4):
            a = t + j * 2 * math.pi / Z         # pin angle about the wheel centre (wheel at (-A, 0); angle 0 faces the planet)
            x, y = -(R + r) + R * math.cos(a), R * math.sin(a)
            c, s = math.cos(-beta), math.sin(-beta)
            cut.append(affinity.translate(pin, c * x - s * y, s * x + c * y))
    cut = unary_union(cut)
    best = None
    for k in range(60):
        ra = r + 0.5 + k * 0.05
        g = Point(0, 0).buffer(ra, 256).difference(cut)
        ring = Point(0, 0).buffer(ra, 256).difference(Point(0, 0).buffer(ra - 0.05, 256))
        land = ring.intersection(g)
        w = min(geom.length for geom in getattr(land, "geoms", [land])) / 2 if not land.is_empty else 0
        if w < TIP_W:
            break
        best = (ra, g)
    return r, best[0], best[1]


def contact_ratio(P, Z, p, ra):
    """planet turn while a pin centre stays inside the tip circle (+ pin radius), over one tooth angle (one side of the
    line of centres; the profile is symmetric, so either drive direction)."""
    r, R = P * p / (2 * math.pi), Z * p / (2 * math.pi)
    best = 0
    for i in range(2000):
        t = i * 0.0005
        a = t
        x, y = -(R + r) + R * math.cos(a), R * math.sin(a)
        if math.hypot(x, y) > ra + PIN / 2 * 0.5:
            break
        best = t * R / r
    return best / (2 * math.pi / P)


def stage_numbers(S):
    a, b = sun(S["ZA"], pitch(S["ZA"], S["PA"], "A")), sun(S["ZB"], pitch(S["ZB"], S["PB"], "B"))
    return a, b


def pts(poly):
    return "[" + ",".join(f"[{x:.3f},{y:.3f}]" for x, y in list(poly.exterior.coords)[:-1]) + "]"


if __name__ == "__main__":
    out = ["// generated by clock_pins.py: planet gear outlines (centre at the origin, a tooth on +x)"]
    for name, S in STAGES.items():
        a, b = stage_numbers(S)
        ratio = 1 - S["ZA"] * S["PB"] / (S["PA"] * S["ZB"])
        hub_max = A - max(a["rim"], b["rim"]) - 1
        print(f"{name}: out/carrier = 1 - {S['ZA']}*{S['PB']}/({S['PA']}*{S['ZB']}) = {ratio:.6f} (1/{1/ratio:.3f})")
        for lay, sn, P in (("A", a, S["PA"]), ("B", b, S["PB"])):
            r, ra, g = planet_profile(P, sn["Z"], sn["p"])
            g = affinity.rotate(g, 180 / P, origin=(0, 0))      # a tooth on +x (and on -x, facing the sun at angle 0)
            cr = contact_ratio(P, sn["Z"], sn["p"], ra)
            print(f"  sun {lay}: {sn['Z']} pins, pitch {sn['p']:.3f}, pin circle r {sn['R']:.3f}, disc r {sn['rim']:.2f}, "
                  f"gap between pins {sn['p'] - PIN:.2f}; planet {P}: pitch r {r:.3f}, tip r {ra:.2f}, contact ratio ~{cr:.2f}")
            out.append(f"function planet_{name}_{lay}() = {pts(g.simplify(0.02))};")
            out.append(f"{name}_{lay}_R = {sn['R']:.4f}; {name}_{lay}_RIM = {sn['rim']:.4f}; {name}_{lay}_TIP = {ra:.3f};")
        print(f"  hub ring r <= A - max disc r - 1 = {A} - {max(a['rim'], b['rim']):.2f} - 1 = {hub_max:.2f} (using {HUB_R})")
        assert HUB_R <= hub_max
    assert M >= 2 * BEND + 0.5 and FG >= 0.5, (M, FG)
    depth = T + CB + T + G + T + M + T + G + T + FG + T
    print(f"between the suns {M:.2f} for 2 rows of bent ends ({2 * BEND:.2f}); sun B front disc to front carrier {FG:.2f}")
    print(f"stage depth {depth:.2f}; sun pin span (outer faces) {2*T+G:.2f}; planet stack {4*T + SP_HUB:.2f}")
    (HERE / "clock_pins_profiles.scad").write_text("\n".join(out) + "\n")
    print("wrote clock_pins_profiles.scad")
