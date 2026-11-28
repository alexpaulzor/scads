#!/usr/bin/env python3
"""Drive diagram for clock_train.scad: a half side-section (above the rod) drawn from the same numbers, every rigid body in
one colour, every bolt / pin / standoff / bearing shown, with what drives what. Plus the 3D renders with a legend.
    python3 marbles/clock/clock_train_drive.py   # -> marbles/views/clock_train_drive.png, clock_train_3d.png"""
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import matplotlib.image as mi  # noqa: E402

import clock_lantern as cl  # noqa: E402

T, A, ZONE, L_SUN, N_PL = cl.T, cl.A, cl.ZONE, cl.L_SUN, cl.N_PL
CB, FC, GAP, CAR_IN, UP_R, CAR_OUT = 3.0, 3.0, 24, 44.5, 50, cl.A + 14
SP_UP, SP_HAND, SP_R, TIE_D = 20, 19, cl.SP_D / 2, cl.TIE_D
BEAM_REACH = 43.01            # 1515 beam corner from the rod: hypot(25, 20 + 15)
COL = dict(fix="0.80", sec="darkorange", mpl="gold", minute="firebrick", hpl="hotpink", hour="royalblue", hw="0.25", pin="0.15")
HERE = Path(__file__).resolve().parent
VIEWS = HERE.parent / "views"


def box(ax, z0, dz, r0, r1, col, ec="k", lw=.5):
    ax.add_patch(plt.Rectangle((z0, r0), dz, r1 - r0, fc=col, ec=ec, lw=lw))


def layout():
    """z (along the rod) inside one stage, back carrier's back face = 0, as clock_train.scad (explode 0)"""
    z0 = T + CB
    zl = [z0 + x for x in (0, T, 2 * T, 2 * T + ZONE, 3 * T + ZONE, 4 * T + ZONE)]
    z = dict(zl=zl, sunA=zl[2] + cl.SUN_CLR, sunB=zl[2] + cl.SUN_CLR + L_SUN * T + cl.SUN_GAP, fc=zl[5] + FC)
    z["depth"] = z["fc"] + T
    z["keeper_front"] = z["sunB"] + (L_SUN + 1) * T
    return z


def stage(ax, z0, name, ccar, cpl, cout, st):
    z = layout()
    zl = [v + z0 for v in z["zl"]]
    z = {k: (v + z0 if not isinstance(v, list) else zl) for k, v in z.items()}
    lr = max(d["r"] for d in st.values()) + cl.PIN_HOLE / 2 + cl.RIM
    fc_in = A - lr + 1
    box(ax, z0, T, CAR_IN, CAR_OUT, ccar); box(ax, z["fc"], T, fc_in, CAR_OUT, ccar)                 # carriers
    box(ax, z["sunA"] - 15, 15, 20, 35, COL["fix"]); box(ax, z["sunA"] - 14.5, 14, 4, 20, COL["fix"])  # beam + SK8 (schematic)
    box(ax, z["sunA"], L_SUN * T, 4.2, st["A"]["tip"], COL["fix"])                                  # fixed sun (3 layers)
    box(ax, z["sunB"], L_SUN * T, 11.1, st["B"]["tip"], cout)                                       # output sun
    for zz in (z["sunB"] - T, z["sunB"] + L_SUN * T):
        box(ax, zz, T, 8, 21, cout)                                                                  # keepers
    box(ax, z["sunB"] + 0.4, 7, 4, 11, "silver")                                                    # 608
    for i in (0, 1, 3, 4):                                                                           # lantern layers
        box(ax, zl[i], T, A - lr, A + lr, cpl)
    r = st["A"]["r"]
    for sgn in (-1, 1):                                                                              # pins (one set, both suns)
        box(ax, zl[1], zl[4] - zl[1], A + sgn * r - cl.PIN / 2, A + sgn * r + cl.PIN / 2, COL["pin"], ec="none")
    for sgn in (-1, 1):                                                                              # tie bolts + spacers
        rt = A + sgn * TIE_D
        box(ax, zl[0] - 2, zl[5] - zl[0] + 4.4, rt - 1.5, rt + 1.5, COL["hw"])
        for za, zb in ((zl[2], zl[3]),):
            box(ax, za, zb - za, rt - SP_R, rt + SP_R, "silver")
    box(ax, z0 - 2, z["fc"] + T + 4.6 - z0, A - 1.5, A + 1.5, COL["hw"])                            # axle bolt (fixed)
    for zz in (z0 + T, z["fc"] - 2.4, z["fc"] + T):
        box(ax, zz, 2.4, A - 3.2, A + 3.2, COL["hw"])
    chk = {"sun B to front lantern disc": zl[3] - (z["sunB"] + L_SUN * T), "fixed sun to output sun's back keeper": cl.SUN_GAP - T,
           "UP_R standoff vs hour beam": UP_R - 2.5 - BEAM_REACH, "UP_R standoff vs lantern discs": A - lr - UP_R - 2.5,
           "tie spacers inside the sun tips": min(st[k]["r"] - (st[k]["tip"] - st[k]["R"]) for k in st) - TIE_D - SP_R}
    for k, v in chk.items():
        assert v > 0, (name, k, v)
    return z, chk


