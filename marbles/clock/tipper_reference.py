#!/usr/bin/env python3
"""Reference: Alex's wire tipper (escapement) at the end of the waiting track, seen along the fulcrum axis (viewer's
view). A rigid wire assembly pivots on an axle at P. The 60 radius arc (a wire pair) is centred on P: its upper-left end
is the upstream end of the short 2-ball section, its lower end meets the overhead track (a wire pair over the 2 balls that
turns down at the right) at the EXIT RING under P. The pendulum's catcher closes in from the right and pushes the exit
ring: the assembly turns clockwise, the 2-ball section lifts over the FIXED post (on the feed track), balls 0 + 1 roll
over it and down the overhead track into the exit ring and the catcher; the arc's end rises between balls 1 and 2 and
holds the queue. They only roll while the catcher is right there.
    python3 marbles/clock/tipper_reference.py   # -> marbles/views/tipper_reference.png"""
import math
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

D = 19.05; R = D / 2
RING_OD = 28.2                    # retaining rings, seen edge-on from this side (a line RING_OD long, across the tube)
AXIS_Z = R + 0.7                  # tube axis above the balls' bottoms (ball centre sits 0.7 below it)
RA = 60.0                         # arc radius = pivot to the 2-ball section's upstream end
P = (RA, 0.0)                     # pivot; the track floor (balls' bottoms) at z = 0 at rest, queue from the left
POST_X, POST_H = 2 * D + 1.4, 4.0 # fixed post just in front of ball 0 (balls 1, 0 centred at R, R + D)
EXIT_A = 250.0                    # exit ring on the arc, a little left of straight under the pivot (clear of the axle)
TH = math.degrees(math.asin(POST_H / (P[0] - POST_X))) + 2.0   # tilt: lift the floor over the post at the post, + 2 deg margin


def rot(pt, th):
    t = math.radians(-th)          # clockwise
    x, y = pt[0] - P[0], pt[1] - P[1]
    return (P[0] + x * math.cos(t) - y * math.sin(t), P[1] + x * math.sin(t) + y * math.cos(t))


def tipper(th):
    """wire pairs (each drawn line = 2 wires, front + back): floor of the 2-ball section, the arc, the overhead track"""
    floor = [(0, 0), (POST_X - 1.5, 0)]
    arc = [(P[0] + RA * math.cos(math.radians(180 + (EXIT_A - 180) * i / 40)), P[1] + RA * math.sin(math.radians(180 + (EXIT_A - 180) * i / 40))) for i in range(41)]
    ex = arc[-1]
    top_z = D + 1.5
    c = (ex[0] + D / 2 + 1.5, top_z - (D / 2 + 1.5) - 0)            # overhead turns down on the right of the descent
    xr = ex[0] + R + 2.5                                              # outer rail of the descent, left of the axle
    over = [(0, top_z), (xr - 12, top_z)] + [(xr - 12 + 12 * math.sin(math.radians(a)), top_z - 12 + 12 * math.cos(math.radians(a))) for a in range(0, 91, 10)]
    over += [(xr, ex[1] + 10)]
    # retaining rings on the tipper, edge-on: upstream end of the 2-ball section (vertical), at the overhead track's bend
    # (45 deg), and the EXIT RING at the bottom of the descent (horizontal: the balls drop down through it)
    h = RING_OD / 2
    xd = xr - R - 1.0                                                 # descent tube axis
    zm = (AXIS_Z + ex[1]) / 2 - 4                                     # a ring part way down the descent
    rings = [((0.6, AXIS_Z - h), (0.6, AXIS_Z + h)),
             ((xd - h, zm), (xd + h, zm)),
             ((xd - h, ex[1]), (xd + h, ex[1]))]                     # exit ring: where the arc and the overhead track meet
    exit_c = (xd, ex[1])
    rr = [[rot(a, th), rot(b, th)] for a, b in rings]
    return [[rot(p, th) for p in floor], [rot(p, th) for p in arc], [rot(p, th) for p in over]], rot(exit_c, th), rr


