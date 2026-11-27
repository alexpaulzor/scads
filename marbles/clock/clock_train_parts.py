#!/usr/bin/env python3
"""Ply3 laser parts for the clock train (lantern version, clock_train.scad / clock_lantern.py), through quickcut.

Files (marbles/gcode/), each zeroed at its bottom-left, W x H in the name = the real cut extent:
  clock_sun_<stage>_<fixed|out>_cut3   one sun layer: cut it 3 times (3 identical layers per sun, M3-bolted)
  clock_carrier_<stage>_back           back carrier + that stage's 2 lantern DISCS (pin holes) nested in its opening
  clock_carrier_<stage>_front          front carrier + that stage's 2 lantern COVERS + 1 output-sun KEEPER ring nested inside
Per stage: 3 + 3 sun layers, 2 carriers, 2 discs + 2 covers (one lantern), 2 keepers (one per side of the output sun:
the front-carrier files give 2, one each).
Hands: first draft in views/clock_hands_sketch.png, cut on full sheet E only.

FULL SHEETS (--sheets): the whole set on 5 sheets of 300 x 300 ply3 (layout area 298 x 290: Y stays under the 292 travel):
  A..D  one carrier (with its nested lantern parts) middle-left + two layers of one sun stacked on the right; the left
        corners hold the 2 extra keepers the set needs (A) or spares (B, C, D)
  E     one layer of each of the 4 suns + the MVP hands (hour, minute, seconds pointer) between them
Together: 3 layers of each of the 4 suns, the 4 carriers, 2 lanterns' discs + covers, 4 keepers (+ spares).

    python3 marbles/clock/clock_train_parts.py            # one file per part (as above)
    python3 marbles/clock/clock_train_parts.py --sheets   # the 5 full sheets
"""
import math
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import Point
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import gcode  # noqa: E402
import clock_lantern as cl  # noqa: E402

MAT = "ply3"
A, P, TIE_D = cl.A, cl.P_PL, cl.TIE_D
M3, M5, PIN_HOLE = 3.3, 5.3, cl.PIN_HOLE
CAR_IN, CAR_OUT = 44.5, A + 14
UP_R, ESC_R, MH_ANG = 50, 80, 45
OUT = HERE.parent / "gcode"
VIEWS = HERE.parent / "views"


def circ(x, y, d, n=64):
    return Point(x, y).buffer(d / 2, n)


def polar(r, a_deg):
    return r * math.cos(math.radians(a_deg)), r * math.sin(math.radians(a_deg))


def holes(g, pts, d):
    return g.difference(unary_union([circ(x, y, d, 24) for x, y in pts]))


def sun_layer(g, kind, stage):
    if kind == "fixed":
        g = holes(g, [(0, 0)], 8.4)
        return holes(g, [(sx * 15, sy * 27.5) for sx in (-1, 1) for sy in (-1, 1)], M3)          # 2 into the beam, 2 clamp
    g = holes(g, [(0, 0)], 22.2)                                                                 # the 608
    g = holes(g, [polar(16, 60 + 120 * k) for k in range(3)], M3)                                # keeper bolts
    if stage == "minute":
        g = holes(g, [polar(UP_R, 36 + 72 * k) for k in range(5)], M3)                           # standoffs to the hour carrier
    return g


def lantern_disc(rp, pins):
    g = holes(circ(0, 0, 2 * cl_disc_r(), 128), [(0, 0)], 3.4)                                  # axle (it spins on it)
    g = holes(g, [(0, -TIE_D), (0, TIE_D)], M3)                                                  # tie bolts
    if pins:
        g = holes(g, [polar(rp, k * 360 / P) for k in range(P)], PIN_HOLE)
    return g


def cl_disc_r():
    return max(cl.pin_r(S) for S in cl.STAGES.values()) + PIN_HOLE / 2 + cl.RIM


