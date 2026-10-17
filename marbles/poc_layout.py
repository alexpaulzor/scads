#!/usr/bin/env python3
"""Lay out the proof-of-concept wire marble run and write marbles/poc_path.scad.

Layout (plan view, board origin at a corner, z up from the board's top):

* A spiral lift in the middle of the board raises marbles to z_exit.
* An exit feeder runs east from the lift, then turns north onto the east
  side of a rounded-square "lap" loop around the board.
* The track descends counter-clockwise around that loop, lap after lap,
  every lap stacked on the one below, clipped to 4 corner posts.
* After the last lap it peels off the south side, turns north and rolls into
  the lift's pickup pocket at z_entry.

The slope is adjusted so the drop is a whole number of laps; the script then
checks that every stacked lap clears the one beneath it.

All dimensions are mm. Marble/wire/clip constants mirror wire_track.scad and
the lift constants mirror spiral_lift.scad; poc_run.scad asserts that the
lift entry/exit points written here match the lift it draws.

Usage:
  python3 marbles/poc_layout.py                 # defaults, writes poc_path.scad
  python3 marbles/poc_layout.py --slope 0.035 --z-exit 400
"""

import argparse
import math
import os

# --- wire_track.scad ---
MARBLE_OD = 16.2
WIRE_OD = 2.1
GAUGE = 10
RUN_CLR = 1.0
SEAT_R = WIRE_OD / 2 + 0.1
WALL = 2
TAB_L = 10
MARBLE_R = MARBLE_OD / 2
RAIL_R = MARBLE_R + WIRE_OD / 2
GUARD_R = RAIL_R + RUN_CLR
FLOOR_A = math.degrees(math.asin(GAUGE / 2 / RAIL_R))
# rail3 clip: tallest saddle used on the laps
R_OUT_RAIL3 = GUARD_R + SEAT_R + WALL
R_OUT_OPEN2 = RAIL_R + SEAT_R + WALL

# --- spiral_lift.scad ---
COIL_R = 14
COIL_BETA = 40


def parse_args():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--board", type=float, default=300)
    p.add_argument("--inset", type=float, default=30,
                   help="board edge to lap centerline")
    p.add_argument("--corner-r", type=float, default=45)
    p.add_argument("--slope", type=float, default=0.03,
                   help="target slope (drop/run); adjusted to whole laps")
    p.add_argument("--z-exit", type=float, default=270,
                   help="marble center height leaving the lift")
    p.add_argument("--z-entry", type=float, default=45,
                   help="marble center height in the lift pickup pocket")
    p.add_argument("--pocket-gap", type=float, default=6,
                   help="feeder rails stop this far short of the pickup point")
    p.add_argument("--post-d", type=float, default=4)
    p.add_argument("--margin", type=float, default=4,
                   help="extra vertical room between stacked laps")
    p.add_argument("--arc-step", type=float, default=7.5, help="degrees")
    p.add_argument("-o", "--out", default=os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "poc_path.scad"))
    return p.parse_args()


class Path:
    """Plan-view polyline with headings, built from straights and left arcs."""

    def __init__(self, x, y, heading_deg):
        self.pts = [(x, y)]
        self.h = heading_deg
        self.seg_style = []
        self.length = 0.0
        self.marks = []  # (point index, kind)

    @property
    def pos(self):
        return self.pts[-1]

    def straight_to(self, length, style="open2", mid_clip=True):
        x, y = self.pos
        hx, hy = math.cos(math.radians(self.h)), math.sin(math.radians(self.h))
        if mid_clip:
            self.pts.append((x + hx * length / 2, y + hy * length / 2))
            self.seg_style.append(style)
            self.marks.append((len(self.pts) - 1, "mid"))
        self.pts.append((x + hx * length, y + hy * length))
        self.seg_style.append(style)
        self.length += length

    def left_arc(self, r, deg, step, style="rail3", kind="corner"):
        x, y = self.pos
        h0 = self.h
        cx = x - r * math.sin(math.radians(h0))
        cy = y + r * math.cos(math.radians(h0))
        n = max(1, round(deg / step))
        for i in range(1, n + 1):
            h = h0 + deg * i / n
            self.pts.append((cx + r * math.sin(math.radians(h)),
                             cy - r * math.cos(math.radians(h))))
            self.seg_style.append(style)
            if i == n // 2 and kind:
                self.marks.append((len(self.pts) - 1, kind))
        self.h = h0 + deg
        self.length += math.radians(deg) * r
        return cx, cy


