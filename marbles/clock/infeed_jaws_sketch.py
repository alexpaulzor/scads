#!/usr/bin/env python3
"""Sketch: infeed scoop on the pendulum. A box (two side walls) that goes round the outstretched end of the waiting
rail; inside it two lower toothed plates (rigid) and a row of independent hooks, each with one tooth on a ~60 mm arm
pivoting on its own M3 through-bolt further along, so every space ratchets on its own. Teeth: ramps (a smooth S from the
pocket floor up to the next tip) face the mouth; concave faces (the ball's curve) face in.
    python3 marbles/clock/infeed_jaws_sketch.py   # -> marbles/views/infeed_jaws.png"""
import math
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from shapely import affinity  # noqa: E402
from shapely.geometry import LineString, Point, Polygon, box  # noqa: E402
from shapely.ops import unary_union  # noqa: E402

BALL = 19.05; BR = BALL / 2; RP = BR + 0.3
P, H = 30.0, 15.0                  # pitch, tooth height (Alex)
N = 4                              # pockets / hooks
XC = math.sqrt(RP ** 2 - (H - BR) ** 2)   # pocketed ball centre, inward of the tip behind it
ROOT = H + BALL + 1.0              # hook teeth: same profile flipped, root this high
ARM, PIV_UP = 60.0, 18.0           # hook arm to its pivot, pivot this far above ROOT (clears the next hook's arm)
T = 2.63; M3 = 3.3
PLATE_SP = 10.0                    # lower plates, centre to centre (between the rail's lower wires, 13.6 apart)
WALL_IN = 30.0                     # box: inside width (round the rail's rings, OD 28.2)


def bezier(p0, p1, p2, p3, n=40):
    return [tuple((1 - t) ** 3 * a + 3 * (1 - t) ** 2 * t * b + 3 * (1 - t) * t * t * c + t ** 3 * d
                  for a, b, c, d in zip(p0, p1, p2, p3)) for t in (i / n for i in range(n + 1))]


def tooth_profile(x0):
    """one pitch of the lower edge, from tip k at (x0, H): concave face (ball curve) down to the pocket floor under the
    ball, then a smooth S up to the next tip at (x0 + P, H)"""
    cx, cy = x0 + XC, BR
    a0 = math.atan2(H - cy, x0 - cx)
    arc = [(cx + RP * math.cos(a), cy + RP * math.sin(a)) for a in [a0 + (1.5 * math.pi - a0) * i / 30 for i in range(31)]]   # down the ball's back
    bot = arc[-1]
    s = bezier(bot, (bot[0] + 0.5 * (P - XC), bot[1]), (x0 + P - 8.0, H - 4.0), (x0 + P, H))   # stays inside the overhang
    return arc + s[1:]


def lower_plate():
    pts = [(-P - 10, -10), (-P - 10, 0)]
    pts += [(x, y) for x, y in bezier((-P - 10, 0), (-P + 2, 0), (-6, H - 9), (0, H))][1:]      # mouth ramp
    for k in range(N):
        pts += tooth_profile(k * P)[1:]
    pts += [(N * P + 30, 0), (N * P + 30, -10)]
    return Polygon(pts)


def hook(k):
    """hook k: one lower tooth (S ramp facing the mouth, concave face facing in) flipped top to bottom, its tip half a
    pitch on from the lower tips, root at ROOT; an arm from the root up to a pivot ARM further along"""
    one = lower_plate().intersection(box(XC, 0, P + XC, H + 1))          # lower tooth 1: tip at (P, H)
    x_t = k * P + P / 2
    tooth = affinity.translate(affinity.scale(one, 1, -1, origin=(0, 0)), x_t - P, ROOT)
    piv = (x_t + ARM, ROOT + PIV_UP)
    root = box(x_t - P + XC, ROOT - 0.01, x_t + XC, ROOT + 4)
    arm = LineString([(x_t, ROOT + 2), piv]).buffer(3.5, 16)
    g = unary_union([tooth, root, arm, Point(piv).buffer(5.5, 32)]).difference(Point(piv).buffer(M3 / 2, 24))
    return g, piv


