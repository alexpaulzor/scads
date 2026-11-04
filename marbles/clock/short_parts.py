#!/usr/bin/env python3
"""Short sieve and keeper pieces, 3 / 4 / 5 ball holes long.

SIEVE (short_sieve_N): the lift_sieve strip cut short. 46 wide, length N x 30
  (ball holes d20 every 30 on Y = 30, first 15 from the end). M5 (exactly 5.0)
  on Y = 10 in the first and last gap between ball holes (30 in from each end),
  so a 3-hole piece has 2 M5 30 apart.
KEEPER (short_keeper_N): same length, 40 wide.
  - row Y = 10: M5 every 3/4" (19.05), centred, at least 10 from the ends
  - row Y = 30: M5 at the sieve's M5 positions for that length
Thickness, kerf and fit come from the material profile (mdf_3mm: 3.1 / 0.10).

    python3 marbles/clock/short_parts.py            # -> marbles/gcode/short_sieve_{3,4,5}.gcode, short_keeper_{3,4,5}.gcode
    python3 marbles/clock/short_parts.py --sizes 3 6
"""
import argparse
import json
import sys
from pathlib import Path

from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import emit_cut, load_profile, material_fit, preamble  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--material", default="mdf_3mm")
ap.add_argument("--sizes", type=int, nargs="+", default=[3, 4, 5], help="ball holes per piece")
args = ap.parse_args()
T, KERF, _ = material_fit(args.material)

PITCH, HOLE_D, M5 = 30.0, 20.0, 5.0
P34 = 19.05


def m5_x(n):
    """first and last gap between ball holes (one gap if only 2 holes)"""
    gaps = [PITCH * (i + 1) for i in range(n - 1)]
    return sorted({gaps[0], gaps[-1]})


def sieve(n):
    L = n * PITCH
    g = box(0, 0, L, 46.0)
    holes = [Point(PITCH / 2 + PITCH * i, 30.0).buffer(HOLE_D / 2, 128) for i in range(n)]
    holes += [Point(x, 10.0).buffer(M5 / 2, 48) for x in m5_x(n)]
    return g.difference(unary_union(holes))


def keeper(n):
    L = n * PITCH
    g = box(0, 0, L, 40.0)
    k = int((L - 20) // P34) + 1
    x0 = (L - P34 * (k - 1)) / 2
    row10 = [x0 + P34 * i for i in range(k)]
    holes = [Point(x, 10.0).buffer(M5 / 2, 48) for x in row10] + [Point(x, 30.0).buffer(M5 / 2, 48) for x in m5_x(n)]
    return g.difference(unary_union(holes)), row10


def min_web(g):
    best = None
    rs = [LineString(r.coords) for r in g.interiors]
    ext = LineString(g.exterior.coords)
    for i, r in enumerate(rs):
        for o in [ext] + rs[i + 1:]:
            d = r.distance(o)
            best = d if best is None else min(best, d)
    return best


s2g, motion, mat, job = load_profile(args.material, 1000, None)
out_dir = HERE.parent / "gcode"
out_dir.mkdir(parents=True, exist_ok=True)
thumbs = []
print(f"T = {T}, KERF = {KERF}")
for n in args.sizes:
    kp, row10 = keeper(n)
    for name, g, note in ((f"short_sieve_{n}", sieve(n), f"sieve, {n} ball holes, M5 at x {m5_x(n)} y 10"),
                          (f"short_keeper_{n}", kp, f"keeper, M5 y10 every 19.05 at x {[round(x, 2) for x in row10]}; "
                                                   f"y30 at x {m5_x(n)}")):
        gk = g.buffer(KERF / 2, join_style=2)
        x0, y0, x1, y1 = gk.bounds
        loops = [list(r.coords) for r in gk.interiors] + [list(gk.exterior.coords)]
        loops = [[(x - x0, y - y0) for x, y in pl] for pl in loops]
        loops.sort(key=lambda pl: abs(Polygon(pl).area))
        cuts = [s2g.Polyline(pl, True) for pl in loops]
        lines = [f"; {name} -- marbles/clock/short_parts.py: {note}",
                 f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
                 f"kerf {KERF}; X0 Y0 = bottom-left; {x1 - x0:.2f} x {y1 - y0:.2f} mm", ";"]
        lines += preamble(s2g, job)
        for i, c in enumerate(cuts, 1):
            lines += emit_cut(s2g, motion, c, i, len(cuts), job)
        lines += s2g._footer()
        (out_dir / f"{name}.gcode").write_text("\n".join(lines))
        print(f"{name}.gcode: {x1 - x0:.2f} x {y1 - y0:.2f} mm; {note}; narrowest web {min_web(g):.2f}")
        thumbs.append({"key": name, "name": "", "per_fork": 1, "bounds": g.bounds,
                       "polys": [{"outer": list(g.exterior.coords), "holes": [list(h.coords) for h in g.interiors]}]})
scenes = HERE.parent / "views" / "scenes"
scenes.mkdir(parents=True, exist_ok=True)
json.dump({"parts": thumbs, "T": T}, open(scenes / "short_thumbs.json", "w"))
