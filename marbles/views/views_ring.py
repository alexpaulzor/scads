"""Views of the wire-ring jig and a spider mandrel (reads scenes/ring_jig.json from clock/ring_jig.py)."""
import json, math
from shapely.geometry import Point, Polygon
from shapely.ops import unary_union
from shapely import affinity
d = json.load(open("scenes/ring_jig.json"))
T, WD, ID, OD, CL = d["T"], d["WD"], d["RING_ID"], d["RING_OD"], d["RING_CL"]
C = d["C"]
def P(rings): return rings
def ann(c, d0, d1): return Point(c).buffer(d1 / 2, 96).difference(Point(c).buffer(d0 / 2, 96))
def rings(g):
    gs = [g] if g.geom_type == "Polygon" else list(g.geoms)
    return [{"outer": list(p.exterior.coords), "holes": [list(h.coords) for h in p.interiors]} for p in gs]
WOOD, WOOD2, STEEL, WIRE = "#d4b07a", "#c99a5c", "#555b61", "#b87333"
# --- jig lying flat: 'as' = polygon in (x, y-on-bench) extruded up
jig = [{"id": "JB", "label": "base", "color": WOOD2, "opacity": 1, "kind": "as", "polys": d["base"], "lo": 0, "hi": T, "group": "JB"},
       {"id": "JC", "label": "core", "color": WOOD, "opacity": 1, "kind": "as",
        "polys": rings(Polygon(d["core"][0]["outer"], d["core"][0]["holes"])), "lo": T, "hi": 2 * T, "group": "JC"},
       {"id": "JT", "label": "top", "color": WOOD, "opacity": 1, "kind": "as", "polys": d["top"], "lo": T, "hi": 2 * T, "group": "JT"},
       {"id": "ring", "label": "wire ring", "color": WIRE, "opacity": 1, "kind": "as", "polys": rings(ann(C, ID, OD)),
        "lo": T, "hi": T + WD, "group": "ring"}]
json.dump({"parts": jig, "balls": []}, open("scenes/ring_jig_scene.json", "w"))
# --- mandrel: spiders on an M5 rod along x, straight wires in the notches, rings over them
sp = Polygon(d["spider"][0]["outer"], d["spider"][0]["holes"])
man = []
for i, x in enumerate((0, 45, 90)):
    man.append({"id": f"sp{i}", "label": "spider", "color": WOOD, "opacity": 1, "kind": "sz",
                "polys": rings(sp), "lo": x, "hi": x + T, "group": "sp"})
man.append({"id": "rod", "label": "M5 rod", "color": STEEL, "opacity": 1, "kind": "sz",
            "polys": rings(Point(0, 0).buffer(2.5, 32)), "lo": -15, "hi": 110, "group": "rod"})
rw = ID / 2 - WD / 2
for k, a in enumerate(d["angles"]):
    c = (rw * math.cos(math.radians(a)), rw * math.sin(math.radians(a)))
    man.append({"id": f"w{k}", "label": "straight wire", "color": WIRE, "opacity": 1, "kind": "sz",
                "polys": rings(Point(c).buffer(WD / 2, 24)), "lo": -10, "hi": 105, "group": "wire"})
for i, x in enumerate((15, 30, 60, 75)):
    man.append({"id": f"r{i}", "label": "ring", "color": WIRE, "opacity": 1, "kind": "sz",
                "polys": rings(ann((0, 0), ID, OD)), "lo": x, "hi": x + WD, "group": "ring"})
json.dump({"parts": man, "balls": [{"c": [100 - 0, 0, 0], "r": 9.525}]}, open("scenes/ring_mandrel.json", "w"))
# NB ball 'c' is [a, s, z] -> world (a, z, s); place it on the axis past the last spider
man_b = json.load(open("scenes/ring_mandrel.json")); man_b["balls"] = [{"c": [120, 0, 0], "r": 9.525}]
json.dump(man_b, open("scenes/ring_mandrel.json", "w"))

