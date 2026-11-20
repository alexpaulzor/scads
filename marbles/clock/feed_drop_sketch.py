#!/usr/bin/env python3
"""Sketch: feed drop at the wheel. Top plate (9 above the rail top, held by tabs in two walls on the rail's faces) with a
90 deg elbow to a 20 drop hole; bottom plate (under the rail) with an ice-cream-cone slot to the 20 circle by the 2020.
    python3 marbles/clock/feed_drop_sketch.py   # -> marbles/views/feed_drop_v5.png"""
import math
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from shapely.geometry import LineString, Point, box, Polygon  # noqa: E402
from shapely.ops import unary_union  # noqa: E402

T = 2.63; BR = 19.05 / 2; ZC = math.sqrt(BR ** 2 - 3.1 ** 2); CL = 0.3
XL = -(10 + T + BR + 1.5)                 # lane line: ball 1.5 clear of the left wall's outer face
RC = -XL                                  # 90 deg elbow from the rail centre out to the lane line
GAP_BEAM = 15.0                           # drop circle's right edge this far left of the 2020's left face (wheel opening)
X_END, YEND = -(10 + GAP_BEAM + 10), -10.0 # drop circle centre: beside the 2020, level with its centre
Y_HOLE = 60.0
Y0 = Y_HOLE + RC                          # elbow starts at Y0 (heading downhill), ends at the drop hole (XL, Y_HOLE)
W_TIP = 14.0                              # cone's wide end: still holds the ball (centre 6.46 up); the circle drops it
TAB_W = 8.0


def geometry():
    el = [(-RC + RC * math.cos(math.radians(90 * i / 40)), Y0 - RC * math.sin(math.radians(90 * i / 40))) for i in range(41)]
    path = LineString([(0, Y0 + 40)] + el)
    # cone: straight (no curve) from under the drop hole to the circle beside the 2020
    y_c0 = Y_HOLE + 6
    p0, p1 = (XL, y_c0), (X_END, YEND)
    L = math.dist(p0, p1); u = ((p1[0] - p0[0]) / L, (p1[1] - p0[1]) / L); n = (-u[1], u[0])
    m = math.sqrt(10 ** 2 - (W_TIP / 2) ** 2)
    pm = (p1[0] - u[0] * m, p1[1] - u[1] * m)
    taper = Polygon([(p0[0] + n[0] * 3, p0[1] + n[1] * 3), (pm[0] + n[0] * W_TIP / 2, pm[1] + n[1] * W_TIP / 2),
                     (pm[0] - n[0] * W_TIP / 2, pm[1] - n[1] * W_TIP / 2), (p0[0] - n[0] * 3, p0[1] - n[1] * 3)])
    cone = unary_union([taper, Point(p1).buffer(10, 64)])
    y_meet = pm
    bot = unary_union([box(-10, 2, 10, y_c0 + 15), cone.buffer(8, join_style=2)]).difference(cone)
    yw1, yw0 = Y0 - (RC + 10) - 4, 5.0
    slots = [box(10 - T - CL, yw0, 10 + T, yw1), box(-10 - T, yw0, -10 + T + CL, yw1)]
    tabs = []
    for y in (yw0 + 5, yw1 - 5 - TAB_W):
        tabs += [box(10, y, 10 + T, y + TAB_W), box(-10 - T, y, -10, y + TAB_W)]   # tabs off the slots' OUTER edges
    yp0, yp1 = 2.0, Y0 + 25                  # top plate stops just short of the 2020
    plate = (box(XL - BR - 8, yp0, 10 + T + 8, yp1).difference(path.buffer(10, 64)).difference(Point(XL, Y_HOLE).buffer(10, 64))
             .difference(unary_union(slots)).union(unary_union(tabs)))
    return dict(path=path, cone=cone, bot=bot, plate=plate, yw=(yw0, yw1), yp=(yp0, yp1), y_meet=y_meet, y_c0=y_c0)


