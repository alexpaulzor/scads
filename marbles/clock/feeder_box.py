#!/usr/bin/env python3
"""Side-entry feeder box (v2 of the feed funnel), 2026-11-04.

A small boxes.py-style box around the funnel, below S_F at the bottom of the lift:
  FF  funnel     sieve column (4 ball holes on the sieve's line) + J channel. The channel's
                 top is CLOSED by a bridge (neck >= 10), and starts in a round pocket that
                 balls enter SIDEWAYS through the port in the front keeper.
  FK  front keeper  20 mm inside spacing from BK; in the plane of F's side slots, so above F's
                 end its 6 mm edge rides in F's far slot. Carries the PORT.
  BK  back keeper   behind the funnel; covers the bottom hole and channel from behind.
  OW  outer wall    tabbed through both keepers; the funnel's outer edge tabs into its middle.
  TW  top wall      over the channel side, tabbed through both keepers.
  BW  bottom wall   under the funnel's outer part, tabbed through both keepers; the funnel's
                 bottom edge tabs into it. (Replaces the old band's 3 M5 into a short 2020.)
PORT (the standard interface for whatever loads balls next): a 20 x 20 square opening, a
  10 mm tab slot centred on each side where a 20-inside square duct's walls land, and 4 M5
  at the corners. Same pattern (without the opening) on BK, so a box can bolt on either side.
Inside spacing between keepers = 20 (the same 20 as the port), funnel centred between them.
Thickness, kerf, fit come from the material profile (mdf3: 2.82 / 0.10 / 0).

    python3 marbles/clock/feeder_box.py       # -> marbles/gcode/feeder_box.gcode (nested) + one file per part,
                                              #    feeder_<part>_<W>x<H>.gcode (bbox rounded up, longest side X)
"""
import argparse
import json
import math
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union
from shapely.prepared import prep

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import emit_cut, load_profile, material_fit, preamble, std_path, gcode  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--material", default="mdf3")
ap.add_argument("--f-end", type=float, default=65.0, help="height (plate y) of F's bottom end")
args = ap.parse_args()
T, KERF, FIT = material_fit(args.material)

M5, TAB, WEB = 5.0, 10.0, max(4.0, T)
HOLE_D, PITCH, COL_W = 20.0, 30.0, 46.0
HOLE_X, M5_X = COL_W - 30.0, COL_W - 10.0
BAND, N_HOLES = 20.0, 4
W = 2 * COL_W + 4.0                             # funnel width (outer edge at x = W); +4 so the outer walls clear the port bolts
H = BAND + 15.0 + PITCH * (N_HOLES - 1) + 15.0  # 140
INSIDE = 20.0                                   # keeper to keeper, inside
GAP = (INSIDE - T) / 2                          # funnel face to each keeper
PORT = 20.0                                     # port opening (square, inside of a standard duct)
PORT_C = (68.0, 108.0)                          # port / pocket centre on the plate
PORT_M5 = 18.0                                  # corner M5 offset from the port centre (through FK, FF and BK)
CH_W = HOLE_D + 1.0
FK_X0_LOW, FK_X0_HIGH = COL_W - 12.0, COL_W - 6.0   # FK inner edge: under F's end / in F's far slot (a 12 / a 6)
BK_X0 = 6.0                                     # BK clears M's body (a <= 40)
y_holes = [BAND + 15.0 + PITCH * i for i in range(N_HOLES)]


