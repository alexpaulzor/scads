#!/usr/bin/env python3
"""Nest the feeder + dispenser plates on one sheet and write ONE G-code file for it.

Priority (highest first): feeder funnel, dispenser funnel, back keeper, front keeper, back keeper,
front keeper, tunnel flange x2, tunnel relief x2. Parts may be turned 0/90/180/270 and flipped
(flat parts, both faces alike). Each part is placed bottom-left first, trying every orientation, on a
fine grid; several part orders are tried and the best (most parts by priority) is kept.

    python3 marbles/clock/feeder_nest.py [--w 300 --h 295 --gap 1.0]
    # -> marbles/gcode/feeder_sheet_<W>x<H>_<material>.gcode (+ a PNG preview with --png)
"""
import argparse
import itertools
import math
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union
from shapely.prepared import prep

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import emit_cut, load_profile, material_fit, preamble, std_path, gcode  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--w", type=float, default=300)
ap.add_argument("--h", type=float, default=295)
ap.add_argument("--gap", type=float, default=1.0, help="material left between neighbouring cut lines")
ap.add_argument("--step", type=float, default=1.0)
ap.add_argument("--material", default="mdf3")
ap.add_argument("--png", help="also write a preview PNG here")
ap.add_argument("--search", action="store_true", help="slow bottom-left search instead of the hand layout")
ap.add_argument("--v2", action="store_true", help="hand layout 2: backs upright, + 1 flange")
a = ap.parse_args()

T, KERF, FIT = material_fit(a.material)
DEFS = ["-D", f"T={T}", "-D", f"KERF={KERF}", "-D", f"FIT={FIT}"]
SCAD = HERE / "feeder.scad"


def svg_loops(part, td, laser=True):
    out = Path(td) / f"{part}{'_l' if laser else ''}.svg"
    r = subprocess.run(["openscad", "-o", str(out), "-D", f'part="{part}"', "-D", f"laser={'true' if laser else 'false'}"]
                       + DEFS + [str(SCAD)], capture_output=True, text=True)
    if r.returncode or not out.exists():
        sys.exit(r.stderr)
    d = " ".join(re.findall(r'd="([^"]+)"', out.read_text()))
    loops = []
    for sub in re.split(r"[Mm]", d):
        pts = [(float(x), -float(y)) for x, y in re.findall(r"(-?[\d.]+),(-?[\d.]+)", sub)]
        if len(pts) > 2:
            loops.append(pts)
    return loops, r.stderr


with tempfile.TemporaryDirectory() as td:
    _, log = svg_loops("funnel", td)
    kb = next(e for e in re.findall(r"ECHO: (.*)", log) if e.startswith("ko_bridges"))
    nums = [float(v) for v in re.findall(r"-?[\d.]+", kb)]
    KO_W, KO_PTS = nums[-1], [(nums[i], nums[i + 1]) for i in range(0, len(nums) - 1, 2)]
    ko_loop = svg_loops("knockout", td, laser=False)[0][0]
    shapes = {}
    for part in ("funnel", "funnel_dispenser", "back_keeper", "front_keeper", "tunnel_flange", "tunnel_relief"):
        ls, _ = svg_loops(part, td)
        polys = [Polygon(l) for l in ls]
        o = max(range(len(polys)), key=lambda i: polys[i].area)
        shapes[part] = Polygon(ls[o], [ls[i] for i in range(len(ls)) if i != o])

KO_PARTS = ("front_keeper", "back_keeper")
WANT = ["funnel", "funnel_dispenser", "back_keeper", "front_keeper", "back_keeper", "front_keeper",
        "tunnel_flange", "tunnel_flange", "tunnel_relief", "tunnel_relief"]
REQUIRED = 7          # Alex: everything but 1 flange and 2 reliefs, at least


def orient(g, rot, flip):
    if flip:
        g = affinity.scale(g, -1, 1, origin=(0, 0))
    g = affinity.rotate(g, rot, origin=(0, 0))
    return g


