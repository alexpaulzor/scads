#!/usr/bin/env python3
"""One black-acrylic plate inside the machine's safe travel (379 x 291, X0 Y0 = the plate's bottom-left corner): the
round spiral (layered version, tap-drill holes), trimmed so its far corners are free, plus every small acrylic part
that fits around it, packed at 8 rotations into the free space. A keep-out at the origin corner covers the area the
ring-test plate already used. Parts that don't fit are reported. Cut through quickcut (frame pass, park, checks).

    python3 marbles/acrylic_plate.py                 # -> marbles/gcode/acrylic_plate_<W>x<H>_acrylic3.gcode + a preview
    python3 marbles/acrylic_plate.py --keepout 56 44 --corner bl
"""
import argparse
import math
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union
from shapely.prepared import prep

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "clock"))
sys.path.insert(0, str(HERE))
import spiral_run as S  # noqa: E402
import escapement_pin as E  # noqa: E402
from laser_parts import gcode  # noqa: E402

PLATE = (379.0, 291.0)
GAP = 2.0                  # between parts (edge to edge)
MAT = "acrylic3"


def ring_jig_parts():
    """the acrylic layer of the rail-mount ring D-jig (core cut in place inside the plate): ring_jig_compact.py runs
    at import, so import it with the acrylic arguments (it also rewrites its own G-code file, unchanged)"""
    argv = sys.argv
    sys.argv = ["x", "--jig-material", MAT, "--centre-y", "30", "--mount-y", "10", "--spiders", "0", "--tag", "_rail",
                "--iron-clear", "4"]
    try:
        import ring_jig_compact as J
    finally:
        sys.argv = argv
    plate, core, R, yc, outline = J.jig_and_core()
    return [core, plate]


def items():
    """[(name, [polygons], copies)] small parts, biggest first"""
    E.anchor()
    ie, ix = E.ANCHOR_INFO["entry"], E.ANCHOR_INFO["exit"]
    B = S.build()
    ex = B["exit"]
    g = B["guide"].difference(unary_union([Point(b).buffer(S.M5 / 2, 32) for b in B["bolts"]]))
    out = [("spiral centre guide", [g], 1),
           ("ring D-jig acrylic layer", ring_jig_parts(), 1),
           ("pallet entry", [ie["t"]], 2),
           ("pallet exit", [ix["t"]], 2),
           ("spiral exit flange", [ex], 1),
           ("pallet keeper", [E.clamp_part()], 2)]
    return out, B


def normalise(polys, ang):
    u = unary_union(polys)
    c = u.centroid
    rp = [affinity.rotate(p, ang, origin=c) for p in polys]
    x0, y0, _, _ = unary_union(rp).bounds
    return [affinity.translate(p, -x0, -y0) for p in rp]


