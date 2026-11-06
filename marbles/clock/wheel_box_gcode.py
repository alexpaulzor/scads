#!/usr/bin/env python3
"""G-code for one wheel keeper (WK) with its box (FC, TB x2, BK), nested tight.

Geometry comes from wheel_box.py (same T, KERF, FIT). The WK is placed first with
its 40-wide strip along X and the lobe pointing +Y; the other parts are dropped
greedily into the smallest bounding box (the notches beside the lobe first).

    python3 marbles/clock/wheel_box_gcode.py            # mdf3 -> marbles/gcode/wheel_box_set.gcode
    python3 marbles/clock/wheel_box_gcode.py --material ply3
    python3 marbles/clock/wheel_box_gcode.py --plain     # plain keeper -> marbles/gcode/plain_keeper.gcode
"""
import argparse
import importlib.util
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import Polygon
from shapely.ops import unary_union
from shapely.prepared import prep

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import emit_cut, load_profile, preamble, std_path, gcode  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--material", default="mdf3", help="profile id: thickness, kerf and slot fit come from it")
ap.add_argument("--t", type=float, default=None, help="override thickness")
ap.add_argument("--fit", type=float, default=None, help="override extra slot width")
ap.add_argument("--gap", type=float, default=2.0, help="clear wood between parts, mm")
ap.add_argument("--step", type=float, default=1.0, help="nesting search grid, mm")
ap.add_argument("--plain", action="store_true", help="the plain 300 x 40 keeper (PK) instead")
ap.add_argument("-o", "--out", type=Path, default=None)
args = ap.parse_args()

# load wheel_box.py as a module with the same T / FIT
sys.argv = ["wheel_box.py", "--material", args.material] + (["--t", str(args.t)] if args.t is not None else []) \
    + (["--fit", str(args.fit)] if args.fit is not None else [])
spec = importlib.util.spec_from_file_location("wheel_box", HERE / "wheel_box.py")
wb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wb)
KERF = wb.KERF
print("----")

def norm(g):
    x0, y0, _, _ = g.bounds
    return affinity.translate(g, -x0, -y0)

def k(g):  # kerf: kept wood grows by half a kerf, holes shrink
    return g.buffer(KERF / 2, join_style=2)

parts = [("WK wheel keeper", norm(k(wb.wheel_keeper_2d()))),            # (u, v) -> X along the strip, lobe +Y
         ("BK back wall", norm(k(wb.bk_2d()))),
         ("FC far cheek", norm(k(wb.cheek_2d()))),
         ("TB top wall", norm(k(wb.tb_2d()))),
         ("TB bottom wall", norm(k(wb.tb_2d())))]

if args.plain:
    parts = [("PK plain keeper", norm(k(wb.plain_keeper_2d())))]
if args.out is None:
    args.out = HERE.parent / "gcode" / ("plain_keeper.gcode" if args.plain else "wheel_box_set.gcode")
placed = [(parts[0][0], parts[0][1])]
def union_bounds(gs):
    b = [g.bounds for g in gs]
    return min(x[0] for x in b), min(x[1] for x in b), max(x[2] for x in b), max(x[3] for x in b)

for name, g in parts[1:]:
    occupied = unary_union([p for _, p in placed]).buffer(args.gap, join_style=2)
    occ = prep(occupied)
    best = None
    X0, Y0, X1, Y1 = union_bounds([p for _, p in placed])
    for rot in (0, 90, 180, 270):
        r = norm(affinity.rotate(g, rot, origin=(0, 0)))
        w, h = r.bounds[2], r.bounds[3]
        x = 0.0
        while x <= X1 + args.gap + 1e-9:
            y = 0.0
            while y <= Y1 + args.gap + 1e-9:
                bx0, by0, bx1, by1 = min(X0, x), min(Y0, y), max(X1, x + w), max(Y1, y + h)
                area = (bx1 - bx0) * (by1 - by0)
                if best is None or (area, by1, bx1) < best[0]:
                    c = affinity.translate(r, x, y)
                    if not occ.intersects(c):
                        best = ((area, by1, bx1), c, rot)
                y += args.step
            x += args.step
    placed.append((name, best[1]))
    print(f"{name}: rot {best[2]}, at ({best[1].bounds[0]:.1f}, {best[1].bounds[1]:.1f})")

X0, Y0, X1, Y1 = union_bounds([p for _, p in placed])
placed = [(n, affinity.translate(p, -X0, -Y0)) for n, p in placed]
W, H = X1 - X0, Y1 - Y0
print(f"footprint {W:.2f} x {H:.2f} mm (first part alone {parts[0][1].bounds[2]:.2f} x {parts[0][1].bounds[3]:.2f})")

# cut order: every hole / slot first (small to large), then the outlines (small to large)
holes, outers = [], []
for n, g in placed:
    for poly in ([g] if g.geom_type == "Polygon" else list(g.geoms)):
        holes += [list(r.coords) for r in poly.interiors]
        outers.append(list(poly.exterior.coords))
holes.sort(key=lambda pl: abs(Polygon(pl).area))
outers.sort(key=lambda pl: abs(Polygon(pl).area))

s2g, motion, mat, job = load_profile(args.material, 1000, None)
cuts = [s2g.Polyline(pl, True) for pl in holes + outers]
cuts = gcode.order(cuts)        # middle-out, shortest travel (quickcut/order.py)
lines = [f"; {args.out.stem} -- marbles/clock/wheel_box_gcode.py: " + ("plain keeper 300 x 40" if args.plain else "one wheel keeper + its box"),
         f"; parts: {', '.join(n for n, _ in placed)}",
         f"; T = {wb.T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
         f"kerf {KERF}, fit {wb.FIT}; X0 Y0 = bottom-left; footprint {W:.2f} x {H:.2f} mm",
         f"; {len(holes)} holes/slots first, then {len(outers)} outlines", ";"]
lines += preamble(s2g, job)
for i, c in enumerate(cuts, 1):
    lines += emit_cut(s2g, motion, c, i, len(cuts), job)
if args.out.parent == HERE.parent / "gcode":      # default location: standard name
    args.out = std_path(args.out.parent, args.out.stem, lines, mat['id'])
args.out.parent.mkdir(parents=True, exist_ok=True)
gcode.write(args.out, lines)
print(f"wrote {args.out} ({len(cuts)} cuts)")
