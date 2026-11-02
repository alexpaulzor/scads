#!/usr/bin/env python3
"""Can the hook rib (with its glued backer) tilt into the steel pegboard?

Side view, rib frame (x out from the backer's front face, y up). The moving
body is the rib's cut outline (kerf included, so a little pessimistic) plus
the backer's side profile; the steel is a panel_t strip behind the backer
with peg_hole_d holes every peg_p. The check rasterizes every combination of
tilt (front of the rib raised, about the hook bend) and slide (x, y), then
asks whether the hung position connects to "clear of the steel" through
free poses. Needs numpy and scipy.

    python3 marbles/hook_fit_check.py
"""

import math
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from laser_parts import load_profile, part_layers  # noqa: E402

RES = 0.05            # mm/px
DTH = 0.25            # deg per tilt step
TH = (-5.0, 100.0)    # tilt range, deg (positive: rib front up)
TX = (-0.5, 20.0)     # slide out from the board, mm
TY = (-8.0, 8.0)      # slide up/down, mm


def main():
    s2g, motion, mat, job = load_profile("plywood_veneer_3ply_3mm", 1000, None)
    th = mat["thickness_mm"]
    out = subprocess.run(["openscad", "-o", "/dev/null", "--export-format", "csg",
                          "-D", 'hy_part="none"', "-D", f"sheet_th={th}", str(HERE / "hybrid.scad")],
                         capture_output=True, text=True).stderr
    m = re.search(r"ECHO: hook_fit = \[([^\]]*)\]", out)
    bt, pt, hole, pitch, hk_y, bb, btop = [float(v) for v in m.group(1).split(",")]
    cuts = part_layers(s2g, "openscad", "hook_rib", th, tempfile.mkdtemp())["cut"]
    def area(p):
        return abs(sum(x0 * y1 - x1 * y0 for (x0, y0), (x1, y1) in zip(p, p[1:] + p[:1]))) / 2
    rib = max((pl.points for pl in cuts), key=area)
    backer = [(-bt, bb), (0, bb), (0, btop), (-bt, btop)]
    pivot = (-(bt + pt) - 2, hk_y + 4)      # near the hook's bend

    sx0, sx1 = -(bt + pt), -bt              # steel strip
    # only body columns that can ever land in the strip matter
    xb0, xb1 = sx0 - TX[1] - 1, sx1 - TX[0] + 1
    yb0, yb1 = -70.0, 90.0
    ncol = int(math.ceil((xb1 - xb0) / RES))
    nrow = int(math.ceil((yb1 - yb0) / RES))
    k = int(round((sx1 - sx0) / RES)) - 2   # strip columns, 1 px grace each side
    txs = np.arange(TX[0], TX[1] + 1e-9, RES)
    tys = np.arange(TY[0], TY[1] + 1e-9, RES)
    ths = np.arange(TH[0], TH[1] + 1e-9, DTH)
    # steel solid as a function of world y, sampled at RES
    wy0 = yb0 + TY[0] - 1
    wy = wy0 + np.arange(nrow + len(tys) + 40) * RES
    solid = np.ones_like(wy, dtype=bool)
    for j in range(-6, 7):
        c = hk_y + j * pitch
        solid &= ~((wy > c - hole / 2) & (wy < c + hole / 2))
    # S[j, r] = steel solid at body row r when slid by tys[j]
    r_idx = np.arange(nrow)
    S = np.stack([solid[np.round((yb0 + r_idx * RES + ty - wy0) / RES).astype(int)] for ty in tys]).astype(np.float32)

    free = np.zeros((len(ths), len(tys), len(txs)), dtype=bool)
    clear = np.zeros(len(ths), dtype=bool)
    for a, t in enumerate(ths):
        c, s = math.cos(math.radians(t)), math.sin(math.radians(t))
        img = Image.new("L", (ncol, nrow), 0)
        d = ImageDraw.Draw(img)
        for poly in (rib, backer):
            pts = []
            for x, y in poly:
                x, y = x - pivot[0], y - pivot[1]
                x, y = c * x - s * y + pivot[0], s * x + c * y + pivot[1]
                pts.append(((x - xb0) / RES, (y - yb0) / RES))
            d.polygon(pts, fill=1)
        occ = np.array(img, dtype=np.int32)
        cs = np.concatenate([np.zeros((nrow, 1), np.int32), np.cumsum(occ, axis=1)], axis=1)
        # strip (shrunk by 1 px each side) in body columns for each slide x
        c0 = np.round((sx0 - txs - xb0) / RES).astype(int) + 1
        M = ((cs[:, c0 + k] - cs[:, c0]) > 0).astype(np.float32)   # rows x ntx
        free[a] = (S @ M) < 0.5
        # fully in front of the steel: nothing left of the strip's front face
        bx = [x for poly in (rib, backer) for x, y in
              [(c * (px - pivot[0]) - s * (py - pivot[1]) + pivot[0], 0) for px, py in poly]]
        clear[a] = min(bx) + TX[1] > sx1 + 0.5
    from scipy import ndimage
    lab, n = ndimage.label(free)
    a0 = int(np.argmin(abs(ths))); j0 = int(np.argmin(abs(tys))); i0 = int(np.argmin(abs(txs)))
    if not free[a0, j0, i0]:
        print("hung pose collides (check geometry)"); sys.exit(1)
    comp = lab[a0, j0, i0]
    reach = lab == comp
    out_ok = any(reach[a, :, -1].any() and clear[a] for a in range(len(ths)))
    tilts = ths[np.nonzero(reach.any(axis=(1, 2)))[0]]
    xs = txs[np.nonzero(reach.any(axis=(0, 1)))[0]]
    print(f"reachable slide out {xs.min():.2f}..{xs.max():.2f} mm")
    print(f"hung pose connects to clear of the steel: {'YES' if out_ok else 'NO'} "
          f"(reachable tilt {tilts.min():.2f}..{tilts.max():.2f} deg)")
    sys.exit(0 if out_ok else 1)


if __name__ == "__main__":
    main()
