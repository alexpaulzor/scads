#!/usr/bin/env python3
"""Sketch: teeter escapement under the end of the waiting track, tripped by the pendulum. One ply3 rocker below the
track with two fingers that come up between the rails: the GATE finger in front of ball 0 and the CARD finger in the V
under where balls 1 and 2 touch. A finger standing 4 above the balls' bottoms stops a ball (rolling over a 4 step takes
~54 deg of tilt), so each finger only moves ~5; the gap under touching balls is 3.5 wide there, room for a 2.63 finger. The pendulum's pin pushes the tail down near the left peak: gate finger
drops (and swings away from ball 0), card finger rises between 1 and 2 (and nudges 1 on): balls 0 + 1 roll into the
catcher. When it leaves, a counterweight rocks it back: the card drops out, the queue rolls up to the gate.
    python3 marbles/clock/feed_escapement_sketch.py   # -> marbles/views/feed_escapement.png"""
import math
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from shapely import affinity  # noqa: E402
from shapely.geometry import Point, Polygon, box  # noqa: E402
from shapely.ops import unary_union  # noqa: E402

D = 19.05; R = D / 2; T = 2.63
UP, DOWN = 4.0, -1.0           # finger tip: blocking height / released height (above the balls' bottoms = y 0)
X0 = 0.0                        # ball 0 centre
GATE_X = X0 + math.sqrt(R ** 2 - (R - 3) ** 2) + T / 2      # gate finger: touching ball 0 at 3 up
CARD_X = X0 - 1.5 * D           # card finger: under where balls 1 and 2 touch
PIV = ((GATE_X + CARD_X) / 2, -16.0)        # low enough that the beam stays under the balls when it rocks
TAIL = 40.0
ARM = GATE_X - PIV[0]
TH = math.degrees(math.asin((UP - DOWN) / ARM))             # rocker swing (the gate tip drops UP -> DOWN)


def v_gap(y):
    """width of the gap between two touching balls at height y above their bottoms"""
    return D - 2 * math.sqrt(max(0.0, R ** 2 - (R - y) ** 2))


def _rot(p, th):
    t = math.radians(th); x, y = p[0] - PIV[0], p[1] - PIV[1]
    return (PIV[0] + x * math.cos(t) - y * math.sin(t), PIV[1] + x * math.sin(t) + y * math.cos(t))


CARD_TIP_REST = _rot((CARD_X, UP), TH)       # placed so that TRIPPED (-TH) its tip lands at (CARD_X, UP), centred in the gap


def rocker(theta):
    """theta 0 = at rest (gate up, card down); -TH = tripped (tail pushed down, clockwise)"""
    cx, cy = CARD_TIP_REST
    beam = box(min(CARD_X, cx) - 6, PIV[1] - 3, GATE_X + TAIL, PIV[1] + 3)
    gate = box(GATE_X - T / 2, PIV[1], GATE_X + T / 2, UP)
    card = Polygon([(cx - T / 2, PIV[1]), (cx + T / 2, PIV[1]), (cx + T / 2, cy - 1.0), (cx, cy), (cx - T / 2, cy - 1.0)])
    weight = box(min(CARD_X, cx) - 12, PIV[1] - 14, min(CARD_X, cx) - 2, PIV[1] - 3)   # hangs below the beam
    g = unary_union([beam, gate, card, weight]).difference(Point(PIV).buffer(1.65, 24))
    return affinity.rotate(g, theta, origin=PIV)


def panel(ax, theta, title, tripped):
    for z in (0.0,):
        ax.plot([-100, 32], [z + 2.4, z + 2.4], color="0.55", lw=2.5)
    ax.text(-98, 4.5, "rails (the track's two lower wires; bottom ring segments clipped here)", fontsize=7, color="0.4")
    for k in range(5):
        x, y = X0 - k * D, R
        if tripped and k < 2:
            x, y = X0 + 40 + (1 - k) * 22, R - 12 - (1 - k) * 4
        ax.add_patch(plt.Circle((x, y), R, fc="seagreen" if k < 2 else "steelblue", alpha=.55, ec="k"))
        ax.text(x - 2, y - 2, str(k), fontsize=9, weight="bold")
    g = rocker(theta)
    ax.fill(*g.exterior.xy, fc="peru", ec="saddlebrown")
    for r in g.interiors:
        ax.fill(*r.xy, fc="w", ec="saddlebrown")
    ax.plot(*PIV, "ko", ms=3)
    tail = affinity.rotate(Point(GATE_X + TAIL - 4, PIV[1] + 3 + 2.5), theta, origin=PIV)
    ax.add_patch(plt.Circle((tail.x, tail.y), 2.5, fc="k"))
    ax.annotate("pendulum pin pushes\nthe tail DOWN", (tail.x, tail.y + 2), (tail.x - 4, tail.y + 18), fontsize=7, arrowprops=dict(arrowstyle="->"))
    ax.text(CARD_X - 16, PIV[1] - 14, "counterweight\n(rocks it back)", fontsize=7)
    ax.plot([GATE_X + 14, GATE_X + 70], [-4, -18], color="0.3", lw=1.5)
    ax.text(GATE_X + 26, -27, "catcher on the pendulum (left peak): balls drop >= 5 over its lip", fontsize=7)
    ax.set_xlim(-102, 95); ax.set_ylim(-32, 32); ax.set_aspect("equal"); ax.set_title(title, fontsize=9)


def main():
    fig, (a, b) = plt.subplots(2, 1, figsize=(12, 8.5))
    panel(a, 0.0, f"AT REST: gate finger {UP:g} up in front of ball 0 (blocks), card finger below the balls; queue waits on the gate", False)
    panel(b, -TH, f"TRIPPED (tail pushed down, rocker {TH:.0f} deg): gate finger drops below the balls and swings away from 0; card finger "
          f"rises\n{UP:g} into the gap under 1|2 (gap there {v_gap(UP):.1f} wide for a {T} finger): balls 0 + 1 roll into the catcher, 2 onward wait", True)
    out = Path(__file__).resolve().parent.parent / "views" / "feed_escapement.png"
    plt.tight_layout(); plt.savefig(out, dpi=100)
    print(f"{out.name}: card tip at rest ({CARD_TIP_REST[0]:.2f}, {CARD_TIP_REST[1]:.2f}) -> tripped ({CARD_X:.2f}, {UP:g}); "
          f"fingers {GATE_X - CARD_X:.2f} apart, pivot midway {PIV[1]:g} below, arms {ARM:.2f}, rocker {TH:.1f} deg; "
          f"V gap at {UP:g} up {v_gap(UP):.2f}, at 4 up {v_gap(4):.2f}")


if __name__ == "__main__":
    main()