def panel(ax, th, title, tripped):
    ax.plot([-80, 0], [0, 0], color="red", lw=2.5); ax.plot([-80, 0], [D + 1.5, D + 1.5], color="red", lw=1, ls=":")
    ax.text(-78, -6, "fixed feed track (red)", fontsize=7, color="red")
    ax.plot([POST_X, POST_X], [-6, POST_H], color="red", lw=3); ax.text(POST_X - 4, -12, "fixed post\n(on the feed track)", fontsize=7, color="red")
    lines, ex, rings = tipper(th)
    for k, (a, b) in enumerate(rings):
        ax.plot([a[0], b[0]], [a[1], b[1]], color="green", lw=4, solid_capstyle="butt")
    ax.text(rings[0][1][0] - 4, rings[0][1][1] + 2, "ring", fontsize=7, color="green")
    ax.text(rings[1][0][0] - 12, rings[1][0][1] - 1, "ring", fontsize=7, color="green")
    ax.plot([-40, -40], [AXIS_Z - RING_OD / 2, AXIS_Z + RING_OD / 2], color="green", lw=4, solid_capstyle="butt")
    ax.text(-46, AXIS_Z + RING_OD / 2 + 2, "fixed track ring", fontsize=7, color="green")
    for ln, col, lab in zip(lines, ("navy", "royalblue", "steelblue"), ("2-ball section floor", "arc r 60 (centred on the pivot)", "overhead track")):
        ax.plot(*zip(*ln), color=col, lw=2.2)
    ax.text(rings[2][1][0] + 2, rings[2][1][1] - 2, "EXIT RING (edge-on:\nballs drop down through it)", fontsize=8, color="green", weight="bold")
    ax.plot(*P, "o", ms=9, mfc="w", mec="k"); ax.text(P[0] + 4, P[1] + 3, "pivot (axle)", fontsize=8)
    balls = [(-(k - 1) * D - R, R) for k in range(1, 4)]                             # 2, 3, 4 on the fixed track (touching ball 1)
    if tripped:
        e0 = rot((ex[0], ex[1]), 0)
        held = [rot((R, R), th), rot((R + D, R), th)]
        held = [(ex[0], ex[1] - 12), (ex[0], ex[1] + 14)]                           # dropping down through the exit ring
    else:
        held = [(R, R), (R + D, R)]
    for (x, y), n in zip(held, (1, 0)):
        ax.add_patch(plt.Circle((x, y), R, fc="seagreen", alpha=.5, ec="k")); ax.text(x - 2, y - 2, str(n), fontsize=9, weight="bold")
    for (x, y), n in zip(balls, (2, 3, 4)):
        ax.add_patch(plt.Circle((x, y), R, fc="steelblue", alpha=.45, ec="k")); ax.text(x - 2, y - 2, str(n), fontsize=9, weight="bold")
    tip = lines[1][0]
    if tripped:
        ax.annotate("arc's end rises between\nballs 1 and 2: holds the queue", tip, (tip[0] - 70, tip[1] + 30), fontsize=7, arrowprops=dict(arrowstyle="->"))
    cx = ex[0] + 32
    ax.add_patch(plt.Rectangle((cx, ex[1] - 25), 8, 50, fc="peru", alpha=.8))
    ax.annotate("", (ex[0] + 15, ex[1]), (cx, ex[1]), arrowprops=dict(arrowstyle="->", lw=2))
    ax.text(cx - 6, ex[1] - 34, "pendulum's catcher\npushes the exit ring", fontsize=7)
    ax.set_xlim(-85, 140); ax.set_ylim(-95, 45); ax.set_aspect("equal"); ax.set_title(title, fontsize=9)


def main():
    lift_end = RA * math.sin(math.radians(TH))
    push = RA * math.radians(TH)
    fig, (a, b) = plt.subplots(2, 1, figsize=(12, 11))
    panel(a, 0.0, "AT REST: balls 1 + 0 on the tipper's 2-ball section against the FIXED post; queue (2, 3, 4) on the fixed track", False)
    panel(b, TH, f"TIPPED {TH:.1f} deg clockwise (catcher pushing the exit ring): the section lifts over the post, 1 + 0 roll down into the "
          f"exit ring;\nthe arc's end has risen {lift_end:.1f} between balls 1 and 2", True)
    fig.text(0.02, 0.01, f"Arc r {RA:g} centred on the pivot; post {POST_H:g} tall, {P[0] - POST_X:.1f} from the pivot -> tilt {TH:.1f} deg "
             f"(incl. 2 deg margin); arc end rises {lift_end:.1f} (>= 4 holds ball 2); catcher pushes the exit ring {push:.1f} "
             "(on r 60). Each drawn line = a wire pair (front + back). Positions adjustable.", fontsize=8)
    out = Path(__file__).resolve().parent.parent / "views" / "tipper_reference.png"
    plt.tight_layout(rect=(0, 0.03, 1, 1)); plt.savefig(out, dpi=100)
    ex = tipper(0)[1]
    print(f"{out.name}: tilt {TH:.1f}, arc end rises {lift_end:.1f}, push {push:.1f}, post {P[0] - POST_X:.1f} from the pivot; "
          f"exit ring at ({ex[0]:.1f}, {ex[1]:.1f}); descent outer rail {P[0] - (ex[0] + R + 2.5):.1f} left of the axle")


if __name__ == "__main__":
    main()
