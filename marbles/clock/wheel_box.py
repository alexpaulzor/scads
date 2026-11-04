#!/usr/bin/env python3
"""V-wheel boxes for the lift's captive slide (replace guide rails G_F/G_M and sliders L_F/L_M).

Each wheel has its own short keeper (WK, 150 long, 2 per 300 sheet edge) that IS the
near wall of its box: 40 wide, curving out to a lobe at the box. A plain keeper (PK,
300 x 40, sieve hole pattern) is the guard/backing wherever no wheel is needed. Each box adds 4 plates around one polymer V-wheel, open on the side facing
the beam the wheel rides:

  FC  far cheek x1    parallel to the keeper, on the other side of the wheel.
                      Keeper lobe + far cheek carry the axle at both ends.
  TB  top/bottom x2   tabbed through the keeper and the far cheek; finger-jointed to BK
  BK  back wall x1    tabbed through the keeper and the far cheek; finger-jointed to TB
  TB + BK hold keeper and far cheek apart (compression); long M5 bolts through
  keeper + far cheek pull them together (tension). No captive nuts in the wood.

The wheel's position along its axle is set by two nuts on the axle bolt, one each
side of the bearing's inner race, so the box does not need precise thickness.
Wheel tension: the axle hole is round. Instead, the keeper's row of M5 holes on
its OWN beam (v = 10, bolted to F for K_F, to M for K_M) are slots running across
(toward / away from the other beam). Slide the keeper, with its boxes, until the
wheels sit in the other beam's groove, then tighten those screws.

Everything is parametric in T (sheet thickness) and KERF; run with --t 2.6 to
check the plywood version. Coordinates as in the lift drawings: a = across
(F at a 0..20, M at a 40..60), s = swing (+ = front), z = along the beams.

    python3 marbles/clock/wheel_box.py              # prints dims, writes marbles/views/scenes/*.json
    python3 marbles/clock/wheel_box.py --material plywood_veneer_3ply_3mm      # 2.6 mm plywood
    python3 marbles/clock/wheel_box.py --material plywood_veneer_3ply_3mm --t 5.2   # two plywood layers
"""
import argparse
import json
import math
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from laser_parts import material_fit  # noqa: E402
sys.path.insert(0, str(Path(__file__).resolve().parent))
from short_parts import keeper as rail_keeper, view_slots  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--material", default="mdf_3mm", help="material profile id (thickness, kerf, slot fit)")
ap.add_argument("--t", type=float, default=None, help="override sheet thickness (e.g. 5.2 for two plywood layers)")
ap.add_argument("--fit", type=float, default=None, help="override extra slot width for tabs")
args = ap.parse_args()

_t, _kerf, _extra = material_fit(args.material)
T = args.t if args.t is not None else _t            # mdf_3mm: 3.1
FIT = args.fit if args.fit is not None else _extra  # mdf_3mm: 0 (verified: tight, snug, no deforming)
KERF = _kerf                                        # mdf_3mm: 0.10
M5 = 5.0
TAB = 10.0                    # tab / finger width (narrower frays MDF corners)
MIN_WEB = 4.0                 # no strip of material narrower than this (or T, if larger)
WEB = max(MIN_WEB, T)

L = 300.0
M5_U = [30.0, 90.0, 150.0, 210.0, 270.0]

# polymer V-wheel (OpenBuilds solid): 24 OD, 10 wide, 5 bore (625 bearings)
WOD, WW = 24.0, 10.0
AX = 9.85                     # axle centre from the beam face (39.7 c-c across a 2020)
ADJ = 1.5                     # keeper slot travel each way (sets wheel tension)
NUT_H, NUT_AF, WASH = 4.7, 8.0, 1.0   # ISO M5 nut; shim/washer on the inner race (check yours)
CLR_M = 2.0                   # box walls clear M's far face by this
CLR_K = 0.5                   # far cheek clears the other keeper's outer face by this
BOLT_CLR = None               # top/bottom walls clear the through bolts by this (= WEB, set below)
WK_L = 150.0                  # wheel keeper length (2 fit along a 300 sheet edge)
WK_SLOTS = [-60.0, 0.0, 60.0] # beam-row slots, relative to the wheel keeper's centre
BOX_Z = [WK_L / 2, L - WK_L / 2]   # as drawn: two wheel keepers end to end on each beam
BOLT_DZ = 30.0                # through bolts use the keeper's far-row holes at zc +/- 30

