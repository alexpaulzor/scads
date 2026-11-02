#!/usr/bin/env python3
"""One G-code file per hybrid.scad laser part: etch first, then cut.

Each part comes from hybrid.scad's lz_cut_2d / lz_etch_2d (one shared frame),
exported to SVG by OpenSCAD and converted here. Every file is zeroed at the
bottom-left corner of the part's CUT outline: jog the laser to the corner of
the stock you want, zero X and Y there, and run it.

Cutting uses quickcut's own emitter (cnc_vibes/quickcut/svg2gcode.py): static
M3, 1 s warmup follow-through, interior loops first, outer boundary last.
Etching uses the material's etch recipe with the settings laser_materials.yaml
records as the fix for etch burn-through: 0.3 mm minimum segments and a short
fixed lead-in (each loop traced once, then followed through etch_lead_in_mm
past its start), not the 1 s cut warmup.

    python3 marbles/laser_parts.py                       # all parts
    python3 marbles/laser_parts.py hook_rib backer       # some parts
    python3 marbles/laser_parts.py --material plywood_baltic_birch_3mm
"""

import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCAD = HERE / "hybrid.scad"
ETCH_LEAD_IN_MM = 3.0
ETCH_MIN_SEG_MM = 0.3


def find_quickcut(arg):
    candidates = [Path(arg)] if arg else []
    candidates += [HERE.parent.parent / "cnc_vibes" / "quickcut",
                   Path.home() / "src" / "vibes" / "quickcut",
                   Path.home() / "src" / "cnc_vibes" / "quickcut"]
    for c in candidates:
        if (c / "svg2gcode.py").exists():
            return c
    sys.exit("can't find quickcut/svg2gcode.py; pass --quickcut PATH")


def part_names(openscad):
    out = subprocess.run([openscad, "-o", "/dev/null", "--export-format", "csg",
                          "-D", 'hy_part="none"', str(SCAD)],
                         capture_output=True, text=True)
    m = re.search(r'ECHO: lz_parts = \[(.*?)\]', out.stderr)
    if m:
        return re.findall(r'"([^"]+)"', m.group(1))
    sys.exit("hybrid.scad didn't echo lz_parts")


def export_svg(openscad, layer, name, path):
    r = subprocess.run([openscad, "-o", str(path), "-D", f'hy_part="lz_{layer}"',
                        "-D", f'lz_name="{name}"', str(SCAD)],
                       capture_output=True, text=True)
    if layer == "etch" and ("top level object is empty" in r.stderr
                           or "not a 2D object" in r.stderr):
        return None
    if r.returncode != 0 or not path.exists():
        sys.exit(f"openscad failed on {name} {layer}:\n{r.stderr}")
    return path.read_text()


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("parts", nargs="*", help="part names (default: all)")
    ap.add_argument("--material", default="plywood_veneer_3ply_3mm")
    ap.add_argument("--s-full-power", type=int, default=1000, help="GRBL $30")
    ap.add_argument("--quickcut", help="path to cnc_vibes/quickcut")
    ap.add_argument("--openscad", default="openscad")
    ap.add_argument("-o", "--out", type=Path, default=HERE / "gcode")
    a = ap.parse_args()

    qc = find_quickcut(a.quickcut)
    sys.path.insert(0, str(qc))
    import svg2gcode as s2g  # noqa: E402
    from materials import SHARED_MATERIALS  # noqa: E402
    from motion import decimate, follow_through  # noqa: E402
    import yaml  # noqa: E402

    materials = {m["id"]: m for m in yaml.safe_load(Path(SHARED_MATERIALS).read_text())}
    if a.material not in materials:
        sys.exit(f"unknown material {a.material}")
    mat = materials[a.material]
    cut_r, etch_r = mat["laser"], mat.get("etch")
    if not etch_r:
        sys.exit(f"{a.material} has no etch recipe")
    cut_job = s2g.CutJob(feed_mm_per_min=cut_r["feed_mm_per_min"],
                         power_percent=cut_r["power_percent"],
                         passes=cut_r.get("passes", 1), material_id=a.material,
                         s_full_power=a.s_full_power)
    etch_s = round(etch_r["power_percent"] / 100 * a.s_full_power)
    etch_f = etch_r["feed_mm_per_min"]
    etch_on = "M3" if etch_r.get("mode", "static") == "static" else "M4"

    names = a.parts or part_names(a.openscad)
    a.out.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp())
    for name in names:
        layers = {}
        for layer in ("cut", "etch"):
            svg = export_svg(a.openscad, layer, name, tmp / f"{name}_{layer}.svg")
            lines, u = s2g.parse_svg(svg) if svg else ([], 1.0)
            # OpenSCAD's SVG is y-down (y negated); back to machine y-up
            layers[layer] = [s2g.Polyline([(x * u, -y * u) for x, y in pl.points], pl.closed)
                             for pl in lines]
        pts = [p for pl in layers["cut"] for p in pl.points]
        x0, y0 = min(p[0] for p in pts), min(p[1] for p in pts)
        x1, y1 = max(p[0] for p in pts), max(p[1] for p in pts)
        for layer in layers:
            for pl in layers[layer]:
                pl.points = [(x - x0, y - y0) for x, y in pl.points]
                if pl.closed and pl.points[0] != pl.points[-1]:
                    pl.points.append(pl.points[0])
        epts = [p for pl in layers["etch"] for p in pl.points]
        ex = (min(p[0] for p in epts), min(p[1] for p in epts),
              max(p[0] for p in epts), max(p[1] for p in epts)) if epts else None

        g = [f"; {name} -- hybrid.scad / laser_parts.py",
             f"; X0 Y0 = bottom-left corner of the cut outline; part is "
             f"{x1 - x0:.2f} x {y1 - y0:.2f} mm",
             f"; etch first ({etch_r['power_percent']}% F{etch_f}, "
             f"{ETCH_LEAD_IN_MM}mm lead-in), then cut",
             ]
        if ex:
            g.append(f"; etch extent X{ex[0]:.2f}..{ex[2]:.2f} Y{ex[1]:.2f}..{ex[3]:.2f}")
        g += s2g._preamble(cut_job)
        g += ["; ===== ETCH ====="]
        for i, pl in enumerate(layers["etch"], 1):
            p = decimate(pl.points, ETCH_MIN_SEG_MM)
            if len(p) < 2:
                continue
            g += [f"; --- etch {i}/{len(layers['etch'])} ---",
                  f"G0 X{p[0][0]:.3f} Y{p[0][1]:.3f}", f"{etch_on} S{etch_s}", f"F{etch_f}"]
            g += [f"G1 X{x:.3f} Y{y:.3f}" for x, y in p[1:]]
            if pl.closed:
                g += [f"G1 X{x:.3f} Y{y:.3f}" for x, y in follow_through(p, ETCH_LEAD_IN_MM)]
            g += ["M5", ""]
        g += ["; ===== CUT ====="]
        cuts = s2g.order_cuts(layers["cut"])
        for i, pl in enumerate(cuts, 1):
            g += s2g._emit_cut(pl, i, len(cuts), cut_job)
        g += s2g._footer()
        out = a.out / f"{name}.gcode"
        out.write_text("\n".join(g))
        print(f"{out.name}: {x1 - x0:.2f} x {y1 - y0:.2f} mm, "
              f"{len(layers['etch'])} etch loops, {len(cuts)} cuts")


if __name__ == "__main__":
    main()
