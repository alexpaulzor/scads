#!/usr/bin/env python3
"""Quick visual sketch of the ball-clock face (not a design): front view + layer order.

48" 2020 frame; face markings on a plate at the back; then, coming forward, the seconds disc
(12 groups of 5, 2-ball gaps), the minutes disc (60 touching), the hours disc (12 spaced, inset
from minutes by the same step as minutes from seconds); the 48" pendulum swings in front from
the top centre. Each disc carries its balls from 12 o'clock clockwise to its "hand": the first
ball loaded, emphasised, with an arrowhead sticking out of the disc's rim.

    python3 marbles/clock/face_sketch.py [--time 10:10:37] [-o face_sketch.png]
"""
import argparse
import math

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Circle, Polygon, Rectangle  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--time", default="10:10:37")
ap.add_argument("-o", "--out", default="face_sketch.png")
a = ap.parse_args()
hh, mm, ss = (int(v) for v in a.time.split(":"))

D = 19.05                       # 3/4" ball
R_S = 12 * (5 + 2) * D / (2 * math.pi)          # seconds: 12 groups of 5 + 2-ball gaps
R_M = D / (2 * math.sin(math.pi / 60))          # minutes: 60 touching
R_H = R_M - (R_S - R_M)                          # hours: same inset again
RIM = D / 2 + 12                                 # disc edge beyond the ball centres
FRAME = 48 * 25.4
EXT = 20.0

STEP = D / R_S                   # radians between neighbours in a group
GAP = 3 * D / R_S                # ... across a 2-ball gap


def seconds_angles():
    """60 hole angles (rad, clockwise from 12) in 12 groups of 5"""
    out, t = [], 0.0
    for g in range(12):
        for k in range(5):
            out.append(t)
            t += STEP if k < 4 else GAP
    return out


def xy(r, ang):                  # ang clockwise from 12 o'clock, radians
    return r * math.sin(ang), r * math.cos(ang)


fig = plt.figure(figsize=(15, 10))
ax = fig.add_axes([0.02, 0.04, 0.62, 0.92])
side = fig.add_axes([0.69, 0.30, 0.29, 0.52])

# ---- frame + face markings (back)
H = FRAME / 2
ax.add_patch(Rectangle((-H, -H), FRAME, FRAME, fc="none", ec="0.45", lw=10, zorder=1))
ax.add_patch(Circle((0, 0), R_S + RIM + 75, fc="#f3ead8", ec="0.6", lw=1, zorder=1))
for i in range(60):
    ang = math.radians(6 * i)
    r0 = R_S + RIM + 8
    r1 = r0 + (22 if i % 5 == 0 else 10)
    ax.plot(*zip(xy(r0, ang), xy(r1, ang)), color="0.25", lw=2.2 if i % 5 == 0 else 0.8, zorder=2)
for h in range(1, 13):
    x, y = xy(R_S + RIM + 52, math.radians(30 * h))
    ax.text(x, y, str(h), ha="center", va="center", fontsize=17, color="0.2", zorder=2, family="serif")


def disc(r_balls, angles, n_filled, color, label, z):
    """disc rotated so its first ball (hole 0) sits at the hand; balls fill from 12 clockwise to it"""
    rot = angles[n_filled - 1] if n_filled else 0.0          # disc turned this far clockwise
    hand = rot
    ax.add_patch(Circle((0, 0), r_balls + RIM, fc=color, ec="0.3", lw=1, zorder=z))
    for k, th in enumerate(angles):
        x, y = xy(r_balls, th + rot - angles[n_filled - 1] if n_filled else th)
    # holes: hole k is k steps behind hole 0 (it reached 12 later)
    for k in range(len(angles)):
        th = hand - angles[k]
        x, y = xy(r_balls, th)
        filled = k < n_filled
        ax.add_patch(Circle((x, y), D / 2, fc="#3b6ea5" if filled else "none",
                            ec="0.35" if not filled else "#22446b", lw=0.6, zorder=z + 1, alpha=1 if filled else 0.5))
    if n_filled:
        x, y = xy(r_balls, hand)
        ax.add_patch(Circle((x, y), D / 2 + 3.5, fc="#f2b632", ec="#7a4f00", lw=1.5, zorder=z + 2))
        ax.add_patch(Circle((x, y), D / 2 - 2, fc="#3b6ea5", ec="none", zorder=z + 3))
        tip, base = r_balls + RIM + 30, r_balls + RIM - 2
        w = math.radians(5.5) * (R_S / r_balls)
        pts = [xy(tip, hand), xy(base, hand - w), xy(base, hand + w)]
        ax.add_patch(Polygon(pts, closed=True, fc="#f2b632", ec="#7a4f00", lw=1.5, zorder=z + 2))
    x, y = xy(r_balls + RIM - 6, math.radians(180))
    ax.text(x, y + 4, label, ha="center", va="bottom", fontsize=8, color="0.15", zorder=z + 4)


