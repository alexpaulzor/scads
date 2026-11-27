#!/usr/bin/env python3
"""Ply3 laser parts for the clock train (lantern version, clock_train.scad / clock_lantern.py), through quickcut.

Files (marbles/gcode/), each zeroed at its bottom-left, W x H in the name = the real cut extent:
  clock_sun_<stage>_<fixed|out>_cut3   one sun layer: cut it 3 times (3 identical layers per sun, M3-bolted)
  clock_carrier_<stage>_back           back carrier + that stage's 2 lantern DISCS (pin holes) nested in its opening
  clock_carrier_<stage>_front          front carrier + that stage's 2 lantern COVERS + 1 output-sun KEEPER ring nested inside
Per stage: 3 + 3 sun layers, 2 carriers, 2 discs + 2 covers (one lantern), 2 keepers (one per side of the output sun:
the front-carrier files give 2, one each).
Hands are only sketched (views/clock_hands_sketch.png), no G-code yet.

    python3 marbles/clock/clock_train_parts.py
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


def hands_sketch():
    """first-draft hands (no G-code): minute hand on the hour carrier, hour hand on the hour sun's spacers, seconds
    pointer on the escape wheel rim"""
    import matplotlib; matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from shapely.geometry import Polygon
    fig, axs = plt.subplots(1, 3, figsize=(16, 6))
    # minute hand: a slim taper from r 44 to r 146, bolted at r 54 / 66 (MH_ANG on the carrier), counterpoise tail-less
    mh = Polygon([(44, -6), (70, -5), (146, -1.2), (149, 0), (146, 1.2), (70, 5), (44, 6)])
    mh = holes(mh, [(54, 0), (66, 0)], M3)
    # hour hand: round hub r 21 on the 3 sun bolts (r 16), a leaf to r 80
    hh = unary_union([circ(0, 0, 42, 128), Polygon([(15, -7), (55, -9), (74, -4), (80, 0), (74, 4), (55, 9), (15, 7)])])
    hh = holes(hh, [(0, 0)], 8.4); hh = holes(hh, [polar(16, 60 + 120 * k) for k in range(3)], M3)
    # seconds pointer: an arrow on the escape wheel rim (2 M3)
    sp = holes(Polygon([(108, -5), (126, -5), (126, -3), (134, 0), (126, 3), (126, 5), (108, 5)]), [(112, 0), (120, 0)], M3)
    for ax, g, t in zip(axs, (mh, hh, sp), ("MINUTE hand (on the hour carrier's back face, 2 M3)",
                                            "HOUR hand (on spacers on the hour sun's 3 bolts)",
                                            "SECONDS pointer (on the escape wheel rim, 2 M3)")):
        ax.fill(*g.exterior.xy, fc="0.85", ec="k")
        for r in g.interiors:
            ax.fill(*r.xy, fc="w", ec="k")
        ax.plot([0], [0], "k+", ms=12); ax.set_aspect("equal"); ax.set_title(t, fontsize=10); ax.grid(alpha=.3)
        ax.set_xlabel("mm from the rod")
    fig.suptitle("Clock hands, FIRST DRAFT (no G-code yet): ply3, shapes to be refined", fontsize=12)
    plt.tight_layout(); out = VIEWS / "clock_hands_sketch.png"; plt.savefig(out, dpi=80)
    return out


if __name__ == "__main__":
    fs = main()
    print(preview(fs).name, hands_sketch().name)