# ---- W_F box, in assembly coordinates (W_M is the mirror: a -> 60 - a, s -> 8.4 - s)
a_w, s_w = 60 + AX, -11.6 + 10            # axle (a), wheel mid-plane (s)
NCi = 20.0                                # near wall = K_F itself; its inner face (F's front face) is s = 20
KEEP_W = 40.0                             # keeper width away from the boxes (covers its beam + the ball column)
FILLET = 15.0                             # radius where the keeper curves out to a box lobe
FCi = -11.6 - T - CLR_K                   # far cheek inner face (clears K_M's outer face)
FCo = FCi - T
D = NCi - FCi                             # inside depth between cheeks
a_open = 60 + CLR_M                       # open side (toward M)
a_bi = a_w + WOD / 2 + 1.0                # back wall inner face (wheel moves with the box)
a_bo = a_bi + T
BOLT_CLR = WEB
H_i = BOLT_DZ + M5 / 2 + BOLT_CLR         # half inside height (z)
a_c0 = 57.0                               # cheeks reach toward M past the walls (clear of S_M/K_M bolt heads at a 45.75..54.25, even at -ADJ)
a_c1 = a_bo + WEB
z_c = H_i + T + WEB                       # cheek half height
gapA = NCi - (s_w + WW / 2)               # near cheek to wheel face: washer + nut A + free thread
gapB = (s_w - WW / 2) - FCi               # wheel face to far cheek: washer + nut B + clearance
k_out = 20.0 + T
bolt_len = k_out - FCo                    # keeper outer face to far cheek outer face

def P(*x):
    print(*x)
P(f"T = {T}, KERF = {KERF}, FIT = {FIT}, tab {TAB}, min web {WEB}")
P(f"wheel axle a = {a_w:.2f}, mid-plane s = {s_w:.2f}; rim reaches a = {a_w - WOD/2:.2f} (M far face a = 60)")
P(f"near wall = K_F s {NCi:.2f}..{NCi+T:.2f}; far cheek s {FCo:.2f}..{FCi:.2f}; inside depth D = {D:.2f}")
P(f"open side a = {a_open:.2f}; back wall a {a_bi:.2f}..{a_bo:.2f}; inside height 2 x {H_i:.2f} = {2*H_i:.2f}")
P(f"cheek plate: a {a_c0:.2f}..{a_c1:.2f} ({a_c1-a_c0:.2f}) x z +/-{z_c:.2f} ({2*z_c:.2f})")
P(f"keeper inner face to wheel: {gapA:.2f} (washer {WASH} + nut {NUT_H} + {gapA-WASH-NUT_H:.2f} free)")
P(f"wheel to far cheek inner face: {gapB:.2f} (washer {WASH} + nut {NUT_H} + {gapB-WASH-NUT_H:.2f} clear)")
BOLT_STD = next(x for x in (40, 45, 50, 55, 60, 65, 70, 80) if x >= bolt_len + NUT_H)
P(f"bolts: keeper outer s {k_out:.2f} to far cheek outer s {FCo:.2f} = {bolt_len:.2f} + nut {NUT_H} = {bolt_len+NUT_H:.2f} -> M5x{BOLT_STD}")
web_slot = (a_w - M5 / 2) - a_c0
P(f"web between axle hole and cheek edge (toward M): {web_slot:.2f}")
P(f"keeper slides +/-{ADJ}: open side then {a_open - ADJ:.2f}..{a_open + ADJ:.2f} (M far face 60), "
  f"cheek edge {a_c0 - ADJ:.2f} (bolt heads end at 54.25)")
