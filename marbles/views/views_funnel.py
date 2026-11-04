"""Views of the bottom feed funnel (reads scenes/funnel_parts.json from clock/feed_funnel.py)."""
import json, math
d = json.load(open("scenes/funnel_parts.json"))
T, H = d["T"], d["H"]
parts = d["parts"]
# short 2020 behind the bottom band, running across (along a), in the s-z plane
sq = [[-3.1 - 20 - 0.0, -H], [-3.1, -H], [-3.1, -H + 20], [-3.1 - 20, -H + 20], [-3.1 - 20, -H]]
parts.append({"id": "X2020", "label": "short 2020", "color": "#b8c4cf", "opacity": 1.0, "kind": "sz",
              "polys": [{"outer": sq, "holes": []}], "lo": -50.0, "hi": 50.0, "group": "X2020"})
# balls queued in the channel: walk the centreline from the bottom hole, one ball diameter apart
bp = d["ball_path"][::-1]                       # from the bottom hole upward
pts, acc, last = [bp[0]], 0.0, bp[0]
for p in bp[1:]:
    acc += math.dist(p, last); last = p
    if acc >= 19.05:
        pts.append(p); acc = 0.0
balls = [{"c": [p[0], -T / 2, p[1]], "r": 9.525} for p in pts[:5]]
json.dump({"parts": parts, "balls": balls}, open("scenes/funnel_scene.json", "w"))
FRONT = {"dir": [0, 0, -1], "up": [0, 1, 0]}
TOP = {"dir": [0, -1, 0], "up": [-1, 0, 0]}
SIDE = {"dir": [-1, 0, 0], "up": [0, 1, 0]}
ISO = {"dir": [-0.9, -0.6, -1.3], "up": [0, 1, 0]}
FC, K = "#3d5a73", "#333"
yb = d["y_holes"][0] - H
sub = [f"Your 2026-11-04 sketch as drawn: one {T} mm plate in the sieve's plane, directly under S_F, its holes continuing S_F's 30 mm pitch.",
       "Balls queue down the J channel into the bottom hole. The catch (top right) and the crossover funnel are still to design."]
lab = [["S_F sieve (stub)", [20, 0, 60], "R"], ["feed funnel FF", [5, 0, -60], "L"],
       ["bottom hole: next ball waits here", [30, 0, yb], "L"], ["queued balls in the J channel", [-23, 0, -40], "R"],
       ["20 mm band, 3 x M5 into a short 2020", [0, 0, -H + 10], "L"], ["M5 into F's centre slot", [10, 0, -30], "L"],
       ["channel mouth: catch drops balls here", [-23, 0, -2], "R"]]
v = {}
v["f_front"] = {"scene": "funnel_scene.json", "cam": FRONT, "title": "3a  Feed funnel, front view (face-on)", "sub": sub,
                "labels": [[t, p, s, FC] for t, p, s in lab]}
v["f_top"] = {"scene": "funnel_scene.json", "cam": TOP, "title": "3b  Feed funnel, top view", "sub": sub + ["FRONT on the LEFT."],
              "labels": [["feed funnel FF (edge-on)", [-30, -T / 2, -20], "L", FC], ["S_F (edge-on)", [20, -T / 2, 120], "R", FC],
                         ["top ball in the channel", [-23, -T / 2, -10], "R", "#24546b"], ["short 2020", [-40, -13, -H + 20], "R", K]]}
v["f_side"] = {"scene": "funnel_scene.json", "cam": SIDE, "title": "3c  Feed funnel, side view", "sub": sub + ["FRONT on the LEFT."],
               "labels": [["feed funnel FF (edge-on)", [46, -T / 2, -70], "L", FC], ["balls stick out both faces", [0, 9, -30], "R", "#24546b"],
                          ["short 2020 behind the band", [50, -13, -H + 10], "R", K], ["S_F (edge-on)", [46, -T / 2, 60], "L", FC]]}
v["f_iso"] = {"scene": "funnel_scene.json", "cam": ISO, "title": "3d  Feed funnel, angled", "sub": sub,
              "labels": [["feed funnel FF", [10, 0, -100], "L", FC], ["J channel", [-23, 0, -50], "R", FC], ["short 2020", [-50, -13, -H + 20], "R", K]]}
old = json.load(open("scenes/views.json"))
old.update(v)
json.dump(old, open("scenes/views.json", "w"), indent=1)
print(list(v))