sec_ang = seconds_angles()
disc(R_S, sec_ang, ss, "#e2c79a", f"seconds disc  (balls r {R_S:.1f}, 12 x 5 + 2-ball gaps)", 3)
disc(R_M, [i * 2 * math.pi / 60 for i in range(60)], mm, "#c9a06b", f"minutes disc  (r {R_M:.1f}, 60 touching)", 10)
disc(R_H, [i * 2 * math.pi / 12 for i in range(12)], hh % 12, "#a8784a", f"hours disc  (r {R_H:.1f})", 20)
ax.add_patch(Circle((0, 0), 14, fc="0.3", zorder=30))

# ---- pendulum in front: 48" 2020 from the top-centre pivot, shown swung 7 deg
piv = (0, H - EXT / 2)
sw = math.radians(7)
L = FRAME - 40
ux, uy = math.sin(sw), -math.cos(sw)
px, py = -uy * EXT / 2, ux * EXT / 2
bar = [(piv[0] + px, piv[1] + py), (piv[0] - px, piv[1] - py),
       (piv[0] - px + ux * L, piv[1] - py + uy * L), (piv[0] + px + ux * L, piv[1] + py + uy * L)]
ax.add_patch(Polygon(bar, closed=True, fc="#9fb3c8", ec="#4a5b6d", lw=1, alpha=0.8, zorder=40))
ax.add_patch(Circle((piv[0] + ux * (L - 60), piv[1] + uy * (L - 60)), 55, fc="#7d8fa3", ec="#4a5b6d", alpha=0.85, zorder=41))
ax.add_patch(Circle(piv, 12, fc="0.2", zorder=42))
ax.text(piv[0] + 30, piv[1] - 25, "pendulum pivot\n(axle + bearing, top centre)", fontsize=8, zorder=43)

ax.set_xlim(-H - 30, H + 30)
ax.set_ylim(-H - 30, H + 30)
ax.set_aspect("equal")
ax.axis("off")
ax.set_title(f'Ball clock face sketch, showing {hh}:{mm:02d}:{ss:02d}   (48" = {FRAME:.0f} mm 2020 frame)', fontsize=13)

# ---- side view (layer order, schematic depths)
layers = [("frame (2020)", 0, 20, "0.55"), ("face plate", 20, 3, "#f3ead8"),
          ("seconds disc", 30, 26, "#e2c79a"), ("minutes disc", 64, 26, "#c9a06b"),
          ("hours disc", 98, 26, "#a8784a"), ("pendulum (2020)", 140, 20, "#9fb3c8")]
radius = {"frame (2020)": H, "face plate": R_S + RIM + 75, "seconds disc": R_S + RIM, "minutes disc": R_M + RIM,
          "hours disc": R_H + RIM, "pendulum (2020)": H}
for name, z0, t, c in layers:
    r = radius[name]
    if name.startswith("pendulum"):
        side.add_patch(Rectangle((z0, -H + 40), t, FRAME - 20, fc=c, ec="0.3"))
    elif name.startswith("frame"):
        for yy in (-H, H - 20):
            side.add_patch(Rectangle((z0, yy), t, 20, fc=c, ec="0.3"))
    else:
        side.add_patch(Rectangle((z0, -r), t, 2 * r, fc=c, ec="0.3"))
    side.text(z0 + t / 2, H + 40, name, rotation=60, fontsize=8, ha="left", va="bottom")
side.plot([-10, 180], [0, 0], color="0.4", ls="-.", lw=0.8)
side.text(182, 0, "common axis", fontsize=7, va="center")
side.set_xlim(-15, 230)
side.set_ylim(-H - 20, H + 230)
side.set_title("side view: back (wall) -> front\n(depths schematic, not designed)", fontsize=9)
side.set_xlabel("mm from the wall")
side.set_yticks([])

fig.text(0.69, 0.22,
         f"Ball rings (centres): seconds {R_S:.1f}, minutes {R_M:.1f}, hours {R_H:.1f}\n"
         f"(step seconds-minutes = minutes-hours = {R_S - R_M:.1f}; hours 12 balls {2 * R_H * math.sin(math.pi / 12):.1f} apart)\n"
         f"Disc outer radii: {R_S + RIM:.0f} / {R_M + RIM:.0f} / {R_H + RIM:.0f}  (seconds disc {2 * (R_S + RIM):.0f} across:\n"
         f"wider than the 400 laser bed, so cut in segments)\n"
         "Gold ball + arrowhead = the first ball on each disc = its hand.",
         fontsize=8.5, va="top")
fig.savefig(a.out, dpi=110)
print(f"wrote {a.out}")