def drive_diagram():
    st = {n: cl.stage(S) for n, S in cl.STAGES.items()}
    fig, ax = plt.subplots(figsize=(18, 11))
    zw = -GAP - 2
    m, chk_m = stage(ax, 0, "minute", COL["sec"], COL["mpl"], COL["minute"], st["minute"])
    z_h = m["keeper_front"] + SP_UP
    h, chk_h = stage(ax, z_h, "hour", COL["minute"], COL["hpl"], COL["hour"], st["hour"])
    box(ax, zw, T, 92, 122, COL["sec"]); box(ax, zw + T, 2, 112, 134, COL["sec"])
    box(ax, zw + T, -zw - T, 79.8 - 2.5, 79.8 + 2.5, COL["sec"])                                         # wheel -> carrier standoff
    box(ax, m["sunB"] + L_SUN * T, z_h - m["sunB"] - L_SUN * T, UP_R - 2.5, UP_R + 2.5, COL["minute"])  # minute sun -> hour carrier
    box(ax, z_h - 1.6, 1.6, UP_R - 4, 146, COL["minute"])                                            # minute hand
    z_hh = h["keeper_front"] + SP_HAND
    box(ax, h["keeper_front"] + 2.4, SP_HAND - 2.4, 16 - SP_R, 16 + SP_R, "silver")                  # spacers on the sun's bolts
    box(ax, z_hh, T, 4.2, 80, COL["hour"])                                                           # hour hand (ply)
    box(ax, z_hh + T + 3, 8, 4, 8, COL["hw"])                                                        # collar
    box(ax, zw - 12, z_hh + T + 25 - zw, -4, 4, COL["fix"])                                          # rod
    chk_hand = z_hh - (h["fc"] + T + 2.4 + 2.6)
    assert chk_hand > 0
    L = lambda txt, xy, xyt, c="k": ax.annotate(txt, xy, xyt, fontsize=8.5, color=c, arrowprops=dict(arrowstyle="->", lw=1, color=c),
                                                bbox=dict(fc="w", ec=c, lw=.8, pad=2))
    sm, sh = st["minute"], st["hour"]
    L("ESCAPE WHEEL front ring\n+ seconds pointer (1 rev/min)", (zw + 1, 125), (zw - 40, 140), COL["sec"])
    L("M5 rods on the wheel's 8 outer\nspoke bolts drive the MINUTE CARRIER", (zw + 12, 79.8), (zw - 40, 104), COL["sec"])
    L("minute carrier: back + front annulus, tied by\nM3 + spacers between the planets\nand by the planet axle bolts", (1, 50), (zw - 40, 52), COL["sec"])
    L(f"MINUTE PLANET (one lantern, counterweight opposite): {cl.P_PL} straight wire pins between 2 discs,\n"
      f"trapped by solid covers; 2 M3 tie bolts; spins on its M3 axle bolt.\n"
      f"The same pins roll round the FIXED {sm['A']['Z']}-tooth sun and push the {sm['B']['Z']}-tooth MINUTE SUN",
      (m["zl"][2] + 12, A + 18), (-38, 118), "darkgoldenrod")
    L(f"FIXED minute sun: {sm['A']['Z']} teeth, 3 ply layers, bolted to a 1515 beam,\nSK8 on the beam clamps the rod "
      f"(beam + SK8 drawn schematically: they sit below the rod)", (m["sunA"] + 1, 30), (zw - 40, 14), "0.35")
    L(f"MINUTE SUN: {sm['B']['Z']} teeth, the 608 sits in its 3 layers,\na keeper ring each side (1 rev/h)", (m["sunB"] + 1, 45), (m["sunB"] - 30, -34), COL["minute"])
    L(f"5 standoffs ({SP_UP}): minute sun\ndrives the HOUR CARRIER", (m["sunB"] + 14, UP_R), (m["sunB"] + 30, -30), COL["minute"])
    L("MINUTE HAND, on the hour carrier", (z_h - 1, 138), (z_h - 50, 148), COL["minute"])
    L(f"HOUR PLANET (one lantern + counterweight): its pins roll\nround the FIXED {sh['A']['Z']}-tooth sun and push the {sh['B']['Z']}-tooth HOUR SUN", (h["zl"][2] + 12, A + 18), (z_h + 6, 112), "mediumvioletred")
    L(f"FIXED hour sun ({sh['A']['Z']} teeth)\n+ its beam + SK8", (h["sunA"] + 1, 30), (z_h + 50, 36), "0.35")
    L(f"HOUR SUN (60 teeth) on a 608,\n{SP_HAND} spacers + HOUR HAND\n(1 rev / 12 h), clear of the\nfront carrier and its nuts", (z_hh + 1, 66), (z_hh + 12, 74), COL["hour"])
    L("straight wire pin: rides in\nBOTH suns' teeth, trapped\nbetween the two covers", (m["zl"][2] + 4, A - sm["A"]["r"]), (m["zl"][2] - 12, 92), COL["pin"])
    L("collar", (z_hh + T + 7, 6), (z_hh + T + 16, -10), "k")
    ax.set_xlim(zw - 44, z_hh + 62); ax.set_ylim(-40, 156); ax.set_aspect("equal")
    ax.set_xlabel("along the rod, mm (back -> front, viewer on the right)"); ax.set_ylabel("radius from the rod, mm")
    ax.set_title("WHAT DRIVES WHAT, lantern version: half side-section above the rod. One colour = one rigid body. Grey = fixed, black = wire.\n"
                 "orange (1 rev/min) -> yellow lantern -> red (1 rev/h) -> pink lantern -> blue (1 rev/12 h)", fontsize=11)
    out = VIEWS / "clock_train_drive.png"
    plt.tight_layout(); plt.savefig(out, dpi=100)
    for n, c in (("minute", chk_m), ("hour", chk_h)):
        print(n, "; ".join(f"{k} {v:.2f}" for k, v in c.items()))
    print(f"hour hand vs front carrier nuts {chk_hand:.2f}; stage depth {m['depth']:.2f}; hour carrier at z {z_h:.2f}; "
          f"hour hand front at z {z_hh + T:.2f}; escape wheel ring at z {zw}")
    return out