def headings(pts):
    out = []
    for i in range(len(pts)):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, len(pts) - 1)]
        d = math.hypot(b[0] - a[0], b[1] - a[1])
        out.append(((b[0] - a[0]) / d, (b[1] - a[1]) / d))
    return out


def build(a, laps):
    c = a.board / 2
    lo, hi = a.inset, a.board - a.inset
    r = a.corner_r
    side = hi - lo - 2 * r
    m = COIL_R + RAIL_R * math.sin(math.radians(COIL_BETA))  # marble radius on lift
    exit_x0 = c + m + RAIL_R * math.cos(math.radians(FLOOR_A))
    entry_x = c + m

    p = Path(exit_x0, c, 0)
    # exit feeder: east, then left onto the east side
    p.straight_to(hi - r - exit_x0, mid_clip=True)
    p.left_arc(r, 90, a.arc_step, kind="free")
    first_lap = len(p.pts) - 1
    # east side remainder up to the NE corner
    p.straight_to(hi - r - p.pos[1], mid_clip=False)
    corners = []
    for _ in range(laps):
        for leg in range(4):
            corners.append(p.left_arc(r, 90, a.arc_step))
            p.straight_to(side)
    # Final 3/4 lap: NE, NW, SW corners, then peel off the south side.
    for leg in range(3):
        corners.append(p.left_arc(r, 90, a.arc_step))
        if leg < 2:
            p.straight_to(side)
    # south side, heading east, up to the turn-in arc
    p.straight_to(entry_x - r - p.pos[0], mid_clip=True)
    p.left_arc(r, 90, a.arc_step, kind="stub")
    p.straight_to(c - a.pocket_gap - p.pos[1], mid_clip=True)
    return p, first_lap, exit_x0, entry_x, m


