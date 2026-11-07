#!/usr/bin/env python3
"""G-code for every part of feeder.scad: one file per part, longest side along X,
named feeder_<part>_<W>x<H>.gcode (cut outline rounded up to whole mm).

Thickness, kerf and slot fit come from the material profile and are passed into the
SCAD (-D T=, KERF=, FIT=), so the model and the cut files always agree. The script
also prints feeder.scad's CHECK report and refuses to write files if it has a WARN
line (use --force to write anyway).

    python3 marbles/clock/feeder_scad_gcode.py
    python3 marbles/clock/feeder_scad_gcode.py --material ply3
"""
import argparse
import math
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import emit_cut, load_profile, material_fit, preamble, gcode  # noqa: E402

SCAD = HERE / "feeder.scad"
ap = argparse.ArgumentParser()
ap.add_argument("--material", default="mdf3")
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

    # knock-outs: parts whose port outline is cut with uncut bridges (feeder.scad KNOCK-OUT PORT)
    knockouts = re.findall(r'"([^"]+)"', next((e for e in echoes if e.startswith("knockouts")), ""))
    kb = next((e for e in echoes if e.startswith("ko_bridges")), "")
    nums = [float(v) for v in re.findall(r"-?[\d.]+", kb)]
    ko_width = nums[-1] if nums else 0.0                       # "ko_bridges = [[x, y], ...], ko_bridge = w"
    ko_pts = [(nums[i], nums[i + 1]) for i in range(0, len(nums) - 1, 2)]
    ko_loop = None
    if knockouts:
        scad(["-D", 'part="knockout"'], td / "knockout.svg")
        s2g_, _, _, _ = load_profile(args.material, 1000, None)
        kl, ku = s2g_.parse_svg((td / "knockout.svg").read_text())
        ko_loop = [(x * ku, -y * ku) for x, y in kl[0].points]

    def knockout_paths(rot, dx, dy):
        """the knock-out's outline as open paths, a bridge (ko_width + kerf of path gap) left at each ko point"""
        line = LineString(ko_loop + [ko_loop[0]])
        pts = [Point(q) for q in ko_pts]
        if rot:
            line = affinity.rotate(line, 90, origin=(0, 0))
            pts = [affinity.rotate(q, 90, origin=(0, 0)) for q in pts]
        line = affinity.translate(line, dx, dy)
        pts = [affinity.translate(q, dx, dy) for q in pts]
        return gcode.bridged(list(line.coords), [q.coords[0] for q in pts], ko_width, KERF)

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
        rot = g.bounds[3] - g.bounds[1] > g.bounds[2] - g.bounds[0]
        if rot:
            g = affinity.rotate(g, 90, origin=(0, 0))
        dx, dy = -g.bounds[0], -g.bounds[1]
        g = affinity.translate(g, dx, dy)
        w, h = g.bounds[2], g.bounds[3]
        name = f"{slug}_{math.ceil(w - 1e-9)}x{math.ceil(h - 1e-9)}_{args.material}"
        holes = sorted([list(r.coords) for r in g.interiors], key=lambda pl: abs(Polygon(pl).area))
        ko = knockout_paths(rot, dx, dy) if p in knockouts else []
        cuts = [s2g.Polyline(pl, True) for pl in holes] + ko + [s2g.Polyline(list(g.exterior.coords), True)]
        gl = [f"; {name} -- marbles/clock/feeder.scad via feeder_scad_gcode.py",
              f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
              f"kerf {KERF}, fit {FIT}; X0 Y0 = bottom-left; {w:.2f} x {h:.2f} mm (longest side along X)",
              f"; {len(holes)} holes/slots first" + (f", then the knock-out port's outline in {len(ko)} pieces "
              f"({len(ko)} bridges of {ko_width:g} left uncut: snap it out on the side you use)" if ko else "")
              + ", then the outline", ";"]
        gl += preamble(s2g, job)
        for i, c in enumerate(cuts, 1):
            gl += emit_cut(s2g, motion, c, i, len(cuts), job)
        gcode.write((args.out / f"{name}.gcode"), gl)
        print(f"wrote {name}.gcode: {w:.2f} x {h:.2f} mm, {len(holes)} holes/slots" + (f", knock-out in {len(ko)} pieces" if ko else ""))