def keeper():
    g = holes(circ(0, 0, 42, 128), [(0, 0)], 16)
    return holes(g, [polar(16, 60 + 120 * k) for k in range(3)], M3)


def carrier(stage, side):
    rin = CAR_IN if side == "back" else A - cl_disc_r() + 1
    g = circ(0, 0, 2 * CAR_OUT, 256).difference(circ(0, 0, 2 * rin, 256))
    g = holes(g, [polar(A, a) for a in (0, 90, 270)], M3)                                        # planet axle, 2 tie posts
    g = holes(g, [polar(A, 180)], M5)                                                            # counterweight bolt
    if side == "back" and stage == "minute":
        g = holes(g, [polar(ESC_R, 15 + 60 * k) for k in range(6)], M3)                          # escape wheel standoffs
    if side == "back" and stage == "hour":
        g = holes(g, [polar(UP_R, 36 + 72 * k) for k in range(5)], M3)                           # standoffs from the minute sun
        g = holes(g, [polar(r, MH_ANG) for r in (54, 66)], M3)                                   # minute hand
    return g, rin


def write(stem_base, polys, note):
    T, kerf, _ = gcode.fit(MAT)
    job = gcode.job(MAT)
    gs = [p.buffer(kerf / 2, join_style=2) for p in polys]
    x0 = min(g.bounds[0] for g in gs); y0 = min(g.bounds[1] for g in gs)
    x1 = max(g.bounds[2] for g in gs); y1 = max(g.bounds[3] for g in gs)
    cuts = []
    for g in gs:
        cuts += [gcode.Polyline([(x - x0, y - y0) for x, y in r.coords], True) for r in g.interiors]
        cuts.append(gcode.Polyline([(x - x0, y - y0) for x, y in g.exterior.coords], True))
    cuts = gcode.order(cuts)
    stem = gcode.name(stem_base, x1 - x0, y1 - y0, MAT)
    lines = gcode.preamble(job, title=f"{stem} -- marbles/clock/clock_train_parts.py",
                           notes=[note, f"{MAT}: T {T}, kerf {kerf}; X0 Y0 = bottom-left"])
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(OUT / f"{stem}.gcode", lines)
    print(f"  {p.name}: {len(cuts)} cuts, {x1 - x0:.2f} x {y1 - y0:.2f}")
    return p, [affinity.translate(g, -x0, -y0) for g in polys]


def main():
    files = []
    dr = cl_disc_r()
    for name, S in cl.STAGES.items():
        st = cl.stage(S)
        rp = st["A"]["r"]
        for kind, lay in (("fixed", "A"), ("out", "B")):
            g = sun_layer(st[lay]["g"], kind, name)
            files.append(write(f"clock_sun_{name}_{kind}{st[lay]['Z']}_cut3", [g],
                               f"{name} {'FIXED' if kind == 'fixed' else 'OUTPUT'} sun, {st[lay]['Z']} teeth (lantern pins r {rp:.3f}): "
                               f"one layer, cut 3"))
        back, rin = carrier(name, "back")
        d = 21.5                                                     # 2 discs side by side in the r 44.5 opening
        assert d - dr > 1 and d + dr < rin - 2
        discs = [affinity.translate(lantern_disc(rp, True), sx * d, 0) for sx in (-1, 1)]
        files.append(write(f"clock_carrier_{name}_back", discs + [back],
                           f"{name} BACK carrier + the 2 lantern DISCS ({P} pin holes on r {rp:.3f}) nested in its opening"))
        front, rin = carrier(name, "front")
        d = 31                                                       # 3 parts at 120 deg in the opening
        assert d * math.sqrt(3) > 2 * 21 + 2 and d + 21 < rin - 2
        inner = [lantern_disc(rp, False), lantern_disc(rp, False), keeper()]
        inner = [affinity.translate(q, *polar(d, 90 + 120 * k)) for k, q in enumerate(inner)]
        files.append(write(f"clock_carrier_{name}_front", inner + [front],
                           f"{name} FRONT carrier + the 2 lantern COVERS + 1 output-sun keeper ring nested in its opening"))
    return files


