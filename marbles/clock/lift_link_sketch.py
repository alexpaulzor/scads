#!/usr/bin/env python3
"""Sketch: a RIGID link (no chain) holding the lift's moving beam M while the pendulum rig rocks.

Side view (swing plane) with the rig at -12 / 0 / +12 deg, the link solve (M's slide = the stroke), a front view
and a detail of the link itself. Geometry numbers are lift_demo.scad's (pivot 45 above M's top pin, M's pin `arm`
behind the pivot, 100 link) until the real rig is measured.

    python3 marbles/clock/lift_link_sketch.py      # -> marbles/views/lift_link_sketch.png
"""
import math
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Circle, FancyBboxPatch, Polygon, Rectangle  # noqa: E402

HERE = Path(__file__).resolve().parent
TILT = 12.0
LIFT = 30 + 2 * 2                                  # pitch + 2 x drop
ARM = 0.98805 * LIFT / (2 * math.sin(math.radians(TILT)))   # pivot ahead of M's top pin (lift_demo)
PIVOT_UP = 45.0
LINK = 100.0
P = (0.0, 0.0)                                     # pivot (side view: y = swing, + toward the front; z up)
M0 = (-ARM, -PIVOT_UP)                             # M's top pin, rig at rest
A = (M0[0], M0[1] + LINK)                          # fixed anchor, straight above the pin
RIG_LEN = 330.0                                    # how much of the rig to draw
M_Y = -26.0                                        # M's beam centre (behind the spine, side view)


def rot(p, a, c=P):
    """turn point p about c by a deg; + = top toward the front (y+) for points above c"""
    a = math.radians(-a)
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * math.cos(a) - y * math.sin(a), c[1] + x * math.sin(a) + y * math.cos(a))


def slide(tilt):
    """M's slide along the rig (+ = up the rig) that keeps the link length at this tilt"""
    lo, hi = -60.0, 60.0
    def err(s):
        q = rot((M0[0], M0[1] + s), tilt)
        return math.dist(q, A) - LINK
    for _ in range(80):
        m = (lo + hi) / 2
        if err(lo) * err(m) <= 0:
            hi = m
        else:
            lo = m
    return (lo + hi) / 2


def rig_shapes(tilt, s):
    """F (the spine, fixed to the pivot) and M (sliding along it), as polygons, rig turned by tilt"""
    def box(y0, y1, z0, z1):
        return [rot(p, tilt) for p in ((y0, z0), (y1, z0), (y1, z1), (y0, z1))]
    F = box(-10, 10, -RIG_LEN, -10)                                    # spine under the pivot clamp
    Mb = box(M_Y - 10, M_Y + 10, -RIG_LEN + s, M0[1] + s - 6)          # M's beam, right behind the spine
    tab = box(M0[0] - 8, M_Y + 10, M0[1] + s - 6, M0[1] + s + 8)      # arm off M's top end, back to the pin
    pin = rot((M0[0], M0[1] + s), tilt)
    return F, Mb, tab, pin


