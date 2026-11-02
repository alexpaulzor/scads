#!/usr/bin/env python3
"""Ball lift sieve strip: one 300 x 46 mm board, laid along X for cutting.

Across the width (Y), from the edge that bolts to the 2020:
  0..20   mounting band, M5 clearance holes on its centreline (Y = 10)
  20..40  20 mm ball holes, centred at Y = 30
  40..46  6 mm edge (fits a 2020 slot if wanted)
Along the length (X): ball holes every PITCH mm, starting PITCH/2 from the
end; M5 holes 10 mm from each end and evenly in between, at most
M5_MAX_GAP apart.

    python3 marbles/clock/lift_sieve.py        # writes marbles/gcode/lift_sieve.gcode
"""

import math
import sys
from pathlib import Path

from shapely.geometry import Point, Polygon
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import emit_cut, load_profile, preamble  # noqa: E402

LENGTH = 300.0
WIDTH = 46.0
BALL_HOLE = 20.0
BALL_Y = 30.0
PITCH = 30.0
M5_HOLE = 5.3            # clearance for M5
M5_Y = 10.0
M5_END = 10.0
M5_MAX_GAP = 100.0
KERF = 0.105             # measured (marbles/kerf_test.py)


def part():
    board = Polygon([(0, 0), (LENGTH, 0), (LENGTH, WIDTH), (0, WIDTH)])
    n_ball = int(LENGTH // PITCH)
    balls = [Point(PITCH / 2 + i * PITCH, BALL_Y).buffer(BALL_HOLE / 2, 128) for i in range(n_ball)]
    span = LENGTH - 2 * M5_END
    n_gap = math.ceil(span / M5_MAX_GAP)
    m5 = [Point(M5_END + i * span / n_gap, M5_Y).buffer(M5_HOLE / 2, 48) for i in range(n_gap + 1)]
    return board.difference(unary_union(balls + m5)), n_ball, n_gap + 1, span / n_gap


def main():
    s2g, motion, mat, job = load_profile("plywood_veneer_3ply_3mm", 1000, None)
    geom, n_ball, n_m5, gap = part()
    g = geom.buffer(KERF / 2, join_style=2)     # kept part grows by half a kerf, holes shrink
    x0, y0 = g.bounds[0], g.bounds[1]
    loops = [list(g.exterior.coords)] + [list(h.coords) for h in g.interiors]
    loops = [[(x - x0, y - y0) for x, y in pl] for pl in loops]
    loops.sort(key=lambda pl: abs(Polygon(pl).area))   # holes first, outline last
    cuts = [s2g.Polyline(pl, True) for pl in loops]
    w, h = g.bounds[2] - x0, g.bounds[3] - y0
    lines = [f"; lift_sieve -- marbles/clock/lift_sieve.py; {mat['id']} ({mat['thickness_mm']} mm)",
             f"; X0 Y0 = bottom-left corner; {w:.2f} x {h:.2f} mm (kerf {KERF})",
             f"; {n_ball} ball holes d{BALL_HOLE:g} at Y{BALL_Y:g}, every {PITCH:g} mm; "
             f"{n_m5} M5 holes d{M5_HOLE:g} at Y{M5_Y:g}, {gap:.2f} mm apart",
             ";"]
    lines += preamble(s2g, job)
    for i, c in enumerate(cuts, 1):
        lines += emit_cut(s2g, motion, c, i, len(cuts), job)
    lines += s2g._footer()
    out = HERE.parent / "gcode" / "lift_sieve.gcode"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines))
    print(f"{out.name}: {w:.2f} x {h:.2f} mm, {n_ball} ball holes, {n_m5} M5 holes {gap:.2f} mm apart, {len(cuts)} cuts")


if __name__ == "__main__":
    main()
