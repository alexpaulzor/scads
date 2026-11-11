#!/usr/bin/env python3
"""One ply3 plate per side of the pin-wheel escapement: a lantern-wheel ring with one pallet clamp nested in a corner.
Cut it twice for the two sides (identical rings for the two faces of the 2020 spokes, and the two clamps, one per
rocker arm). The rocker hub plate (86 x 80) does not fit beside a 289 ring on 300 mm stock: cut esc_pin_anchor_plate
x2 from an offcut. Through quickcut (frame pass, park, checks).

    python3 marbles/clock/esc_side_plate.py          # -> marbles/gcode/esc_side_plate_<W>x<H>_ply3.gcode + preview
"""
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
import escapement_pin as E  # noqa: E402
import acrylic_plate as P  # noqa: E402
from laser_parts import gcode  # noqa: E402

SHEET = (300.0, 291.0)
MAT = "ply3"


def main():
    E.anchor()
    ring = E.wheel()
    x0, y0, _, _ = ring.bounds
    ring = affinity.translate(ring, -x0 + 0.5, -y0 + 0.5)
    windows = [Polygon(r) for r in ring.interiors if Polygon(r).area > 500]
    free = box(0, 0, *SHEET).difference(Polygon(ring.exterior).buffer(P.GAP)).union(
        unary_union([w.buffer(-P.GAP) for w in windows]))
    r = P.place(free, [E.clamp_part()], step=1.0, angles=range(0, 360, 15))
    parts = [("ring", ring)] + ([("pallet clamp", r[3][0])] if r else [])
    T, kerf, _ = gcode.fit(MAT)
    job = gcode.job(MAT)
    cuts = []
    for _, p in parts:
        for ri in p.interiors:
            cuts.append(gcode.Polyline(list(Polygon(ri).buffer(-kerf / 2, join_style=2).exterior.coords), True))
        cuts.append(gcode.Polyline(list(Polygon(p.exterior).buffer(kerf / 2, join_style=2).exterior.coords), True))
    cuts = gcode.order(cuts)
    W = max(p.bounds[2] for _, p in parts) + kerf
    H = max(p.bounds[3] for _, p in parts) + kerf
    stem = gcode.name("esc_side_plate", W, H, MAT)
    lines = gcode.preamble(job, title=f"{stem} -- marbles/clock/esc_side_plate.py: one escapement side (cut it twice)",
                           notes=[f"lantern ring ({E.N} M3 holes on r {E.R:g}, 608 seat, M5 on the spokes)"
                                  + (" + 1 pallet clamp" if r else ""),
                                  "the rocker hub plate (86 x 80) is not on this plate: cut esc_pin_anchor_plate x2 from an offcut",
                                  f"{MAT}: T {T}, kerf {kerf}; X0 Y0 = bottom-left"])
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(HERE.parent / "gcode" / f"{stem}.gcode", lines)
    mins = sum(LineString(c.points).length * job.passes for c in cuts) / job.feed_mm_per_min
    print(f"{p.name}: {len(cuts)} cuts, ~{mins:.0f} min; clamp {'at (%.0f, %.0f)' % (r[1], r[0]) if r else 'did NOT fit'}")
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(8, 8))
    ax.add_patch(plt.Rectangle((0, 0), *SHEET, fill=False, ec="k", ls="--"))
    for name, g in parts:
        ax.fill(*g.exterior.xy, color="burlywood", alpha=.6)
        ax.plot(*g.exterior.xy, "k-", lw=.5)
        for ri in g.interiors:
            ax.fill(*ri.xy, color="w")
            ax.plot(*ri.xy, "k-", lw=.5)
    ax.set_aspect("equal")
    ax.set_title(f"{stem}: cut twice (one per side)", fontsize=9)
    plt.tight_layout()
    plt.savefig(HERE.parent / "views" / f"{stem}.png", dpi=100)


if __name__ == "__main__":
    main()
