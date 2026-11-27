#!/usr/bin/env python3
"""Drive diagram for clock_train.scad: a half side-section (above the rod) drawn from the same numbers, every rigid body in
one colour, every bolt / pin / standoff / bearing shown, with what drives what. Plus the 3D renders with a legend.
    python3 marbles/clock/clock_train_drive.py   # -> marbles/views/clock_train_drive.png, clock_train_3d.png"""
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import matplotlib.image as mi  # noqa: E402

import clock_pins as cp  # noqa: E402

T, A, G, MID, CB, FG = cp.T, cp.A, cp.G, cp.M, cp.CB, cp.FG
GAP, CAR_IN, UP_R, CAR_OUT = 24, 44.5, 50, cp.A + 14
SP_UP, SP_HAND, SP_R = 20, 12, cp.SP_D / 2
COL = dict(fix="0.80", sec="darkorange", mpl="gold", minute="firebrick", hpl="hotpink", hour="royalblue", hw="0.25", pin="0.15")
HERE = Path(__file__).resolve().parent
VIEWS = HERE.parent / "views"


def box(ax, z0, dz, r0, r1, col, ec="k", lw=.5):
    ax.add_patch(plt.Rectangle((z0, r0), dz, r1 - r0, fc=col, ec=ec, lw=lw))


def suns(name):
    S = cp.STAGES[name]
    a, b = cp.stage_numbers(S)
    return S, a, b


def layout():
    """z positions (along the rod) of one stage, back carrier's back face = 0 (same as clock_train.scad, explode 0)"""
    z = dict(bc=0.0)
    z["fa"] = T + CB
    z["fb"] = z["fa"] + 2 * T + G + MID
    z["fc"] = z["fb"] + 2 * T + G + FG
    z["pa"] = z["fa"] + T + (G - 2 * T) / 2
    z["pb"] = z["fb"] + T + (G - 2 * T) / 2
    z["depth"] = z["fc"] + T
    return z


def pin_wheel(ax, z0, sn, col, bore_r, hub_in, hub_out, bolt_r, rings):
    zf = z0 + T + G
    for zz in (z0, zf):
        box(ax, zz, T, bore_r, sn["rim"], col)
    if rings:
        box(ax, z0 + T, G, hub_in, hub_out, col)                                   # cut rings = the 608 housing
    else:
        box(ax, z0 + T, G, bolt_r - SP_R, bolt_r + SP_R, "silver")                 # bought spacer
    box(ax, z0 - 2, zf + T + 4.4 - z0, bolt_r - 1.5, bolt_r + 1.5, COL["hw"])      # M3 bolt
    R = sn["R"]
    box(ax, z0 - cp.PIN, 2 * T + G + 2 * cp.PIN, R - cp.PIN / 2, R + cp.PIN / 2, COL["pin"], ec="none")
    for zz in (z0 - cp.PIN, zf + T):
        box(ax, zz, cp.PIN, R - 4, R + cp.PIN / 2, COL["pin"], ec="none")


def stage(ax, z0, name, ccar, cpl, cout):
    S, a, b = suns(name)
    z = {k: v + z0 for k, v in layout().items()}
    fc_in = max(x["rim"] for n in cp.STAGES for x in suns(n)[1:]) + 1
    box(ax, z["bc"], T, CAR_IN, CAR_OUT, ccar); box(ax, z["fc"], T, fc_in, CAR_OUT, ccar)
    box(ax, z["fa"] - 15, 15, 20, 35, COL["fix"]); box(ax, z["fa"] - 14.5, 14, 4, 20, COL["fix"])    # beam + SK8 (schematic)
    pin_wheel(ax, z["fa"], a, COL["fix"], 4.2, 0, 0, 27.5, False)
    pin_wheel(ax, z["fb"], b, cout, 8, 11.1, 21, 16, True)
    box(ax, z["fb"] + T + 0.4, 7, 4, 11, "silver")                                                   # 608

    tipA, tipB = TIPS[name]
    for zp, tip in ((z["pa"], tipA), (z["pb"], tipB)):
        box(ax, zp, 2 * T, A - tip, A + tip, cpl)
    for sgn in (-1, 1):                                                                             # 2 tie bolts on spacers
        rt = A + sgn * cp.TIE_D
        box(ax, z["pa"] + 2 * T, z["pb"] - z["pa"] - 2 * T, rt - SP_R, rt + SP_R, "silver")
        box(ax, z["pa"] - 2, z["pb"] + 2 * T - z["pa"] + 4.4, rt - 1.5, rt + 1.5, COL["hw"])
        box(ax, z["pb"] + 2 * T, 2.4, rt - 3.2, rt + 3.2, COL["hw"])
    box(ax, z["bc"] - 2, z["fc"] + T + 4.4 - z["bc"], A - 1.5, A + 1.5, COL["hw"])                  # centre axle bolt (fixed)
    for zz in (z["bc"] + T, z["fc"] - 2.4, z["fc"] + T):
        box(ax, zz, 2.4, A - 3.2, A + 3.2, COL["hw"])
    # clearances (assert, then report)
    chk = {"planet tie spacers inside the middle discs' rims": A - cp.TIE_D - SP_R - max(a["rim"], b["rim"]),
           "planet tips vs fixed sun spacers (r 27.5 + 3.5)": A - tipA - 31,
           "hour hand vs front carrier nuts": SP_HAND - (FG + T + 2.4 + 2),
           "front carrier opening vs sun B rim": fc_in - b["rim"]}
    for k, v in chk.items():
        assert v > 0, (name, k, v)
    return z, a, b, chk


