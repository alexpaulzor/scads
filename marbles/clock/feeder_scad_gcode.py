#!/usr/bin/env python3
"""G-code for every part of feeder.scad: one file per part, longest side along X,
named feeder_<part>_<W>x<H>.gcode (cut outline rounded up to whole mm).

Thickness, kerf and slot fit come from the material profile and are passed into the
SCAD (-D T=, KERF=, FIT=), so the model and the cut files always agree. The script
also prints feeder.scad's CHECK report and refuses to write files if it has a WARN
line (use --force to write anyway).

    python3 marbles/clock/feeder_scad_gcode.py
    python3 marbles/clock/feeder_scad_gcode.py --material plywood_veneer_3ply_3mm
"""
import argparse
import math
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from shapely import affinity
from shapely.geometry import Polygon

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import emit_cut, load_profile, material_fit, preamble  # noqa: E402

SCAD = HERE / "feeder.scad"
ap = argparse.ArgumentParser()
ap.add_argument("--material", default="mdf_3mm")
ap.add_argument("--openscad", default="openscad")
ap.add_argument("--force", action="store_true", help="write files even if the CHECK report has WARN lines")
ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
args = ap.parse_args()

T, KERF, FIT = material_fit(args.material)
DEFS = ["-D", f"T={T}", "-D", f"KERF={KERF}", "-D", f"FIT={FIT}"]


def scad(extra, out):
    r = subprocess.run([args.openscad, "-o", str(out)] + DEFS + extra + [str(SCAD)], capture_output=True, text=True)
    if r.returncode != 0 or not Path(out).exists():
        sys.exit(f"openscad failed:\n{r.stderr}")
    return r.stderr


with tempfile.TemporaryDirectory() as td:
    td = Path(td)
    log = scad(["-D", 'part="funnel"'], td / "check.svg")
    echoes = [m for m in re.findall(r'ECHO: (.*)', log)]
    parts = re.findall(r'"([^"]+)"', next(e for e in echoes if e.startswith("parts")))
    report = [e.strip('"') for e in echoes if not e.startswith("parts")]
    print("\n".join(report))
    if any(line.startswith("WARN") for line in report) and not args.force:
        sys.exit("feeder.scad CHECK has WARN lines: fix them (or --force)")

    s2g, motion, mat, job = load_profile(args.material, 1000, None)
    args.out.mkdir(parents=True, exist_ok=True)
    for p in parts:
        if p.startswith("wall:"):
            _, i, name = p.split(":")
            extra = ["-D", 'part="wall"', "-D", f"wall_i={i}"]
            slug = f"feeder_wall_{name}"
        else:
            extra = ["-D", f'part="{p}"']
            slug = f"feeder_{p}"
        svg = td / f"{slug}.svg"
        scad(extra + ["-D", "laser=true"], svg)
        lines, u = s2g.parse_svg(svg.read_text())
        loops = [[(x * u, -y * u) for x, y in pl.points] for pl in lines]      # OpenSCAD SVG is y-down
        polys = [Polygon(pl) for pl in loops]
        outer = max(range(len(polys)), key=lambda i: abs(polys[i].area))
        g = Polygon(loops[outer], [loops[i] for i in range(len(loops)) if i != outer])
        if g.bounds[3] - g.bounds[1] > g.bounds[2] - g.bounds[0]:
            g = affinity.rotate(g, 90, origin=(0, 0))
        g = affinity.translate(g, -g.bounds[0], -g.bounds[1])
        w, h = g.bounds[2], g.bounds[3]
        name = f"{slug}_{math.ceil(w - 1e-9)}x{math.ceil(h - 1e-9)}"
        holes = sorted([list(r.coords) for r in g.interiors], key=lambda pl: abs(Polygon(pl).area))
        cuts = [s2g.Polyline(pl, True) for pl in holes + [list(g.exterior.coords)]]
        gl = [f"; {name} -- marbles/clock/feeder.scad via feeder_scad_gcode.py",
              f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
              f"kerf {KERF}, fit {FIT}; X0 Y0 = bottom-left; {w:.2f} x {h:.2f} mm (longest side along X)",
              f"; {len(holes)} holes/slots first, then the outline", ";"]
        gl += preamble(s2g, job)
        for i, c in enumerate(cuts, 1):
            gl += emit_cut(s2g, motion, c, i, len(cuts), job)
        gl += s2g._footer()
        (args.out / f"{name}.gcode").write_text("\n".join(gl))
        print(f"wrote {name}.gcode: {w:.2f} x {h:.2f} mm, {len(holes)} holes/slots")
