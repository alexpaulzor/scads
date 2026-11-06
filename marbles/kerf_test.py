#!/usr/bin/env python3
"""Kerf test: one zig-zag cut makes N parallel lines, then a box cut frees the strips.

    lines at x = 0, P, 2P, ... (N of them), each running OVER mm past the box
    the zig-zag's turnarounds sit outside the box, in scrap
    box: one pitch outside the first and last line, so every strip
    (N - 1 between lines + 2 at the edges = N + 1) is cut on both long
    sides and is P - kerf wide

Stack any 10 strips and measure across the stack:
    kerf = (10 * P - stack) / 10
or mic one strip: kerf = P - strip.

No kerf compensation: the beam runs on the drawn lines. Zeroed at the
bottom-left of everything the laser fires on.

    python3 marbles/kerf_test.py                  # 10 lines, 5 mm pitch
    python3 marbles/kerf_test.py --pitch 4 --lines 12 --length 30
"""

import argparse
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from laser_parts import emit_cut, find_quickcut, preamble, std_path, gcode  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--lines", type=int, default=10)
    ap.add_argument("--pitch", type=float, default=5.0, help="line spacing, mm")
    ap.add_argument("--length", type=float, default=40.0, help="strip length, mm")
    ap.add_argument("--over", type=float, default=3.0,
                    help="lines run this far past the box; turnarounds live there")
    ap.add_argument("--material", default="ply3")
    ap.add_argument("--s-full-power", type=int, default=1000, help="GRBL $30")
    ap.add_argument("--quickcut", help="path to cnc_vibes/quickcut")
    ap.add_argument("-o", "--out", type=Path, default=HERE / "gcode" / "kerf_test.gcode")
    a = ap.parse_args()

    sys.path.insert(0, str(find_quickcut(a.quickcut)))
    import svg2gcode as s2g  # noqa: E402
    import motion  # noqa: E402
    from materials import SHARED_MATERIALS  # noqa: E402
    import yaml  # noqa: E402

    mats = {m["id"]: m for m in yaml.safe_load(Path(SHARED_MATERIALS).read_text())}
    if a.material not in mats:
        sys.exit(f"unknown material {a.material}")
    r = mats[a.material]["laser"]
    job = s2g.CutJob(feed_mm_per_min=r["feed_mm_per_min"], power_percent=r["power_percent"],
                     passes=r.get("passes", 1), material_id=a.material,
                     s_full_power=a.s_full_power)

    P, L, o, n = a.pitch, a.length, a.over, a.lines
    # frame: box from (0,0) to (W, L) with lines at x = P .. n*P;
    # turnarounds at y = -o / L + o, so shift everything up by o at the end
    zig = []
    for i in range(n):
        x = P * (i + 1)
        ys = (-o, L + o) if i % 2 == 0 else (L + o, -o)
        zig += [(x, ys[0]), (x, ys[1])]
    W = P * (n + 1)
    box = [(0, 0), (W, 0), (W, L), (0, L), (0, 0)]
    shift = lambda pts: [(x, y + o) for x, y in pts]  # noqa: E731
    cuts = [s2g.Polyline(shift(zig), False), s2g.Polyline(shift(box), True)]

    strips = n + 1
    stack_n = min(10, strips)
    g = [f"; kerf test -- {n} lines {P:g} mm apart, {L:g} mm strips, {strips} strips",
         f"; X0 Y0 = bottom-left of the zig-zag turnarounds; extent "
         f"{W:.2f} x {L + 2 * o:.2f} mm",
         f"; box (strips) X0..{W:.2f} Y{o:.2f}..{L + o:.2f}",
         f"; each strip = {P:g} - kerf; stack {stack_n}: kerf = "
         f"({stack_n * P:g} - stack) / {stack_n}",
         ";"]
    g += preamble(s2g, job)
    for i, c in enumerate(cuts, 1):
        g += emit_cut(s2g, motion, c, i, len(cuts), job)
    a.out.parent.mkdir(parents=True, exist_ok=True)
    if a.out.parent == HERE / "gcode" and a.out.stem in ("kerf_test", "ring_jig"):   # default: standard name
        a.out = std_path(a.out.parent, a.out.stem, g, a.material)
    gcode.write(a.out, g)
    print(f"{a.out.name}: {W:.2f} x {L + 2 * o:.2f} mm, {strips} strips of "
          f"{P:g} x {L:g} mm nominal; stack {stack_n}: kerf = "
          f"({stack_n * P:g} - stack) / {stack_n}")


if __name__ == "__main__":
    main()