def main():
    s_f, s_b = slide(TILT), slide(-TILT)
    stroke = abs(s_f - s_b)
    link_ang = [math.degrees(math.atan2(rig_shapes(t, slide(t))[3][0] - A[0], A[1] - rig_shapes(t, slide(t))[3][1]))
                for t in (-TILT, TILT)]
    fig = plt.figure(figsize=(16, 10))
    ax = fig.add_axes([0.03, 0.06, 0.50, 0.86])
    ax2 = fig.add_axes([0.56, 0.47, 0.42, 0.45])
    ax3 = fig.add_axes([0.56, 0.05, 0.42, 0.36])

    # --- side view
    ax.add_patch(Rectangle((-170, A[1] + 6), 260, 20, fc="#333", ec="k"))              # fixed top beam (outer frame)
    ax.text(-165, A[1] + 30, "fixed frame beam (2020, reachable from above / sides)", fontsize=8)
    ax.add_patch(Rectangle((-20, 6), 40, 30, fc="#999", ec="k"))                        # pillow block
    ax.text(25, 20, "pillow block (pivot, as now)", fontsize=8)
    ax.add_patch(Rectangle((A[0] - 9, A[1]), 18, 8, fc="#777", ec="k"))                 # anchor bracket
    cols = {-TILT: "#1f77b4", 0.0: "#555", TILT: "#d62728"}
    for t in (-TILT, 0.0, TILT):
        s = slide(t)
        F, Mb, tab, pin = rig_shapes(t, s)
        a = 0.85 if t == 0 else 0.35
        ax.add_patch(Polygon(F, fc="#c0c0c0", ec=cols[t], alpha=a, lw=1.2))
        ax.add_patch(Polygon(Mb, fc="#e8d3a8", ec=cols[t], alpha=a, lw=1.2))
        ax.add_patch(Polygon(tab, fc="#b07040", ec=cols[t], alpha=a, lw=1.2))
        ax.plot([A[0], pin[0]], [A[1], pin[1]], "-", color=cols[t], lw=5 if t == 0 else 3, alpha=.9, solid_capstyle="round")
        ax.add_patch(Circle(pin, 3, color="k"))
    ax.add_patch(Circle(A, 3.5, color="k"))
    ax.add_patch(Circle(P, 5, fc="w", ec="k", lw=2))
    ax.annotate("rigid LINK\n(rod ends both ends)", (A[0] - 2, A[1] - LINK / 2), (A[0] - 135, A[1] - 60),
                arrowprops=dict(arrowstyle="->"), fontsize=9)
    ax.annotate("fixed pivot\n(link anchor)", A, (A[0] - 135, A[1] - 5), arrowprops=dict(arrowstyle="->"), fontsize=8)
    ax.annotate("arm bolted to the top of M\n(T-nuts in its slot),\ncarries the lower pin", rig_shapes(0, 0)[3], (M0[0] - 135, M0[1] - 75),
                arrowprops=dict(arrowstyle="->"), fontsize=8)
    ax.annotate("spine (F): clamped to the\npivot shaft only, as now", rot((0, -200), 0), (40, -200),
                arrowprops=dict(arrowstyle="->"), fontsize=8)
    ax.annotate("M (outside assembly):\nslides along F", rot((M_Y, -200), 0), (-210, -240),
                arrowprops=dict(arrowstyle="->"), fontsize=8)
    ax.text(-200, -RIG_LEN + 10, f"blue: rig back {TILT:g} deg, M slid {s_b:+.1f}\nred: rig forward {TILT:g} deg, M slid {s_f:+.1f}\n"
            f"stroke {stroke:.1f} (target {LIFT:g} = 30 pitch + 2 x 2 drop)\nlink swings {link_ang[0]:+.1f} / {link_ang[1]:+.1f} deg",
            fontsize=9, va="bottom", bbox=dict(fc="w", ec="0.7"))
    ax.set_xlim(-220, 140)
    ax.set_ylim(-RIG_LEN - 10, A[1] + 50)
    ax.set_aspect("equal")
    ax.set_title(f"SIDE VIEW (swing plane): link {LINK:g}, pin {ARM:.1f} behind / {PIVOT_UP:g} below the pivot "
                 "(lift_demo numbers until measured)", fontsize=9)
    ax.set_xlabel("swing direction, mm (front ->)")

    # --- front view: one link each side of the spine, on one anchor shaft
    ax2.add_patch(Rectangle((-110, 120), 220, 20, fc="#333"))
    ax2.text(-108, 144, "fixed frame beam", fontsize=8)
    for x in (-30, 30):
        ax2.add_patch(Rectangle((x - 8, 100), 16, 20, fc="#777", ec="k"))                # anchor brackets
    ax2.plot([-45, 45], [108, 108], "k-", lw=4)                                          # anchor shaft
    ax2.text(48, 105, "M5 / 8 mm anchor shaft through both brackets", fontsize=7)
    ax2.add_patch(Rectangle((-10, -140), 20, 235, fc="#c0c0c0", ec="k"))                # spine F (centre)
    ax2.add_patch(Rectangle((-14, 88), 28, 12, fc="#999", ec="k"))                       # SK8 clamp on the shaft
    ax2.text(-12, 92, "SK8", fontsize=6)
    for side in (-1, 1):
        x = side * 30
        ax2.add_patch(Rectangle((x - 10 + side * 10, -140), 20, 130, fc="#e8d3a8", ec="k"))   # M side beams
        ax2.add_patch(Rectangle((x - 8 + side * 10, -14), 16, 16, fc="#b07040", ec="k"))     # top tabs
        ax2.plot([x, x + side * 10], [108, -6], "-", color="#555", lw=6, solid_capstyle="round")  # links
        ax2.add_patch(Circle((x + side * 10, -6), 2.5, color="k"))
        ax2.add_patch(Circle((x, 108), 2.5, color="k"))
    ax2.add_patch(Rectangle((-50, -150), 100, 10, fc="#b07040", alpha=.6))
    ax2.text(-48, -165, "front keepers tie M's two sides together (as built)", fontsize=7)
    ax2.text(60, -40, "two links, one each side,\nso M can't twist: with the\nanchor shaft and M they\nmake a rigid frame", fontsize=8)
    ax2.set_xlim(-115, 160)
    ax2.set_ylim(-175, 160)
    ax2.set_aspect("equal")
    ax2.axis("off")
    ax2.set_title("FRONT VIEW (schematic, not to scale): spine untouched; links reach M's outer beams from above", fontsize=9)

    # --- link detail
    ax3.plot([20, 180], [0, 0], color="#888", lw=7, solid_capstyle="butt")
    for x, lab in ((0, "M6 rod end\n(right-hand)"), (200, "M6 rod end\n(left-hand)")):
        ax3.add_patch(Circle((x, 0), 11, fc="#bbb", ec="k"))
        ax3.add_patch(Circle((x, 0), 3, fc="w", ec="k"))
        ax3.add_patch(Rectangle((x - 4 + (16 if x == 0 else -16), -5), 8, 10, fc="#666"))     # lock nuts
        ax3.text(x, -28, lab, ha="center", fontsize=8)
    ax3.text(100, 10, "M6 threaded rod (or a coupler nut between two rods)", ha="center", fontsize=8)
    ax3.annotate("", (20, 22), (180, 22), arrowprops=dict(arrowstyle="<->"))
    ax3.text(100, 26, f"pin to pin = LINK ({LINK:g} here): turn the rod to set it, lock nuts hold it", ha="center", fontsize=8)
    ax3.text(100, -55, "each end pivots on an M5 shoulder bolt (or M5 + sleeve) through the bracket / M's tab:\n"
             "no slack either way, so M is held up AND down (the chain only pulled)", ha="center", fontsize=8)
    ax3.set_xlim(-30, 230)
    ax3.set_ylim(-75, 40)
    ax3.set_aspect("equal")
    ax3.axis("off")
    ax3.set_title("LINK DETAIL: a turnbuckle you can push on", fontsize=9)
    out = HERE.parent / "views" / "lift_link_sketch.png"
    plt.savefig(out, dpi=110)
    print(f"{out.name}: arm {ARM:.1f}, stroke {stroke:.2f} (M slides {s_b:+.2f} back / {s_f:+.2f} forward), "
          f"link swings {link_ang[0]:+.1f} / {link_ang[1]:+.1f} deg")


if __name__ == "__main__":
    main()
