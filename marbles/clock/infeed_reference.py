#!/usr/bin/env python3
"""Reference diagram: pendulum infeed, all wire. Waiting track -> wire teeter escapement (2 balls per trip, tripped by
a pin on the pendulum near the left peak) -> catch cradle on the pendulum -> one 4-wire tube running front to back
(parallel to the pivot axis, so the swing never changes its slope) -> first branch into the FRONT lane, the tube's end
into the BACK lane (overflow). Dimensions in mm; positions are adjustable, the point is to spend little height.
    python3 marbles/clock/infeed_reference.py   # -> marbles/views/infeed_reference.png"""
import math
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Arc, Circle, FancyArrowPatch, Rectangle  # noqa: E402

D = 19.05; R = D / 2; WD = 2.05
RW = 11.025                       # tube wire centre radius (4-wire, 20 bore)
RING_OD = 28.2
LANE_F, LANE_B = -20.0, 20.0      # lane holes, front (viewer side, -y) and back, 40 apart, on the flange face x = 0
BEND = 31.02                      # tube centreline bend radius (bending form's 30 corner + half the wire)
CATCH_Y = -78.0                   # catch cradle centre (front end of the tube)
DROP = 5.0                        # ball drop at the catch (the one-way step)
SLOPE = 2.5 / 40                  # main tube: 2.5 down per 40 toward the back
# teeter (from feed_escapement_sketch.py)
FINGERS = 36.83; PIV_DOWN = 16.0; UP = 4.0; SWING = 15.8


def dim(ax, p, q, txt, off=(0, 0), fs=7):
    ax.annotate("", q, p, arrowprops=dict(arrowstyle="<->", lw=0.8, color="0.25"))
    ax.text((p[0] + q[0]) / 2 + off[0], (p[1] + q[1]) / 2 + off[1], txt, fontsize=fs, ha="center", color="0.15")


def tube_path(ax, pts, col="0.35"):
    """a 4-wire tube along pts, top view: centreline + the two side wires at +-RW*cos45 (the top/bottom pairs overlap)"""
    xs, ys = zip(*pts)
    ax.plot(xs, ys, color="steelblue", lw=0.8, ls="--")
    for s in (1, -1):
        off = []
        for i, (x, y) in enumerate(pts):
            a = pts[max(i - 1, 0)]; b = pts[min(i + 1, len(pts) - 1)]
            dx, dy = b[0] - a[0], b[1] - a[1]; L = math.hypot(dx, dy) or 1
            off.append((x - s * dy / L * RW * math.cos(math.pi / 4), y + s * dx / L * RW * math.cos(math.pi / 4)))
        ax.plot(*zip(*off), color=col, lw=1.6)