def main():
    fig = plt.figure(figsize=(15, 10.5))
    a = fig.add_axes([0.03, 0.40, 0.94, 0.56]); s1 = fig.add_axes([0.03, 0.03, 0.3, 0.34]); t = fig.add_axes([0.37, 0.03, 0.6, 0.34])
    a.add_patch(plt.Rectangle((-P - 14, -14), N * P + 30 + ARM + 30, ROOT + PIV_UP + 26, fc="0.93", ec="0.6", ls="--"))
    a.text(-P - 12, ROOT + PIV_UP + 8, "BOX side wall (behind): goes round the rail's end; M3 through-bolts are the hook pivots", fontsize=8, color="0.4")
    lo = lower_plate()
    a.fill(*lo.exterior.xy, fc="burlywood", ec="saddlebrown")
    for k in range(N):
        a.add_patch(plt.Circle((k * P + XC, BR), BR, fc="steelblue", alpha=.5, ec="k"))
    for k in range(N):
        g, piv = hook(k)
        col = "peru" if k % 2 == 0 else "sienna"
        a.fill(*g.exterior.xy, fc=col, ec="k", alpha=.85)
        for r in g.interiors:
            a.fill(*r.xy, fc="w", ec="k")
    a.plot([-P - 14 + 4, N * P + 60], [ROOT + 6.5, ROOT + 6.5], "k:", lw=1)
    a.text(N * P - 10, ROOT + 2.5, "rest stop (M3 bolt or bar under the arms)", fontsize=7)
    a.annotate("", (N * P + 25, -20), (-P, -20), arrowprops=dict(arrowstyle="->", lw=2)); a.text(30, -26, "balls go this way: to the splitter's funnel", fontsize=8)
    a.text(-P - 13, 3, "MOUTH", fontsize=9, weight="bold")
    a.text(5, -8, f"LOWER PLATES (2, {PLATE_SP:g} apart): pocket floor runs on in a smooth S to the next tip", fontsize=8)
    a.set_xlim(-P - 18, N * P + ARM + 20); a.set_ylim(-30, ROOT + PIV_UP + 22); a.set_aspect("equal")
    a.set_title(f"SIDE VIEW: teeth {H:g} tall, pitch {P:g}; {N} independent hooks, {ARM:g} arms on M3 pivots (alternate hooks in two planes)", fontsize=10)
    # section across the box at the pickup
    W = WALL_IN / 2
    for sx in (-1, 1):
        s1.add_patch(plt.Rectangle((sx * W if sx > 0 else -W - T, -22), T, 64, fc="burlywood", ec="saddlebrown"))
        s1.add_patch(plt.Rectangle((sx * PLATE_SP / 2 - T / 2, -22), T, 11.8, fc="burlywood", ec="saddlebrown"))
        s1.add_patch(plt.Circle((sx * 7.8, -7.8), 1.025, fc="0.5"))
    s1.add_patch(plt.Circle((0, 0), 14.1, fc="none", ec="0.6", lw=1.5, ls="--"))
    s1.add_patch(plt.Circle((0, -10.2 + math.sqrt(BR ** 2 - (PLATE_SP / 2) ** 2) + 1), BR, fc="steelblue", alpha=.5, ec="k"))
    for sx, col in ((-1, "peru"), (1, "sienna")):
        s1.add_patch(plt.Rectangle((sx * 1.5 - T / 2, 11), T, 20, fc=col, ec="k"))
    s1.plot([-W - T - 2, W + T + 2], [30, 30], "k-", lw=2.5); s1.text(-W, 32.5, "M3 through-bolt (a hook pivot)", fontsize=7)
    s1.text(-W - 4, -28, f"walls {WALL_IN:g} apart inside (rail rings 28.2 dashed);\nlower plates rise between the rail's lower wires", fontsize=7)
    s1.set_xlim(-22, 22); s1.set_ylim(-31, 38); s1.set_aspect("equal"); s1.axis("off")
    s1.set_title("SECTION across the box at the pickup", fontsize=9)
    t.axis("off")
    t.text(0, 1, "- The box goes round the end of the waiting rail at the top of the left swing (> 40 overlap). The queue is driven in:\n"
           "  each ball rolls up the smooth S onto the next tip and drops into the next pocket; only the hook over THAT space lifts.\n"
           "- Each hook: one tooth (the lower profile flipped, half a pitch on), a 60 arm to its own M3 pivot further along, a rest\n"
           "  stop under the arms, a light band if gravity isn't enough when the box tips. Alternate hooks sit in two planes 3 apart\n"
           "  (centred over the ball), so neighbouring arms never touch; each pivot sits 18 above the hook roots, clear of the\n"
           "  next hook's arm.\n"
           "- Swinging right, the funnel slopes down toward the box: each ball rolls back into the concave face behind it (15 tall).\n\n"
           "Waiting rail end: last ~50 open on top (no upper wires; bottom ring segments clipped for the lower plates).",
           fontsize=8.5, va="top", family="monospace")
    out = Path(__file__).resolve().parent.parent / "views" / "infeed_jaws.png"
    plt.savefig(out, dpi=100)
    # check: the S stays clear of the pocketed ball
    tp = LineString(tooth_profile(0))
    print(out.name, "S-curve to pocketed ball min gap %.2f" % (tp.distance(Point(XC, BR)) - BR))


if __name__ == "__main__":
    main()
