"""View specs for the wheel-box drawings; reads scenes/box_dims.json from wheel_box.py."""
import json
d = json.load(open("scenes/box_dims.json"))
T, NCi, FCi, FCo = d["T"], d["NCi"], d["FCi"], d["FCo"]
a_w, s_w, a_bi, a_bo, H_i = d["a_w"], d["s_w"], d["a_bi"], d["a_bo"], d["H_i"]
a_c0, a_c1, z_c, a_open = d["a_c0"], d["a_c1"], d["z_c"], d["a_open"]
smid = (NCi + FCi) / 2
TOP = {"dir": [0, -1, 0], "up": [-1, 0, 0]}
FRONT = {"dir": [0, 0, -1], "up": [0, 1, 0]}
SIDE = {"dir": [-1, 0, 0], "up": [0, 1, 0]}
ISO = {"dir": [-1, -0.75, -1.4], "up": [0, 1, 0]}
ISO2 = {"dir": [1.2, -0.75, 1.2], "up": [0, 1, 0]}
OPEN = {"dir": [1.0, -0.55, 0.9], "up": [0, 1, 0]}
FC, MC, GF, GM, K = "#3d5a73", "#8a4a2f", "#3f6e2a", "#6b3f85", "#333"
def mir(p):   # W_F point -> W_M point
    return [60 - p[0], 8.4 - p[1], p[2]]
v = {}
sub = [f"Sheet T = {T} mm. Moment: M's holes lined up with F's. One wheel box per end of each keeper (4 total).",
       "Green = boxes on K_F (wheel rides M's far groove); purple = boxes on K_M (wheel rides F's far groove). Keepers see-through."]
v["b_assy_top"] = {"scene": "box_assembly.json", "cam": TOP, "title": "1a  Lift slide with wheel boxes, top view (looking down the beams)",
    "sub": sub + ["FRONT is on the LEFT."],
    "labels": [["F", [10, 10, 320], "L", FC], ["M", [50, -1.6, 320], "R", MC], ["S_F sieve", [30, -1.6, 300], "R", FC],
               ["S_M sieve", [30, 10, 300], "L", MC], ["K_F keeper", [40, 21.6, 300], "L", FC], ["K_M keeper", [20, -13.2, 300], "R", MC],
               ["box on K_F: top wall", [75, smid, 240 + H_i + T], "L", GF], ["box on K_M: top wall", mir([75, smid, 240 + H_i + T]), "R", GM],
               ["wheel rim in M's far groove", [60.8, s_w, 240], "R", GF]],
    "notes": [{"t": "FRONT", "at": [100, 35, 300]}, {"t": "BACK", "at": [100, -30, 300]}]}
ds = []
for p0, p1 in (([a_w - 6.5, NCi + T / 2, 60], [a_w + 6.5, NCi + T / 2, 60]), ([a_w - 6.5, FCo + T / 2, 60], [a_w + 6.5, FCo + T / 2, 60]),
               ([a_w - 6.5, 20 + T / 2, 60], [a_w + 6.5, 20 + T / 2, 60])):
    ds.append([p0, p1, GF]); ds.append([mir(p0), mir(p1), GM])
v["b_assy_section"] = {"scene": "box_section.json", "cam": TOP, "title": "1b  Section at z = 60 (through the lower axles), looking down",
    "sub": ["Everything above z = 60 removed. Both sieves are solid at z = 60 (between ball holes).",
            "Dashed lines join the two halves of a cheek or keeper that the cut splits at its axle slot. FRONT on the LEFT."],
    "labels": [["F", [10, 10, 60], "L", FC], ["M", [50, -1.6, 60], "R", MC],
               ["S_F: band on F, edge in M's near slot", [44, -1.6, 60], "R", FC], ["S_M: band on M, edge in F's near slot", [16, 10, 60], "L", MC],
               ["K_F keeper (axle slot)", [40, 20 + T / 2, 60], "L", FC], ["K_M keeper (axle slot)", [20, -11.6 - T / 2, 60], "R", MC],
               ["ball (below the cut)", [30, 4.2, 44], "L", "#24546b"],
               ["near cheek CH (on K_F)", [89, NCi + T / 2, 60], "L", GF], ["back wall BK", [a_bi + T / 2, smid, 60], "R", GF],
               ["far cheek CH", [89, FCo + T / 2, 60], "R", GF], ["V-wheel (cut through axle)", [59.3, s_w, 60], "R", GF],
               ["nut A + washer", [74, s_w + 8, 60], "L", K], ["nut B + washer", [74, s_w - 9, 60], "R", K],
               ["axle M5x50", [a_w, FCo - 3, 60], "R", K], ["bottom wall TB (below)", [80, smid + 6, 60 - H_i - T], "L", GF],
               ["box on K_M (mirror)", mir([89, smid, 60]), "R", GM]],
    "dashed": ds, "ml": 360, "mr": 360,
    "notes": [{"t": "FRONT", "at": [100, 35, 60]}, {"t": "BACK", "at": [100, -30, 60]}]}