def place(free, polys, step=2.0, angles=range(0, 360, 45)):
    """bottom-left fill: the lowest (then leftmost) spot where the part (any of the angles) fits inside free"""
    pf = prep(free)
    best = None
    fx0, fy0, fx1, fy1 = free.bounds
    for ang in angles:
        ps = normalise(polys, ang)
        foot = unary_union(ps).buffer(GAP / 2, join_style=2)
        w, h = foot.bounds[2] - foot.bounds[0], foot.bounds[3] - foot.bounds[1]
        y = fy0
        found = None
        while y + h <= fy1 + 1e-6 and found is None:
            if best is not None and y > best[0]:
                break
            x = fx0
            while x + w <= fx1 + 1e-6:
                f = affinity.translate(foot, x - foot.bounds[0], y - foot.bounds[1])
                if pf.contains(f):
                    found = (y, x, ang, [affinity.translate(p, x - foot.bounds[0], y - foot.bounds[1]) for p in ps], f)
                    break
                x += step
            y += step
        if found and (best is None or (found[0], found[1]) < (best[0], best[1])):
            best = found
    return best


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--keepout", type=float, nargs=2, default=[34.0, 33.0], help="used corner (the ring test), W H inside the plate")
    ap.add_argument("--corner", choices=["bl", "br", "tl", "tr"], default="tr",
                    help="which plate corner is used (tr: the sheet turned 180 deg, so the ring-test corner is the far one)")
    ap.add_argument("-o", "--out", type=Path, default=HERE / "gcode")
    a = ap.parse_args()
    S.configure(True, 20.0, PLATE[1])
    S.TRIM = True
    parts, B = items()
    # the spiral piece, against the right edge
    dx = PLATE[0] - S.STOCK - 0.3
    outline = affinity.translate(S.piece_outline(), dx, 0)
    screw = S.screw_points(B["cut"], [h for h, _ in B["holes"]])
    sp_holes = [Polygon(h) for h, _ in B["holes"]] + [Polygon(c) for c in S.screw_cuts(screw, "pilot")]
    sp_holes = [affinity.translate(h, dx, 0) for h in sp_holes]
    sp_cut = affinity.translate(LineString(B["cut"]), dx, 0)
    kw, kh = a.keepout
    kx = 0 if a.corner in ("bl", "tl") else PLATE[0] - kw
    ky = 0 if a.corner in ("bl", "br") else PLATE[1] - kh
    keep = box(kx, ky, kx + kw, ky + kh)
    free = box(0, 0, *PLATE).difference(outline.buffer(GAP, join_style=2)).difference(keep)
    placed, missing = [], []
    for name, polys, n in parts:
        for i in range(n):
            r = place(free, polys)
            if r is None:
                missing.append(name)
                continue
            placed.append((name, r[3]))
            free = free.difference(r[4])
            print(f"placed {name} at ({r[1]:.0f}, {r[0]:.0f}) rotated {r[2]} deg")
    for m in missing:
        print(f"DOES NOT FIT: {m}")
    print("not on this plate: spiral entry guide (150 x 285) - needs its own sheet (acrylic or ply3)")
    # cuts: holes first (kerf inward), outlines (kerf outward), the spiral's open line
    T, kerf, _ = gcode.fit(MAT)
    job = gcode.job(MAT, min_segment_mm=0.3)
    cuts = []
    for h in sp_holes:
        cuts.append(gcode.Polyline(list(h.buffer(-kerf / 2, join_style=2).exterior.coords), True))
    cuts.append(gcode.Polyline(list(sp_cut.coords), False))
    cuts.append(gcode.Polyline(list(outline.buffer(kerf / 2, join_style=2).exterior.coords), True))
    for _, polys in placed:
        for p in polys:
            for r in p.interiors:
                cuts.append(gcode.Polyline(list(Polygon(r).buffer(-kerf / 2, join_style=2).exterior.coords), True))
            cuts.append(gcode.Polyline(list(Polygon(p.exterior).buffer(kerf / 2, join_style=2).exterior.coords), True))
    cuts = gcode.order(cuts)
    stem = gcode.name("acrylic_plate", PLATE[0], PLATE[1], MAT)
    names = sorted(set(n for n, _ in placed))
    lines = gcode.preamble(job, title=f"{stem} -- marbles/acrylic_plate.py: round spiral + small acrylic parts",
                           notes=[f"X0 Y0 = plate bottom-left; keep-out {kw:g} x {kh:g} at the {a.corner} corner (ring test)",
                                  f"spiral {S.STOCK:g} x {S.STOCK_H:g}, {B['laps']:.2f} laps, M3 tap holes; " + ", ".join(names),
                                  f"{MAT}: T {T}, kerf {kerf}"])
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(a.out / f"{stem}.gcode", lines)
    mins = sum(LineString(c.points).length * job.passes for c in cuts) / job.feed_mm_per_min
    print(f"{p.name}: {len(cuts)} cuts, ~{mins:.0f} min")
    # preview
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(11, 8.6))
    ax.add_patch(plt.Rectangle((0, 0), *PLATE, fill=False, ec="k", ls="--"))
    ax.add_patch(plt.Rectangle((kx, ky), kw, kh, fc="lightgray", ec="gray", hatch="//"))
    ax.text(kx + kw / 2, ky + kh / 2, "used\n(ring test)", ha="center", va="center", fontsize=7)

    def draw(g, c):
        ax.fill(*g.exterior.xy, color=c, alpha=.5)
        ax.plot(*g.exterior.xy, "k-", lw=.5)
        for r in g.interiors:
            ax.fill(*r.xy, color="w")
            ax.plot(*r.xy, "k-", lw=.5)
    draw(outline, "#444")
    for h in sp_holes:
        ax.plot(*h.exterior.xy, "w-", lw=.6)
    ax.plot(*sp_cut.xy, "r-", lw=.5)
    for name, polys in placed:
        for p in polys:
            draw(p, "#888")
        c = unary_union(polys).centroid
        ax.text(c.x, c.y, name.replace(" ", "\n"), ha="center", va="center", fontsize=6, color="navy")
    ax.set_xlim(-5, PLATE[0] + 5)
    ax.set_ylim(-5, PLATE[1] + 5)
    ax.set_aspect("equal")
    ax.set_title(f"{stem}: {len(placed)} small parts" + (f"; not fitting: {', '.join(missing)}" if missing else ""), fontsize=9)
    plt.tight_layout()
    plt.savefig(HERE / "views" / f"{stem}.png", dpi=100)


if __name__ == "__main__":
    main()
