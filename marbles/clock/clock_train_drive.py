#!/usr/bin/env python3
"""Drive diagram for clock_train.scad: a half side-section (above the rod) drawn from the same numbers, every rigid body in
one colour, every bolt / pin / standoff / bearing shown, with what drives what. Plus the 3D renders with a legend.
    python3 marbles/clock/clock_train_drive.py   # -> marbles/views/clock_train_drive.png, clock_train_3d.png"""
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import matplotlib.image as mi  # noqa: E402

T = 2.63; GAP = 24; CAR_IN = 44.5; UP_R = 50; HUB = 21
M = dict(MOD=2.0, ZA=59, PA=12, ZB=60, PB=12, N=3)
H = dict(MOD=2.0, ZA=55, PA=10, ZB=60, PB=10, N=5)
COL = dict(fix="0.80", sec="darkorange", mpl="gold", minute="firebrick", hpl="hotpink", hour="royalblue", hw="0.25")
HERE = Path(__file__).resolve().parent
VIEWS = HERE.parent / "views"


def geo(S):
    A = S["MOD"] * (S["ZA"] + S["PA"]) / 2
    mB = 2 * A / (S["ZB"] + S["PB"])
    return A, mB


def box(ax, z0, dz, r0, r1, col, lab=None, lx=0, ly=0, fs=7.5, ec="k"):
    ax.add_patch(plt.Rectangle((z0, r0), dz, r1 - r0, fc=col, ec=ec, lw=.6))
    if lab:
        ax.annotate(lab, (z0 + dz / 2, (r0 + r1) / 2), (z0 + dz / 2 + lx, (r0 + r1) / 2 + ly), fontsize=fs,
                    arrowprops=dict(arrowstyle="-", lw=.6, color="0.3"), bbox=dict(fc="w", ec="0.7", lw=.5, pad=1.5))


def stage(ax, z0, S, ccar, cpl, cout, name):
    A, mB = geo(S)
    pr_a = S["MOD"] * S["PA"] / 2 + S["MOD"]; pr_b = mB * S["PB"] / 2 + mB
    sun_a = S["MOD"] * S["ZA"] / 2 + S["MOD"]; sun_b = mB * S["ZB"] / 2 + mB
    zA, zB = z0 + T, z0 + 2 * T
    box(ax, z0, T, CAR_IN, A + S["MOD"] * S["PA"] / 2 + 4, ccar)                          # carrier
    box(ax, zA - 15, 15, 20, 35, COL["fix"]); box(ax, zA - 14.5, 14, 4, 20, COL["fix"])   # beam + SK8 behind the fixed sun
    box(ax, zA, T, 4.2, sun_a, COL["fix"])                                                # fixed sun
    box(ax, zB, T, 11.1, sun_b, cout); box(ax, zB + T, 2 * T, 11.1, HUB, cout)            # output sun + hub rings
    box(ax, zB + 0.3, 7, 4, 11, "silver")                                                 # 608
    box(ax, zA, T, A - pr_a, A + pr_a, cpl); box(ax, zB, T, A - pr_b, A + pr_b, cpl)      # planet layers A, B
    box(ax, z0 - 2, 3 * T + 6, A - 1.5, A + 1.5, ccar, ec="k")                            # axle bolt (clamped to the carrier)
    for s in (-1, 1):
        box(ax, zA - 0.4, 2 * T + 0.8, A + s * S["MOD"] * S["PA"] / 5 - 1, A + s * S["MOD"] * S["PA"] / 5 + 1, "k")   # wire pins
    return dict(A=A, sun_a=sun_a, sun_b=sun_b, pr_a=pr_a, zA=zA, zB=zB, front=zB + 3 * T)


