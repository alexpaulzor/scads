#!/usr/bin/env python3
"""One hook-rib set (rib + backer + crossmember) in the smallest footprint, for scrap.

Nesting is a raster bottom-left fill (numpy FFT overlap test) over the parts'
real cut outlines from hybrid.scad. Every part may take any of the 8
right-angle orientations, mirrored ones included: a through-cut part flipped
over is its own mirror image. It sweeps the strip width, nests the three
parts into each width, and keeps the layout with the smallest bounding box.

--gap is the spacing between parts' toolpaths (kerf is already in the
outlines). Zeroed at the bottom-left of the layout's toolpaths, like
laser_parts.py. Cuts go part by part, each part's holes before its outline,
with laser_parts.emit_cut (warmup wiggle at every start, loops overlap their
seam).

    python3 marbles/laser_set.py              # writes gcode/hook_rib_set.gcode
    python3 marbles/laser_set.py --gap 2 --png layout.png
"""

import argparse
import math
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from laser_parts import emit_cut, load_profile, part_layers, preamble  # noqa: E402

SET = ["hook_rib", "backer", "crossmember"]
ORIENTS = [(r, m) for m in (False, True) for r in (0, 90, 180, 270)]


def loop_area(pts):
    return abs(sum(x0 * y1 - x1 * y0 for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1]))) / 2


def transform(pts, rot, mirror):
    out = []
    for x, y in pts:
        if mirror:
            x = -x
        c, s = round(math.cos(math.radians(rot))), round(math.sin(math.radians(rot)))
        out.append((c * x - s * y, s * x + c * y))
    return out


class Shape:
    """One part in one orientation, normalized so its outline's min corner is (0,0)."""

    def __init__(self, name, cuts, rot, mirror, res, pad):
        self.name, self.rot, self.mirror = name, rot, mirror
        loops = [transform(pl.points, rot, mirror) for pl in cuts]
        outline = max(loops, key=loop_area)
        x0 = min(p[0] for p in outline)
        y0 = min(p[1] for p in outline)
        self.loops = [[(x - x0, y - y0) for x, y in lp] for lp in loops]
        self.closed = [pl.closed for pl in cuts]
        self.outline = [(x - x0, y - y0) for x, y in outline]
        self.w = max(p[0] for p in self.outline)
        self.h = max(p[1] for p in self.outline)
        # raster of the outline grown by pad (half the gap) on every side
        n = int(math.ceil(pad / res)) + 1   # +1 px: polygon raster edges
        W, H = int(math.ceil(self.w / res)) + 2 * n + 2, int(math.ceil(self.h / res)) + 2 * n + 2
        img = Image.new("L", (W, H), 0)
        ImageDraw.Draw(img).polygon([(x / res + n, y / res + n) for x, y in self.outline], fill=1)
        m = np.array(img, dtype=bool)
        # grow by n px with a round brush
        yy, xx = np.mgrid[-n:n + 1, -n:n + 1]
        disk = (xx * xx + yy * yy) <= n * n
        g = np.zeros_like(m)
        for dy, dx in zip(*np.nonzero(disk)):
            g |= np.roll(np.roll(m, dy - n, 0), dx - n, 1)
        self.mask, self.off = g, n   # mask pixel (n, n) = outline min corner


def nest(shapes, order, grid_w, grid_h, res, edge_px):
    """Bottom-left fill. Returns [(name, Shape, x_mm, y_mm)] or None if one didn't fit."""
    occ = np.zeros((grid_h, grid_w), dtype=np.float32)
    placed = []
    fshape = (grid_h, grid_w)
    cache = {}
    for name in order:
        F = np.fft.rfft2(occ)
        best = None
        for sh in shapes[name]:
            if sh.mask.shape[0] > grid_h or sh.mask.shape[1] > grid_w:
                continue
            key = id(sh)
            if key not in cache:
                k = np.zeros(fshape, dtype=np.float32)
                k[:sh.mask.shape[0], :sh.mask.shape[1]] = sh.mask[::-1, ::-1]
                cache[key] = np.fft.rfft2(k)
            # overlap[y, x] = sum(occ[y:y+h, x:x+w] * mask), read at the far corner
            ov = np.fft.irfft2(F * cache[key], s=fshape)
            mh, mw = sh.mask.shape
            ov = ov[mh - 1:, mw - 1:]               # top-left placement index
            # outline must keep edge_px from the sheet edge
            ys, xs = np.arange(ov.shape[0]), np.arange(ov.shape[1])
            okx = (xs + sh.off >= edge_px) & (xs + sh.off + sh.w / res <= grid_w - edge_px)
            oky = (ys + sh.off >= edge_px) & (ys + sh.off + sh.h / res <= grid_h - edge_px)
            free = (ov < 0.5) & oky[:, None] & okx[None, :]
            if not free.any():
                continue
            fy, fx = np.nonzero(free)
            # lowest top edge, then leftmost
            top = fy + sh.off + sh.h / res
            i = np.lexsort((fx, top))[0]
            cand = (top[i], fx[i], fy[i], sh)
            if best is None or cand[:2] < best[:2]:
                best = cand
        if best is None:
            return None
        _, x, y, sh = best
        mh, mw = sh.mask.shape
        occ[y:y + mh, x:x + mw] = np.maximum(occ[y:y + mh, x:x + mw], sh.mask)
        placed.append((name, sh, (x + sh.off) * res, (y + sh.off) * res))
    return placed