def place(order):
    """bottom-left fill in this order; returns [(part, rot, flip, dx, dy, geom)] (skips what doesn't fit)"""
    placed, occ = [], None
    sheet = box(0, 0, a.w, a.h)
    for part in order:
        best = None
        for rot, flip in itertools.product((0, 90, 180, 270), (False, True)):
            g = orient(shapes[part], rot, flip)
            gx0, gy0, gx1, gy1 = g.bounds
            w, h = gx1 - gx0, gy1 - gy0
            if w > a.w or h > a.h:
                continue
            y = 0.0
            found = None
            while y <= a.h - h + 1e-9 and found is None:
                x = 0.0
                while x <= a.w - w + 1e-9:
                    c = affinity.translate(g, x - gx0, y - gy0)
                    if occ is None or not occ.intersects(c):
                        found = (y, x, c, x - gx0, y - gy0)
                        break
                    x += a.step
                y += a.step
            if found and (best is None or (found[0], found[1]) < (best[0][0], best[0][1])):
                best = (found, rot, flip)
        if best is None:
            continue
        (y, x, c, dx, dy), rot, flip = best
        placed.append((part, rot, flip, dx, dy, c))
        occ_geom = unary_union([p[5].buffer(a.gap, join_style=2) for p in placed])
        occ = prep(occ_geom)
    return placed


def score(placed):
    names = [p[0] for p in placed]
    got = []
    pool = list(names)
    for want in WANT:
        if want in pool:
            pool.remove(want)
            got.append(1)
        else:
            got.append(0)
    return tuple(got)


def manual():
    """the hand layout: funnel bottom-left (extension bottom-right), dispenser funnel top-right turned 180
    (extension top-left), back + front keeper stacked right of the feeder funnel's body and over its
    extension, back + front keeper stacked over the feeder funnel's body"""
    G = a.gap
    def pick(part, test):
        for rot, flip in itertools.product((0, 90, 180, 270), (False, True)):
            g = orient(shapes[part], rot, flip)
            if test(g):
                return rot, flip, g
        sys.exit(f"no orientation for {part}")
    def wide(g):
        b = g.bounds
        return b[2] - b[0] > b[3] - b[1]
    def ext_bottom_right(g):        # funnel lying long-ways, its narrow extension at the bottom right
        b = g.bounds
        return wide(g) and not g.intersects(box(b[2] - 30, b[3] - 10, b[2], b[3])) and g.intersects(box(b[2] - 5, b[1], b[2], b[1] + 5))
    def ext_top_left(g):
        b = g.bounds
        return wide(g) and not g.intersects(box(b[0], b[1], b[0] + 30, b[1] + 10)) and g.intersects(box(b[0], b[3] - 5, b[0] + 5, b[3]))
    out = []
    def put(part, rot, flip, g, x, y):
        b = g.bounds
        c = affinity.translate(g, x - b[0], y - b[1])
        out.append((part, rot, flip, x - b[0], y - b[1], c))
        return c
    r, f, g = pick("funnel", ext_bottom_right)
    f1 = put("funnel", r, f, g, 0, 0)
    r, f, g = pick("funnel_dispenser", ext_top_left)
    b = g.bounds
    f2 = put("funnel_dispenser", r, f, g, a.w - (b[2] - b[0]), a.h - (b[3] - b[1]))
    # the feeder funnel's body ends where its extension starts: find that x and the extension's top
    fb = f1.bounds
    body_x1 = max(x for x, y in f1.exterior.coords if y > fb[3] - 1)          # body's right edge (top edge's end)
    ext_y1 = max(y for x, y in f1.exterior.coords if x > body_x1 + 2)        # extension's top (incl. its fillet)
    r, f, gb = pick("back_keeper", wide)
    r2, f2_, gf = pick("front_keeper", wide)
    def lowest(g, x, y0, others):
        """slide g (left edge at x) up from y0 until it clears every placed part by the gap"""
        y = y0
        while True:
            b = g.bounds
            c = affinity.translate(g, x - b[0], y - b[1])
            if all(c.distance(o[5]) >= G for o in others):
                return y
            y += 0.1
    if "--v2" in sys.argv:
        # backs stood upright side by side between the feeder funnel's extension and the dispenser funnel,
        # both fronts flat over the feeder funnel's body, a flange in the corner left of the dispenser funnel
        rb, fb_, gbv = pick("back_keeper", lambda g: not wide(g))
        wv = gbv.bounds[2] - gbv.bounds[0]
        for x in (a.w - wv, a.w - 2 * wv - G - 0.01):
            put("back_keeper", rb, fb_, gbv, x, lowest(gbv, x, 0, out))
        k = put("front_keeper", r2, f2_, gf, 0, lowest(gf, 0, fb[3], out))
        k = put("front_keeper", r2, f2_, gf, 0, lowest(gf, 0, k.bounds[3], out))
        rf, ff, gfl = pick("tunnel_flange", lambda g: True)
        put("tunnel_flange", rf, ff, gfl, 0, lowest(gfl, 0, k.bounds[3], out))
    else:
        manual_v1(r, f, gb, r2, f2_, gf, lowest, put, fb, out, G)
    sheet = box(-1e-6, -1e-6, a.w + 1e-6, a.h + 1e-6)
    for i, p_ in enumerate(out):
        if not sheet.contains(p_[5]):
            sys.exit(f"{p_[0]} leaves the sheet: {p_[5].bounds}")
        for q in out[i + 1:]:
            d = p_[5].distance(q[5])
            if d < G - 1e-6:
                sys.exit(f"{p_[0]} and {q[0]} only {d:.2f} apart")
    return out