v["b_assy_front"] = {"scene": "box_assembly.json", "cam": FRONT, "title": "1c  Front view", "w": 1300, "h": 1500,
    "sub": ["Keepers see-through. a (across) runs left to right."],
    "labels": [["F", [10, 10, 315], "L", FC], ["M", [50, -1.6, 315], "R", MC], ["K_F keeper (see-through)", [5, 20 + T, 160], "L", FC],
               ["S_M sieve", [30, 11.6, 150], "R", MC], ["box on K_F (upper)", [89, 0, 240], "R", GF], ["box on K_F (lower)", [89, 0, 60], "R", GF],
               ["box on K_M (upper)", mir([89, 0, 240]), "L", GM], ["box on K_M (lower)", mir([89, 0, 60]), "L", GM],
               ["axle + 2 bolts per box", [a_w, 30, 60], "R", K]]}
v["b_assy_side"] = {"scene": "box_assembly.json", "cam": SIDE, "title": "1d  Side view (from beyond M)", "w": 1300, "h": 1500,
    "sub": ["FRONT on the LEFT. You see the back walls of the K_F boxes."],
    "labels": [["M", [60, -1.6, 315], "R", MC], ["F", [20, 16, 315], "L", FC], ["K_F edge", [80, 20 + T / 2, 160], "L", FC],
               ["K_M edge", [60, -11.6 - T / 2, 160], "R", MC], ["back wall BK", [a_bo, smid, 240], "R", GF],
               ["near cheek CH", [a_c1, NCi + T / 2, 240 + 30], "L", GF], ["far cheek CH", [a_c1, FCo + T / 2, 240 + 30], "R", GF],
               ["top wall TB", [a_bo, smid - 8, 240 + H_i + T / 2], "R", GF], ["bolt heads on K_F", [a_c1, 25, 90], "L", K]]}
v["b_assy_iso"] = {"scene": "box_assembly.json", "cam": ISO, "title": "1e  Angled view (front, M side, above)", "sub": ["Keepers see-through."],
    "labels": [["F", [10, 10, 320], "L", FC], ["M", [50, -1.6, 320], "R", MC], ["K_F (see-through)", [5, 20 + T, 250], "L", FC],
               ["box on K_F (upper)", [a_bo, smid, 240], "R", GF], ["box on K_F (lower)", [a_bo, smid, 60], "R", GF], ["box on K_M", mir([a_c1, -10, 240]), "L", GM]]}
v["b_assy_iso2"] = {"scene": "box_assembly.json", "cam": ISO2, "title": "1f  Angled view (back, F side, above)", "sub": ["Keepers see-through."],
    "labels": [["F", [10, 10, 320], "L", FC], ["M", [50, -1.6, 320], "R", MC], ["K_M (see-through)", [40, -11.6 - T, 250], "R", MC],
               ["box on K_M (upper)", mir([a_bo, smid, 240]), "L", GM], ["box on K_M (lower)", mir([a_bo, smid, 60]), "L", GM], ["box on K_F", [a_c1, -10, 240], "R", GF]]}
subb = [f"The lower box on K_F, with a stub of M and the edge of K_F. T = {T} mm.",
        "5 plates: 2 cheeks (CH), top + bottom (TB), back (BK). Long M5 bolts: keeper -> near cheek -> far cheek, nut outside."]
v["b_one_top"] = {"scene": "box_one.json", "cam": TOP, "title": "2a  One wheel box, top view", "ghost": ["boxF60"], "ghost_op": 0.12,
    "sub": subb + ["Box plates drawn as outlines so the wheel and nuts show. FRONT on the LEFT."],
    "labels": [["K_F edge", [60, 20 + T / 2, 110], "L", FC], ["near cheek CH", [89, NCi + T / 2, 60 + z_c], "L", GF],
               ["far cheek CH", [89, FCo + T / 2, 60 + z_c], "R", GF], ["top wall TB", [80, smid, 60 + H_i + T], "R", GF],
               ["M stub", [50, -1.6, 110], "R", MC], ["V-wheel", [59.5, s_w, 60], "R", GF], ["nut A", [74, s_w + 8, 60], "L", K],
               ["nut B", [74, s_w - 9, 60], "R", K], ["bolt + axle heads", [a_w, 24, 60], "L", K]],
    "notes": [{"t": "FRONT", "at": [100, 35, 100]}, {"t": "BACK", "at": [100, -30, 100]}]}
