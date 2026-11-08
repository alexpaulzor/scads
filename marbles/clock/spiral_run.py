#!/usr/bin/env python3
"""Spiral marble run: one sheet, ONE spiral cut line (nothing removed but the holes).

Pull the centre down and the sheet between the turns becomes a descending helical shelf (a slinky): each turn
sits a little lower than the one outside it, so the outer turn's edge is a low wall. The ball rolls on the shelf,
held out against that wall by its own centripetal force, round and down to the centre.

  - the spiral is a single cut line (kerf only), Archimedean, PITCH apart: the shelf is PITCH - kerf wide,
    a little wider than the ball's radius
  - it starts at R_OUT toward the corner where the mount row starts (the ball is fed in there by the existing
    flange, mounted on the top beam) and ends early at R_IN: the centre stays a solid disk
  - centre: the wire-track flange pattern (bore 23.1, 4 wire notches, 4 stitch holes, M5 at 20 from the centre:
    4 corners + 4 mid-sides), fully enclosed; tie the centre down to the beam below through those M5
  - mount: M5 10 from the top edge, every MOUNT_STEP from the corner, into the top 2020
  - outline: the stock's rectangle, cut last

    python3 marbles/clock/spiral_run.py                    # ply3, mdf3, birch3
    python3 marbles/clock/spiral_run.py --material birch3 --pitch 12
"""
import argparse
import math
import sys
from pathlib import Path

from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import gcode  # noqa: E402  (quickcut's gcode core)

W, H = 280.0, 285.0            # stock (under the 300 x 292 sheet)
CX, CY = 140.0, 140.0          # spiral centre
R_OUT = 125.0                  # the cut starts here (leaves 7.5 of wood to the mount holes)
R_IN = 36.0                    # ... and ends here: the centre disk holds the flange pattern
PITCH = 11.0                   # shelf width + kerf: a bit over the ball's radius (9.525)
START_DEG = 135.0              # the cut's outer end points at the top-left corner (the mount row's start)
MOUNT_STEP = 50.0
M5 = 5.0
# wire-track flange pattern (feeder.scad tunnel flange)
TUN_FBORE, TUN_HOLE, TUN_NOTCH_OUT, TUN_SR, FLANGE_BOLT = 23.1, 2.35, 12.2, 18.99, 20.0


def spiral(pitch=PITCH, r_out=R_OUT, r_in=R_IN, start_deg=START_DEG, step_mm=0.5):
    """the cut's centre line: clockwise inward from r_out to r_in"""
    turns = (r_out - r_in) / pitch
    total = turns * 2 * math.pi
    pts, t = [], 0.0
    while t <= total + 1e-9:
        r = r_out - pitch * t / (2 * math.pi)
        a = math.radians(start_deg) - t
        pts.append((CX + r * math.cos(a), CY + r * math.sin(a)))
        t += step_mm / max(r, 1.0)
    return pts, turns


def holes():
    """[(points, closed)] of every hole, nominal (kerf added at emission)"""
    out, bore = [], [Point(CX, CY).buffer(TUN_FBORE / 2, 96)]
    for a in (45, 135, 225, 315):
        u = (math.cos(math.radians(a)), math.sin(math.radians(a)))
        bore.append(LineString([(CX, CY), (CX + TUN_NOTCH_OUT * u[0], CY + TUN_NOTCH_OUT * u[1])]).buffer(TUN_HOLE / 2, cap_style=2))
        out.append((list(Point(CX + TUN_SR * u[0], CY + TUN_SR * u[1]).buffer(TUN_HOLE / 2, 24).exterior.coords), True))
    out.insert(0, (list(unary_union(bore).exterior.coords), True))      # the bore with its 4 wire notches: one cut
    bolts = [(CX + sx * FLANGE_BOLT, CY + sy * FLANGE_BOLT) for sx in (-1, 0, 1) for sy in (-1, 0, 1) if (sx, sy) != (0, 0)]
    mount = [(x, H - 10) for x in [10 + MOUNT_STEP * i for i in range(int((W - 20) // MOUNT_STEP) + 1)]]
    for p in bolts + mount:
        out.append((list(Point(p).buffer(M5 / 2, 48).exterior.coords), True))
    return out, bolts, mount


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--material", nargs="+", default=["ply3", "mdf3", "birch3"])
    ap.add_argument("--pitch", type=float, default=PITCH)
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    sp, turns = spiral(a.pitch)
    sp_len = LineString(sp).length
    hole_list, bolts, mount = holes()
    for mat in a.material:
        T, kerf, _ = gcode.fit(mat)
        job = gcode.job(mat, min_segment_mm=0.3)
        cuts = []
        for pts, closed in hole_list:                   # holes: the cut runs half a kerf inside the nominal edge
            cuts.append(gcode.Polyline(list(Polygon(pts).buffer(-kerf / 2, join_style=2).exterior.coords), True))
        cuts.append(gcode.Polyline(sp, False))         # the spiral: a single cut line, centred on the path
        outline = box(0, 0, W, H).buffer(kerf / 2, join_style=2)
        cuts.append(gcode.Polyline(list(outline.exterior.coords), True))
        cuts = gcode.order(cuts)
        # shift so the kerf-grown outline's corner is X0 Y0
        cuts = [gcode.Polyline([(x + kerf / 2, y + kerf / 2) for x, y in c.points], c.closed) for c in cuts]
        name = gcode.name("spiral_run", W + kerf, H + kerf, mat)
        lines = gcode.preamble(job, title=f"{name} -- marbles/clock/spiral_run.py", notes=[
            f"ONE spiral cut ({turns:.1f} turns, pitch {a.pitch:g}: shelf {a.pitch - kerf:.2f} wide for a 19.05 ball; "
            f"{sp_len / 1000:.2f} m of cut), r {R_OUT:g} -> {R_IN:g}, starting toward the top-left corner",
            f"centre: wire-track flange pattern, 8 M5 at {FLANGE_BOLT:g} from the centre (tie the centre down here)",
            f"mount: {len(mount)} M5 10 from the top edge, every {MOUNT_STEP:g} from the corner",
            f"stock {W:g} x {H:g}; {mat}: T {T}, kerf {kerf}; X0 Y0 = the stock's bottom-left corner"])
        for i, c in enumerate(cuts, 1):
            lines += gcode.cut(c, job, i, len(cuts))
        path = gcode.write(a.out / f"{name}.gcode", lines)
        mins = sum(LineString(c.points).length * job.passes for c in cuts) / job.feed_mm_per_min
        print(f"{path.name}: {len(cuts)} cuts, spiral {turns:.1f} turns / {sp_len / 1000:.2f} m, "
              f"{job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}: ~{mins:.0f} min of cutting")


if __name__ == "__main__":
    main()
