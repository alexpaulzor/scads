#!/usr/bin/env python3
"""Drawing for escapement_pin.py: front view (front ring see-through) + a section through the wheel axle."""
import sys
from pathlib import Path
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import escapement_pin as E  # noqa: E402
import matplotlib  # noqa: E402
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from shapely import affinity  # noqa: E402
from shapely.geometry import LineString  # noqa: E402
from shapely.ops import unary_union  # noqa: E402


def draw(ax, g, c, a=1.0, ls="-"):
    for p in getattr(g, "geoms", [g]):
        ax.fill(*p.exterior.xy, color=c, alpha=a)
        ax.plot(*p.exterior.xy, ls, color="k", lw=.6)
        for r in p.interiors:
            ax.fill(*r.xy, color="w")
            ax.plot(*r.xy, ls, color="k", lw=.6)


hub, ie, ix, (e, x) = E.anchor()
arms = unary_union([ie["beam"], ix["beam"], E.ANCHOR_INFO["tail"]])
eb, xb = ie["t"], ix["t"]
clamps = unary_union([ie["clamp"], ix["clamp"]])
pal = unary_union([e, x])
th, phi = E.AMP, 0.0
while E.pins(phi).intersection(affinity.rotate(pal, th, origin=(0, 0))).area < 1e-4 and phi < 12:
    phi += 0.05
phi -= 0.05
reach = E.beam_reach() - 3
fig = plt.figure(figsize=(18, 9.5))
ax = fig.add_subplot(1, 2, 1)
draw(ax, affinity.rotate(E.wheel(), -phi, origin=E.W), "burlywood", .5)
for i in range(8):
    a = i * 45 - phi
    b = LineString([E.polar(E.HUB_A, a, E.W), E.polar(reach, a, E.W)]).buffer(10, cap_style=2)
    draw(ax, b, "silver", .9 if i % 2 == 0 else .45, "-" if i % 2 == 0 else "--")
draw(ax, affinity.translate(affinity.rotate(E.hub_spacer(), -phi, origin=(0, 0)), *E.W), "peru", .9)
for k in range(E.N):
    ax.add_patch(plt.Circle(E.polar(E.R, 90 - k * E.PITCH - phi, E.W), E.PR, color="dimgray", zorder=4))
for t, c in ((-12, "tab:red"), (12, "tab:red")):
    draw(ax, affinity.rotate(unary_union([eb, xb]), t, origin=(0, 0)), c, .12, "--")
draw(ax, affinity.rotate(arms, th, origin=(0, 0)), "silver", .95)
draw(ax, affinity.rotate(hub, th, origin=(0, 0)), "peru", .8)
draw(ax, affinity.rotate(clamps, th, origin=(0, 0)), "burlywood", .95)
for bx in ie["m5"] + ix["m5"]:
    draw(ax, affinity.rotate(LineString([bx, bx]).buffer(2.5), th, origin=(0, 0)), "gold", 1)
draw(ax, affinity.rotate(eb, th, origin=(0, 0)), "#222", .9)
draw(ax, affinity.rotate(xb, th, origin=(0, 0)), "#222", .9)
ax.add_patch(plt.Circle((0, 0), 4, color="k"))
ax.set_aspect("equal")
ax.grid(alpha=.25)
ax.set_title(f"Front view, front ring see-through: rings {2 * E.RING_R:g} across, {E.N} M3 pins on r{E.R:g}; anchor (2020 arms, hub plates, "
             f"acrylic T pallets clamped in the arms' side slots)\nat +{th:g} deg (red ghosts: +-12 deg); tips stay {E.tip_margin():.0f} mm inside the rings; "
             f"wheel 2020 spokes {E.HUB_A:g}..{reach:.0f}", fontsize=9)
ax2 = fig.add_subplot(1, 2, 2)
T = 2.63
for y0 in (0, T + E.GAP):
    ax2.add_patch(plt.Rectangle((-E.RING_R, y0), 2 * E.RING_R, T, fc="burlywood", ec="k"))
for sx in (-1, 1):
    ax2.add_patch(plt.Rectangle((E.HUB_A if sx > 0 else -reach, T), reach - E.HUB_A, E.GAP, fc="silver", ec="k"))
    ax2.add_patch(plt.Rectangle((sx * E.R - E.PR, -6), E.PIN_D, 2 * T + E.GAP + 12, fc="dimgray"))
ax2.add_patch(plt.Rectangle((-E.HUB_A, T), 2 * E.HUB_A, 7 * 2.82, fc="peru", ec="k"))
for y0 in (-0.5, 2 * T + E.GAP - 6.5):
    ax2.add_patch(plt.Rectangle((-11, y0), 22, 7, fc="none", ec="b", lw=1.2))
ax2.add_patch(plt.Rectangle((-4, -15), 8, 2 * T + E.GAP + 30, fc="lightgray", ec="k"))
ax2.add_patch(plt.Rectangle((E.R - 12, T + E.GAP / 2 - 5.5), 20, 11, fc="#222", alpha=.8))
ax2.text(E.R + 14, T + E.GAP / 2, "pallet,\nin the gap", va="center", fontsize=8)
ax2.text(0, -24, "fixed 8 mm axle, a 608 in each ring (blue), octagon spacer x7 mdf3", ha="center", fontsize=8)
ax2.text(E.R, 2 * T + E.GAP + 9, "M3 screw pins", ha="center", fontsize=8)
ax2.text(-55, T + E.GAP / 2, "2020 spoke", ha="center", va="center", fontsize=8)
ax2.set_xlim(-155, 155)
ax2.set_ylim(-32, 50)
ax2.set_aspect("equal")
ax2.set_title("Section through the wheel axle (true scale)", fontsize=9)
plt.tight_layout()
plt.savefig(HERE / "escapement_pin.png", dpi=100)
