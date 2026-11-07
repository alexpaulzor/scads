#!/usr/bin/env python3
"""Sieve and plain keeper pieces, 3 to 10 ball holes long (90 .. 300 mm, 30 per hole).

SIEVE (sieve_<n>h): the lift_sieve strip at any length. 46 wide; ball holes d20 every 30 on
  Y = 30, first 15 from the end. Rail M5 (exactly 5.0) on Y = 10 in every other gap between
  ball holes starting with the first (X = 30, 90, 150 ...); if that misses the last gap, the
  last gap gets one too, so both ends are held (3 holes: 30, 60).
KEEPER (keeper_<n>h): same length, 40 wide.
  - Y = 10 (over the ball column): VIEW SLOTS. The old 3/4" (19.05) hole row with every other
    pair of holes joined: slot 19.05 + 5 = 24.05 long, 5 wide, then 19.05 - 5 = 14.05 solid,
    repeated, centred. 5 wide is far too narrow for a 3/4" ball to catch in.
  - Y = 30 (over the beam): rail M5 at the sieve's M5 positions for that length.
Thickness, kerf and fit come from the material profile (mdf3: 2.82 / 0.10).

    python3 marbles/clock/short_parts.py                 # -> marbles/gcode/{sieve,keeper}_<n>h_<W>x<H>.gcode, n = 3..10
    python3 marbles/clock/short_parts.py --sizes 4 7
"""
import argparse
import json
import math
import sys
from pathlib import Path

from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

PITCH, HOLE_D, M5 = 30.0, 20.0, 5.0
P34 = 19.05                        # 3/4"
SLOT_W = 5.0
SLOT_L = P34 + SLOT_W              # 24.05
SOLID = P34 - SLOT_W               # 14.05
END_MIN = 5.0                      # wood from a view slot to the end of the piece, at least


def rail_m5_x(n):
    """every other gap between ball holes from the first; plus the last gap if that misses it"""
    gaps = [PITCH * (i + 1) for i in range(n - 1)]
    xs = gaps[::2]
    if gaps and xs[-1] != gaps[-1]:
        xs.append(gaps[-1])
    return xs


