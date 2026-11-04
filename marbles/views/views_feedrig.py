"""Render of the feed funnel at the bottom of the lift, as Claude understands the intent (2026-11-04).

Reads scenes/funnel_parts.json (from clock/feed_funnel.py). Coordinates as the lift drawings:
a across (F at a 0..20, M at a 40..60), s swing (+ front), z up (S_F's bottom end at z = 0).
Writes scenes/feedrig*.json and adds views fr_* to scenes/views.json.
"""
import json
import math

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

d = json.load(open("scenes/funnel_parts.json"))
T, H = d["T"], d["H"]
F_END = -75.0          # F's bottom end: above where the channel passes under F (ball top ~ z -83)
GAP = 8.4              # funnel face to each keeper: ball 19.05 = 3.1 plate + 2 x 8.4 - 0.85 play
S_BALL = -T / 2        # ball centre plane (mid funnel)
FK_S = (GAP, GAP + T)                  # front slot keeper: same plane as S_M / F's side slots (s 8.4..11.5)
BK_S = (-T - GAP - T, -T - GAP)        # back keeper


def rings(g):
    gs = [g] if g.geom_type == "Polygon" else list(g.geoms)
    return [{"outer": list(p.exterior.coords), "holes": [list(h.coords) for h in p.interiors]} for p in gs]


def profile2020(a0, s0):
    sq = box(0, 0, 20, 20)
    cuts = []
    for ang in (0, 90, 180, 270):
        sl = unary_union([box(10 - 3.1, 20 - 1.8, 10 + 3.1, 20.1), box(10 - 5.5, 20 - 6.1, 10 + 5.5, 20 - 1.8),
                          Polygon([(10 - 4.6, 20.01), (10 + 4.6, 20.01), (10 + 3.1, 18.5), (10 - 3.1, 18.5)])])
        cuts.append(affinity.rotate(sl, ang, origin=(10, 10)))
    return affinity.translate(sq.difference(unary_union(cuts)).difference(Point(10, 10).buffer(2.1, 24)), a0, s0)


def P(pid, label, color, kind, geom, lo, hi, op=1.0, group=None):
    return {"id": pid, "label": label, "color": color, "opacity": op, "kind": kind, "polys": rings(geom),
            "lo": lo, "hi": hi, "group": group or pid}


ff = unary_union([Polygon(r["outer"], r["holes"]) for r in d["parts"][0]["polys"]])     # funnel in (a, z)
WOOD, WOOD_M, KEEP, BEAM, BEAM_M, STEEL = "#e39b5b", "#e6c995", "#9cc28a", "#b8c4cf", "#d9b8a8", "#555b61"
parts = [P("FF", "feed funnel", WOOD, "az", ff, -T, 0)]
# S_F above the funnel (stub), on F's back face
sf = box(0, 0, 46, 130).difference(unary_union([Point(30, 15 + 30 * i).buffer(10, 64) for i in range(4)]
                                               + [Point(10, u).buffer(2.5, 32) for u in (30, 90)]))
parts.append(P("S_F", "S_F", "#d4b07a", "az", sf, -T, 0))
# beams: F ends above the channel crossing; M runs down past the funnel (the funnel's edge rides in its near slot)
parts.append(P("F", "F", BEAM, "as", profile2020(0, 0), F_END, 130))
parts.append(P("M", "M", BEAM_M, "as", profile2020(40, -11.6), -H - 5, 130))
# S_M on M's front face, holes lined up with the funnel's (moment: M's holes level with F's)
sm = box(14, -H, 60, 130).difference(unary_union([Point(30, z).buffer(10, 64) for z in range(-125, 130, 30)]
                                                 + [Point(50, z).buffer(2.5, 32) for z in (-80, -20, 40, 100)]))
parts.append(P("S_M", "S_M", WOOD_M, "az", sm, 8.4, 8.4 + T))
# front slot keeper: edge 6 mm into F's far slot above F's end, reaches under F below it; covers the channel
fk = unary_union([box(-52, F_END, 6, 0), box(-52, -H, 12, F_END)])
fk = fk.buffer(-2, join_style=2).buffer(2, join_style=2)
parts.append(P("FKS", "front slot keeper", KEEP, "az", fk, FK_S[0], FK_S[1], 0.55))
# back keeper on spacers through the funnel's band and beam holes
bk = box(-52, -H, 38, 0)
holes = [(30, -H + 10), (0, -H + 10), (-30, -H + 10), (10, -60), (10, -30)]
bk = bk.difference(unary_union([Point(p).buffer(2.5, 32) for p in holes]))
parts.append(P("BK", "back keeper", KEEP, "az", bk, BK_S[0], BK_S[1], 0.55))
for i, p in enumerate(holes[:3]):
    parts.append(P(f"sp{i}", "spacer", "#c9cdd2", "az", Point(p).buffer(5, 32).difference(Point(p).buffer(2.6, 24)),
                   BK_S[1], -T, group="spacer"))
# short 2020 behind the back keeper, across, carrying the band
sq = Polygon([(BK_S[0] - 20, -H), (BK_S[0], -H), (BK_S[0], -H + 20), (BK_S[0] - 20, -H + 20)])
parts.append({"id": "X2020", "label": "short 2020", "color": BEAM, "opacity": 1, "kind": "sz",
              "polys": [{"outer": list(sq.exterior.coords), "holes": []}], "lo": -50, "hi": 45, "group": "X2020"})
# balls: queue in the channel, one in the bottom hole, a few up the lift column
bp = [(a, z) for a, z in d["ball_path"]][::-1]
pts, acc, last = [bp[0]], 0.0, bp[0]
for p in bp[1:]:
    acc += math.dist(p, last); last = p
    if acc >= 19.4:
        pts.append(p); acc = 0.0
