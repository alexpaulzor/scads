"""Views of the side-entry feeder box (reads scenes/feeder_box.json from clock/feeder_box.py)."""
import json, math
from shapely import affinity
from shapely.geometry import Point, Polygon, box
from shapely.ops import unary_union
d = json.load(open("scenes/feeder_box.json"))
T, H, GAP = d["T"], d["H"], d["GAP"]
sbk, sfk = d["s_bk_in"], d["s_fk_in"]
F_END = d["f_end"]
def rings(g):
    gs = [g] if g.geom_type == "Polygon" else list(g.geoms)
    return [{"outer": list(p.exterior.coords), "holes": [list(h.coords) for h in p.interiors]} for p in gs]
def P(pid, label, color, kind, polys, lo, hi, op=1.0, group=None):
    return {"id": pid, "label": label, "color": color, "opacity": op, "kind": kind, "polys": polys, "lo": lo, "hi": hi, "group": group or pid}
def profile2020(a0, s0):
    sq = box(0, 0, 20, 20); cuts = []
    for ang in (0, 90, 180, 270):
        sl = unary_union([box(6.9, 18.2, 13.1, 20.1), box(4.5, 13.9, 15.5, 18.2), Polygon([(5.4, 20.01), (14.6, 20.01), (13.1, 18.5), (6.9, 18.5)])])
        cuts.append(affinity.rotate(sl, ang, origin=(10, 10)))
    return affinity.translate(sq.difference(unary_union(cuts)).difference(Point(10, 10).buffer(2.1, 24)), a0, s0)
WOOD, KEEP, WALL, BEAM, BEAM_M, DUCT = "#e39b5b", "#9cc28a", "#7fae6a", "#b8c4cf", "#d9b8a8", "#c7a3d9"
parts = [P("FF", "funnel", WOOD, "az", d["FF"], -T, 0),
         P("FK", "front keeper", KEEP, "az", d["FK"], sfk, sfk + T, 0.6),
         P("BK", "back keeper", KEEP, "az", d["BK"], sbk - T, sbk, 0.6),
         P("OW", "outer wall", WALL, "sz", d["OW"], d["OW_a"][0], d["OW_a"][1]),
         P("TW", "top wall", WALL, "as", d["TW"], d["TW_z"][0], d["TW_z"][1]),
         P("BW", "bottom wall", WALL, "as", d["BW"], d["BW_z"][0], d["BW_z"][1])]
sf = box(0, 0, 46, 130).difference(unary_union([Point(30, 15 + 30 * i).buffer(10, 64) for i in range(4)] + [Point(10, u).buffer(2.5, 32) for u in (30, 90)]))
parts.append(P("S_F", "S_F", "#d4b07a", "az", rings(sf), -T, 0))
parts.append(P("F", "F", BEAM, "as", rings(profile2020(0, 0)), F_END, 130))
parts.append(P("M", "M", BEAM_M, "as", rings(profile2020(40, -11.6)), -H - 5, 130))
sm = box(14, -H, 60, 130).difference(unary_union([Point(30, z).buffer(10, 64) for z in range(-125, 130, 30)]))
parts.append(P("S_M", "S_M", "#e6c995", "az", rings(sm), 8.4, 8.4 + T, 0.5))
# an example duct on the port: 4 walls, 20 inside, 30 long, sticking out the front
pc = (46 - d["PORT_C"][0], d["PORT_C"][1] - H)
L0, L1 = sfk + T, sfk + T + 30
for i, g in enumerate([box(pc[0] - 10 - T, pc[1] - 10 - T, pc[0] - 10, pc[1] + 10 + T), box(pc[0] + 10, pc[1] - 10 - T, pc[0] + 10 + T, pc[1] + 10 + T),
                       box(pc[0] - 10, pc[1] - 10 - T, pc[0] + 10, pc[1] - 10), box(pc[0] - 10, pc[1] + 10, pc[0] + 10, pc[1] + 10 + T)]):
    parts.append(P(f"duct{i}", "example duct", DUCT, "az", rings(g), L0, L1, 0.6, group="duct"))
# balls: one coming in through the port, a queue down the channel, one in the bottom hole
bp = d["ball_path"][::-1]
pts, acc, last = [bp[0]], 0.0, bp[0]
for p in bp[1:]:
    acc += math.dist(p, last); last = p
    if acc >= 19.4:
        pts.append(p); acc = 0.0
balls = [{"c": [p[0], -T / 2, p[1]], "r": 9.525} for p in pts[:4]]
balls.append({"c": [pc[0], sfk + T + 15, pc[1]], "r": 9.525})
json.dump({"parts": parts, "balls": balls}, open("scenes/feederbox.json", "w"))
ZC = pc[1]
sec = []
for p in parts:
    q = dict(p)
    g = unary_union([Polygon(r["outer"], r["holes"]) for r in p["polys"]])
    if p["kind"] == "az" or p["kind"] == "sz":
        g = g.intersection(box(-500, -500, 500, ZC))
        if g.is_empty: continue
        q["polys"] = rings(g)
    else:
        if p["lo"] >= ZC: continue
        q["hi"] = min(p["hi"], ZC)
    sec.append(q)