def seg_min_dist(a, b):
    """Min distance between two polylines (exact, segment to segment via sampling a)."""
    a, b = np.asarray(a), np.asarray(b)
    # sample a densely
    pts = []
    for p, q in zip(a[:-1], a[1:]):
        k = max(1, int(np.hypot(*(q - p)) / 0.1))
        pts.append(p + (q - p) * np.linspace(0, 1, k + 1)[:, None])
    pts = np.concatenate(pts)
    p0, p1 = b[:-1], b[1:]
    d = p1 - p0
    L2 = np.maximum((d * d).sum(1), 1e-12)
    t = np.clip(((pts[:, None, :] - p0[None]) * d[None]).sum(2) / L2[None], 0, 1)
    proj = p0[None] + t[..., None] * d[None]
    return float(np.sqrt(((pts[:, None, :] - proj) ** 2).sum(2)).min())


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--gap", type=float, default=1.5, help="min mm between parts' toolpaths")
    ap.add_argument("--res", type=float, default=0.25, help="nesting raster, mm/px")
    ap.add_argument("--material", default="plywood_veneer_3ply_3mm")
    ap.add_argument("--s-full-power", type=int, default=1000, help="GRBL $30")
    ap.add_argument("--quickcut", help="path to cnc_vibes/quickcut")
    ap.add_argument("--openscad", default="openscad")
    ap.add_argument("-o", "--out", type=Path, default=HERE / "gcode" / "hook_rib_set.gcode")
    ap.add_argument("--png", type=Path, help="also draw the layout here")
    a = ap.parse_args()

    s2g, motion, mat, job = load_profile(a.material, a.s_full_power, a.quickcut)
    sheet_th = mat["thickness_mm"]
    tmp = tempfile.mkdtemp()
    res = a.res
    cuts_of = {nm: part_layers(s2g, a.openscad, nm, sheet_th, tmp)["cut"] for nm in SET}
    # fixed row: rib mirrored (hook/peg side facing right), crossmember on
    # end beside the hook/peg side, then the backer; bottoms aligned
    rib = Shape("hook_rib", cuts_of["hook_rib"], 0, True, res, 0)
    cm = Shape("crossmember", cuts_of["crossmember"], 90, False, res, 0)
    bk = Shape("backer", cuts_of["backer"], 0, False, res, 0)
    placed = [("hook_rib", rib, 0.0, 0.0),
              ("crossmember", cm, rib.w + a.gap, 0.0),
              ("backer", bk, rib.w + a.gap + cm.w + a.gap, 0.0)]
    x0 = y0 = 0.0
    ext = (0.0, 0.0, rib.w + cm.w + bk.w + 2 * a.gap, max(rib.h, cm.h, bk.h))
    parts = []
    for name, sh, x, y in placed:
        loops = [[(px + x - x0, py + y - y0) for px, py in lp] for lp in sh.loops]
        outline = [(px + x - x0, py + y - y0) for px, py in sh.outline]
        parts.append((name, sh, loops, outline))
    min_gap = min(seg_min_dist(parts[i][3] + parts[i][3][:1], parts[j][3] + parts[j][3][:1])
                  for i in range(3) for j in range(i + 1, 3))
    if min_gap < a.gap - 0.05:
        sys.exit(f"spacing check failed: {min_gap:.2f} mm < {a.gap} mm")
    W, H = ext[2] - ext[0], ext[3] - ext[1]
    orient = ", ".join(f"{nm} {sh.rot}{' mirrored' if sh.mirror else ''}" for nm, sh, _, _ in parts)

    g = [f"; hook_rib_set -- laser_set.py: one rib + backer + crossmember",
         f"; {a.material} ({sheet_th} mm thick)",
         f"; X0 Y0 = bottom-left of the layout; footprint {W:.2f} x {H:.2f} mm",
         f"; min gap between parts {min_gap:.2f} mm (asked {a.gap}); orientations: {orient}",
         "; each part: holes first, outline last",
         ";"]
    g += preamble(s2g, job)
    cuts = []
    for name, sh, loops, outline in parts:
        idx = sorted(range(len(loops)), key=lambda k: loop_area(loops[k]))   # outline last
        cuts += [s2g.Polyline(loops[k], sh.closed[k]) for k in idx]
    for i, c in enumerate(cuts, 1):
        if c.closed and c.points[0] != c.points[-1]:
            c.points = c.points + [c.points[0]]
        g += emit_cut(s2g, motion, c, i, len(cuts), job)
    g += s2g._footer()
    a.out.parent.mkdir(parents=True, exist_ok=True)
    a.out.write_text("\n".join(g))
    print(f"{a.out.name}: footprint {W:.2f} x {H:.2f} mm, min gap {min_gap:.2f} mm, "
          f"{len(cuts)} cuts; {orient}")

    if a.png:
        S = 8
        img = Image.new("RGB", (int(W * S) + 20, int(H * S) + 20), "white")
        d = ImageDraw.Draw(img)
        col = {"hook_rib": "red", "backer": "blue", "crossmember": "green"}
        for name, sh, loops, outline in parts:
            for lp in loops:
                d.line([(10 + x * S, 10 + (H - y) * S) for x, y in lp + lp[:1]], fill=col[name], width=2)
        img.save(a.png)


if __name__ == "__main__":
    main()