balls = [{"c": [p[0], S_BALL, p[1]], "r": 9.525} for p in pts[:5]]
balls += [{"c": [30, 4.2, z], "r": 9.525} for z in (15 - 0.5, 45 - 0.5, 75 - 0.5)]
json.dump({"parts": parts, "balls": balls}, open("scenes/feedrig.json", "w"))

# section through the channel where it passes under F (z = -95), looking down
ZC = -95.0
sec = []
for p in parts:
    q = dict(p)
    if p["kind"] == "az":
        g = unary_union([Polygon(r["outer"], r["holes"]) for r in p["polys"]]).intersection(box(-500, -500, 500, ZC))
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
json.dump({"parts": sec, "balls": [b for b in balls if b["c"][2] - b["r"] < ZC]}, open("scenes/feedrig_sec.json", "w"))

# neck: the strip left of the bottom hole that joins the funnel's sieve column to the rest
neck = 46 - 30 - 10
print(f"F ends at z {F_END}; channel passes under F at z about -102..-92 (ball top about -83)")
print(f"keepers: front s {FK_S[0]:.1f}..{FK_S[1]:.1f} (F's side-slot plane), back s {BK_S[0]:.1f}..{BK_S[1]:.1f}; "
      f"ball centre s {S_BALL:.2f}, clearance each side {GAP - (9.525 - T / 2):.2f}")
print(f"neck (wood left of the bottom hole) = 46 - 30 - 10 = {neck:g} mm")

FRONT = {"dir": [0, 0, -1], "up": [0, 1, 0]}
TOP = {"dir": [0, -1, 0], "up": [-1, 0, 0]}
SIDE = {"dir": [1, 0, 0], "up": [0, 1, 0]}            # from the channel side (a-), looking toward the lift
ISO = {"dir": [0.8, -0.55, -1.2], "up": [0, 1, 0]}
FC, MC, GK, K, O = "#3d5a73", "#8a4a2f", "#3f6e2a", "#333", "#a8501a"
sub = ["As Claude understands it: the funnel continues S_F below the lift; balls queue down the J channel into the bottom hole,",
       "where M's lowest hole picks them up. F ends above the channel; keepers 8.4 mm off each face hold the balls in the channel."]
lab = [["F (ends above the channel)", [10, 10, F_END + 5], "R", FC], ["M", [50, -1.6, 100], "R", MC],
       ["S_F", [5, -T / 2, 100], "L", FC], ["feed funnel FF", [-45, -T / 2, -60], "L", O],
       ["front keeper in F's side slot (see-through)", [-10, FK_S[1], -40], "L", GK],
       ["back keeper on spacers (see-through)", [-45, BK_S[0], -120], "L", GK],
       ["queued balls", [-20, S_BALL, -50], "L", "#24546b"], ["bottom hole: M picks up here", [30, S_BALL, -105], "R", "#24546b"],
       ["short 2020 behind the band", [45, BK_S[0] - 10, -H + 10], "R", K],
       [f"neck: only {neck:g} mm (left of the bottom hole)", [43, -T / 2, -105], "R", "#b3261e"]]
v = {}
v["fr_front"] = {"scene": "feedrig.json", "cam": FRONT, "title": "5a  Feed funnel at the bottom of the lift, front view", "sub": sub,
                 "labels": lab, "ghost": ["FKS", "S_M"], "ghost_op": 0.18, "w": 1600, "h": 1150, "ml": 400, "mr": 420}
v["fr_section"] = {"scene": "feedrig_sec.json", "cam": TOP, "title": f"5b  Section at z = {ZC:g} (where the channel passes under F), looking down",
                   "sub": ["FRONT on the LEFT. The ball sits between the two keepers, 8.4 mm off each face of the funnel.",
                           "F has ended above this cut; M (right) carries S_M and the funnel's edge in its near slot."],
                   "labels": [["feed funnel FF", [-40, -T / 2, ZC], "R", O], ["front keeper (F's side-slot plane)", [-40, FK_S[1], ZC], "L", GK],
                              ["back keeper", [-40, BK_S[0], ZC], "R", GK], ["S_M", [20, 8.4 + T, ZC], "L", MC],
                              ["M", [50, -1.6, ZC], "R", MC], ["ball in the channel", [8, S_BALL, ZC], "L", "#24546b"]],
                   "notes": [{"t": "FRONT", "at": [70, 25, ZC]}, {"t": "BACK", "at": [70, -30, ZC]}]}
v["fr_side"] = {"scene": "feedrig.json", "cam": SIDE, "title": "5c  Side view, from the channel side", "sub": ["FRONT on the RIGHT."] + sub[1:],
                "labels": [["front keeper", [-52, FK_S[1], -60], "R", GK], ["back keeper", [-52, BK_S[0], -60], "L", GK],
                           ["feed funnel FF (edge)", [-52, -T / 2, -20], "L", O], ["short 2020", [-50, BK_S[0] - 10, -H + 10], "L", K],
                           ["F", [0, 10, 100], "R", FC], ["M", [40, -1.6, 110], "L", MC]],
                "w": 1300, "h": 1150}
v["fr_iso"] = {"scene": "feedrig.json", "cam": ISO, "title": "5d  Feed funnel at the bottom of the lift, angled", "sub": sub,
               "labels": [l for l in lab if not l[0].startswith("neck")], "ghost": ["FKS"], "ghost_op": 0.25, "w": 1600, "ml": 400, "mr": 380}
old = json.load(open("scenes/views.json"))
old.update(v)
json.dump(old, open("scenes/views.json", "w"), indent=1)
print(list(v))
