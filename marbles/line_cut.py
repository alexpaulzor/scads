#!/usr/bin/env python3
"""One straight laser cut between two points, with the material's recipe: warmup lead-in, then the
recipe's passes back and forth along the line, laser off, park. Coordinates are WORK coordinates of
whatever zero you'll run it from (e.g. the front button's G54 = the bed origin).

    python3 marbles/line_cut.py X0 Y0 X1 Y1 [--material mdf3] [--overrun 1] [--name trim]
    # -> marbles/gcode/<name>_<W>x<H>_<material>.gcode

--overrun extends the line past both ends (mm), so it fully crosses a part whose outline is
already cut.
"""
import argparse
import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from laser_parts import emit_cut, load_profile, preamble, std_path  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("x0", type=float)
ap.add_argument("y0", type=float)
ap.add_argument("x1", type=float)
ap.add_argument("y1", type=float)
ap.add_argument("--material", default="mdf3")
ap.add_argument("--overrun", type=float, default=1.0)
ap.add_argument("--name", default="line_cut")
ap.add_argument("--note", default="")
a = ap.parse_args()

L = math.hypot(a.x1 - a.x0, a.y1 - a.y0)
ux, uy = (a.x1 - a.x0) / L, (a.y1 - a.y0) / L
p0 = (a.x0 - ux * a.overrun, a.y0 - uy * a.overrun)
p1 = (a.x1 + ux * a.overrun, a.y1 + uy * a.overrun)
s2g, motion, mat, job = load_profile(a.material, 1000, None)
cut = s2g.Polyline([p0, p1], False)
lines = [f"; {a.name} -- marbles/line_cut.py: one line X{p0[0]:.3f} Y{p0[1]:.3f} -> X{p1[0]:.3f} Y{p1[1]:.3f} "
         f"({L:.2f} mm + {a.overrun:g} overrun each end)" + (f"; {a.note}" if a.note else ""),
         f"; {mat['id']} recipe {job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes} (back and forth); "
         f"WORK coordinates: run it from the zero named in the note", ";"]
lines += preamble(s2g, job)
lines += emit_cut(s2g, motion, cut, 1, 1, job)
lines += s2g._footer(lines)
out = std_path(HERE / "gcode", a.name, lines, mat["id"])
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text("\n".join(lines))
print(f"wrote {out.name}: X{p0[0]:.3f} Y{p0[1]:.3f} -> X{p1[0]:.3f} Y{p1[1]:.3f}, {job.passes} passes at F{job.feed_mm_per_min}")