json.dump({"parts": sec, "balls": [b for b in balls if b["c"][2] - b["r"] < ZC]}, open("scenes/feederbox_sec.json", "w"))
FRONT = {"dir": [0, 0, -1], "up": [0, 1, 0]}
TOP = {"dir": [0, -1, 0], "up": [-1, 0, 0]}
SIDE = {"dir": [1, 0, 0], "up": [0, 1, 0]}
ISO = {"dir": [0.8, -0.55, -1.2], "up": [0, 1, 0]}
FC, MC, GK, K, O, DC = "#3d5a73", "#8a4a2f", "#3f6e2a", "#333", "#a8501a", "#6b3f85"
sub = ["Side-entry feeder box under S_F. Balls come in sideways through the port in the front keeper, drop into the pocket,",
       f"queue down the closed-top J channel into the bottom hole. Keepers are {d['INSIDE']:g} apart inside, the funnel centred between them."]
lab = [["F (ends above the channel)", [10, 10, F_END + 5], "R", FC], ["M", [50, -1.6, 100], "R", MC], ["S_F", [5, -T / 2, 100], "L", FC],
       ["funnel FF (closed top, bridge over the pocket)", [-30, -T / 2, -8], "L", O],
       ["front keeper FK, edge in F's far slot (see-through)", [-5, sfk + T, -40], "L", GK],
       ["back keeper BK (see-through)", [-40, sbk - T, -130], "L", GK], ["outer wall OW", [-47.5, 0, -70], "L", GK], ["top wall TW", [-30, 0, 1.5], "R", GK], ["bottom wall BW (box closed, no beam)", [-30, 0, -H - 1.5], "R", GK],
       ["port: 20 square, 10 mm tab slots, 4 x M5", [pc[0] + 10, sfk + T, pc[1] + 14], "R", DC], ["example 20-inside duct", [pc[0] + 11, sfk + T + 25, pc[1]], "R", DC],
       ["queued balls", [-10, -T / 2, -80], "L", "#24546b"], ["bottom hole: M picks up here", [30, -T / 2, -105], "R", "#24546b"]]
v = {}
v["fb_front"] = {"scene": "feederbox.json", "cam": FRONT, "title": "6a  Side-entry feeder box, front view", "sub": sub, "labels": lab,
                 "ghost": ["FK", "S_M", "duct"], "ghost_op": 0.18, "w": 1700, "h": 1150, "ml": 470, "mr": 420}
v["fb_section"] = {"scene": "feederbox_sec.json", "cam": TOP, "title": f"6b  Section through the port (z = {ZC:g}), looking down",
                   "sub": ["FRONT on the LEFT. Ball enters from the duct (left), through the front keeper, into the funnel's pocket.",
                           f"Funnel {GAP:.2f} off each keeper; the walls hold the keepers {d['INSIDE']:g} apart."],
                   "labels": [["funnel FF", [-35, -T / 2, ZC], "R", O], ["front keeper FK", [-35, sfk + T / 2, ZC], "L", GK],
                              ["back keeper BK", [-35, sbk - T / 2, ZC], "R", GK], ["outer wall OW", [-47.5, 0, ZC], "R", GK],
                              ["example duct", [pc[0] - 11.5, sfk + 20, ZC], "L", DC], ["ball coming in", [pc[0], sfk + T + 15, ZC], "L", "#24546b"],
                              ["M", [50, -1.6, ZC], "R", MC], ["F", [10, 10, ZC], "L", FC]],
                   "notes": [{"t": "FRONT", "at": [70, 35, ZC]}, {"t": "BACK", "at": [70, -30, ZC]}]}
v["fb_side"] = {"scene": "feederbox.json", "cam": SIDE, "title": "6c  Side view, from the outer wall", "sub": ["FRONT on the RIGHT."] + sub[1:],
                "labels": [["outer wall OW (tabs through both keepers)", [-49, 0, -60], "L", GK], ["example duct on the port", [pc[0], sfk + 25, pc[1]], "R", DC],
                           ["top wall TW", [-49, 0, 1.5], "L", GK], ["M", [40, -1.6, 110], "L", MC], ["F", [0, 10, 100], "R", FC]],
                "w": 1500, "h": 1150, "ml": 430}
v["fb_iso"] = {"scene": "feederbox.json", "cam": ISO, "title": "6d  Side-entry feeder box, angled", "sub": sub, "w": 1700, "ml": 470, "mr": 400,
               "labels": lab, "ghost": ["FK"], "ghost_op": 0.3}
old = json.load(open("scenes/views.json")); old.update(v)
json.dump(old, open("scenes/views.json", "w"), indent=1)
print(list(v))
