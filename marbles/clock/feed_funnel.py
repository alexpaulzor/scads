#!/usr/bin/env python3
"""Bottom feed funnel plate and short plain keepers (from the 2026-11-04 sketch).

FEED FUNNEL (FF) -- one plate in the sieve's plane, below S_F:
  plate coords: x across (x = 0 is the sieve's 6 mm edge side, x = 46 is the beam
  side, x 46..92 sticks out past the beam), y up (y = 0 bottom edge).
  - left column (x 0..46) continues the sieve: ball holes d20 every 30 on x = 16,
    M5 holes on x = 36 (the beam's centre slot) in the gaps that clear the channel.
  - a J-shaped channel, one ball wide, enters at the top of the right column and
    sweeps down and left into the BOTTOM hole; balls queue in it by gravity.
    The channel lies in the plane of the rocking, so rocking never changes its slope.
  - bottom band 20 tall with its own M5 holes (y = 10) for a short 2020 across.
SHORT KEEPER (SK) -- 150 x 40 plain keeper: M5 every 3/4" (19.05) on v = 10, and
  the standard 60 mm spacing on v = 30.

Thickness, kerf and slot fit come from the material profile (mdf_3mm: 3.1 / 0.10).

    python3 marbles/clock/feed_funnel.py      # -> marbles/gcode/feed_funnel.gcode, feed_keeper.gcode, short_keeper.gcode
"""
import argparse
import json
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import emit_cut, load_profile, material_fit, preamble  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--material", default="mdf_3mm")
ap.add_argument("--sk-len", type=float, default=150.0, help="short keeper length")
args = ap.parse_args()
T, KERF, _ = material_fit(args.material)

M5 = 5.0
HOLE_D, PITCH, COL_W = 20.0, 30.0, 46.0      # sieve: ball holes, pitch, strip width
HOLE_X, M5_X = COL_W - 30.0, COL_W - 10.0    # x of ball holes / beam M5 (sieve's v = 30 / v = 10)
BAND = 20.0                                  # bottom band for a short 2020
N_HOLES = 4                                  # ball holes in the funnel's sieve column
W = 2 * COL_W                                # plate width
H = BAND + 15.0 + PITCH * (N_HOLES - 1) + 15.0   # end margins like the sieve (first hole 15 from the end)
CH_W = HOLE_D + 1.0                          # channel width (ball 19.05)
CH_X = COL_W + COL_W / 2                     # channel centre where it leaves the top edge
WEB = max(4.0, T)

y_holes = [BAND + 15.0 + PITCH * i for i in range(N_HOLES)]
yb = y_holes[0]


def bezier(p0, p1, p2, p3, n=80):
    out = []
    for i in range(n + 1):
        t = i / n
        a, b, c, d = (1 - t) ** 3, 3 * (1 - t) ** 2 * t, 3 * (1 - t) * t ** 2, t ** 3
        out.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return out


# channel centreline: straight down from above the top edge, then a curve that ends heading
# slightly downhill into the bottom hole, so the bottom hole is the lowest point
path = [(CH_X, H + 5)] + bezier((CH_X, H - 20), (CH_X, yb + 18), (HOLE_X + 26, yb + 6), (HOLE_X, yb))
channel = LineString(path).buffer(CH_W / 2, 32)


def funnel_2d():
    g = box(0, 0, W, H)
    cuts = [channel] + [Point(HOLE_X, y).buffer(HOLE_D / 2, 64) for y in y_holes]
    m5 = []
    for y in [(a + b) / 2 for a, b in zip(y_holes, y_holes[1:])]:          # gaps between ball holes
        p = Point(M5_X, y).buffer(M5 / 2, 32)
        if p.distance(channel) >= WEB:
            m5.append((M5_X, y))
    band = [(x, BAND / 2) for x in (HOLE_X, COL_W, W - HOLE_X)]
    cuts += [Point(p).buffer(M5 / 2, 32) for p in m5 + band]
    return g.difference(unary_union(cuts)), m5, band


