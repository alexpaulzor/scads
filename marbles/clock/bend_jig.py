#!/usr/bin/env python3
"""Wire bending form: a rounded rectangle with a different radius at each corner (15, 30, 45, 60 by default), straight
sides between them. Bend a wire round a corner for a quarter turn at that radius. Optional lip plates (the same shape
grown by LIP) go either side of the form to make a groove the wire can't jump out of: lip / form / lip, M5 bolts.
Ring jig built in (as the D jig): ring hole + iron hole, the mandrel core cut in place; the top lip has a window
over it, the bottom lip a rod hole under the core. Etched marks (form and the top lip): crosshairs at each corner's arc centre, its radius in digits, long ticks where the
curve starts and ends, short ticks at 30 / 45 / 60 deg round it.

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
VIBES = Path("/home/user/cnc_vibes") if Path("/home/user/cnc_vibes").exists() else HERE.parents[2] / "cnc_vibes"
sys.path.insert(0, str(VIBES / "cnc_calibrate"))
from spiral_cal import _label_strokes  # noqa: E402  (digit stroke font)

ap = argparse.ArgumentParser()
ap.add_argument("--radii", type=float, nargs=4, default=[15, 30, 45, 60], help="corner radii (form edge = inside of the bend)")
ap.add_argument("--straight", type=float, default=20.0, help="least straight run on every side")
ap.add_argument("--lip", type=float, default=2.5, help="lip plates stand this far proud of the form (groove depth)")
ap.add_argument("--wire", type=float, default=2.05)
ap.add_argument("--material", default="ply3")
args = ap.parse_args()

M5 = 5.0
WOOD = 8.0
# ring jig (same as ring_jig_compact.py's D jig): ring hole with the mandrel core cut in place, iron hole at its top
BORE, ROD, IRON, GROOVE_CLR = 20.0, 3.0, 15.0, 0.3   # M3 rod
RING_ID = BORE + 2 * args.wire
RING_OD = RING_ID + 2 * args.wire
RING_CL = RING_ID + args.wire
HOLE = RING_OD + GROOVE_CLR
ANGLES = (45, 135, 225, 315, 0, 90, 180, 270)
RING_WOOD = 4.0


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


def corners(W, H, order):
    """[(centre, r, a0)] per corner: the arc runs a0 -> a0 + 90 (deg, counter-clockwise)"""
    bl, br, tr, tl = order
    return [((bl, bl), bl, 180), ((W - br, br), br, 270), ((W - tr, H - tr), tr, 0), ((tl, H - tl), tl, 90)]


TICK_END, TICK_MID, TICK_45 = 6.0, 3.0, 4.5     # tick lengths in from the edge: curve start/end, 30/60, 45
CROSS, LABEL_H = 3.0, 4.0


RING_CUT = None


def etch_marks(W, H, order, holes, out_to=0.0):
    """etched strokes [(x1, y1, x2, y2)]: crosshair at each arc centre, the radius in digits beside it, radial ticks at
    0 / 90 (start, end), 30 / 60 and 45 deg round each curve; ticks run from inside the edge out to out_to past it"""
    strokes = []
    cs = corners(W, H, order)
    obst = [Point(h).buffer(M5 / 2 + 1.5) for h in holes] + [Point(c).buffer(CROSS + 1) for c, _, _ in cs] + ([RING_CUT.buffer(1.5)] if RING_CUT is not None else [])
    for c, r, a0 in cs:
        cx, cy = c
        strokes += [(cx - CROSS, cy, cx + CROSS, cy), (cx, cy - CROSS, cx, cy + CROSS)]
        for da, L in ((0, TICK_END), (90, TICK_END), (30, TICK_MID), (60, TICK_MID), (45, TICK_45)):
            t = math.radians(a0 + da)
            u = (math.cos(t), math.sin(t))
            strokes.append((cx + u[0] * (r - L), cy + u[1] * (r - L), cx + u[0] * (r + out_to), cy + u[1] * (r + out_to)))
        # label: of 16 spots 8 from the centre, the one furthest from bolts, crosshairs and this corner's ticks
        txt = f"{r:g}"
        best = None
        for k in range(16):
            t = math.radians(k * 22.5)
            p = (cx + 8 * math.cos(t), cy + 8 * math.sin(t))
            lab = box(p[0] - len(txt) * 1.6, p[1] - LABEL_H / 2 - 0.5, p[0] + len(txt) * 1.6, p[1] + LABEL_H / 2 + 0.5)
            others = [o for o in obst if not o.contains(Point(c))]
            edge = rounded_rect(W, H, order).exterior.distance(lab)
            tick_zone = Point(c).buffer(r + 1).difference(Point(c).buffer(r - TICK_END - 1.5))
            d = min([edge - 3] + [lab.distance(o) for o in others] + [lab.distance(Point(c).buffer(CROSS + 0.8))]
                    + [-1 if lab.intersects(tick_zone) else 99])
            if best is None or d > best[0]:
                best = (d, p)
        strokes += _label_strokes(txt, best[1][0], best[1][1], LABEL_H)
    return strokes


def ring_parts(c, iron_dir):
    """(hole cut-out incl. the iron hole, core cut in place) for a ring jig centred on c, iron hole toward iron_dir (deg)"""
    t = math.radians(iron_dir)
    ic = (c[0] + RING_CL / 2 * math.cos(t), c[1] + RING_CL / 2 * math.sin(t))
    iron = Point(ic).buffer(IRON / 2, 96)
    cut = unary_union([Point(c).buffer(HOLE / 2, 128), iron])
    w = args.wire + 0.15
    r = RING_ID / 2
    notches = [affinity.rotate(box(r - args.wire, -w / 2, r + 1, w / 2), a, origin=(0, 0)) for a in ANGLES]
    core = Point(0, 0).buffer(r, 128).difference(unary_union(notches + [Point(0, 0).buffer((ROD + 0.3) / 2, 48)]))
    core = affinity.translate(core, *c).difference(iron)
    return cut, core


def place_ring(form0, W, H, order):
    """centre + iron direction for the ring jig: inside the form with RING_WOOD all round and clear of the edge ticks and
    the arc-centre crosshairs (the most clearance wins)"""
    keep = form0.buffer(-(TICK_END + 1))
    cross = unary_union([Point(cc).buffer(CROSS + 6) for cc, _, _ in corners(W, H, order)])
    best = None
    for i in range(0, int(W) + 1, 2):
        for j in range(0, int(H) + 1, 2):
            for d in range(0, 360, 45):
                cut, _ = ring_parts((i, j), d)
                f = cut.buffer(RING_WOOD)
                if not keep.contains(f) or f.intersects(cross):
                    continue
                score = min(keep.exterior.distance(f), f.distance(cross))
                if best is None or score > best[0]:
                    best = (score, (i, j), d)
    return best


def bolts(shape, W, H, avoid):
    """4 M5 (same holes through form and lips): one per quadrant, as far out as WOOD to the edge allows, clear of
    `avoid` (the ring jig and the crosshairs) by RING_WOOD"""
    inner = shape.buffer(-(M5 / 2 + WOOD))
    out = []
    for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        best = None
        for i in range(0, int(W) + 1, 1):
            for j in range(0, int(H) + 1, 1):
                if (i - W / 2) * sx < 3 or (j - H / 2) * sy < 3:
                    continue
                p = Point(i, j)
                if inner.contains(p) and p.distance(avoid) >= M5 / 2 + RING_WOOD and all(p.distance(q) > 20 for q in out):
                    d = p.distance(Point(W / 2, H / 2))
                    if best is None or d > best[0]:
                        best = (d, p)
        if best:
            out.append(best[1])
    return out


def write(name, polys, note, strokes=()):
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
    # ply3 etch recipe is 100 % at F5000, over the 3000 XY cap: run F3000 at 60 % (scaled by time per mm; estimate)
    ejob = gcode.job(args.material, recipe="etch", feed_mm_per_min=3000, power_percent=60)
    chains = gcode.fuse_touching([[(a - x0, b - y0), (c - x0, d - y0)] for a, b, c, d in strokes], tol=0.05)
    etches = gcode.order([gcode.Polyline([tuple(q) for q in ch], False) for ch in chains if len(ch) > 1])
    lines = gcode.preamble(job, title=f"{stem} -- marbles/clock/bend_jig.py", notes=[note, f"{args.material}: T {T}, kerf {kerf}; X0 Y0 = bottom-left"],
                           etch=ejob if etches else None)
    for i, e in enumerate(etches, 1):
        lines += gcode.etch(e, ejob, i, len(etches))
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(HERE.parent / "gcode" / f"{stem}.gcode", lines)
    print(f"  {p.name}: {len(cuts)} cuts")
    return p


def main():
    global RING_CUT
    order, W, H = layout(args.radii)
    form0 = rounded_rect(W, H, order)
    pr = place_ring(form0, W, H, order)
    if pr is None:
        sys.exit("no room for the ring jig on the form: raise --straight")
    _, rcen, rdir = pr
    RING_CUT, core = ring_parts(rcen, rdir)
    cross = unary_union([Point(cc).buffer(CROSS + 12) for cc, _, _ in corners(W, H, order)])   # room for the labels
    holes = bolts(form0, W, H, unary_union([RING_CUT, cross]))
    hm = unary_union([h.buffer(M5 / 2, 48) for h in holes])
    form = form0.difference(hm).difference(RING_CUT)
    lip0 = form0.buffer(args.lip, 64)
    rod = Point(rcen).buffer((ROD + 0.3) / 2, 48)
    lip_top = lip0.difference(hm).difference(RING_CUT)           # window over the ring jig
    lip_bot = lip0.difference(hm).difference(rod)                # backs the groove; rod hole pins the core
    rc = [r + args.wire / 2 for r in order]
    print(f"form {W:g} x {H:g}: corners BL {order[0]:g}, BR {order[1]:g}, TR {order[2]:g}, TL {order[3]:g} "
          f"(wire centreline {', '.join(f'{x:.2f}' for x in rc)}); straight runs "
          f"{W - order[0] - order[1]:g} / {H - order[1] - order[2]:g} / {W - order[2] - order[3]:g} / {H - order[3] - order[0]:g}; "
          f"M5 at {[(round(p.x, 1), round(p.y, 1)) for p in holes]}")
    print(f"ring jig: centre {rcen}, iron hole toward {rdir} deg; ring hole d{HOLE:.2f}, core d{RING_ID:.2f} cut in place, "
          f"iron d{IRON:g}; clearance {pr[0]:.1f}")
    write("bend_form", [core, form], f"bend form + ring jig: corner radii {order} (BL, BR, TR, TL), M5 x4; ring hole d{HOLE:.2f} "
          f"with the mandrel core cut in place; etched centres, radii, ticks", etch_marks(W, H, order, holes))
    gap = 3.0
    dx = lip0.bounds[2] - lip0.bounds[0] + gap
    write("bend_lips_x2", [lip_top, affinity.translate(lip_bot, dx, 0)],
          f"2 lip plates (form grown {args.lip:g}): TOP (etched, window over the ring jig) / form / BOTTOM (rod hole under "
          f"the core), M5 x4", etch_marks(W, H, order, holes, out_to=args.lip))


if __name__ == "__main__":
    main()
