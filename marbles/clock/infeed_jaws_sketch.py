#!/usr/bin/env python3
"""Sketch: infeed jaws on the pendulum. Lower jaw (two toothed ply plates, rigid on the pendulum) and upper jaw (one
plate, same teeth, offset half a pitch, hinged near the funnel end, pulled shut by a band at the mouth). Teeth: ramps face
the mouth, concave faces face in, so the waiting queue pushes balls in as the pendulum swings up into it and nothing runs
back out when the swing reverses and the funnel slopes down toward the jaws.
    python3 marbles/clock/infeed_jaws_sketch.py   # -> marbles/views/infeed_jaws.png"""
import math
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from shapely import affinity  # noqa: E402
from shapely.geometry import Point, Polygon, box  # noqa: E402
from shapely.ops import unary_union  # noqa: E402

BALL = 19.05; BR = BALL / 2; RP = BR + 0.3
P, H = 30.0, 15.0              # Alex: 30 pitch, 15 tall
N = 4                          # pockets
XC = math.sqrt(RP ** 2 - (H - BR) ** 2)   # pocketed ball centre, inward of the tip it sits behind
ROOT = H + BALL + 1.0          # upper jaw root above the lower floor (a ball over a lower tip clears it by 1)
PLATE_SP = 10.0                # the two lower plates, centre to centre (fit between the track's lower wires, 13.6 apart)
T = 2.63
OVERLAP = 40.0


def lower_jaw():
    """floor y = 0, mouth at the left (x < 0), balls go right. Tooth k: ramp up from the pocket floor to its tip at
    (kP, H), concave face down the right side round the ball at (kP + XC, BR)."""
    teeth = [Polygon([(k * P - (P - XC), 0), (k * P, H), (k * P + XC, 0)]) for k in range(N + 1)]
    body = unary_union([box(-P, -10, N * P + 30, 0)] + teeth)
    return body.difference(unary_union([Point(k * P + XC, BR).buffer(RP, 96) for k in range(N + 1)])).buffer(1.2).buffer(-1.2)


def upper_jaw():
    """the lower profile flipped top to bottom (ramps still face the mouth, concave faces in), shifted half a pitch,
    root at ROOT; a tail past the last tooth for the hinge"""
    lo = lower_jaw().intersection(box(-P, -0.01, N * P + 30, H + 1))
    up = affinity.scale(lo, 1, -1, origin=(0, 0))
    up = affinity.translate(up, P / 2, ROOT)
    return unary_union([up, box(-P + P / 2, ROOT, N * P + 45, ROOT + 8)])


def main():
    fig = plt.figure(figsize=(15, 10))
    a = fig.add_axes([0.03, 0.42, 0.94, 0.53]); s1 = fig.add_axes([0.03, 0.04, 0.3, 0.34]); t = fig.add_axes([0.37, 0.04, 0.6, 0.34])
    lo, up = lower_jaw(), upper_jaw()
    a.fill(*lo.exterior.xy, fc="burlywood", ec="saddlebrown"); a.fill(*up.exterior.xy, fc="peru", ec="k", alpha=.85)
    for k in range(N):
        a.add_patch(plt.Circle((k * P + XC, BR), BR, fc="steelblue", alpha=.5, ec="k"))
    hx, hy = N * P + 38, ROOT + 4
    a.plot(hx, hy, "wo", ms=7, mec="k"); a.text(hx - 6, hy + 7, "pivot (upper jaw)", fontsize=8)
    a.plot([-P / 2 + 3, -P / 2 + 3], [ROOT + 8, -10], "g--", lw=1.5); a.text(-P / 2 + 5, ROOT + 10, "band / spring / weight pulls the mouth shut", fontsize=8, color="g")
    a.annotate("", (N * P + 25, -16), (-P + 5, -16), arrowprops=dict(arrowstyle="->", lw=2)); a.text(30, -21, "balls go this way: into the splitter's funnel", fontsize=8)
    a.text(-P - 18, 8, "MOUTH", fontsize=9, weight="bold")
    a.text(15, -7, f"LOWER JAW: 2 plates {PLATE_SP:g} apart, rigid on the pendulum", fontsize=8)
    a.text(25, ROOT + 2, "UPPER JAW: same teeth, offset half a pitch, hinged", fontsize=8)
    a.set_xlim(-P - 22, N * P + 55); a.set_ylim(-25, ROOT + 18); a.set_aspect("equal")
    a.set_title(f"SIDE VIEW along the jaws: teeth {H:g} tall, pitch {P:g}; ramps face the mouth, concave faces (ball + 0.3) face in", fontsize=10)
    # section across at the pickup
    for sx in (-1, 1):
        s1.add_patch(plt.Circle((sx * 7.8, -7.8), 1.025, fc="0.5"))                        # track's lower wires
        s1.add_patch(plt.Rectangle((sx * PLATE_SP / 2 - T / 2, -22), T, 22 - 10.2 + 0, fc="burlywood", ec="saddlebrown"))
    zc = -10.2 + math.sqrt(BR ** 2 - (PLATE_SP / 2) ** 2)
    s1.add_patch(plt.Circle((0, zc + 1.0), BR, fc="steelblue", alpha=.5, ec="k"))
    s1.add_patch(plt.Rectangle((-T / 2, zc + BR + 2), T, 12, fc="peru", ec="k"))
    s1.text(-15, -27, "lower jaw plates rise between the track's lower wires\n(13.6 apart; plates 12.63 over their outsides)", fontsize=7)
    s1.text(3, zc + BR + 8, "upper jaw\n(clipped ring tops;\nno upper wires here)", fontsize=7)
    s1.set_xlim(-18, 18); s1.set_ylim(-30, 25); s1.set_aspect("equal"); s1.axis("off")
    s1.set_title("SECTION across at the pickup", fontsize=9)
    t.axis("off")
    t.text(0, 1, "How it works (your sketch):\n"
           f"- Near the top of the left swing the mouth runs over the front of the waiting queue by > {OVERLAP:g} (more than a pitch).\n"
           "  The queue (pushed by the column from the hopper) is driven into the jaws: each ball climbs a ramp, the upper jaw lifts\n"
           "  on its hinge, and the ball drops in behind the tip; balls already in the jaws get pushed on toward the funnel.\n"
           "- Swinging right, the funnel slopes down toward the jaws: every ball rolls back against the concave face behind it\n"
           f"  ({H:g} tall: it can't climb that) and stays put. Full jaws just push the queue back at the lip.\n\n"
           "What this needs from the waiting track:\n"
           f"- its last ~{OVERLAP + 10:g} mm open on top: no upper wires there (a ball has to rise {H:g} to get over a tooth; inside the\n"
           "  tunnel it can rise only 1.4), and the bottom ring segments clipped so the lower jaw plates can come up between the rails;\n"
           "- the lip on the sides, not in the middle (the jaw plates need the middle 13 mm clear).\n\n"
           f"Numbers: pocketed ball {XC:.2f} in from the tip behind it; ramp {P - XC:.1f} long at "
           f"{math.degrees(math.atan(H / (P - XC))):.1f} deg; upper jaw root {ROOT:.2f} up, its tips {ROOT - H:.2f} up\n"
           f"(3.90 clear of a pocketed ball); ball rides {math.sqrt(BR ** 2 - (PLATE_SP / 2) ** 2):.2f} above the two lower plates' edges.",
           fontsize=8.5, va="top", family="monospace")
    out = Path(__file__).resolve().parent.parent / "views" / "infeed_jaws.png"
    plt.savefig(out, dpi=100)
    print(out.name)


if __name__ == "__main__":
    main()
