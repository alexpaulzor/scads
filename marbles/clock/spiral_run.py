#!/usr/bin/env python3
"""Spiral marble run: one 300 x 300 sheet, ONE spiral cut line (nothing removed but holes).

Pull the centre down and the sheet between the turns becomes a descending helical shelf (a slinky): each turn sits a
little lower than the one outside it, so the outer turn's edge is a low wall. The ball rolls on the shelf, held out
against that wall by its own centripetal force, round and down to the centre.

Layout (machine frame, X0 Y0 = the stock's corner; the MOUNT edge is the front, y = 0, so every cut stays under the
292 mm Y reach; in use that edge is the top, on the beam):
  - mount: M5 10 from the mount edge, every 50 from the corner, into the top 2020
  - the spiral fills the width: an elliptical Archimedean spiral, semi-axes 144 x 135, PITCH 12.7 (1/2"), centred
    so its outer edge clears the mount holes by 7.5. It starts at the point nearest the beam, running PARALLEL to it.
  - it ends in a CURL: after the last lap the cut tightens smoothly (same tangent, the radius shrinking a little
    faster every degree) and stops beside the exit bore, so the wall that keeps the ball on the shelf also steers it
    into the hole; the bore is fully enclosed. Only the centre M5 holes clear of the ball's path are kept.
  - entry: a cropped wire-track flange stands on the sheet at the start, its bore centred NO_DROP_AXIS above the
    surface, so a ball resting on the tunnel's bottom wires is already at shelf level: it rolls straight off the wire
    ends onto the shelf, parallel to the beam. The flange bolts to the side of a short 2020 post, held to the beam by
    a corner bracket through a mount hole.

    python3 marbles/clock/spiral_run.py                    # ply3, mdf3, birch3: sheet + entry flange
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

STOCK = 300.0
BALL_R = 19.05 / 2
PITCH = 12.7                   # 1/2"
MOUNT_Y, MOUNT_STEP, M5 = 10.0, 50.0, 5.0
SIDE = 6.0                     # wood outside the spiral at the sides
A0 = STOCK / 2 - SIDE          # 144: x semi-axis of the outer cut
B0 = 135.0                     # y semi-axis: outer edge 7.5 clear of the mount holes, top at y 290 (< 292 reach)
CX, CY = STOCK / 2, MOUNT_Y + M5 / 2 + 7.5 + B0
B_IN = 46.0                    # the laps stop here (y semi-axis) ...
CURL_DEG = 200.0               # ... then the curl turns this far more (short enough that an opposite pair of
                               #     tie-down bolts can stay clear of the ball on both sides of the bore) ...
R_END = 18.0                   # ... ending this far from the centre; past it the ball runs on downhill into the bore
# wire-track flange pattern (feeder.scad tunnel flange)
TUN_WIRE, TUN_RW, TUN_FBORE, TUN_HOLE, TUN_NOTCH_OUT, TUN_SR, FLANGE_BOLT = 2.05, 11.025, 23.1, 2.35, 12.2, 18.99, 20.0
FLANGE_HALF = 26.5
# ball resting on the two lower wires (225 / 315 deg) sits this far below the tunnel axis
BALL_DROP = TUN_RW * math.sin(math.radians(45)) - math.sqrt((BALL_R + TUN_WIRE / 2) ** 2 - (TUN_RW * math.cos(math.radians(45))) ** 2)
NO_DROP_AXIS = BALL_R + BALL_DROP          # axis height above the shelf for a no-drop hand-off
EXIT_GAP = 12.0                            # the flange's downstream face this far before the cut starts
HEAD_CLEAR = 11.5                          # a button-head M5 (9.5 x 2.75) clears a ball centred this far away
CUT_CLEAR = M5 / 2 + 4                     # and keeps 4 of wood to the cut


def spiral(pitch=PITCH):
    """(cut points, ball-centre points): CCW from the point nearest the beam, laps to B_IN, then the curl"""
    k = pitch / (2 * math.pi)
    t_main = (B0 - B_IN) / k
    a_end, b_end = A0 - k * t_main, B_IN
    phi = math.radians(CURL_DEG)
    ka = (a_end - k * phi - R_END) / phi ** 2          # r = r_end - k phi - kq phi^2: same slope where the curl begins
    kb = (b_end - k * phi - R_END) / phi ** 2
    cut, t = [], 0.0
    while True:
        if t <= t_main:
            ra, rb = A0 - k * t, B0 - k * t
        else:
            f = t - t_main
            if f > phi:
                break
            ra, rb = a_end - k * f - ka * f * f, b_end - k * f - kb * f * f
        th = -math.pi / 2 + t
        cut.append((CX + ra * math.cos(th), CY + rb * math.sin(th)))
        t += 0.5 / max(min(ra, rb), 5.0)
    line = LineString(cut)
    ball = []
    for i in range(1, len(cut) - 1):               # ball centre: BALL_R inward of the wall (left of travel, CCW)
        (x0, y0), (x1, y1) = cut[i - 1], cut[i + 1]
        d = math.hypot(x1 - x0, y1 - y0)
        nx, ny = -(y1 - y0) / d, (x1 - x0) / d
        ball.append((cut[i][0] + BALL_R * nx, cut[i][1] + BALL_R * ny))
    return cut, ball, (B0 - B_IN) / pitch, line.length


def tie_pair(cut, ball):
    """the opposite pair of centre tie-down M5 with the most room: (r, angle_deg, margin)"""
    bl, cl = LineString(ball), LineString(cut)
    best = None
    for r in [18 + 0.5 * i for i in range(30)]:
        for ad in range(0, 180, 2):
            a = math.radians(ad)
            ps = [Point(CX + r * math.cos(a), CY + r * math.sin(a)), Point(CX - r * math.cos(a), CY - r * math.sin(a))]
            m = min(min(p.distance(bl) for p in ps) - HEAD_CLEAR, min(p.distance(cl) for p in ps) - CUT_CLEAR)
            if best is None or m > best[2]:
                best = (r, ad, m)
    return best


def holes(cut, ball):
    """[(closed points, label)] on the sheet: the exit bore (enclosed), the tie-down pair, the mount row"""
    r, ad, margin = tie_pair(cut, ball)
    ties = [(CX + r * math.cos(math.radians(ad)), CY + r * math.sin(math.radians(ad))),
            (CX - r * math.cos(math.radians(ad)), CY - r * math.sin(math.radians(ad)))]
    out = [(list(Point(CX, CY).buffer(TUN_FBORE / 2, 96).exterior.coords), "exit bore")]
    out += [(list(Point(p).buffer(M5 / 2, 48).exterior.coords), "tie-down M5") for p in ties]
    mount = [(10 + MOUNT_STEP * i, MOUNT_Y) for i in range(int((STOCK - 20) // MOUNT_STEP) + 1)]
    out += [(list(Point(p).buffer(M5 / 2, 48).exterior.coords), "mount M5") for p in mount]
    return out, ties, (r, ad, margin), mount


def exit_flange(tie):
    """the wire-track flange that goes UNDER the sheet's exit bore: bore, wire notches, stitch holes as the standard
    flange, but bolted through the sheet's two tie-down M5 (the standard 8-bolt ring can't clear the curl)"""
    r, ad, _ = tie
    plate = box(-FLANGE_HALF, -FLANGE_HALF, FLANGE_HALF, FLANGE_HALF).buffer(-2, join_style=2).buffer(2, 16)
    cuts = [Point(0, 0).buffer(TUN_FBORE / 2, 96)]
    for a in (45, 135, 225, 315):
        u = (math.cos(math.radians(a)), math.sin(math.radians(a)))
        cuts.append(LineString([(0, 0), (TUN_NOTCH_OUT * u[0], TUN_NOTCH_OUT * u[1])]).buffer(TUN_HOLE / 2, cap_style=2))
        cuts.append(Point(TUN_SR * u[0], TUN_SR * u[1]).buffer(TUN_HOLE / 2, 24))
    for sgn in (1, -1):
        cuts.append(Point(sgn * r * math.cos(math.radians(ad)), sgn * r * math.sin(math.radians(ad))).buffer(M5 / 2, 48))
    return plate.difference(unary_union(cuts))


def entry_flange():
    """the cropped wire-track flange (u across the tunnel, v up from the sheet), bore centre at (0, NO_DROP_AXIS).
    Its bottom edge sits on the sheet: the bore and the two lower wire notches open through it."""
    v0 = NO_DROP_AXIS
    plate = box(-FLANGE_HALF, 0, FLANGE_HALF, v0 + FLANGE_HALF)
    plate = plate.buffer(-2, join_style=2).buffer(2, 16).union(box(-FLANGE_HALF + 2, 0, FLANGE_HALF - 2, 2))
    cuts = [Point(0, v0).buffer(TUN_FBORE / 2, 96)]
    for a in (45, 135, 225, 315):
        u = (math.cos(math.radians(a)), math.sin(math.radians(a)))
        end = TUN_NOTCH_OUT if a < 180 else (v0 + 1) / abs(u[1])          # lower notches run out through the bottom
        cuts.append(LineString([(0, v0), (end * u[0], v0 + end * u[1])]).buffer(TUN_HOLE / 2, cap_style=2))
        s = (TUN_SR * u[0], v0 + TUN_SR * u[1])
        if s[1] - TUN_HOLE / 2 > 4:
            cuts.append(Point(s).buffer(TUN_HOLE / 2, 24))
    bolts = [(sx * FLANGE_BOLT, v0 + sy * FLANGE_BOLT) for sx in (-1, 0, 1) for sy in (0, 1) if (sx, sy) != (0, 0)]
    cuts += [Point(b).buffer(M5 / 2, 48) for b in bolts]
    g = plate.difference(unary_union(cuts))
    if g.geom_type == "MultiPolygon":
        g = max(g.geoms, key=lambda q: q.area)     # slivers between the opened bore and the lower notches fall out
    return g, bolts


def emit(path_stem, polys_closed, opens, mat, title, notes, out_dir, shift=(0.0, 0.0), outline=None):
    T, kerf, _ = gcode.fit(mat)
    job = gcode.job(mat, min_segment_mm=0.3)
    cuts = [gcode.Polyline(list(Polygon(p).buffer(-kerf / 2, join_style=2).exterior.coords), True) for p in polys_closed]
    cuts += [gcode.Polyline(o, False) for o in opens]
    if outline is not None:
        cuts.append(gcode.Polyline(list(outline.buffer(kerf / 2, join_style=2).exterior.coords), True))
    cuts = gcode.order(cuts)
    cuts = [gcode.Polyline([(x + shift[0], y + shift[1]) for x, y in c.points], c.closed) for c in cuts]
    lines = gcode.preamble(job, title=title, notes=notes + [f"{mat}: T {T}, kerf {kerf}"])
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(out_dir / f"{path_stem}_{mat}.gcode", lines)
    mins = sum(LineString(c.points).length * job.passes for c in cuts) / job.feed_mm_per_min
    return p, len(cuts), mins


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--material", nargs="+", default=["ply3", "mdf3", "birch3"])
    ap.add_argument("--pitch", type=float, default=PITCH)
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    cut, ball, laps, length = spiral(a.pitch)
    hole_list, ties, tie, mount = holes(cut, ball)
    ex = exit_flange(tie)
    fl, fl_bolts = entry_flange()
    print(f"spiral: {laps:.1f} laps + {CURL_DEG:g} deg curl, {length / 1000:.2f} m of cut; tie-down M5 pair at r {tie[0]:g}, "
          f"{tie[1]} / {tie[1] + 180} deg ({tie[2] + HEAD_CLEAR:.1f} from the ball's centre line at the closest); "
          f"no-drop axis {NO_DROP_AXIS:.2f}")
    for mat in a.material:
        p, n, mins = emit("spiral_run_300x290", [h for h, _ in hole_list], [cut], mat,
                          "spiral_run -- marbles/clock/spiral_run.py: ONE spiral cut on 300 x 300 stock (no outline cut)",
                          [f"pitch {a.pitch:g}, {laps:.1f} laps + a {CURL_DEG:g} deg curl into the exit bore; "
                           f"{length / 1000:.2f} m of cut",
                           "X0 Y0 = the stock's corner, the MOUNT edge toward the front (Y0); in use that edge is the top",
                           f"centre: exit bore 23.1, enclosed; tie-down M5 pair at r {tie[0]:g} ({tie[1]} / {tie[1] + 180} deg), "
                           "clear of the ball: they also hold the exit flange underneath"],
                          a.out)
        print(f"{p.name}: {n} cuts, ~{mins:.0f} min")
        g = fl.buffer(0)
        x0, y0 = g.bounds[0], g.bounds[1]
        p, n, mins = emit(gcode.name("spiral_entry_flange", g.bounds[2] - x0 + 0.1, g.bounds[3] - y0 + 0.1, mat).rsplit("_", 1)[0],
                          [list(r.coords) for r in g.interiors], [], mat,
                          "spiral_entry_flange -- marbles/clock/spiral_run.py: cropped wire-track flange, bottom edge on the sheet",
                          [f"bore centre {NO_DROP_AXIS:.2f} above the bottom edge: a ball on the tunnel's lower wires is at shelf level",
                           "lower notches open through the bottom edge; bolts to the side of a 2020 post (M5 at u -20)"],
                          a.out, shift=(-x0 + 0.05, -y0 + 0.05), outline=Polygon(g.exterior.coords))
        print(f"{p.name}: {n} cuts, ~{mins:.1f} min")
        p, n, mins = emit(gcode.name("spiral_exit_flange", 2 * FLANGE_HALF + 0.1, 2 * FLANGE_HALF + 0.1, mat).rsplit("_", 1)[0],
                          [list(r.coords) for r in ex.interiors], [], mat,
                          "spiral_exit_flange -- marbles/clock/spiral_run.py: wire-track flange under the exit bore",
                          ["bore / notches / stitch holes as the standard flange; M5 = the sheet's tie-down pair"],
                          a.out, shift=(FLANGE_HALF + 0.05, FLANGE_HALF + 0.05), outline=Polygon(ex.exterior.coords))
        print(f"{p.name}: {n} cuts, ~{mins:.1f} min")


if __name__ == "__main__":
    main()
