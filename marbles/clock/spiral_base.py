#!/usr/bin/env python3
"""Flat ply3 base plate under the round acrylic spiral (the 287 x 291 trimmed one): no spiral cut, just its holes
projected onto a 300 x 300 sheet, for M3 hex standoffs (risers) between the plate and the spiral layers.

  - the spiral's layer-screw spots as slots (3.3 x 6.3 along the lap, room to settle as it bends into the helix)
  - its M5 holes: mount row, centre-guide bolts, entry-guide bolts; the exit bore (the ball drops through)
  - the RIM LAYOUT's M5 for future spirals (20 mm rim, M5 every <= 100 mm round it, entry guide bolted every 50 mm
    along its curve): on this plate they mount it, and a future rim-layout spiral bolts to them
  - ETCHED next to every spiral hole: the riser height (mm, plate top to spiral underside) for RISE per lap, the
    solid centre on CENTRE_RISER, every lap outward RISE higher

Same origin as the spiral: X0 Y0 = the bottom-left corner, the mount edge along Y0.

    python3 marbles/clock/spiral_base.py                 # -> marbles/gcode/spiral_base_300x300_ply3.gcode + preview
    python3 marbles/clock/spiral_base.py --rise 15 --centre 0
"""
import argparse
import bisect
import math
import sys
from pathlib import Path

from shapely.geometry import LineString, Point, Polygon

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
VIBES = Path("/home/user/cnc_vibes") if Path("/home/user/cnc_vibes").exists() else HERE.parents[2] / "cnc_vibes"
sys.path.insert(0, str(VIBES / "cnc_calibrate"))
import spiral_run as S  # noqa: E402
from laser_parts import gcode  # noqa: E402
from spiral_cal import _label_strokes  # noqa: E402  (digit stroke font)

PLATE = (300.0, 300.0)
MAT = "ply3"
LABEL_H = 4.0


def current_spiral():
    """the round, trimmed 287 x 291 spiral being cut in acrylic (thin-frame layout)"""
    S.configure(True, 20.0, 291.0, 0.0)
    S.TRIM = True
    return S.build()