v["b_one_front"] = {"scene": "box_one.json", "cam": FRONT, "title": "2b  One wheel box, front view", "hide": ["K_F"], "ghost": ["boxF60"], "ghost_op": 0.12,
    "sub": subb + ["K_F hidden; box plates drawn as outlines."],
    "labels": [["axle slot: push wheel to M, tighten", [a_w - 1.5, 0, 60], "L", GF], ["through bolt (keeper far-row hole)", [70, 25, 90], "R", K],
               ["through bolt", [70, 25, 30], "R", K], ["top wall tab in cheek", [73, 0, 60 + H_i + T / 2], "R", GF],
               ["back wall tabs in cheek", [a_bi + T / 2, 0, 60 + 20.75], "R", GF], ["V-wheel", [62, 0, 66], "L", GF], ["M stub (behind)", [50, 8.4, 20], "L", MC]],
    "arrows": [[[80, 0, 49], [64, 0, 49]]]}
v["b_one_side"] = {"scene": "box_one.json", "cam": SIDE, "title": "2c  One wheel box, side view (from the back)", "ghost": ["boxF60"], "ghost_op": 0.12,
    "sub": subb + ["FRONT on the LEFT; plates as outlines. Nuts A and B lock the wheel's position along the axle."],
    "labels": [["K_F edge", [80, 20 + T / 2, 25], "L", FC], ["near cheek CH", [a_c1, NCi + T / 2, 60 + 40], "L", GF],
               ["far cheek CH", [a_c1, FCo + T / 2, 60 + 40], "R", GF], ["back wall BK (finger joints)", [a_bo, smid, 60 + 25], "R", GF],
               ["top wall TB", [a_bo, smid - 10, 60 + H_i + T / 2], "R", GF], ["V-wheel", [a_w + 12, s_w, 60], "R", GF],
               ["nut A", [a_w + 4, s_w + 8, 60], "L", K], ["nut B", [a_w + 4, s_w - 9, 60], "R", K], ["M stub", [60, -10, 105], "R", MC]]}
v["b_one_iso"] = {"scene": "box_one.json", "cam": OPEN, "title": "2d  One wheel box, angled into the open side", "hide": ["M"],
    "sub": ["Opaque; M hidden so you can look into the open side, which faces M's far groove."],
    "labels": [["V-wheel", [a_open - 3, s_w, 60], "L", GF], ["near cheek CH", [a_c0, NCi + T / 2, 60 + 40], "L", GF],
               ["far cheek CH", [a_c0, FCo, 60 + 40], "R", GF], ["top wall TB", [a_open, smid, 60 + H_i + T], "L", GF],
               ["bottom wall TB", [a_open, smid, 60 - H_i - T], "R", GF], ["back wall BK", [a_bi, smid + 8, 60 + 20], "R", GF],
               ["nuts on far cheek", [70, FCo - 3, 30], "R", K], ["K_F", [50, 20 + T, 100], "L", FC]]}
E = 24.0
v["b_one_exploded"] = {"scene": "box_exploded.json", "cam": {"dir": [0.55, -0.5, -1.0], "up": [0, 1, 0]},
    "title": "2e  One wheel box, exploded (hardware left out)",
    "sub": ["Plates pulled straight out of their joints, seen from the front and the open (M) side.",
            "TB and BK tabs go through the cheeks' slots; TB and BK finger-joint at the back corners."],
    "labels": [["K_F (piece)", [75, 70 + T, 20], "R", FC], ["near cheek CH", [a_c0, NCi + T + E, 60 + 35], "L", GF],
               ["far cheek CH", [a_c1, FCo - E, 60 + 35], "R", GF], ["top wall TB", [a_open, smid, 60 + H_i + T + 1.6 * E], "L", GF],
               ["bottom wall TB", [a_open, smid, 60 - H_i - T - 1.6 * E], "L", GF], ["back wall BK", [a_bo + 1.6 * E, smid, 60], "R", GF]]}
json.dump(v, open("scenes/views.json", "w"), indent=1)
print(list(v))