def manual_v1(r, f, gb, r2, f2_, gf, lowest, put, fb, out, G):
    # right stack: back keeper then front keeper
    # pushed to the sheet's right edge: clear of the fillet where the funnel's extension meets its body
    xb = a.w - (gb.bounds[2] - gb.bounds[0])
    xf = a.w - (gf.bounds[2] - gf.bounds[0])
    k = put("back_keeper", r, f, gb, xb, lowest(gb, xb, 0, out))
    k2 = put("front_keeper", r2, f2_, gf, xf, lowest(gf, xf, k.bounds[3], out))
    # left stack: back keeper then front keeper over the funnel's body
    k = put("back_keeper", r, f, gb, 0, lowest(gb, 0, fb[3], out))
    put("front_keeper", r2, f2_, gf, 0, lowest(gf, 0, k.bounds[3], out))


if "--search" not in sys.argv:
    placed = manual()
    s = score(placed)
    print("manual layout: " + ", ".join(f"{w}{'' if g_ else ' (not placed)'}" for w, g_ in zip(WANT, s)))
    cands = []
else:
    cands = None
# orders that respect "big things first" variety; keep the best by priority
if "--search" in sys.argv:
    cands = []
big = ["funnel", "funnel_dispenser"]
keepers = ["back_keeper", "front_keeper", "back_keeper", "front_keeper"]
small = ["tunnel_flange", "tunnel_flange", "tunnel_relief", "tunnel_relief"]
seen = set()
if "--search" in sys.argv:          # flange right after the funnels, so it takes a funnel's notch
    for ks in (["back_keeper", "back_keeper", "front_keeper", "front_keeper"],
               ["back_keeper", "front_keeper", "back_keeper", "front_keeper"],
               ["front_keeper", "front_keeper", "back_keeper", "back_keeper"]):
        cands.append(big + ["tunnel_flange"] + ks + ["tunnel_flange"] + small[2:])
        cands.append(big + ["tunnel_flange", "tunnel_flange"] + ks + small[2:])
for kp in []:
    for interleave in range(0, 5):
        ks = list(kp)
        order = big + ks[:interleave] + ks[interleave:] + small
        for o2 in (order, [big[0]] + ks[:1] + [big[1]] + ks[1:] + small, big[::-1] + ks + small):
            t = tuple(o2)
            if t not in seen:
                seen.add(t)
                cands.append(list(o2))
best = (s, placed, None) if not cands else None
for order in cands:
    pl = place(order)
    s = score(pl)
    if best is None or s > best[0]:
        best = (s, pl, order)
    if sum(s) == len(WANT):
        break