def drive_diagram():
    global TIPS
    TIPS = {n: tuple(cp.planet_profile(S[p], sn["Z"], sn["p"])[1] for p, sn in (("PA", suns(n)[1]), ("PB", suns(n)[2])))
            for n, S in cp.STAGES.items()}
    fig, ax = plt.subplots(figsize=(18, 11))
    zw = -GAP - 2
    m, ma, mb, chk_m = stage(ax, 0, "minute", COL["sec"], COL["mpl"], COL["minute"])
    z_h = m["fb"] + 2 * T + G + SP_UP
    h, ha, hb, chk_h = stage(ax, z_h, "hour", COL["minute"], COL["hpl"], COL["hour"])
    box(ax, zw, T, 92, 122, COL["sec"]); box(ax, zw + T, 2, 112, 134, COL["sec"])
    box(ax, zw + T, -zw - T, 80 - 2.5, 80 + 2.5, COL["sec"])                                         # wheel -> carrier standoff
    z_mfd = m["fb"] + T + G
    box(ax, z_mfd + T, z_h - z_mfd - T, UP_R - 2.5, UP_R + 2.5, COL["minute"])                       # minute sun -> hour carrier
    box(ax, z_h - 1.6, 1.6, UP_R - 4, 142, COL["minute"])                                            # minute hand
    z_hfd = h["fb"] + T + G + T
    z_hh = z_hfd + SP_HAND
    box(ax, z_hfd + 2.4, SP_HAND - 2.4, 16 - SP_R, 16 + SP_R, "silver")                              # spacers on the sun's bolts
    box(ax, z_hh, T, 4.2, 76, COL["hour"])                                                           # hour hand (ply)
    box(ax, z_hh + T + 3, 8, 4, 8, COL["hw"])                                                        # collar
    box(ax, zw - 12, z_hh + T + 25 - zw, -4, 4, COL["fix"])                                          # rod
    L = lambda txt, xy, xyt, c="k": ax.annotate(txt, xy, xyt, fontsize=8.5, color=c, arrowprops=dict(arrowstyle="->", lw=1, color=c),
                                                bbox=dict(fc="w", ec=c, lw=.8, pad=2))
    L("ESCAPE WHEEL front ring\n+ seconds pointer (1 rev/min)", (zw + 1, 125), (zw - 40, 138), COL["sec"])
    L("6 standoffs: wheel drives\nthe MINUTE CARRIER", (zw + 12, 80), (zw - 40, 100), COL["sec"])
    L("minute carrier: back + front annulus,\ntied by 3 M3 bolts + 40 spacers between the planets,\nand by the 3 planet axle bolts", (1, 50), (zw - 40, 52), COL["sec"])
    L(f"MINUTE PLANET (16 teeth): gear A (2 layers) + gear B (2 layers), tied by 2 M3\nthrough bolts + nuts on 15 spacers, spinning on the centre M3 axle bolt.\n"
      f"A rolls round the FIXED {ma['Z']}-pin sun, B pushes the {mb['Z']}-pin MINUTE SUN", (m["pa"] + 3, A + 12), (-30, 108), "darkgoldenrod")
    L(f"FIXED minute sun: {ma['Z']} wire pins between 2 discs (8 spacers on its 4 M3 bolts),\nends bent inward; bolted to a 1515 beam, SK8 on the beam\n"
      f"clamps the rod (beam + SK8 drawn schematically: they sit below the rod)", (m["fa"] + 1, 30), (zw - 40, 14), "0.35")
    L(f"MINUTE SUN: {mb['Z']} pins between 2 discs,\n608 in 3 cut housing rings (1 rev/h)", (m["fb"] + 1, 45), (m["fb"] - 20, -34), COL["minute"])
    L("5 standoffs (20): minute sun\ndrives the HOUR CARRIER", (z_mfd + 6, UP_R), (z_mfd + 14, -30), COL["minute"])
    L("MINUTE HAND, on the hour carrier", (z_h - 1, 135), (z_h - 50, 145), COL["minute"])
    L(f"HOUR PLANET: A rolls round the FIXED {ha['Z']}-pin sun,\nB pushes the {hb['Z']}-pin HOUR SUN", (h["pb"] + 3, A + 12), (z_h + 10, 108), "mediumvioletred")
    L(f"FIXED hour sun ({ha['Z']} pins)\n+ its beam + SK8", (h["fa"] + 1, 30), (z_h + 50, 36), "0.35")
    L("HOUR SUN (60 pins) on a 608,\n12 spacers + HOUR HAND\n(1 rev / 12 h), clear of the\nfront carrier and its nuts", (z_hh + 1, 66), (z_hfd + 16, 72), COL["hour"])
    L("wire pin (engages the teeth),\nends bent over on both faces", (m["fa"] - 1, ma["R"] - 2), (m["fa"] - 2, 90), COL["pin"])
    L("collar", (z_hh + 7, 6), (z_hh + 16, -10), "k")
    ax.set_xlim(zw - 44, z_hfd + 60); ax.set_ylim(-40, 152); ax.set_aspect("equal")
    ax.set_xlabel("along the rod, mm (back -> front, viewer on the right)"); ax.set_ylabel("radius from the rod, mm")
    ax.set_title("WHAT DRIVES WHAT, pin-wheel version: half side-section above the rod. One colour = one rigid body. Grey = fixed, black = wire.\n"
                 "orange (1 rev/min) -> yellow planets -> red (1 rev/h) -> pink planets -> blue (1 rev/12 h)", fontsize=11)
    out = VIEWS / "clock_train_drive.png"
    plt.tight_layout(); plt.savefig(out, dpi=100)
    for n, c in (("minute", chk_m), ("hour", chk_h)):
        print(n, "; ".join(f"{k} {v:.2f}" for k, v in c.items()))
    print(f"stage depth {m['depth']:.2f}; hour carrier at z {z_h:.2f}; hour hand front at z {z_hh + 1.6:.2f}; "
          f"escape wheel ring at z {zw}")
    return out