def drive_diagram():
    fig, ax = plt.subplots(figsize=(17, 11))
    zw = -GAP - 2
    box(ax, -60, 140, -4, 4, COL["fix"]); ax.text(-58, -11, "FIXED smooth 8 mm rod (escape-wheel axle)", fontsize=8)
    box(ax, zw, T, 92, 122, COL["sec"]); box(ax, zw + T, 2, 112, 134, COL["sec"])
    m = stage(ax, 0, M, COL["sec"], COL["mpl"], COL["minute"], "minute")
    box(ax, zw + T, -zw - T, m["A"] + 13 - 2.5, m["A"] + 13 + 2.5, COL["sec"])            # wheel -> carrier standoff
    z_h = m["front"] + GAP
    box(ax, 3 * T, z_h - 3 * T, UP_R - 2.5, UP_R + 2.5, COL["minute"])                     # minute sun -> hour carrier standoff
    h = stage(ax, z_h, H, COL["minute"], COL["hpl"], COL["hour"], "hour")
    box(ax, z_h - 1.6, 1.6, UP_R - 4, 142, COL["minute"])                                  # minute hand
    box(ax, h["front"], 1.6, 0, 76, COL["hour"])                                           # hour hand
    box(ax, h["front"] + 3, 8, 4, 8, COL["hw"])                                            # collar
    # labels
    L = lambda txt, xy, xyt, c="k": ax.annotate(txt, xy, xyt, fontsize=8.5, color=c, arrowprops=dict(arrowstyle="->", lw=1, color=c),
                                                bbox=dict(fc="w", ec=c, lw=.8, pad=2))
    L("ESCAPE WHEEL front ring\n+ seconds pointer (1 rev/min)", (zw + 1, 125), (-62, 136), COL["sec"])
    L("6 standoffs: wheel drives\nthe MINUTE CARRIER", (zw + 12, m["A"] + 13), (-62, 98), COL["sec"])
    L("minute carrier (annulus)", (1, 78), (-62, 70), COL["sec"])
    L("3 M3 axle bolts, nutted to the carrier:\nthe planets spin on them", (T * 3 + 3, m["A"]), (-62, 50), COL["sec"])
    L("MINUTE PLANET (2 layers tied by 2 wire pins):\nlayer A rolls round the FIXED sun 59,\nlayer B pushes the MINUTE SUN 60", (2 * T, m["A"] + 8), (-10, 104), "darkgoldenrod")
    L("FIXED minute sun 59, bolted to a 1515 beam;\nSK8 on the beam clamps the rod", (T * 1.5, 30), (-62, 22), "0.35")
    L("MINUTE SUN 60 + 2 hub rings on a 608\n(1 rev/hour)", (2.5 * T, 50), (20, 70), COL["minute"])
    L("5 standoffs: minute sun drives\nthe HOUR CARRIER", (25, UP_R), (24, 37), COL["minute"])
    L("MINUTE HAND, on the hour carrier", (z_h - 1, 130), (z_h - 46, 140), COL["minute"])
    L("HOUR PLANET (2 layers, 2 pins):\nA rolls round the FIXED sun 55,\nB pushes the HOUR SUN 60", (z_h + 2 * T, h["A"] + 6), (z_h + 18, 100), "mediumvioletred")
    L("FIXED hour sun 55\n+ its beam + SK8", (z_h + T * 1.5, 28), (z_h + 18, 22), "0.35")
    L("HOUR SUN 60 on a 608\n+ HOUR HAND (1 rev / 12 h)", (h["front"] + 1, 60), (h["front"] + 14, 74), COL["hour"])
    L("collar", (h["front"] + 7, 6), (h["front"] + 16, -10), "k")
    ax.set_xlim(-64, 125); ax.set_ylim(-16, 150); ax.set_aspect("equal")
    ax.set_xlabel("along the rod, mm (back -> front, viewer on the right)"); ax.set_ylabel("radius from the rod, mm")
    ax.set_title("WHAT DRIVES WHAT: half side-section above the rod. One colour = one rigid body. Grey = fixed.\n"
                 "orange (1 rev/min) -> yellow planets -> red (1 rev/h) -> pink planets -> blue (1 rev/12 h)", fontsize=11)
    out = VIEWS / "clock_train_drive.png"
    plt.tight_layout(); plt.savefig(out, dpi=100)
    return out


def renders():
    fig = plt.figure(figsize=(20, 15))
    for i, (n, t) in enumerate((("ct_iso", "exploded, from the front"), ("ct_back", "exploded, from behind: the SK8 + 1515 mounts"),
                                ("ct_planet", "one minute planet: 2 layers, 2 wire pins, M3 axle bolt"))):
        a = fig.add_axes([0.0 + (i % 2) * 0.5, 0.52 - (i // 2) * 0.5, 0.5, 0.46]); a.imshow(mi.imread(VIEWS / f"{n}.png")); a.axis("off"); a.set_title(t, fontsize=14)
    a = fig.add_axes([0.52, 0.04, 0.46, 0.42]); a.axis("off")
    for k, (c, txt) in enumerate(((COL["sec"], "ORANGE: escape wheel + standoffs + minute carrier + its 3 planet axle bolts (1 rev/min)"),
                                  (COL["mpl"], "YELLOW: the 3 minute planets (spin on their bolts)"),
                                  (COL["minute"], "RED: minute sun 60 + 5 standoffs + hour carrier + its 5 axle bolts + minute hand (1 rev/h)"),
                                  (COL["hpl"], "PINK: the 5 hour planets"),
                                  (COL["hour"], "BLUE: hour sun 60 + hour hand (1 rev / 12 h)"),
                                  (COL["fix"], "GREY: fixed: rod, fixed suns 59 + 55, 1515 beams, SK8s"))):
        a.add_patch(plt.Rectangle((0, 0.9 - k * 0.15), 0.06, 0.1, fc=c, ec="k", transform=a.transAxes))
        a.text(0.08, 0.95 - k * 0.15, txt, fontsize=13, va="center", transform=a.transAxes)
    out = VIEWS / "clock_train_3d.png"
    plt.savefig(out, dpi=60)
    return out


if __name__ == "__main__":
    print(drive_diagram().name, renders().name)