TOP = {"dir": [0, -1, 0], "up": [0, 0, -1]}
FRONT = {"dir": [0, 0, -1], "up": [0, 1, 0]}
SIDE = {"dir": [-1, 0, 0], "up": [0, 1, 0]}
ISO = {"dir": [-0.7, -0.9, -1.0], "up": [0, 1, 0]}
K, G, W_ = "#333", "#7a5420", "#9a4f12"
ic = d["IRON_C"]
# label points are [a, s, z] -> world (x=a, y=z, z=s); for the flat jig: a = x on the plate, s = y on the plate, z = height
jl = [["top plate JT (etched guide)", [90, 10, 2 * T], "R", G], ["core JC (glued to the base)", [C[0] - 6, C[1], 2 * T], "L", G],
      ["wire ring in the groove", [C[0] - OD / 2 + 1, C[1] + 6, T + WD], "L", W_],
      ["15 mm iron hole on the joint", [ic[0] + 4, ic[1], T], "R", K], ["cut-length guide", [40, 9, 2 * T], "L", G],
      ["base plate JB", [100, 50, T / 2], "R", G], ["M5 / alignment", [8, d["PH"] - 8, 2 * T], "L", K]]
v = {}
sub = [f"Lay a {WD:g} mm wire cut to {math.pi * CL:.2f} in the groove (it forms itself round the core), butt the ends at the iron hole, solder.",
       f"Ring ID {ID:.2f} = bore 20 + 2 x wire; OD {OD:.2f}. Top and base bolt or pin together at the two corner holes."]
v["r_top"] = {"scene": "ring_jig_scene.json", "cam": TOP, "title": "4a  Ring jig, top view", "sub": sub, "labels": jl}
v["r_front"] = {"scene": "ring_jig_scene.json", "cam": FRONT, "title": "4b  Ring jig, front view (edge)", "sub": sub, "w": 1500, "h": 600,
                "labels": [["top plate JT", [80, 0, 2 * T], "R", G], ["base JB", [80, 0, T / 2], "R", G], ["wire ring (below the top surface)", [C[0], 0, T + WD], "L", W_]]}
v["r_side"] = {"scene": "ring_jig_scene.json", "cam": SIDE, "title": "4c  Ring jig, side view (edge)", "sub": sub, "w": 1500, "h": 600,
               "labels": [["top plate JT", [110, 30, 2 * T], "R", G], ["base JB", [110, 30, T / 2], "R", G]]}
v["r_iso"] = {"scene": "ring_jig_scene.json", "cam": ISO, "title": "4d  Ring jig, angled", "sub": sub, "labels": jl[:5]}
ms = ["Spiders strung on an M5 threaded rod (nuts either side, not drawn) hold the straight wires in their notches,",
      "flush with the rim, so rings slide over at exact size. Solder each ring to the wires, then slide the spiders out."]
ml = [["spider SP (notches hold the wires)", [45, 0, 12], "L", G], ["straight wire", [100, 7.8, 7.8], "R", W_],
      ["ring", [62, 0, -13], "R", W_], ["M5 rod", [-12, 0, 0], "L", K], ["3/4\" ball fits the bore", [120, 0, 9.5], "R", "#24546b"]]
v["m_front"] = {"scene": "ring_mandrel.json", "cam": FRONT, "title": "4e  Mandrel, front view", "sub": ms, "labels": ml}
v["m_side"] = {"scene": "ring_mandrel.json", "cam": SIDE, "title": "4f  Mandrel, end view (down the track)", "sub": ms,
               "labels": [["spider + notches", [130, 0, -12], "L", G], ["straight wires", [130, 7.8, 7.8], "R", W_], ["ring", [130, 0, -13.5], "R", W_]]}
v["m_top"] = {"scene": "ring_mandrel.json", "cam": {"dir": [0, -1, 0], "up": [0, 0, -1]}, "title": "4g  Mandrel, top view", "sub": ms, "labels": ml[:4]}
v["m_iso"] = {"scene": "ring_mandrel.json", "cam": {"dir": [-1, -0.6, -0.8], "up": [0, 1, 0]}, "title": "4h  Mandrel, angled", "sub": ms, "labels": ml}
old = json.load(open("scenes/views.json")); old.update(v)
json.dump(old, open("scenes/views.json", "w"), indent=1)
print(list(v))