s, placed, order = best
print(f"placed {sum(s)} of {len(WANT)}: " + ", ".join(f"{w}{'' if g else ' (MISSING)'}" for w, g in zip(WANT, s)))
if sum(s[:6]) < 6:
    sys.exit(f"could not place the 2 funnels + 4 keepers on {a.w:g} x {a.h:g}")


# ---------------------------------------------------------------- G-code
def ko_paths(rot, flip, dx, dy):
    line = LineString(ko_loop + [ko_loop[0]])
    pts = [Point(q) for q in KO_PTS]
    line = affinity.translate(orient(line, rot, flip), dx, dy)
    pts = [affinity.translate(orient(q, rot, flip), dx, dy) for q in pts]
    return [pl.points for pl in gcode.bridged(list(line.coords), [q.coords[0] for q in pts], KO_W, KERF)]


s2g, motion, mat, job = load_profile(a.material, 1000, None)
holes, kos, outs = [], [], []
for part, rot, flip, dx, dy, g in placed:
    holes += [list(r.coords) for r in g.interiors]
    if part in KO_PARTS:
        kos += ko_paths(rot, flip, dx, dy)
    outs.append(list(g.exterior.coords))
holes.sort(key=lambda pl: abs(Polygon(pl).area))
outs.sort(key=lambda pl: abs(Polygon(pl).area))
cuts = [s2g.Polyline(pl, True) for pl in holes] + [s2g.Polyline(pl, False) for pl in kos] + [s2g.Polyline(pl, True) for pl in outs]
cuts = gcode.order(cuts)        # middle-out, shortest travel (quickcut/order.py)
W = max(g.bounds[2] for *_, g in placed)
H = max(g.bounds[3] for *_, g in placed)
lines = [f"; feeder_sheet -- marbles/clock/feeder_nest.py: feeder + dispenser plates on one {a.w:g} x {a.h:g} sheet",
         "; parts: " + ", ".join(f"{p}{' (flipped)' if f else ''} r{r}" for p, r, f, *_ in placed)]
lines += ["; missing: " + ", ".join(w for w, g in zip(WANT, s) if not g)] if sum(s) < len(WANT) else []
lines += [f"; {mat['id']} T {T}, kerf {KERF}; {len(holes)} holes, {len(kos)} knock-out pieces (bridged), "
          f"then {len(outs)} outlines; X0 Y0 = bottom-left; footprint {W:.1f} x {H:.1f} mm", ";"]
lines += preamble(s2g, job)
for i, c in enumerate(cuts, 1):
    lines += emit_cut(s2g, motion, c, i, len(cuts), job)
out = std_path(HERE.parent / "gcode", "feeder_sheet", lines, mat["id"])
gcode.write(out, lines)
print(f"wrote {out.name}: footprint {W:.1f} x {H:.1f} mm (sheet {a.w:g} x {a.h:g}), {len(cuts)} cuts")
for p, r, f, dx, dy, g in placed:
    b = g.bounds
    print(f"  {p:18s} rot {r:3d}{' flip' if f else '     '}  x {b[0]:6.1f}..{b[2]:6.1f}  y {b[1]:6.1f}..{b[3]:6.1f}")

if a.png:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(8, 8 * a.h / a.w))
    ax.add_patch(plt.Rectangle((0, 0), a.w, a.h, fill=False, ec="0.5", ls="--"))
    for p, r, f, dx, dy, g in placed:
        for ring in [g.exterior] + list(g.interiors):
            xs, ys = ring.xy
            ax.plot(xs, ys, color="#c0392b", lw=0.8)
        cx, cy = g.centroid.x, g.centroid.y
        ax.text(cx, cy, p.replace("_", "\n"), ha="center", va="center", fontsize=6)
    for pl in kos:
        ax.plot(*zip(*pl), color="#2c7bb6", lw=0.8)
    ax.set_xlim(-5, a.w + 5)
    ax.set_ylim(-5, a.h + 5)
    ax.set_aspect("equal")
    ax.set_title(f"feeder sheet {a.w:g} x {a.h:g}: {sum(s)} of {len(WANT)} parts", fontsize=9)
    fig.savefig(a.png, dpi=120)
