#!/usr/bin/env python3
"""Wire bending form: a rounded rectangle with a different radius at each corner (15, 30, 45, 60 by default), straight
sides between them. Bend a wire round a corner for a quarter turn at that radius. Optional lip plates (the same shape
grown by LIP) go either side of the form to make a groove the wire can't jump out of: lip / form / lip, M5 bolts.
Corner marks: 1..4 small holes near each corner, smallest radius = 1.

    python3 marbles/clock/bend_jig.py      # -> marbles/gcode/bend_form_<W>x<H>_ply3.gcode, bend_lips_x2_<W>x<H>_ply3.gcode
"""
import argparse
import math
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import gcode  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--radii", type=float, nargs=4, default=[15, 30, 45, 60], help="corner radii (form edge = inside of the bend)")
ap.add_argument("--straight", type=float, default=10.0, help="least straight run on every side")
ap.add_argument("--lip", type=float, default=2.5, help="lip plates stand this far proud of the form (groove depth)")
ap.add_argument("--wire", type=float, default=2.05)
ap.add_argument("--material", default="ply3")
args = ap.parse_args()

M5 = 5.0
WOOD = 8.0


def layout(radii):
    """corner order (BL, BR, TR, TL) and size: the biggest radius between the two smallest gives the smallest plate"""
    r = sorted(radii)                        # a <= b <= c <= d
    order = [r[0], r[3], r[1], r[2]]         # BL a, BR d, TR b, TL c: d's neighbours are a and b
    bl, br, tr, tl = order
    W = max(bl + br, tl + tr) + args.straight
    H = max(bl + tl, br + tr) + args.straight
    return order, W, H


def rounded_rect(W, H, order):
    bl, br, tr, tl = order
    pts = []
    def arc(cx, cy, r, a0, a1):
        for i in range(41):
            a = math.radians(a0 + (a1 - a0) * i / 40)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    arc(bl, bl, bl, 180, 270)
    arc(W - br, br, br, 270, 360)
    arc(W - tr, H - tr, tr, 0, 90)
    arc(tl, H - tl, tl, 90, 180)
    return Polygon(pts)


def marks(W, H, order):
    """n 2.5 holes near corner n (n = rank of its radius), 8 in from the edge along the corner's bisector"""
    rank = {r: i + 1 for i, r in enumerate(sorted(order))}
    out = []
    corners = [((1, 1), (0, 0)), ((-1, 1), (W, 0)), ((-1, -1), (W, H)), ((1, -1), (0, H))]
    for r, ((sx, sy), (x0, y0)) in zip(order, corners):
        cx, cy = x0 + sx * r, y0 + sy * r                    # arc centre
        d = r - WOOD                                          # from the arc centre toward the corner
        bx, by = cx - sx * d / math.sqrt(2), cy - sy * d / math.sqrt(2)
        n = rank[r]
        tx, ty = sx / math.sqrt(2), -sy / math.sqrt(2)       # along the edge
        for k in range(n):
            o = (k - (n - 1) / 2) * 4.0
            out.append(Point(bx + tx * o, by + ty * o).buffer(1.25, 24))
    return out


def bolts(shape, W, H):
    """4 M5 on a 30 square round the middle (same holes through form and lips): clear of the corner marks"""
    return [Point(W / 2 + sx * 15, H / 2 + sy * 15) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]


def write(name, polys, note):
    T, kerf, _ = gcode.fit(args.material)
    job = gcode.job(args.material)
    gs = [p.buffer(kerf / 2, join_style=2) for p in polys]
    x0 = min(g.bounds[0] for g in gs); y0 = min(g.bounds[1] for g in gs)
    x1 = max(g.bounds[2] for g in gs); y1 = max(g.bounds[3] for g in gs)
    cuts = []
    for g in gs:
        cuts += [gcode.Polyline([(x - x0, y - y0) for x, y in r.coords], True) for r in g.interiors]
        cuts.append(gcode.Polyline([(x - x0, y - y0) for x, y in g.exterior.coords], True))
    cuts = gcode.order(cuts)
    stem = gcode.name(name, x1 - x0, y1 - y0, args.material)
    lines = gcode.preamble(job, title=f"{stem} -- marbles/clock/bend_jig.py", notes=[note, f"{args.material}: T {T}, kerf {kerf}; X0 Y0 = bottom-left"])
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(HERE.parent / "gcode" / f"{stem}.gcode", lines)
    print(f"  {p.name}: {len(cuts)} cuts")
    return p


def main():
    order, W, H = layout(args.radii)
    form0 = rounded_rect(W, H, order)
    holes = bolts(form0, W, H)
    lip0 = form0.buffer(args.lip, 64)
    hm = unary_union([h.buffer(M5 / 2, 48) for h in holes])
    form = form0.difference(hm).difference(unary_union(marks(W, H, order)))
    lip = lip0.difference(hm)
    rc = [r + args.wire / 2 for r in order]
    print(f"form {W:g} x {H:g}: corners BL {order[0]:g}, BR {order[1]:g}, TR {order[2]:g}, TL {order[3]:g} "
          f"(wire centreline {', '.join(f'{x:.2f}' for x in rc)}); straight runs "
          f"{W - order[0] - order[1]:g} / {H - order[1] - order[2]:g} / {W - order[2] - order[3]:g} / {H - order[3] - order[0]:g}; "
          f"M5 at {[(round(p.x, 1), round(p.y, 1)) for p in holes]}")
    write("bend_form", [form], f"bend form: corner radii {order} (BL, BR, TR, TL; 1..4 dots = smallest..largest), M5 x4")
    gap = 3.0
    l2 = [lip, affinity.translate(lip, lip.bounds[2] - lip.bounds[0] + gap, 0)]
    write("bend_lips_x2", l2, f"2 lip plates: the form grown {args.lip:g} (groove depth for a {args.wire:g} wire): lip / form / lip, M5 x4")


if __name__ == "__main__":
    main()