def lap_param(cut, cut_t, p):
    """the spiral parameter t of the cut nearest p, measured along the cut"""
    line = LineString(cut)
    acc = [0.0]
    for a, b in zip(cut, cut[1:]):
        acc.append(acc[-1] + math.dist(a, b))
    s = line.project(Point(p))
    i = min(bisect.bisect(acc, s) - 1, len(cut) - 2)
    f = (s - acc[i]) / max(acc[i + 1] - acc[i], 1e-9)
    return cut_t[i] + f * (cut_t[i + 1] - cut_t[i])


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--rise", type=float, default=15.0, help="shelf top to shelf top per lap, mm")
    ap.add_argument("--centre", type=float, default=0.0, help="riser under the solid centre, mm (0: the centre sits on the plate)")
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    B = current_spiral()
    cut, cut_t, t_end = B["cut"], B["cut_t"], B["t_end"]
    frame_riser = a.centre + a.rise * t_end / (2 * math.pi)
    screws = S.screw_points(cut, [h for h, _ in B["holes"]])
    slots = [Polygon(c) for c in S.screw_cuts(screws, "slot")]
    holes, labels = [], []                       # labels: (text, x, y, angle)
    cx, cy = S.CX, S.CY

    def label(p, height, inward=7.5):
        d = math.dist(p, (cx, cy)) or 1
        ux, uy = (cx - p[0]) / d, (cy - p[1]) / d                     # toward the spiral centre
        ang = (math.degrees(math.atan2(uy, ux)) - 90) % 360            # text runs along the lap ...
        if 90 < ang < 270:
            ang -= 180                                                 # ... but never upside down
        labels.append((f"{height:.0f}", p[0] + ux * inward, p[1] + uy * inward, ang))

    for (p, _), sl in zip(screws, slots):
        t = lap_param(cut, cut_t, (p[0] + (cx - p[0]) * 1e-3, p[1] + (cy - p[1]) * 1e-3))
        label(p, a.centre + a.rise * (t_end - t) / (2 * math.pi))
    for h, lab in B["holes"]:
        if lab == "relief":
            continue
        poly = Polygon(h)
        holes.append(poly)
        c = poly.centroid
        if lab == "guide M5":
            label((c.x, c.y), a.centre)
        elif lab == "mount M5":
            labels.append((f"{frame_riser:.0f}", c.x + 10, c.y, 0.0))     # beside the hole, clear of the edge
        elif lab == "entry guide M5":
            label((c.x, c.y), frame_riser)
    # the rim layout's holes (future spirals; also mount this plate)
    S.configure(True, 20.0, 291.0, 20.0)
    S.TRIM = False
    F = S.build()
    future = []
    for h, lab in F["holes"]:
        if lab in ("rim M5", "entry guide M5", "mount M5"):
            c = Polygon(h).centroid
            if all(c.distance(q) > 9 for q in holes + slots):
                future.append(Polygon(h))
    T, kerf, _ = gcode.fit(MAT)
    job = gcode.job(MAT)
    # the ply3 etch recipe is 100 % at F5000, above the machine's 3000 XY cap that quickcut enforces: run it at
    # F3000 and scale the power by the time per mm (5000 / 3000), so 60 % (an estimate, not calibrated)
    ejob = gcode.job(MAT, recipe="etch", feed_mm_per_min=3000, power_percent=60)
    strokes = []
    for text, x, y, ang in labels:
        strokes += _label_strokes(text, x, y, LABEL_H, angle_deg=ang)
    chains = gcode.fuse_touching([[(x1, y1), (x2, y2)] for x1, y1, x2, y2 in strokes], tol=0.05)   # 7-segment digits -> strokes
    etches = gcode.order([gcode.Polyline([tuple(q) for q in ch], False) for ch in chains if len(ch) > 1])
    cuts = gcode.order([gcode.Polyline(list(g.buffer(-kerf / 2, join_style=2).exterior.coords), True) for g in holes + slots + future])
    stem = gcode.name("spiral_base", *PLATE, MAT)
    lines = gcode.preamble(job, title=f"{stem} -- marbles/clock/spiral_base.py: flat base under the round spiral (no outline)",
                           notes=[f"X0 Y0 = bottom-left (the spiral's mount edge); {len(slots)} standoff slots, {len(holes)} spiral holes, "
                                  f"{len(future)} rim-layout M5",
                                  f"etched: riser height mm (plate top to spiral underside) for {a.rise:g} per lap, centre {a.centre:g}, "
                                  f"frame {frame_riser:.0f}", f"{MAT}: T {T}, kerf {kerf}"], etch=ejob)
    for i, e in enumerate(etches, 1):
        lines += gcode.etch(e, ejob, i, len(etches))
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(a.out / f"{stem}.gcode", lines)
    mins = sum(LineString(c.points).length for c in cuts) * job.passes / job.feed_mm_per_min
    print(f"{p.name}: {len(slots)} slots, {len(holes)} spiral holes, {len(future)} rim-layout M5, {len(labels)} labels; "
          f"risers {a.centre:g} (centre) to {frame_riser:.1f} (frame); ~{mins:.0f} min cutting + etch")
    heights = sorted(set(round(float(t)) for t, *_ in labels))
    print("riser heights used (mm):", heights)
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(10, 10))
    ax.add_patch(plt.Rectangle((0, 0), *PLATE, fc="#f3e6cf", ec="k"))
    ax.plot(*LineString(cut).xy, ":", color="gray", lw=.6)
    for g in holes:
        ax.plot(*g.exterior.xy, "r-", lw=.8)
    for g in slots:
        ax.plot(*g.exterior.xy, "b-", lw=.8)
    for g in future:
        ax.plot(*g.exterior.xy, "-", color="darkgreen", lw=1)
    for x1, y1, x2, y2 in strokes:
        ax.plot([x1, x2], [y1, y2], "k-", lw=.6)
    ax.set_aspect("equal")
    ax.set_title(f"{stem}: slots (blue) + spiral M5 (red) + rim-layout M5 (green); etched riser mm for {a.rise:g}/lap "
                 f"(spiral cut dotted, not cut)", fontsize=8)
    plt.tight_layout()
    plt.savefig(HERE.parent / "views" / f"{stem}.png", dpi=110)


if __name__ == "__main__":
    main()
