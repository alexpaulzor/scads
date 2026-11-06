#!/usr/bin/env python3
"""Printable 1:1 PDF of the feeder / dispenser plates (no trough parts): heavy outlines at the nominal
(design) size, the knock-out port dashed, a 100 mm and a 4 in scale bar on every page.
Print at 100 % / "actual size" on US Letter, then check the scale bars with a ruler.

    python3 marbles/clock/feeder_print.py [-o feeder_plates_1to1.pdf]
"""
import argparse
import re
import subprocess
import tempfile
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.backends.backend_pdf import PdfPages  # noqa: E402

HERE = Path(__file__).resolve().parent
SCAD = HERE / "feeder.scad"
ap = argparse.ArgumentParser()
ap.add_argument("-o", "--out", default="feeder_plates_1to1.pdf")
ap.add_argument("--material", default="mdf3")
a = ap.parse_args()

import sys  # noqa: E402
sys.path.insert(0, str(HERE.parent))
from laser_parts import material_fit  # noqa: E402
T, KERF, FIT = material_fit(a.material)
DEFS = ["-D", f"T={T}", "-D", f"KERF={KERF}", "-D", f"FIT={FIT}", "-D", "laser=false"]


def loops(part, td):
    svg = Path(td) / f"{part}.svg"
    subprocess.run(["openscad", "-o", str(svg), "-D", f'part="{part}"'] + DEFS + [str(SCAD)],
                   capture_output=True, text=True, check=True)
    d = " ".join(re.findall(r'd="([^"]+)"', svg.read_text()))
    out = []
    for sub in re.split(r"[Mm]", d):
        pts = [(float(x), -float(y)) for x, y in re.findall(r"(-?[\d.]+),(-?[\d.]+)", sub)]
        if len(pts) > 2:
            out.append(pts + [pts[0]])
    return out


def bounds(ls):
    xs = [p[0] for l in ls for p in l]
    ys = [p[1] for l in ls for p in l]
    return min(xs), min(ys), max(xs), max(ys)


PW, PH = 215.9, 279.4                    # US Letter portrait, mm
TITLES = {"funnel": "FEEDER funnel (centre plate, extension solid)",
          "funnel_dispenser": "DISPENSER funnel (centre plate, slot past the exit)",
          "front_keeper": "front keeper (both boxes)", "back_keeper": "back keeper (both boxes)",
          "tunnel_flange": "tunnel flange", "tunnel_relief": "tunnel relief", "spacer": "spacer"}
# page layouts: (part, x, y) = where the part's bottom-left goes, mm from the page's bottom-left
PAGES = [[("funnel", 20, 45)], [("funnel_dispenser", 20, 45)],
         [("front_keeper", 15, 120), ("back_keeper", 105, 120),
          ("tunnel_flange", 15, 45), ("tunnel_relief", 85, 45), ("spacer", 160, 60)]]

with tempfile.TemporaryDirectory() as td, PdfPages(a.out) as pdf:
    ko = loops("knockout", td)
    for page in PAGES:
        fig = plt.figure(figsize=(PW / 25.4, PH / 25.4))
        ax = fig.add_axes([0, 0, 1, 1])
        ax.set_xlim(0, PW)
        ax.set_ylim(0, PH)
        ax.axis("off")
        for part, px, py in page:
            ls = loops(part, td)
            x0, y0, x1, y1 = bounds(ls)
            dx, dy = px - x0, py - y0
            for l in ls:
                ax.plot([p[0] + dx for p in l], [p[1] + dy for p in l], color="black", lw=2.0, solid_joinstyle="round")
            if part in ("front_keeper", "back_keeper"):
                for l in ko:
                    ax.plot([p[0] + dx for p in l], [p[1] + dy for p in l], color="black", lw=1.2, ls=(0, (4, 2)))
            ax.text(px, py + (y1 - y0) + 3, f"{TITLES[part]}\n{x1 - x0:.1f} x {y1 - y0:.1f} mm",
                    fontsize=7, va="bottom")
        # scale bars
        ax.plot([20, 120], [22, 22], color="black", lw=2)
        for x in (20, 120):
            ax.plot([x, x], [19, 25], color="black", lw=1.5)
        ax.text(70, 26, "100 mm", ha="center", fontsize=8)
        ax.plot([135, 135 + 101.6], [22, 22], color="black", lw=2)
        for x in (135, 135 + 101.6):
            ax.plot([x, x], [19, 25], color="black", lw=1.5)
        ax.text(135 + 50.8, 26, "4 in", ha="center", fontsize=8)
        ax.text(PW / 2, 8, f"PRINT AT 100% / ACTUAL SIZE (Letter). Nominal design outlines, {a.material} T {T} "
                           "(the laser cut adds kerf compensation). Dashed = knock-out port.",
                ha="center", fontsize=6.5)
        pdf.savefig(fig)
        plt.close(fig)
print(f"wrote {a.out}")