def short_keeper_2d(length):
    g = box(0, 0, length, 40.0)
    p34 = 19.05
    n = int((length - 2 * 10) // p34) + 1
    x0 = (length - p34 * (n - 1)) / 2
    row10 = [x0 + p34 * i for i in range(n)]
    n60 = int((length - 2 * 10) // 60) + 1
    x60 = (length - 60 * (n60 - 1)) / 2
    row30 = [x60 + 60 * i for i in range(n60)]
    holes = [Point(x, 10).buffer(M5 / 2, 32) for x in row10] + [Point(x, 30).buffer(M5 / 2, 32) for x in row30]
    return g.difference(unary_union(holes)), row10, row30


def min_web(g):
    best = None
    for poly in ([g] if g.geom_type == "Polygon" else list(g.geoms)):
        rs = [LineString(r.coords) for r in poly.interiors]
        ext = LineString(poly.exterior.coords)
        for i, r in enumerate(rs):
            for o in [ext] + rs[i + 1:]:
                d = r.distance(o)
                best = d if best is None else min(best, d)
    return best


ff, m5, band = funnel_2d()
# FEED KEEPER (FK): same outline and M5 holes as the funnel, no ball holes, no channel.
# One on each face of the funnel keeps the balls in its plane (same part both sides, no flip).
fk = box(0, 0, W, H).difference(unary_union([Point(p).buffer(M5 / 2, 32) for p in m5 + band]))
sk, row10, row30 = short_keeper_2d(args.sk_len)
# narrowest neck of the funnel plate: where the sieve column joins the rest (below the channel)
print(f"T = {T}, KERF = {KERF}")
print(f"FF feed funnel: {W:g} x {H:g}; ball holes x {HOLE_X:g} at y {y_holes}; channel {CH_W:g} wide, "
      f"enters the top edge at x {CH_X - CH_W/2:g}..{CH_X + CH_W/2:g}")
print(f"   beam M5 (x {M5_X:g}) at y {[round(p[1], 1) for p in m5]} (gaps that clear the channel by >= {WEB:g}); "
      f"band M5 at y {BAND/2:g}, x {[p[0] for p in band]}")
print(f"   narrowest web hole-to-edge/hole {min_web(ff):.2f}; pieces {1 if ff.geom_type == 'Polygon' else len(ff.geoms)}")
neck = box(0, 0, W, yb).intersection(ff).area
print(f"   wood below the bottom hole (y < {yb:g}): {neck:.0f} mm^2")
print(f"SK short keeper: {args.sk_len:g} x 40; M5 v=10 every 19.05 at x {[round(x, 2) for x in row10]}; "
      f"v=30 every 60 at x {[round(x, 2) for x in row30]}; narrowest web {min_web(sk):.2f}")

# ---------------------------------------------------------------- G-code
s2g, motion, mat, job = load_profile(args.material, 1000, None)
out_dir = HERE.parent / "gcode"
out_dir.mkdir(parents=True, exist_ok=True)
print(f"FK feed keeper: {W:g} x {H:g}, M5 at {[(round(x, 1), round(y, 1)) for x, y in m5 + band]}; narrowest web {min_web(fk):.2f}")
for name, g, note in (("feed_funnel", ff, "bottom feed funnel plate (sieve column + J channel + 20 mm band)"),
                      ("feed_keeper", fk, "feed keeper: funnel outline + M5 holes, no ball holes or channel; cut 2"),
                      ("short_keeper", sk, f"short plain keeper {args.sk_len:g} x 40")):
    gk = g.buffer(KERF / 2, join_style=2)
    x0, y0, x1, y1 = gk.bounds
    loops = []
    for poly in ([gk] if gk.geom_type == "Polygon" else list(gk.geoms)):
        loops += [list(r.coords) for r in poly.interiors] + [list(poly.exterior.coords)]
    loops = [[(x - x0, y - y0) for x, y in pl] for pl in loops]
    loops.sort(key=lambda pl: abs(Polygon(pl).area))
    cuts = [s2g.Polyline(pl, True) for pl in loops]
    lines = [f"; {name} -- marbles/clock/feed_funnel.py: {note}",
             f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
             f"kerf {KERF}; X0 Y0 = bottom-left; {x1 - x0:.2f} x {y1 - y0:.2f} mm", ";"]
    lines += preamble(s2g, job)
    for i, c in enumerate(cuts, 1):
        lines += emit_cut(s2g, motion, c, i, len(cuts), job)
    lines += s2g._footer()
    (out_dir / f"{name}.gcode").write_text("\n".join(lines))
    print(f"wrote {name}.gcode: {x1 - x0:.2f} x {y1 - y0:.2f} mm, {len(cuts)} cuts")

# ---------------------------------------------------------------- scene for the views
def rings(g):
    gs = [g] if g.geom_type == "Polygon" else list(g.geoms)
    return [{"outer": list(p.exterior.coords), "holes": [list(h.coords) for h in p.interiors]} for p in gs]

scenes = HERE.parent / "views" / "scenes"
scenes.mkdir(parents=True, exist_ok=True)
# place: plate x -> a = 46 - x, y -> z = y - H (the funnel sits directly under S_F, holes continue S_F's pitch)
ff_az = affinity.affine_transform(ff, [-1, 0, 0, 1, COL_W, -H])
parts = [{"id": "FF", "label": "feed funnel", "color": "#e39b5b", "opacity": 1.0, "kind": "az", "polys": rings(ff_az),
          "lo": -T, "hi": 0.0, "group": "FF"}]
sf = box(0, 0, 46, 120).difference(unary_union([Point(30, 15 + 30 * i).buffer(10, 64) for i in range(4)]
                                                + [Point(10, u).buffer(2.5, 32) for u in (30, 90)]))
parts.append({"id": "S_F", "label": "S_F", "color": "#d4b07a", "opacity": 1.0, "kind": "az", "polys": rings(sf),
              "lo": -T, "hi": 0.0, "group": "S_F"})
json.dump({"parts": parts, "W": W, "H": H, "y_holes": y_holes, "path": path, "T": T,
           "ball_path": [(COL_W - x, y - H) for x, y in path]}, open(scenes / "funnel_parts.json", "w"))
json.dump({"parts": [{"key": "FF", "name": "feed funnel", "per_fork": 1, "polys": rings(ff), "bounds": ff.bounds},
                     {"key": "SK", "name": f"short keeper {args.sk_len:g} x 40", "per_fork": 0, "polys": rings(sk), "bounds": sk.bounds}]},
          open(scenes / "funnel_thumbs.json", "w"))