def view_slots(L, y, x0=0.0):
    """centred row of view slots (as shapes) along [x0, x0 + L] at height y"""
    m = int((L - 2 * END_MIN + SOLID) // (SLOT_L + SOLID))
    span = m * SLOT_L + (m - 1) * SOLID
    s0 = x0 + (L - span) / 2
    out = []
    for i in range(m):
        a = s0 + i * (SLOT_L + SOLID) + SLOT_W / 2
        out.append(LineString([(a, y), (a + P34, y)]).buffer(SLOT_W / 2, 24))
    return out


def sieve(n):
    L = n * PITCH
    g = box(0, 0, L, 46.0)
    holes = [Point(PITCH / 2 + PITCH * i, 30.0).buffer(HOLE_D / 2, 128) for i in range(n)]
    holes += [Point(x, 10.0).buffer(M5 / 2, 48) for x in rail_m5_x(n)]
    return g.difference(unary_union(holes))


def keeper(n):
    L = n * PITCH
    g = box(0, 0, L, 40.0)
    cuts = view_slots(L, 10.0) + [Point(x, 30.0).buffer(M5 / 2, 48) for x in rail_m5_x(n)]
    return g.difference(unary_union(cuts))


# ---------------------------------------------------------------- DOUBLE sieve / keeper (two lanes in parallel)
# 71.8 wide = a 20 mm beam band in the middle + on each side a 20 mm ball hole and 5.9 of wood outside it.
# x along the length (positions every PITCH, first PITCH/2 from the end), y across.
DBL_BEAM, DBL_WOOD = 20.0, 5.9
DBL_W = round(DBL_BEAM + 2 * (HOLE_D + DBL_WOOD), 6)                       # 71.8
DBL_HOLE_Y = (round(DBL_WOOD + HOLE_D / 2, 6), round(DBL_W - DBL_WOOD - HOLE_D / 2, 6))  # 15.9, 55.9: the two lanes
DBL_M5_Y = round(DBL_W / 2, 6)                                               # 35.9: the beam bolts
PORT, TAB, PORT_BOLT = 20.0, 10.0, 20.0                            # the standard port interface (feeder.scad)


def port_cut(cx, cy, T, fit=0.0):
    """the port interface as one cut: PORT x PORT opening + a TAB slot T + fit deep on each side"""
    h, d = PORT / 2, T + fit
    return unary_union([box(cx - h, cy - h, cx + h, cy + h),
                        box(cx + h - 0.01, cy - TAB / 2, cx + h + d, cy + TAB / 2),
                        box(cx - h - d, cy - TAB / 2, cx - h + 0.01, cy + TAB / 2),
                        box(cx - TAB / 2, cy + h - 0.01, cx + TAB / 2, cy + h + d),
                        box(cx - TAB / 2, cy - h - d, cx + TAB / 2, cy - h + 0.01)])


def double_sieve(n, kinds=None, T=2.82, fit=0.0):
    """(shape, notes). kinds: one of "hole" | "solid" | "port" per position (default all holes), both lanes.
    Beam M5 on the centre line at the rail pattern; a port's corner bolts land on the centre line too
    (shared by both lanes' ports) and replace any rail M5 within 2 hole diameters of them; corner bolts
    that fall off the plate are left out (and reported)."""
    kinds = kinds or ["hole"] * n
    L = n * PITCH
    cuts, m5, notes = [], [], []
    for i, k in enumerate(kinds):
        x = PITCH / 2 + PITCH * i
        for y in DBL_HOLE_Y:
            if k == "hole":
                cuts.append(Point(x, y).buffer(HOLE_D / 2, 128))
            elif k == "port":
                cuts.append(port_cut(x, y, T, fit))
                for bx in (x - PORT_BOLT, x + PORT_BOLT):
                    for by in (y - PORT_BOLT, y + PORT_BOLT):
                        if 0 < by < DBL_W:
                            m5.append((round(bx, 6), round(by, 6)))
                        else:
                            notes.append(f"port at x {x:g}: corner bolt ({bx:g}, {by:g}) is off the plate, left out")
    m5 = sorted(set(m5))
    for rx in rail_m5_x(n):
        if all(abs(rx - bx) > 2 * M5 for bx, _ in m5):
            m5.append((rx, DBL_M5_Y))
    cuts += [Point(p).buffer(M5 / 2, 48) for p in m5]
    return box(0, 0, L, DBL_W).difference(unary_union(cuts)), sorted(set(notes)), sorted(m5)


def min_web(g):
    best = None
    rs = [LineString(r.coords) for r in g.interiors]
    ext = LineString(g.exterior.coords)
    for i, r in enumerate(rs):
        for o in [ext] + rs[i + 1:]:
            d = r.distance(o)
            best = d if best is None else min(best, d)
    return best


def main():
    from laser_parts import emit_cut, load_profile, material_fit, preamble, gcode
    ap = argparse.ArgumentParser()
    ap.add_argument("--material", default="mdf3")
    ap.add_argument("--sizes", type=int, nargs="+", default=list(range(3, 11)), help="ball holes per piece")
    args = ap.parse_args()
    T, KERF, _ = material_fit(args.material)
    s2g, motion, mat, job = load_profile(args.material, 1000, None)
    out_dir = HERE.parent / "gcode"
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"T = {T}, KERF = {KERF}")
    thumbs = []
    for n in args.sizes:
        for kind, g in (("sieve", sieve(n)), ("keeper", keeper(n))):
            gk = g.buffer(KERF / 2, join_style=2)
            x0, y0, x1, y1 = gk.bounds
            name = f"{kind}_{n}h_{math.ceil(x1 - x0 - 1e-9)}x{math.ceil(y1 - y0 - 1e-9)}_{args.material}"
            loops = [list(r.coords) for r in gk.interiors]
            loops.sort(key=lambda pl: abs(Polygon(pl).area))
            loops.append(list(gk.exterior.coords))
            loops = [[(x - x0, y - y0) for x, y in pl] for pl in loops]
            cuts = [s2g.Polyline(pl, True) for pl in loops]
            note = (f"{n} ball holes, rail M5 at X {rail_m5_x(n)} Y 10" if kind == "sieve" else
                    f"view slots {SLOT_L:g} x {SLOT_W:g} on Y 10 ({len(view_slots(n * PITCH, 10))}), rail M5 at X {rail_m5_x(n)} Y 30")
            lines = [f"; {name} -- marbles/clock/short_parts.py: {kind}, {note}",
                     f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
                     f"kerf {KERF}; X0 Y0 = bottom-left; {x1 - x0:.2f} x {y1 - y0:.2f} mm", ";"]
            lines += preamble(s2g, job)
            for i, c in enumerate(cuts, 1):
                lines += emit_cut(s2g, motion, c, i, len(cuts), job)
            gcode.write((out_dir / f"{name}.gcode"), lines)
            print(f"{name}.gcode: {note}; narrowest web {min_web(g):.2f}")
            thumbs.append({"key": name, "polys": [{"outer": list(g.exterior.coords), "holes": [list(h.coords) for h in g.interiors]}]})
    scenes = HERE.parent / "views" / "scenes"
    scenes.mkdir(parents=True, exist_ok=True)
    json.dump(thumbs, open(scenes / "rail_parts.json", "w"))


if __name__ == "__main__":
    main()