def preview(files):
    import matplotlib; matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    n = len(files)
    fig, axs = plt.subplots(2, (n + 1) // 2, figsize=(4.2 * ((n + 1) // 2), 9))
    for ax, (p, polys) in zip(axs.flat, files):
        for g in sorted(polys, key=lambda q: -q.area):           # big first, so nested parts draw on top
            for q in getattr(g, "geoms", [g]):
                ax.fill(*q.exterior.xy, fc="burlywood", ec="k", lw=.4)
                for r in q.interiors:
                    ax.fill(*r.xy, fc="w", ec="k", lw=.4)
        ax.set_aspect("equal"); ax.set_title(p.stem.replace("clock_", ""), fontsize=8); ax.tick_params(labelsize=6)
    for ax in list(axs.flat)[n:]:
        ax.axis("off")
    plt.tight_layout(); out = VIEWS / "clock_train_parts.png"; plt.savefig(out, dpi=80)
    return out


def hands():
    """MVP hands, in clock coordinates (the rod at the origin, pointing +x): minute hand (on the hour carrier's back face,
    2 M3 at r 54 / 66), hour hand (round hub on the hour sun's 3 bolts at r 16, leaf to r 80), seconds pointer (escape
    wheel rim, 2 M3)"""
    from shapely.geometry import Polygon
    mh = holes(Polygon([(44, -6), (70, -5), (146, -1.2), (149, 0), (146, 1.2), (70, 5), (44, 6)]), [(54, 0), (66, 0)], M3)
    hh = unary_union([circ(0, 0, 42, 128), Polygon([(15, -7), (55, -9), (74, -4), (80, 0), (74, 4), (55, 9), (15, 7)])])
    hh = holes(hh, [(0, 0)], 8.4); hh = holes(hh, [polar(16, 60 + 120 * k) for k in range(3)], M3)
    sp = holes(Polygon([(108, -5), (126, -5), (126, -3), (134, 0), (126, 3), (126, 5), (108, 5)]), [(112, 0), (120, 0)], M3)
    return mh, hh, sp


def hands_sketch():
    """first-draft hands: minute hand on the hour carrier, hour hand on the hour sun's spacers, seconds pointer on the
    escape wheel rim (cut on full sheet E)"""
    import matplotlib; matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, axs = plt.subplots(1, 3, figsize=(16, 6))
    mh, hh, sp = hands()
    for ax, g, t in zip(axs, (mh, hh, sp), ("MINUTE hand (on the hour carrier's back face, 2 M3)",
                                            "HOUR hand (on spacers on the hour sun's 3 bolts)",
                                            "SECONDS pointer (on the escape wheel rim, 2 M3)")):
        ax.fill(*g.exterior.xy, fc="0.85", ec="k")
        for r in g.interiors:
            ax.fill(*r.xy, fc="w", ec="k")
        ax.plot([0], [0], "k+", ms=12); ax.set_aspect("equal"); ax.set_title(t, fontsize=10); ax.grid(alpha=.3)
        ax.set_xlabel("mm from the rod")
    fig.suptitle("Clock hands, FIRST DRAFT (MVP: cut on full sheet E), ply3, shapes to be refined", fontsize=12)
    plt.tight_layout(); out = VIEWS / "clock_hands_sketch.png"; plt.savefig(out, dpi=80)
    return out


SHEET_W, SHEET_H, GAP = 298.0, 290.0, 3.0


def parts():
    """every part, centred at the origin: suns[(stage, kind)], carrier groups[(stage, side)] (carrier + nested), keeper"""
    suns, groups = {}, {}
    for name, S in cl.STAGES.items():
        st = cl.stage(S)
        rp = st["A"]["r"]
        for kind, lay in (("fixed", "A"), ("out", "B")):
            suns[(name, kind)] = (sun_layer(st[lay]["g"], kind, name), st[lay]["Z"])
        back, _ = carrier(name, "back")
        groups[(name, "back")] = [affinity.translate(lantern_disc(rp, True), sx * 21.5, 0) for sx in (-1, 1)] + [back]
        front, _ = carrier(name, "front")
        inner = [lantern_disc(rp, False), lantern_disc(rp, False), keeper()]
        groups[(name, "front")] = [affinity.translate(q, *polar(31, 90 + 120 * k)) for k, q in enumerate(inner)] + [front]
    return suns, groups


def sheets():
    suns, groups = parts()
    T, kerf, _ = gcode.fit(MAT)
    rs = max(math.hypot(x, y) for g, _ in suns.values() for x, y in g.exterior.coords) + kerf / 2   # sun radius incl. kerf
    rc = CAR_OUT + kerf / 2
    rk = 21 + kerf / 2                                                 # keeper / lantern disc radius (keeper is the bigger)
    c_car = (rc, SHEET_H / 2)                                          # carrier middle-left
    c_suns = [(SHEET_W - rs, rs), (SHEET_W - rs, SHEET_H - rs)]        # two suns stacked on the right
    c_corner = [(rk, rk), (rk, SHEET_H - rk)]                          # the left corners
    grid = [(rs, rs), (SHEET_W - rs, rs), (rs, SHEET_H - rs), (SHEET_W - rs, SHEET_H - rs)]
    chk = {"carrier-sun": (math.dist(c_car, c_suns[0]), rc + rs + GAP), "sun-sun": (c_suns[1][1] - c_suns[0][1], 2 * rs + GAP),
           "corner-carrier": (math.dist(c_corner[0], c_car), rc + rk + GAP), "grid": (min(SHEET_W, SHEET_H) - 2 * rs, 2 * rs + GAP)}
    for k, (have, need) in chk.items():
        assert have >= need, (k, have, need)
    print("; ".join(f"{k} {have:.2f} (need {need:.2f})" for k, (have, need) in chk.items()))
    st = {n: cl.stage(S)["A"]["r"] for n, S in cl.STAGES.items()}
    spare = {"keeper": keeper(), "mindisc": lantern_disc(st["minute"], True), "houdisc": lantern_disc(st["hour"], True),
             "cover": lantern_disc(st["minute"], False)}
    # tag, carrier group, sun kind (x2), corner parts (2 keepers are part of the set; the rest are SPARES)
    plan = [("A", ("minute", "back"), ("minute", "fixed"), ["keeper", "keeper"]),
            ("B", ("minute", "front"), ("minute", "out"), ["mindisc", "cover"]),
            ("C", ("hour", "back"), ("hour", "fixed"), ["houdisc", "cover"]),
            ("D", ("hour", "front"), ("hour", "out"), ["keeper", "keeper"])]
    out = []
    for tag, grp, sk, corner in plan:
        polys = [affinity.translate(q, *c_car) for q in groups[grp]]
        polys += [affinity.translate(suns[sk][0], *xy) for xy in c_suns]
        polys += [affinity.translate(spare[c], *xy) for c, xy in zip(corner, c_corner)]
        cn = "2 keepers (the set needs them)" if tag == "A" else "spares: " + " + ".join(corner)
        what = f"{grp[0]} {grp[1]} carrier + its nested lantern parts; 2 layers of the {sk[0]} {sk[1]} sun ({suns[sk][1]} teeth); corners: {cn}"
        out.append(write_sheet(f"clock_sheet{tag}_{grp[0][:3]}{grp[1]}_{sk[0][:3]}{sk[1]}{suns[sk][1]}x2", polys, what))
    ks = [("minute", "fixed"), ("minute", "out"), ("hour", "fixed"), ("hour", "out")]
    polys = [affinity.translate(suns[k][0], *xy) for k, xy in zip(ks, grid)]
    # the MVP hands in the cross-shaped gap between the 4 suns: hour hub in the middle, its leaf up the vertical channel,
    # the minute hand down it, the seconds pointer in the left arm
    mh, hh, sp = hands()
    cx, cy = SHEET_W / 2, SHEET_H / 2
    polys.append(affinity.translate(affinity.rotate(hh, 90, origin=(0, 0)), cx, cy))
    polys.append(affinity.translate(affinity.rotate(mh, -90, origin=(0, 0)), cx, cy - 21 - GAP - 1 + 44))   # base under the hub, tip down
    polys.append(affinity.translate(sp, -108 + 2 + kerf, cy))
    what = "1 layer of each sun (min 59 BL, min 60 BR, hour 55 TL, hour 60 TR) + MVP hands"
    out.append(write_sheet("clock_sheetE_suns_hands", polys, what))
    return out


def write_sheet(stem_base, polys, note):
    """like write(), but laid out in sheet coordinates (no re-zeroing): X0 Y0 = the stock's bottom-left corner"""
    T, kerf, _ = gcode.fit(MAT)
    job = gcode.job(MAT)
    gs = [p.buffer(kerf / 2, join_style=2) for p in polys]
    x1 = max(g.bounds[2] for g in gs); y1 = max(g.bounds[3] for g in gs)
    assert min(g.bounds[0] for g in gs) >= -1e-6 and min(g.bounds[1] for g in gs) >= -1e-6 and x1 <= SHEET_W + 1e-6 and y1 < 292
    gap = min(gs[i].distance(gs[j]) for i in range(len(gs)) for j in range(i + 1, len(gs)))
    assert gap >= 2.0, (stem_base, gap)                       # cut edges (kerf-grown parts) at least 2 mm apart
    cuts = []
    for g in gs:
        cuts += [gcode.Polyline(list(r.coords), True) for r in g.interiors]
        cuts.append(gcode.Polyline(list(g.exterior.coords), True))
    cuts = gcode.order(cuts)
    stem = gcode.name(stem_base, x1, y1, MAT)
    lines = gcode.preamble(job, title=f"{stem} -- marbles/clock/clock_train_parts.py --sheets",
                           notes=[note, f"{MAT}: T {T}, kerf {kerf}; X0 Y0 = the 300 x 300 stock's bottom-left corner"])
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(OUT / f"{stem}.gcode", lines)
    print(f"  {p.name}: {len(cuts)} cuts, extent {x1:.2f} x {y1:.2f}, closest parts {gap:.2f} apart")
    return p, polys


def sheet_preview(files):
    import matplotlib; matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, axs = plt.subplots(2, 3, figsize=(15, 10.5))
    for ax in list(axs.flat)[len(files):]:
        ax.axis("off")
    for ax, (p, polys) in zip(axs.flat, files):
        ax.add_patch(plt.Rectangle((0, 0), 300, 300, fc="none", ec="0.6", ls="--"))
        ax.axhline(292, color="r", lw=.6, ls=":")
        for g in sorted(polys, key=lambda q: -q.area):
            for q in getattr(g, "geoms", [g]):
                ax.fill(*q.exterior.xy, fc="burlywood", ec="k", lw=.4)
                for r in q.interiors:
                    ax.fill(*r.xy, fc="w", ec="k", lw=.4)
        ax.set_xlim(-5, 305); ax.set_ylim(-5, 305); ax.set_aspect("equal")
        ax.set_title(p.stem.replace("clock_", ""), fontsize=8); ax.tick_params(labelsize=6)
    fig.suptitle("Clock train, full ply3 sheets (300 x 300 stock dashed; red dotted = Y 292 travel limit)", fontsize=11)
    plt.tight_layout(); out = VIEWS / "clock_train_sheets.png"; plt.savefig(out, dpi=80)
    return out


if __name__ == "__main__":
    if "--sheets" in sys.argv:
        print(sheet_preview(sheets()).name)
    else:
        fs = main()
        print(preview(fs).name, hands_sketch().name)