def renders():
    fig = plt.figure(figsize=(20, 15))
    for i, (n, t) in enumerate((("ct_iso", "assembled, from the front"),
                                ("ct_planet", "a minute planet (exploded 5 mm): gear A in the fixed sun's pins, hub, gear B in the minute sun's pins"))):
        a = fig.add_axes([0.0 + (i % 2) * 0.5, 0.52 - (i // 2) * 0.5, 0.5, 0.46]); a.imshow(mi.imread(VIEWS / f"{n}.png")); a.axis("off"); a.set_title(t, fontsize=14)
    a = fig.add_axes([0.05, 0.04, 0.9, 0.42]); a.axis("off")
    for k, (c, txt) in enumerate(((COL["sec"], "ORANGE: escape wheel + 6 standoffs + minute carrier (back + front) (1 rev/min)"),
                                  (COL["mpl"], "YELLOW: the 3 minute planets: gear A + gear B (2 layers each) tied by 2 M3 through bolts on spacers, on an M3 axle"),
                                  (COL["minute"], "RED: minute sun (60 pins) + 5 standoffs + hour carrier (back + front) + minute hand (1 rev/h)"),
                                  (COL["hpl"], "PINK: the 3 hour planets (gear A in the fixed 55-pin sun, gear B in the hour sun)"),
                                  (COL["hour"], "BLUE: hour sun (60 pins) + hour hand (on spacers) (1 rev / 12 h)"),
                                  (COL["fix"], "GREY: fixed: rod, fixed pin suns (59 and 55 pins), 1515 beams, SK8s.   BLACK: 2.05 wire pins, bent over at both ends"))):
        a.add_patch(plt.Rectangle((0, 0.9 - k * 0.15), 0.06, 0.1, fc=c, ec="k", transform=a.transAxes))
        a.text(0.08, 0.95 - k * 0.15, txt, fontsize=13, va="center", transform=a.transAxes)
    out = VIEWS / "clock_train_3d.png"
    plt.savefig(out, dpi=60)
    return out


if __name__ == "__main__":
    print(drive_diagram().name, renders().name)