def main():
    g = geometry()
    path, cone, bot, plate = g["path"], g["cone"], g["bot"], g["plate"]
    (yw0, yw1), (yp0, yp1), y_meet, y_c0 = g["yw"], g["yp"], g["y_meet"], g["y_c0"]
    fig = plt.figure(figsize=(15, 10.5))
    a = fig.add_axes([0.02, 0.04, 0.44, 0.92]); d = fig.add_axes([0.48, 0.5, 0.3, 0.44])
    c = fig.add_axes([0.79, 0.56, 0.2, 0.36]); s = fig.add_axes([0.5, 0.05, 0.48, 0.38])

    def draw(ax, geo, **k):
        for p in getattr(geo, "geoms", [geo]):
            ax.fill(*p.exterior.xy, **k)
            for r in p.interiors:
                ax.fill(*r.xy, fc="w", ec=k.get("ec", "k"))
    a.add_patch(plt.Rectangle((-10, -20), 20, 20, fc="#444", ec="k")); a.text(-8, -9, "2020", color="w", fontsize=8)
    a.plot([-10 - GAP_BEAM] * 2, [-40, 10], "r--", lw=1); a.text(-86, -32, "wheel opening starts\n15 left of the 2020", color="r", fontsize=7)
    draw(a, bot, fc="tan", ec="sienna"); a.fill(*cone.exterior.xy, fc="w", ec="sienna")
    a.add_patch(plt.Rectangle((-10, 0), 20, yp1 + 8, fc="#ccc", ec="k", alpha=.35)); a.text(-7, yp1 + 3, "rail", fontsize=8)
    draw(a, plate, fc="burlywood", ec="saddlebrown", alpha=.65)
    for x in (10, -10 - T):
        a.add_patch(plt.Rectangle((x, yw0), T, yw1 - yw0, fc="peru", ec="k"))
    a.plot(*path.xy, "b--", lw=.9); a.plot([XL, X_END], [y_c0, YEND], "g--", lw=.9)
    a.add_patch(plt.Circle((0, Y0 + 15), BR, fc="steelblue", alpha=.35))
    a.add_patch(plt.Circle((XL, Y_HOLE), BR, fc="steelblue", alpha=.6)); a.add_patch(plt.Circle((X_END, YEND), BR, fc="green", alpha=.6))
    A = dict(arrowprops=dict(arrowstyle="->"), fontsize=8)
    a.annotate("TOP PLATE, 9 above the rail top:\n90 deg elbow to a 20 drop hole", (XL - 12, Y_HOLE + 18), (-86, Y0 + 20), **A)
    a.annotate("drops onto the narrow\nend of the cone below", (XL, Y_HOLE), (-86, Y_HOLE - 12), **A)
    a.annotate(f"BOTTOM PLATE: taper 6 -> {W_TIP:g},\nconcave step into the 20 circle", y_meet, (-86, 25), **A)
    a.annotate("walls on the rail's faces,\ndownhill of the elbow;\nleft one between the\nlane and the rail", (-10 - T, (yw0 + yw1) / 2), (22, (yw0 + yw1) / 2 + 20), **A)
    a.annotate("tabs on the slots'\nOUTER edges", (10 + T, yw1 - 9), (24, yw1 + 10), **A)
    a.set_xlim(-88, 52); a.set_ylim(-42, yp1 + 12); a.invert_yaxis(); a.set_aspect("equal")
    a.set_xlabel("mm across the rail: page left = LEFT looking downhill"); a.set_ylabel("from the 2020's face (balls roll UP the page)")
    a.set_title("TOP VIEW, looking down; downhill is up the page", fontsize=10)
    steps = [("1. walls drop through the\n   slots, INSIDE of the tabs", T + CL, False), ("2. press them OUT\n   onto the tabs", 0, False),
             ("3. rail slides in\n   between: locked", 0, True)]
    for k, (lab, dx, rail) in enumerate(steps):
        ox = k * 62
        if rail:
            d.add_patch(plt.Rectangle((ox - 10, -20), 20, 20, fc="#ddd", ec="k")); d.add_patch(plt.Rectangle((ox - 3.1, -6), 6.2, 6, fc="w"))
        for sg in (1, -1):
            d.add_patch(plt.Rectangle((ox + sg * (10 + T), ZC - T / 2), sg * 8, T, fc="burlywood", ec="saddlebrown"))
            d.add_patch(plt.Rectangle((ox + sg * 10, ZC - T / 2), sg * T, T, fc="burlywood", ec="saddlebrown"))
            xin = ox + sg * (10 - dx)
            d.add_patch(plt.Rectangle(((xin if sg > 0 else xin - T), -20), T, 40, fc="peru", ec="k", alpha=.85))
        d.add_patch(plt.Rectangle((ox - (10 - T - CL), ZC - T / 2), 2 * (10 - T - CL), T, fc="burlywood", ec="saddlebrown"))
        d.text(ox - 20, 23, lab, fontsize=7.5, va="bottom")
    d.set_xlim(-24, 146); d.set_ylim(-24, 36); d.set_aspect("equal"); d.axis("off")
    d.set_title("ASSEMBLY (section across, through a tab)", fontsize=9)
    c.add_patch(plt.Rectangle((-10, -20), 20, 20, fc="#ddd", ec="k")); c.add_patch(plt.Rectangle((-3.1, -6), 6.2, 6, fc="w"))
    c.add_patch(plt.Rectangle((XL - 17, -20 - T), 27 - XL + 17 - 17, T, fc="tan", ec="sienna"))
    c.add_patch(plt.Rectangle((XL - 4.5, -20 - T), 9, T, fc="w", ec="sienna"))
    for x in (10, -10 - T):
        c.add_patch(plt.Rectangle((x, -20), T, 40, fc="peru", ec="k"))
    for x0, x1 in ((XL - BR - 8, -10 - T), (-10 - T, -10), (-10 + T + CL, 10 - T - CL), (10, 10 + T), (10 + T, 10 + T + 8)):
        c.add_patch(plt.Rectangle((x0, ZC - T / 2), x1 - x0, T, fc="burlywood", ec="saddlebrown"))
    c.add_patch(plt.Circle((XL - 2, -20 + math.sqrt(BR ** 2 - 4.5 ** 2)), BR, fc="green", alpha=.45))
    c.set_xlim(XL - 20, 24); c.set_ylim(-26, 22); c.set_aspect("equal"); c.set_title("SECTION at the walls (ball in the cone)", fontsize=9)
    s.add_patch(plt.Rectangle((0, -20), yp1 + 8, 20, fc="#ddd", ec="k")); s.text(yp1 - 15, -12, "rail", fontsize=8)
    s.add_patch(plt.Rectangle((yp0, ZC - T / 2), yp1 - yp0, T, fc="burlywood", ec="saddlebrown")); s.text(yp1 - 35, ZC + 3, "top plate", fontsize=8)
    s.add_patch(plt.Rectangle((YEND - 18, -20 - T), y_c0 + 15 - YEND + 18, T, fc="tan", ec="sienna", alpha=.8)); s.text(y_c0 - 25, -30, "bottom plate", fontsize=8)
    s.add_patch(plt.Rectangle((-20, -34), 20, 62, fc="#444", alpha=.5))
    s.add_patch(plt.Circle((Y_HOLE, ZC), BR, fc="steelblue", alpha=.5))
    s.add_patch(plt.Circle((Y_HOLE, -20 + math.sqrt(BR ** 2 - 9)), BR, fc="green", alpha=.35)); s.add_patch(plt.Circle((YEND, -26), BR, fc="green", alpha=.6))
    s.annotate("", (Y_HOLE, -20 + 9.04 + BR - 1), (Y_HOLE, ZC - BR), arrowprops=dict(arrowstyle="->", lw=1.5))
    s.annotate("", (YEND + 14, -20 + 6.5), (Y_HOLE - 14, -20 + 9.04), arrowprops=dict(arrowstyle="->", lw=1, color="g"))
    s.set_xlim(-32, yp1 + 10); s.set_ylim(-36, 24); s.set_aspect("equal")
    s.set_title("SIDE (along the rail; the 2020 on the left; the lane is beside the rail)", fontsize=9)
    out = Path(__file__).resolve().parent.parent / "views" / "feed_drop_v5.png"
    plt.savefig(out, dpi=100)
    t = math.degrees(math.acos(1 - 10 / RC))
    print(f"{out.name}: lane x {XL:.2f}; elbow r {RC:.2f}, y {Y0:.1f} -> hole at {Y_HOLE:g}; cone 6 at {y_c0:g} -> {W_TIP:g} at "
          f"({y_meet[0]:.1f}, {y_meet[1]:.1f}), circle centre ({X_END:g}, {YEND:g}); walls {yw0:g}..{yw1:.1f}; ball centre crosses the rail edge {t:.1f} deg into the elbow")


if __name__ == "__main__":
    main()