def bezier(p0, p1, p2, p3, n=80):
    return [((1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t ** 2 * p2[0] + t ** 3 * p3[0],
             (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t ** 2 * p2[1] + t ** 3 * p3[1])
            for t in (i / n for i in range(n + 1))]


yb = y_holes[0]
path = bezier(PORT_C, (PORT_C[0], yb), (HOLE_X + 26, yb + 6), (HOLE_X, yb))
channel = unary_union([LineString(path).buffer(CH_W / 2, 32), Point(PORT_C).buffer(CH_W / 2, 64)])
c = lambda p, d: Point(p).buffer(d / 2, 48)


def port_cuts(open_hole):
    cx, cy = PORT_C
    h = PORT / 2
    cuts = [box(cx + h, cy - TAB / 2, cx + h + T + FIT, cy + TAB / 2), box(cx - h - T - FIT, cy - TAB / 2, cx - h, cy + TAB / 2),
            box(cx - TAB / 2, cy + h, cx + TAB / 2, cy + h + T + FIT), box(cx - TAB / 2, cy - h - T - FIT, cx + TAB / 2, cy - h)]
    cuts += [c((cx + sx * PORT_M5, cy + sy * PORT_M5), M5) for sx in (-1, 1) for sy in (-1, 1)]
    if open_hole:
        cuts.append(box(cx - h, cy - h, cx + h, cy + h))
    return cuts


beam_m5 = [(M5_X, y) for y in ((y_holes[1] + y_holes[2]) / 2, (y_holes[2] + y_holes[3]) / 2)]

# ---- spacer walls: separate walls in each gap (funnel <-> FK, funnel <-> BK), GAP deep, tabbed into BOTH the
# funnel and that keeper. Front and back walls on the same line put their tabs on one shared 10 mm grid, front on
# cells k = 1 (mod 4), back on k = 3 (mod 4), so every funnel slot takes one tab from one side only and the walls
# line up through the funnel: load goes straight through to the funnel and its bolts into the beam.
y_port_lo = PORT_C[1] - PORT_M5 - M5 / 2 - WEB          # outer walls stop below the port's lower M5
y_top = H - WEB - T                                      # top walls
y_bot = WEB                                              # bottom walls
x_out = W - WEB - T                                      # outer walls
SPACERS = [  # (key, side, orient, fixed coordinate, lo, hi): 'v' = runs along y at x..x+T; 'h' = runs along x at y..y+T
    ("SF1", "F", "v", x_out, y_bot + T, y_top),
    ("SF2", "F", "h", y_top, FK_X0_HIGH + WEB, W - WEB),
    ("SF3", "F", "h", y_bot, FK_X0_LOW + WEB, W - WEB),
    ("SB1", "B", "v", x_out, y_bot + T, y_top),
    ("SB2", "B", "h", y_top, HOLE_X + HOLE_D / 2 + WEB, W - WEB),
    ("SB3", "B", "h", y_bot, BK_X0 + WEB, W - WEB),
    ("SB4", "B", "v", M5_X + M5 / 2 + 0.5, None, y_top),   # beside the beam bolts: carries them to F
]


def port_m5():
    cx, cy = PORT_C
    return [(cx + sx * PORT_M5, cy + sy * PORT_M5) for sx in (-1, 1) for sy in (-1, 1)]


# nothing a tab slot may come within WEB of
KEEPOUT = unary_union([channel] + [c((HOLE_X, y), HOLE_D) for y in y_holes] + [c(p, M5) for p in beam_m5 + port_m5()]
                      + port_cuts(True))


def slot_box(orient, f, a0, a1):
    return box(f - FIT / 2, a0, f + T + FIT / 2, a1) if orient == "v" else box(a0, f - FIT / 2, a1, f + T + FIT / 2)


def tabs(sp):
    """10 mm cells on a shared grid. A line shared with a wall on the other side of the funnel: front on
    cells k = 1 (mod 4), back on k = 3 (mod 4). A line used by one wall only: every other cell."""
    key, side, orient, f, lo, hi = sp
    shared = any(o[1] != side and o[2] == orient and abs(o[3] - f) < 1e-6 for o in SPACERS)
    ok_k = (lambda k: k % 4 == (1 if side == "F" else 3)) if shared else (lambda k: k % 2 == 1)
    out, k = [], 0
    while TAB * k < hi:
        a0, a1 = TAB * k, TAB * (k + 1)
        if ok_k(k) and a0 >= lo and a1 <= hi and slot_box(orient, f, a0, a1).distance(KEEPOUT) >= WEB:
            out.append((a0, a1))
        k += 1
    return out


# SB4 starts as low as it can while staying clear of the channel
_sb = [sp for sp in SPACERS if sp[0] == "SB4"][0]
_lo = next(y for y in range(0, 200) if box(_sb[3], y, _sb[3] + T, _sb[5]).distance(channel) > 1.5)
SPACERS = [sp if sp[0] != "SB4" else (sp[0], sp[1], sp[2], sp[3], float(_lo), sp[5]) for sp in SPACERS]


def spacer_slots(sp):
    """slots this spacer needs in the funnel and in its keeper (same positions), plate coords"""
    key, side, orient, f, lo, hi = sp
    return [slot_box(orient, f, a0, a1) for a0, a1 in tabs(sp)]


def spacer_2d(sp):
    """(u, v): u along the wall, v across the gap (0 = funnel face .. GAP = keeper face), tabs into both"""
    key, side, orient, f, lo, hi = sp
    t = tabs(sp)
    g = unary_union([box(lo, 0, hi, GAP)] + [box(a0, -T, a1, 0.01) for a0, a1 in t]
                    + [box(a0, GAP - 0.01, a1, GAP + T) for a0, a1 in t])
    return g


def keeper_outline(x0_low, x0_high, y_split):
    g = unary_union([box(x0_low, 0, W, y_split), box(x0_high, y_split, W, H)])
    return g.buffer(-2, join_style=2).buffer(2, join_style=2)


def funnel():
    cuts = [channel] + [c((HOLE_X, y), HOLE_D) for y in y_holes] + [c(p, M5) for p in beam_m5 + port_m5()]
    cuts += [sl for sp in SPACERS for sl in spacer_slots(sp)]
    return box(0, 0, W, H).difference(unary_union(cuts))


def front_keeper():
    g = keeper_outline(FK_X0_LOW, FK_X0_HIGH, args.f_end)
    cuts = port_cuts(True) + [sl for sp in SPACERS if sp[1] == "F" for sl in spacer_slots(sp)]
    return g.difference(unary_union(cuts))


def back_keeper():
    g = keeper_outline(BK_X0, BK_X0, H)
    cuts = port_cuts(False) + [c(p, M5) for p in beam_m5] + [sl for sp in SPACERS if sp[1] == "B" for sl in spacer_slots(sp)]
    return g.difference(unary_union(cuts))


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


NAMES = {"SF1": "outer spacer, front", "SF2": "top spacer, front", "SF3": "bottom spacer, front",
         "SB1": "outer spacer, back", "SB2": "top spacer, back", "SB3": "bottom spacer, back",
         "SB4": "inner spacer, back (beam bolts)"}
PARTS = [("FF funnel", funnel()), ("FK front keeper", front_keeper()), ("BK back keeper", back_keeper())]
PARTS += [(f"{sp[0]} {NAMES[sp[0]]}", spacer_2d(sp)) for sp in SPACERS]
# the channel must stay clear of every wall (ball footprint = channel outline)
for sp in SPACERS:
    key, side, orient, f, lo, hi = sp
    fp = box(f, lo, f + T, hi) if orient == "v" else box(lo, f, hi, f + T)
    assert fp.distance(channel) > 1.0, f"{key} hits the channel"
    print(f"{key}: {orient} at {f:.2f}, {lo:.2f}..{hi:.2f}, tabs {tabs(sp)}; clear of the channel by {fp.distance(channel):.2f}")
ff = PARTS[0][1]
bridge = H - (PORT_C[1] + CH_W / 2)
print(f"T = {T}, KERF = {KERF}, FIT = {FIT}; inside {INSIDE:g} (funnel {GAP:.2f} off each keeper)")
print(f"funnel {W:g} x {H:g}: channel closed at the top, bridge {bridge:.2f} above the pocket; pocket centre {PORT_C}")
for n, g in PARTS:
    x0, y0, x1, y1 = g.bounds
    mw = min_web(g)
    print(f"{n}: {x1 - x0:.2f} x {y1 - y0:.2f}; pieces {1 if g.geom_type == 'Polygon' else len(g.geoms)}; "
          f"narrowest web {mw if mw is None else round(mw, 2)}")
print(f"port: {PORT:g} square, 10 mm tab slots at +/-{PORT / 2:g}..{PORT / 2 + T:.2f}, M5 at +/-{PORT_M5:g} corners")

# ---------------------------------------------------------------- nest + G-code
GAPN, STEP = 2.0, 1.0
def norm(g):
    x0, y0, _, _ = g.bounds
    return affinity.translate(g, -x0, -y0)
items = [(n, norm(g.buffer(KERF / 2, join_style=2))) for n, g in PARTS]
items.sort(key=lambda it: -it[1].area)
placed = [items[0]]
for name, g in items[1:]:
    occ = prep(unary_union([p for _, p in placed]).buffer(GAPN, join_style=2))
    b = [p.bounds for _, p in placed]
    X0, Y0, X1, Y1 = min(q[0] for q in b), min(q[1] for q in b), max(q[2] for q in b), max(q[3] for q in b)
    best = None
    for rot in (0, 90, 180, 270):
        r = norm(affinity.rotate(g, rot, origin=(0, 0)))
        w, h = r.bounds[2], r.bounds[3]
        x = 0.0
        while x <= X1 + GAPN + STEP:
            y = 0.0
            while y <= Y1 + GAPN + STEP:
                key = ((max(X1, x + w) - min(X0, x)) * (max(Y1, y + h) - min(Y0, y)), max(Y1, y + h))
                if best is None or key < best[0]:
                    cand = affinity.translate(r, x, y)
                    if not occ.intersects(cand):
                        best = (key, cand)
                y += STEP
            x += STEP
    placed.append((name, best[1]))
b = [p.bounds for _, p in placed]
X0, Y0, X1, Y1 = min(q[0] for q in b), min(q[1] for q in b), max(q[2] for q in b), max(q[3] for q in b)
holes, outers = [], []
for _, g in placed:
    g = affinity.translate(g, -X0, -Y0)
    for poly in ([g] if g.geom_type == "Polygon" else list(g.geoms)):
        holes += [list(r.coords) for r in poly.interiors]
        outers.append(list(poly.exterior.coords))
holes.sort(key=lambda pl: abs(Polygon(pl).area))
outers.sort(key=lambda pl: abs(Polygon(pl).area))
s2g, motion, mat, job = load_profile(args.material, 1000, None)
cuts = [s2g.Polyline(pl, True) for pl in holes + outers]
cuts = gcode.order(cuts)        # middle-out, shortest travel (quickcut/order.py)
lines = [f"; feeder_box -- marbles/clock/feeder_box.py: side-entry feeder box (funnel, 2 keepers, 6 spacer walls)",
         f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
         f"kerf {KERF}, fit {FIT}; X0 Y0 = bottom-left; footprint {X1 - X0:.2f} x {Y1 - Y0:.2f} mm",
         f"; {len(holes)} holes/slots first, then {len(outers)} outlines", ";"]
lines += preamble(s2g, job)
for i, cc in enumerate(cuts, 1):
    lines += emit_cut(s2g, motion, cc, i, len(cuts), job)
out = std_path(HERE.parent / "gcode", "feeder_box", lines, mat['id'])
out.parent.mkdir(parents=True, exist_ok=True)
gcode.write(out, lines)
print(f"wrote {out.name}: {X1 - X0:.2f} x {Y1 - Y0:.2f} mm, {len(cuts)} cuts")

# ---------------------------------------------------------------- one file per part, longest side along X
SLUG = {"FF": "feeder_funnel", "FK": "feeder_front_keeper", "BK": "feeder_back_keeper",
        "SF1": "feeder_spacer_outer_front", "SF2": "feeder_spacer_top_front", "SF3": "feeder_spacer_bottom_front",
        "SB1": "feeder_spacer_outer_back", "SB2": "feeder_spacer_top_back", "SB3": "feeder_spacer_bottom_back",
        "SB4": "feeder_spacer_inner_back"}
for n, g in PARTS:
    gk = norm(g.buffer(KERF / 2, join_style=2))
    if gk.bounds[3] > gk.bounds[2]:
        gk = norm(affinity.rotate(gk, 90, origin=(0, 0)))
    w, h = gk.bounds[2], gk.bounds[3]
    name = f"{SLUG[n.split()[0]]}_{math.ceil(w - 1e-9)}x{math.ceil(h - 1e-9)}_{mat['id']}"
    hs, os_ = [], []
    for poly in ([gk] if gk.geom_type == "Polygon" else list(gk.geoms)):
        hs += [list(r.coords) for r in poly.interiors]
        os_.append(list(poly.exterior.coords))
    hs.sort(key=lambda pl: abs(Polygon(pl).area))
    pc = [s2g.Polyline(pl, True) for pl in hs + os_]
    ln = [f"; {name} -- marbles/clock/feeder_box.py: {n}",
          f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
          f"kerf {KERF}, fit {FIT}; X0 Y0 = bottom-left; {w:.2f} x {h:.2f} mm (longest side along X)", ";"]
    ln += preamble(s2g, job)
    for i, cc in enumerate(pc, 1):
        ln += emit_cut(s2g, motion, cc, i, len(pc), job)
    gcode.write((out.parent / f"{name}.gcode"), ln)
    print(f"wrote {name}.gcode: {w:.2f} x {h:.2f} mm, {len(pc)} cuts")

# ---------------------------------------------------------------- scene data (a = 46 - x, z = y - H)
def rings(g):
    gs = [g] if g.geom_type == "Polygon" else list(g.geoms)
    return [{"outer": list(p.exterior.coords), "holes": [list(h.coords) for h in p.interiors]} for p in gs]
to_az = lambda g: affinity.affine_transform(g, [-1, 0, 0, 1, COL_W, -H])
s_bk_in = -T - GAP                    # BK inner face (s)
s_fk_in = GAP                         # FK inner face (s)
def spacer_scene(sp):
    key, side, orient, f, lo, hi = sp
    g = spacer_2d(sp)                         # (u, v); v 0 = funnel face
    if side == "F":                           # s = v (funnel front face at s 0)
        sv = [1, 0]
    else:                                     # s = -T - v
        sv = [-1, -T]
    if orient == "v":                         # u = y -> z = y - H; plane (s, z), along a: a = 46 - x
        geom = affinity.affine_transform(g, [0, sv[0], 1, 0, sv[1], -H])
        return {"kind": "sz", "polys": rings(geom), "lo": COL_W - f - T, "hi": COL_W - f}
    geom = affinity.affine_transform(g, [-1, 0, 0, sv[0], COL_W, sv[1]])   # u = x -> a = 46 - x; plane (a, s), along z
    return {"kind": "as", "polys": rings(geom), "lo": f - H, "hi": f + T - H}
json.dump({"T": T, "H": H, "W": W, "GAP": GAP, "INSIDE": INSIDE, "s_bk_in": s_bk_in, "s_fk_in": s_fk_in,
           "PORT_C": PORT_C, "PORT": PORT, "f_end": args.f_end - H,
           "FF": rings(to_az(funnel())), "FK": rings(to_az(front_keeper())), "BK": rings(to_az(back_keeper())),
           "spacers": [dict(spacer_scene(sp), key=sp[0], side=sp[1]) for sp in SPACERS],
           "ball_path": [(COL_W - x, y - H) for x, y in path],
           "thumbs": [{"key": n.split()[0], "name": " ".join(n.split()[1:]), "per_fork": 1, "polys": rings(g), "bounds": g.bounds}
                      for n, g in PARTS]},
          open(HERE.parent / "views" / "scenes" / "feeder_box.json", "w"))