def arc_pts(c, r, a0, a1, n=30):
    return [(c[0] + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), c[1] + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def top_view(ax):
    ax.add_patch(Rectangle((0, -45), 2.63, 90, fc="burlywood", ec="saddlebrown"))           # flange (wire-interface entry flange)
    ax.text(4, 40, "entry flange (wire interface,\n23.1 bores + notches)", fontsize=7)
    for y, lab in ((LANE_F, "FRONT lane hole"), (LANE_B, "BACK lane hole")):
        ax.plot([0, 0], [y - 11.55, y + 11.55], color="w", lw=3); ax.text(5, y - 2, lab, fontsize=7, weight="bold")
    xm = -BEND                                                                               # main tube centreline x
    y_fb = LANE_F - BEND                                                                     # front branch leaves the main tube here
    y_be = LANE_B - BEND                                                                     # back elbow starts here
    tube_path(ax, [(xm, CATCH_Y + 10), (xm, y_be)] + arc_pts((0, y_be), BEND, 180, 90)[1:])  # main tube + back elbow
    tube_path(ax, arc_pts((0, y_fb), BEND, 180, 90), col="seagreen")                        # front branch
    ax.add_patch(Circle((xm, CATCH_Y), 17, fc="none", ec="peru", lw=2))                      # catch cradle
    ax.text(xm - 46, CATCH_Y - 4, "CATCH cradle\n(open top, on the\npendulum)", fontsize=7, color="saddlebrown")
    # waiting track arriving from the left, along x, at the front
    ax.plot([-170, xm - 6], [CATCH_Y + RW * 0.707, CATCH_Y + RW * 0.707], color="0.5", lw=1.6)
    ax.plot([-170, xm - 6], [CATCH_Y - RW * 0.707, CATCH_Y - RW * 0.707], color="0.5", lw=1.6)
    for k in range(4):
        ax.add_patch(Circle((xm - 22 - k * D, CATCH_Y), R, fc="steelblue", alpha=.4, ec="k"))
    ax.text(-168, CATCH_Y + 12, "waiting track (fixed) + teeter under its end", fontsize=7)
    ax.add_patch(FancyArrowPatch((xm, CATCH_Y + 18), (xm, y_fb + 3), arrowstyle="->", mutation_scale=12, color="k"))
    ax.text(xm - 30, (CATCH_Y + y_fb) / 2, f"downhill\n{SLOPE * 40:g} per 40", fontsize=7)
    ax.annotate("first opening: FRONT lane\n(a full lane leaves a ball\nfilling the gap; the next\nrolls on past)", (xm + 8, y_fb + 6), (-150, -30),
                fontsize=7, arrowprops=dict(arrowstyle="->"))
    ax.annotate("tube's end: BACK lane\n(overflow only)", (xm + 10, y_be + 18), (-150, 15), fontsize=7, arrowprops=dict(arrowstyle="->"))
    dim(ax, (6, LANE_F), (6, LANE_B), "40", off=(6, 0))
    dim(ax, (xm, y_fb - 6), (0, y_fb - 6), f"r {BEND:.0f} bends\n(form corner 30)", off=(0, -9))
    ax.annotate("", (-180, -120), (-180, -95), arrowprops=dict(arrowstyle="->")); ax.text(-176, -112, "toward the\nviewer", fontsize=7)
    ax.set_xlim(-185, 60); ax.set_ylim(-125, 50); ax.set_aspect("equal"); ax.invert_yaxis()
    ax.set_title("TOP VIEW (looking down; the viewer / clock face is at the TOP of this panel)", fontsize=9)


def front_view(ax):
    xm = -BEND
    z_catch = 0.0 + 3.0                                        # catch: ball centre ~3 above the lane hole centres
    z_feed = z_catch + DROP
    ax.add_patch(Rectangle((0, -40), 2.63, 120, fc="burlywood", ec="saddlebrown")); ax.text(4, 70, "flange\n(pendulum)", fontsize=7)
    ax.plot([-170, xm - 8], [z_feed - R + 2.4] * 2, color="0.5", lw=2)                    # track rails
    for k in range(4):
        ax.add_patch(Circle((xm - 22 - k * D, z_feed), R, fc="seagreen" if k < 2 else "steelblue", alpha=.45, ec="k"))
        ax.text(xm - 24 - k * D, z_feed - 2, str(k), fontsize=8, weight="bold")
    ax.add_patch(Circle((xm, z_catch), R, fc="seagreen", alpha=.25, ec="k", ls="--"))
    ax.add_patch(Rectangle((xm - 17, z_catch - R - 4), 34, 3, fc="peru", ec="saddlebrown")); ax.text(xm - 15, z_catch - R - 10, "catch floor", fontsize=7)
    dim(ax, (xm + 14, z_catch), (xm + 14, z_feed), f">= {DROP:g} drop", off=(11, 0))
    # teeter under the track end
    x_gate = xm - 22 + R + 1.3
    x_card = xm - 22 - 1.5 * D
    xp = (x_gate + x_card) / 2; zp = z_feed - R - PIV_DOWN
    ax.plot([x_card - 8, x_gate + 30], [zp, zp], color="0.15", lw=2.5)
    ax.plot([x_gate, x_gate], [zp, z_feed - R + UP], color="0.15", lw=2.2); ax.plot([x_card, x_card], [zp, z_feed - R - 1], color="0.15", lw=2.2)
    ax.plot(xp, zp, "wo", ms=6, mec="k")
    ax.add_patch(Rectangle((x_card - 10, zp - 9), 6, 7, fc="0.4")); ax.text(x_card - 20, zp - 16, "counterweight (nut)", fontsize=7)
    ax.add_patch(Circle((x_gate + 26, zp + 4.5), 2.5, fc="k"))
    ax.annotate("trip pin on the pendulum\n(on a springy wire: overtravel)", (x_gate + 26, zp + 7), (x_gate + 5, zp + 32), fontsize=7, arrowprops=dict(arrowstyle="->"))
    ax.text(x_card - 30, zp + 10, "WIRE TEETER", fontsize=8, weight="bold")
    ax.set_xlim(-170, 60); ax.set_ylim(-45, 85); ax.set_aspect("equal")
    ax.set_title("FRONT VIEW (clock face; pendulum at the left peak, drawn upright)", fontsize=9)


def teeter_detail(ax):
    zb = 0.0                                                  # balls' bottoms
    x0 = 0.0
    x_gate = x0 + math.sqrt(R ** 2 - (R - 3) ** 2) + 1.0
    x_card = x0 - 1.5 * D
    xp = (x_gate + x_card) / 2; zp = zb - PIV_DOWN
    ax.plot([-75, 25], [2.4, 2.4], color="0.5", lw=2); ax.text(-74, 4, "rails", fontsize=7, color="0.4")
    for k in range(4):
        ax.add_patch(Circle((x0 - k * D, R), R, fc="seagreen" if k < 2 else "steelblue", alpha=.45, ec="k"))
    ax.plot([x_card - 6, x_gate + 32], [zp, zp], color="0.15", lw=2.5)
    ax.plot([x_gate, x_gate], [zp, UP], color="0.15", lw=2.2)
    ax.plot([x_card - 3, x_card], [zp, -1.0], color="0.15", lw=2.2)
    ax.plot(xp, zp, "wo", ms=7, mec="k")
    dim(ax, (x_card, zp - 6), (x_gate, zp - 6), f"{FINGERS:.1f} (2 balls)", off=(0, -6))
    dim(ax, (x_gate + 6, zb), (x_gate + 6, UP), f"{UP:g} up blocks", off=(13, 0))
    dim(ax, (xp - 6, zb), (xp - 6, zp), f"pivot {PIV_DOWN:g}\nbelow, midway", off=(-14, 0))
    ax.text(-74, -30, f"At rest: gate finger {UP:g} up in front of ball 0, card finger below the balls.\n"
            f"Tripped (pin pushes the tail down, rocker {SWING:.0f} deg): gate drops and swings away, card rises {UP:g}\n"
            "into the gap under balls 1|2 (3.5 wide there). Balls 0 + 1 go; the counterweight rocks it back.\n"
            "Clip the bottom ring segments where the fingers come up.", fontsize=7, va="top")
    ax.set_xlim(-78, 45); ax.set_ylim(-48, 24); ax.set_aspect("equal"); ax.set_title("TEETER DETAIL (side, along the track)", fontsize=9)


def main():
    fig = plt.figure(figsize=(16, 11))
    top_view(fig.add_axes([0.02, 0.36, 0.52, 0.6]))
    front_view(fig.add_axes([0.56, 0.55, 0.43, 0.42]))
    teeter_detail(fig.add_axes([0.56, 0.06, 0.43, 0.44]))
    t = fig.add_axes([0.02, 0.02, 0.52, 0.3]); t.axis("off")
    t.text(0, 1, "REFERENCE: pendulum infeed, all wire (positions adjustable; spend as little height as possible)\n\n"
           "1. Waiting track (fixed) holds the queue against the teeter's gate finger.\n"
           "2. Near the left peak a pin on the pendulum pushes the teeter's tail down: balls 0 + 1 roll off the track end.\n"
           f"3. They drop >= {DROP:g} into the CATCH cradle on the pendulum (the drop is the one-way step: rolling back over a 5 step\n"
           "   takes ~62 deg of tilt).\n"
           f"4. One 4-wire tube runs front to back, parallel to the pivot axis (the swing never changes its slope), {SLOPE * 40:g} down per 40.\n"
           "5. First opening: the FRONT lane (a branch elbow into its hole). A full lane leaves a ball sitting in that opening,\n"
           "   so the next one rolls past to the tube's end: the BACK lane (overflow only).\n"
           f"Bends: the bending form's 30 corner (wire centreline r {BEND:.2f}). Ball {D}, tube bore 20, ring OD {RING_OD}.\n"
           "Open: what happens when both lanes are full (overflow lip at the catch back to the hopper, or trust the rates).",
           fontsize=8.5, va="top", family="monospace")
    out = Path(__file__).resolve().parent.parent / "views" / "infeed_reference.png"
    plt.savefig(out, dpi=110)
    print(out.name)


if __name__ == "__main__":
    main()