def main():
    a = parse_args()
    drop = a.z_exit - a.z_entry
    # length of the non-lap part of the route
    p0, *_ = build(a, 0)
    lap_len = 4 * (a.board - 2 * a.inset - 2 * a.corner_r) + 2 * math.pi * a.corner_r
    need = R_OUT_RAIL3 + MARBLE_R + a.margin
    # stacked laps need at least `need` of drop per lap; round laps down so the
    # slope never falls below the target
    min_slope = max(a.slope, need / lap_len)
    laps = max(0, math.floor((drop / min_slope - p0.length) / lap_len))
    p, first_lap, exit_x0, entry_x, m = build(a, laps)
    slope = drop / p.length

    # z along the path (marble center)
    zs, s = [a.z_exit], 0.0
    for i in range(1, len(p.pts)):
        s += math.dist(p.pts[i - 1], p.pts[i])
        zs.append(a.z_exit - s * slope)
    svals = [0.0]
    for i in range(1, len(p.pts)):
        svals.append(svals[-1] + math.dist(p.pts[i - 1], p.pts[i]))

    # stacked-lap clearance: densely resample, compare points that are
    # close in plan but far apart along the track
    dense = []
    for i in range(1, len(p.pts)):
        (x0, y0), (x1, y1) = p.pts[i - 1], p.pts[i]
        n = max(1, int(math.dist((x0, y0), (x1, y1)) / 5))
        for k in range(n):
            t = k / n
            dense.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t,
                          zs[i - 1] + (zs[i] - zs[i - 1]) * t,
                          svals[i - 1] + (svals[i] - svals[i - 1]) * t))
    # a clip (clip_th along the track) can only hit a marble on the lap below
    # if they are within about a marble radius along the track
    near = MARBLE_R + 3
    worst = None
    for i in range(len(dense)):
        xi, yi, zi, si = dense[i]
        for j in range(i + 1, len(dense)):
            xj, yj, zj, sj = dense[j]
            if sj - si < 150:
                continue
            if math.hypot(xi - xj, yi - yj) < near:
                dz = abs(zi - zj)
                if worst is None or dz < worst[0]:
                    worst = (dz, (round(xi, 1), round(yi, 1)))

    hs = headings(p.pts)
    # right-hand side of travel (outside of the left turns)
    rights = [(hy, -hx) for hx, hy in hs]

    # clips: corners get side_post clips (tab outward to a corner post),
    # straights get free gauge-keeping clips, the bottom feeder gets
    # stub posts down into the board.
    post_c = R_OUT_RAIL3 + TAB_L - (a.post_d / 2 + WALL)
    clips, posts = [], {}
    for idx, kind in p.marks:
        x, y = p.pts[idx]
        hx, hy = hs[idx]
        rx, ry = rights[idx]
        style = p.seg_style[min(idx, len(p.seg_style) - 1)]
        if kind == "corner":
            mount, tab_a = "side_post", 90
            px, py = round(x + rx * post_c, 1), round(y + ry * post_c, 1)
            posts.setdefault((px, py), 0)
            posts[(px, py)] = max(posts[(px, py)], zs[idx] + 20)
        elif kind == "stub" or zs[idx] < a.z_entry + 25:
            mount, tab_a = "post", 0
        else:
            mount, tab_a = "none", 0
        clips.append((x, y, zs[idx], hx, hy, style, mount, tab_a))

    wire = {"left floor": 0.0, "right floor": 0.0, "guard": 0.0}
    for i in range(1, len(p.pts)):
        for name, off in (("left floor", -GAUGE / 2), ("right floor", GAUGE / 2)):
            a0 = (p.pts[i - 1][0] + rights[i - 1][0] * off, p.pts[i - 1][1] + rights[i - 1][1] * off)
            a1 = (p.pts[i][0] + rights[i][0] * off, p.pts[i][1] + rights[i][1] * off)
            wire[name] += math.hypot(math.dist(a0, a1), zs[i] - zs[i - 1])
        if p.seg_style[i - 1] == "rail3":
            a0 = (p.pts[i - 1][0] + rights[i - 1][0] * GUARD_R, p.pts[i - 1][1] + rights[i - 1][1] * GUARD_R)
            a1 = (p.pts[i][0] + rights[i][0] * GUARD_R, p.pts[i][1] + rights[i][1] * GUARD_R)
            wire["guard"] += math.hypot(math.dist(a0, a1), zs[i] - zs[i - 1])

    with open(a.out, "w") as f:
        f.write("// GENERATED by poc_layout.py -- do not edit; rerun the script.\n")
        f.write(f"// args: {vars(a)}\n")
        f.write(f"poc_board = {a.board};\n")
        f.write(f"poc_lift_c = [{a.board / 2}, {a.board / 2}];\n")
        f.write(f"poc_exit_x0 = {exit_x0:.4f};\npoc_entry_x = {entry_x:.4f};\n")
        f.write(f"poc_z_exit = {a.z_exit};\npoc_z_entry = {a.z_entry};\n")
        f.write(f"poc_post_d = {a.post_d};\npoc_slope = {slope:.6f};\npoc_laps = {laps};\n")
        f.write("poc_pts = [\n" + ",\n".join(
            f"  [{x:.3f}, {y:.3f}, {z:.3f}]" for (x, y), z in zip(p.pts, zs)) + "];\n")
        f.write("poc_right = [\n" + ",\n".join(
            f"  [{rx:.5f}, {ry:.5f}]" for rx, ry in rights) + "];\n")
        f.write("poc_seg_style = [" + ", ".join(f'"{s}"' for s in p.seg_style) + "];\n")
        f.write("// [x, y, z, heading_x, heading_y, style, mount, tab_a]\npoc_clips = [\n" + ",\n".join(
            f'  [{x:.3f}, {y:.3f}, {z:.3f}, {hx:.5f}, {hy:.5f}, "{st}", "{mo}", {ta}]'
            for x, y, z, hx, hy, st, mo, ta in clips) + "];\n")
        f.write("// [x, y, height]\npoc_posts = [\n" + ",\n".join(
            f"  [{x}, {y}, {h:.1f}]" for (x, y), h in posts.items()) + "];\n")

    n_mount = {}
    for c in clips:
        n_mount[c[6]] = n_mount.get(c[6], 0) + 1
    print(f"wrote {a.out}")
    print(f"laps: {laps}  (lap length {lap_len:.1f})")
    print(f"track length: {p.length:.1f} mm, drop: {drop:.1f} mm, slope: {slope * 100:.3f} %")
    print(f"drop per lap: {lap_len * slope:.2f} mm")
    print(f"stacked-lap clearance needed: {need:.2f} mm "
          f"(rail3 clip r_out {R_OUT_RAIL3:.2f} + marble_r {MARBLE_R:.2f} + margin {a.margin})")
    if worst:
        print(f"stacked-lap clearance worst: {worst[0]:.2f} mm near {worst[1]}"
              f" -> {'OK' if worst[0] >= need else 'TOO TIGHT'}")
    print("wire per rail (mm): " + ", ".join(f"{k} {v:.0f}" for k, v in wire.items()))
    print(f"clips: {len(clips)} " + str(n_mount))
    print("corner posts [x, y, height]: " + ", ".join(
        f"[{x}, {y}, {h:.1f}]" for (x, y), h in posts.items()))


if __name__ == "__main__":
    main()