P(f"keeper slots: v {10 - ADJ:.2f}..{10 + ADJ:.2f}, web to the keeper's edge {10 - ADJ - M5 / 2:.2f}")

# ---- tabs
def tab_spans(L0, L1):
    """k tabs of width TAB centred on [L0, L1], gaps equal (>= TAB when room)."""
    Lr = L1 - L0
    k = max(1, int((Lr - TAB) // (2 * TAB)))
    g = (Lr - k * TAB) / (k + 1)
    return [(L0 + g * (i + 1) + TAB * i, L0 + g * (i + 1) + TAB * (i + 1)) for i in range(k)]

def finger_segments(L0, L1):
    """odd number of equal segments, each >= TAB."""
    n = int((L1 - L0) // TAB)
    if n % 2 == 0:
        n -= 1
    n = max(1, n)
    w = (L1 - L0) / n
    return [(L0 + w * i, L0 + w * (i + 1)) for i in range(n)]

tb_tabs = tab_spans(a_open, a_bi)               # top/bottom tabs into the cheeks (along a)
bk_tabs = tab_spans(-H_i, H_i)                  # back wall tabs into the cheeks (along z, relative)
corner = finger_segments(FCi, NCi)              # TB/BK corner fingers along s
P(f"top/bottom tabs into cheeks at a: {[(round(x,2), round(y,2)) for x, y in tb_tabs]}")
P(f"back tabs into cheeks at z-zc: {[(round(x,2), round(y,2)) for x, y in bk_tabs]}")
P(f"corner fingers along s ({len(corner)} x {corner[0][1]-corner[0][0]:.2f}): TB owns the outer ones, BK the middle")

# ---- part outlines in their own plane
def hexagon(cx, cy, af):
    r = af / math.sqrt(3)
    return Polygon([(cx + r * math.cos(math.radians(60 * k)), cy + r * math.sin(math.radians(60 * k))) for k in range(6)])

def axle_hole(cz=0.0):
    return Point(a_w, cz).buffer(M5 / 2, 32)

def box_cuts():
    """holes and tab slots shared by the far cheek and the keeper lobe, in (a, z - zc)"""
    cuts = [axle_hole()] + [Point(70.0, dz).buffer(M5 / 2, 32) for dz in (-BOLT_DZ, BOLT_DZ)]
    w = T + FIT
    for zs in (1, -1):
        z0 = H_i if zs > 0 else -H_i - T
        for x0, x1 in tb_tabs:
            cuts.append(box(x0 - FIT / 2, z0 - FIT / 2, x1 + FIT / 2, z0 + w - FIT / 2))
    for z0, z1 in bk_tabs:
        cuts.append(box(a_bi - FIT / 2, z0 - FIT / 2, a_bi + w - FIT / 2, z1 + FIT / 2))
    return unary_union(cuts)

def cheek_2d():
    """far cheek, (a, z - zc)"""
    return box(a_c0, -z_c, a_c1, z_c).difference(box_cuts())

def tb_2d():
    """top/bottom wall in (a, s): body a_open..a_bi, corner fingers a_bi..a_bo, tabs through the cheeks."""
    g = box(a_open, FCi, a_bi, NCi)
    fingers = [box(a_bi, s0, a_bo, s1) for i, (s0, s1) in enumerate(corner) if i % 2 == 0]
    tabs = [box(x0, NCi - 0.01, x1, NCi + T) for x0, x1 in tb_tabs] + [box(x0, FCi - T, x1, FCi + 0.01) for x0, x1 in tb_tabs]
    return unary_union([g] + fingers + tabs)

def bk_2d():
    """back wall in (s, z - zc): body between top/bottom, middle corner fingers, tabs through the cheeks."""
    g = box(FCi, -H_i, NCi, H_i)
    fingers = []
    for i, (s0, s1) in enumerate(corner):
        if i % 2 == 1:
            fingers += [box(s0, H_i - 0.01, s1, H_i + T), box(s0, -H_i - T, s1, -H_i + 0.01)]
    tabs = [box(NCi - 0.01, z0, NCi + T, z1) for z0, z1 in bk_tabs] + [box(FCi - T, z0, FCi + 0.01, z1) for z0, z1 in bk_tabs]
    return unary_union([g] + fingers + tabs)

def wheel_keeper_2d():
    """WK: one wheel box's keeper, (u, v) = (along the beam, across from its own beam's outer face).
    WK_L long, KEEP_W wide, a lobe out to the box's outer edge in the middle (curving in with FILLET).
    Beam row v = 10: slots across (+/-ADJ) to set this one wheel's tension. Lobe: the box's bolt holes,
    round axle hole and tab slots."""
    zc = WK_L / 2
    g = unary_union([box(0, 0, WK_L, KEEP_W), box(zc - z_c, 0, zc + z_c, a_c1)])
    g = g.buffer(FILLET, 64).buffer(-FILLET, 64).intersection(box(0, 0, WK_L, a_c1))   # curve the inside corners
    g = g.buffer(-3, 32).buffer(3, 32)                                                  # round the outside corners
    cuts = [LineString([(zc + du, 10.0 - ADJ), (zc + du, 10.0 + ADJ)]).buffer(M5 / 2, 32) for du in WK_SLOTS]
    cuts.append(affinity.affine_transform(box_cuts(), [0, 1, 1, 0, zc, 0]))            # (a, dz) -> (u, v)
    cuts += view_slots(WK_L, 30.0)                                                      # over the ball column
    return g.difference(unary_union(cuts))

def plain_keeper_2d():
    """PK: plain backing/guard = short_parts keeper_10h (view slots + rail M5)."""
    return rail_keeper(10)

# min web checks (thinnest material between a cut and an edge / another cut)
def min_web(g):
    """narrowest wood between a hole and the outline, or between two holes (None if no holes)"""
    gs = [g] if g.geom_type == "Polygon" else list(g.geoms)
    best = None
    for poly in gs:
        rs = [LineString(r.coords) for r in poly.interiors]
        ext = LineString(poly.exterior.coords)
        for i, r in enumerate(rs):
            for o in [ext] + rs[i + 1:]:
                d = r.distance(o)
                best = d if best is None else min(best, d)
    return best
PARTS = {"FC": ("far cheek", cheek_2d(), 1), "TB": ("top / bottom wall", tb_2d(), 2), "BK": ("back wall", bk_2d(), 1)}
kp = wheel_keeper_2d()
P(f"wheel keeper WK: {WK_L:g} x {a_c1:.2f} (strip {KEEP_W:g} wide, lobe u {WK_L/2-z_c:.2f}..{WK_L/2+z_c:.2f}, fillet r {FILLET:g}); "
  f"beam slots at u {[WK_L/2 + d for d in WK_SLOTS]}; narrowest web {min_web(kp):.2f}")
pk = plain_keeper_2d()
P(f"plain keeper PK = short_parts keeper_10h (view slots + rail M5); narrowest web {min_web(pk):.2f}")
for k, (n, g, q) in PARTS.items():
    x0, y0, x1, y1 = g.bounds
    mw = min_web(g)
    P(f"{k} {n}: {x1-x0:.2f} x {y1-y0:.2f}, {q} per box ({4*q} total); "
      + (f"narrowest web hole-to-edge/hole {mw:.2f}" if mw is not None else f"no holes; tabs {TAB:g} wide"))

# ---------------------------------------------------------------- 3D scene
def rings(g):
    gs = [g] if g.geom_type == "Polygon" else list(g.geoms)
    return [{"outer": list(p.exterior.coords), "holes": [list(h.coords) for h in p.interiors]} for p in gs]

parts = []
def add(kind, pid, label, color, geom, lo, hi, opacity=1.0, group=None):
    parts.append({"id": pid, "label": label, "color": color, "opacity": opacity, "kind": kind,
                  "polys": rings(geom), "lo": min(lo, hi), "hi": max(lo, hi), "group": group or pid})

def mirror_part(p):
    """W_F -> W_M: a -> 60 - a, s -> 8.4 - s"""
    q = dict(p)
    if p["kind"] == "az":      # (a, z), extruded along s
        g = unary_union([Polygon(r["outer"], r["holes"]) for r in p["polys"]])
        q["polys"] = rings(affinity.affine_transform(g, [-1, 0, 0, 1, 60, 0]))
        q["lo"], q["hi"] = 8.4 - p["hi"], 8.4 - p["lo"]
    elif p["kind"] == "as":    # (a, s), extruded along z
        g = unary_union([Polygon(r["outer"], r["holes"]) for r in p["polys"]])
        q["polys"] = rings(affinity.affine_transform(g, [-1, 0, 0, -1, 60, 8.4]))
    else:                      # sz: (s, z), extruded along a
        g = unary_union([Polygon(r["outer"], r["holes"]) for r in p["polys"]])
        q["polys"] = rings(affinity.affine_transform(g, [-1, 0, 0, 1, 8.4, 0]))
        q["lo"], q["hi"] = 60 - p["hi"], 60 - p["lo"]
    return q

def profile2020(a0, s0):
    sq = box(0, 0, 20, 20)
    cuts = []
    for ang in (0, 90, 180, 270):
        sl = unary_union([box(10 - 3.1, 20 - 1.8, 10 + 3.1, 20.1), box(10 - 5.5, 20 - 6.1, 10 + 5.5, 20 - 1.8),
                          Polygon([(10 - 4.6, 20.01), (10 + 4.6, 20.01), (10 + 3.1, 18.5), (10 - 3.1, 18.5)])])
        cuts.append(affinity.rotate(sl, ang, origin=(10, 10)))
    return affinity.translate(sq.difference(unary_union(cuts)).difference(Point(10, 10).buffer(2.1, 24)), a0, s0)

def sieve2d(on_f):
    if on_f:
        g, ba = box(0, 0, 46, L), 10
    else:
        g, ba = box(14, 0, 60, L), 50
    hs = [Point(30, 15 + 30 * i).buffer(10, 64) for i in range(10)] + [Point(ba, u).buffer(M5 / 2, 32) for u in M5_U]
    return g.difference(unary_union(hs))

BEAM, BEAM_M = "#b8c4cf", "#d9b8a8"
F_COL, M_COL = "#d4b07a", "#e6c995"
BOX_F, BOX_M = "#9cc28a", "#c7a3d9"
WHEEL, STEEL, WASHC = "#8d97a3", "#555b61", "#c9cdd2"

def keeper_az(on_f, zc):
    """wheel keeper centred at z = zc, in (a, z)"""
    k = wheel_keeper_2d()         # (u, v)
    if on_f:                      # a = v, z = u
        return affinity.affine_transform(k, [0, 1, 1, 0, 0, zc - WK_L / 2])
    return affinity.affine_transform(k, [0, -1, 1, 0, 60, zc - WK_L / 2])   # a = 60 - v

def box_parts(zc, tag, col, explode=0.0, hardware=True):
    """W_F box at zc, as a list of part dicts (mirror for W_M)."""
    out_start = len(parts)
    ch = affinity.translate(cheek_2d(), 0, zc)
    e = explode
    add("az", f"CHf{tag}", "FC far cheek", col, ch, FCo - e, FCi - e, group=f"box{tag}")
    tb = tb_2d()
    add("as", f"TBt{tag}", "TB top wall", col, tb, zc + H_i + 1.6 * e, zc + H_i + T + 1.6 * e, group=f"box{tag}")
    add("as", f"TBb{tag}", "TB bottom wall", col, tb, zc - H_i - T - 1.6 * e, zc - H_i - 1.6 * e, group=f"box{tag}")
    add("sz", f"BK{tag}", "BK back wall", col, affinity.translate(bk_2d(), 0, zc), a_bi + 1.6 * e, a_bo + 1.6 * e, group=f"box{tag}")
    if hardware:
        for r, w, k in ((10.0, WW, 0), (11.0, 8.0, 1), (12.0, 6.0, 2)):
            add("az", f"wh{tag}{k}", "V-wheel", WHEEL, Point(a_w, zc).buffer(r, 64), s_w - w / 2, s_w + w / 2, group=f"wheel{tag}")
        ann = Point(a_w, zc).buffer(5.0, 32).difference(Point(a_w, zc).buffer(2.6, 24))
        add("az", f"wa{tag}", "washer", WASHC, ann, s_w + WW / 2, s_w + WW / 2 + WASH, group=f"hw{tag}")
        add("az", f"wb{tag}", "washer", WASHC, ann, s_w - WW / 2, s_w - WW / 2 - WASH, group=f"hw{tag}")
        hx = hexagon(a_w, zc, NUT_AF).difference(Point(a_w, zc).buffer(2.5, 24))
        add("az", f"na{tag}", "nut A", STEEL, hx, s_w + WW / 2 + WASH, s_w + WW / 2 + WASH + NUT_H, group=f"hw{tag}")
        add("az", f"nb{tag}", "nut B", STEEL, hx, s_w - WW / 2 - WASH, s_w - WW / 2 - WASH - NUT_H, group=f"hw{tag}")
        for a, dz, nm in ((a_w, 0, "axle"), (70.0, -BOLT_DZ, "bolt"), (70.0, BOLT_DZ, "bolt")):
            add("az", f"{nm}{tag}{dz}", f"M5x{BOLT_STD} {nm}", STEEL, Point(a, zc + dz).buffer(2.5, 24), k_out + 3, FCo - NUT_H - 1, group=f"hw{tag}")
            add("az", f"{nm}h{tag}{dz}", f"M5x{BOLT_STD} {nm}", STEEL, Point(a, zc + dz).buffer(4.25, 24), k_out, k_out + 5, group=f"hw{tag}")
            add("az", f"{nm}n{tag}{dz}", "nut", STEEL, hexagon(a, zc + dz, NUT_AF), FCo, FCo - NUT_H, group=f"hw{tag}")
    return parts[out_start:]

def build_assembly(ghost_keepers=0.55):
    parts.clear()
    add("as", "F", "F", BEAM, profile2020(0, 0), -20, 320)
    add("as", "M", "M", BEAM_M, profile2020(40, -11.6), -20, 320)
    add("az", "S_F", "S_F", F_COL, sieve2d(True), -T, 0)
    add("az", "S_M", "S_M", M_COL, sieve2d(False), 8.4, 8.4 + T)
    for zc in BOX_Z:
        add("az", f"K_F{int(zc)}", "WK on F", F_COL, keeper_az(True, zc), 20, 20 + T, ghost_keepers, group="K_F")
        add("az", f"K_M{int(zc)}", "WK on M", M_COL, keeper_az(False, zc), -11.6 - T, -11.6, ghost_keepers, group="K_M")
    for zc in BOX_Z:
        fbox = box_parts(zc, f"F{int(zc)}", BOX_F)
        for p in fbox:
            q = mirror_part(p)
            q["id"] = q["id"].replace("F", "M", 1) + "m"
            q["group"] = q["group"].replace(f"F{int(zc)}", f"M{int(zc)}")
            if q["color"] == BOX_F:
                q["color"] = BOX_M
            parts.append(q)
    for u in M5_U:   # keeper / sieve bolts into the beam slots (heads)
        add("az", f"kbF{u}", "M5", STEEL, Point(10, u).buffer(4.25, 24), 20 + T, 25 + T)
        add("az", f"kbM{u}", "M5", STEEL, Point(50, u).buffer(4.25, 24), -11.6 - T, -16.6 - T)
        add("az", f"sbF{u}", "M5", STEEL, Point(10, u).buffer(4.25, 24), -T, -T - 5)
        add("az", f"sbM{u}", "M5", STEEL, Point(50, u).buffer(4.25, 24), 8.4 + T, 13.4 + T)
    return list(parts)

OUT = Path(__file__).resolve().parent.parent / "views" / "scenes"
OUT.mkdir(parents=True, exist_ok=True)
balls = [{"c": [30, 4.2, 15 + 30 * i - 0.5], "r": 9.525} for i in range(10)]
assy = build_assembly()
json.dump({"parts": assy, "balls": balls}, open(OUT / "box_assembly.json", "w"))

ZC = BOX_Z[0]
half = box(-500, -500, 500, ZC)
sec = []
for p in assy:
    q = dict(p)
    if p["kind"] == "az":
        g = unary_union([Polygon(r["outer"], r["holes"]) for r in p["polys"]]).intersection(half)
        g = unary_union([x for x in (g.geoms if hasattr(g, "geoms") else [g]) if x.geom_type == "Polygon"]) if not g.is_empty else g
        if g.is_empty:
            continue
        q["polys"] = rings(g)
    elif p["kind"] == "as":
        if p["lo"] >= ZC:
            continue
        q["hi"] = min(p["hi"], ZC)
    else:
        g = unary_union([Polygon(r["outer"], r["holes"]) for r in p["polys"]]).intersection(box(-500, -500, 500, ZC))
        if g.is_empty:
            continue
        q["polys"] = rings(g)
    sec.append(q)
json.dump({"parts": sec, "balls": [b for b in balls if b["c"][2] + b["r"] <= ZC]}, open(OUT / "box_section.json", "w"))

# one box alone (W_F lower) with stubs of M and K_F
parts.clear()
add("as", "M", "M", BEAM_M, profile2020(40, -11.6), 60 - WK_L / 2 - 5, 60 + WK_L / 2 + 5)
kf = keeper_az(True, 60.0)
add("az", "K_F", "K_F", F_COL, kf, 20, 20 + T, 0.55)
box_parts(60.0, "F60", BOX_F)
json.dump({"parts": list(parts), "balls": []}, open(OUT / "box_one.json", "w"))
parts.clear()
add("az", "K_F", "K_F", F_COL, kf, 20 + 24, 20 + T + 24, 1.0)
box_parts(60.0, "F60", BOX_F, explode=24.0, hardware=False)
json.dump({"parts": list(parts), "balls": []}, open(OUT / "box_exploded.json", "w"))

def thumbs(lst):
    return [{"key": k, "name": n, "per_fork": q, "polys": rings(g), "bounds": g.bounds} for k, n, q, g in lst]
json.dump({"parts": thumbs([(k, n, q, g) for k, (n, g, q) in PARTS.items()]),
           "assy": thumbs([("S_F / S_M", "sieve 300 x 46 (lift_sieve)", 2, sieve2d(True)),
                           ("WK", f"wheel keeper {WK_L:g} long (one per wheel)", 4, wheel_keeper_2d()),
                           ("PK", f"plain keeper {L:g} x {KEEP_W:g} (as needed)", 0, plain_keeper_2d()),
                           ("box", "wheel box: FC x1, TB x2, BK x1", 4, cheek_2d())])},
          open(OUT / "box_thumbs.json", "w"))
json.dump({"T": T, "NCi": NCi, "FCi": FCi, "FCo": FCo, "a_w": a_w, "s_w": s_w, "a_bi": a_bi, "a_bo": a_bo, "H_i": H_i,
           "a_c0": a_c0, "a_c1": a_c1, "z_c": z_c, "a_open": a_open, "corner": corner, "BOX_Z": BOX_Z},
          open(OUT / "box_dims.json", "w"))