def renders():
    fig = plt.figure(figsize=(20, 15))
    for i, (n, t) in enumerate((("ct_iso", "assembled, from the front"),
                                ("ct_planet", "a minute planet (lantern), exploded 5 mm"))):
        a = fig.add_axes([0.0 + (i % 2) * 0.5, 0.52 - (i // 2) * 0.5, 0.5, 0.46]); a.imshow(mi.imread(VIEWS / f"{n}.png")); a.axis("off"); a.set_title(t, fontsize=14)
    a = fig.add_axes([0.05, 0.04, 0.9, 0.42]); a.axis("off")
    for k, (c, txt) in enumerate(((COL["sec"], "ORANGE: escape wheel + 6 standoffs + minute carrier (back + front) (1 rev/min)"),
                                  (COL["mpl"], "YELLOW: the minute planet: one lantern, 16 straight wire pins between 2 discs, on an M3 axle (counterweight opposite)"),
                                  (COL["minute"], "RED: minute sun (60 teeth) + 5 standoffs + hour carrier (back + front) + minute hand (1 rev/h)"),
                                  (COL["hpl"], "PINK: the hour planet (one lantern: its pins mesh the fixed 55-tooth sun and the hour sun)"),
                                  (COL["hour"], "BLUE: hour sun (60 teeth) + hour hand (on spacers) (1 rev / 12 h)"),
                                  (COL["fix"], "GREY: fixed: rod, fixed suns (59 and 55 teeth), 1515 beams, SK8s.   BLACK: straight 2.05 wire pins"))):
        a.add_patch(plt.Rectangle((0, 0.9 - k * 0.15), 0.06, 0.1, fc=c, ec="k", transform=a.transAxes))
        a.text(0.08, 0.95 - k * 0.15, txt, fontsize=13, va="center", transform=a.transAxes)
    out = VIEWS / "clock_train_3d.png"
    plt.savefig(out, dpi=60)
    return out


if __name__ == "__main__":
    print(drive_diagram().name, renders().name)
