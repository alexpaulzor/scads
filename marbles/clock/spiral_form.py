#!/usr/bin/env python3
"""Glue-up form for laminating the spiral (3 layers of the same spiral sheet glued in shape). WIP, untested.

Small HOLDERS stand on the table along 8 RAYS (every 45 deg round the spiral centre). Each holder carries GROUP (3)
neighbouring strips of its ray at their exact heights - 3 holders per ray, the innermost (holder 1) under the solid
centre, the outermost reaching under the frame. Each is LAYERS (3) identical MDF layers glued (8.5 thick, so it
stands on its own), hollowed to 6 mm walls. Holders are per ray: the stair along every ray is the same 12.7 x 10
stair, but slid along itself by the spiral's angle, so each ray's treads sit at different heights. Dots on each
layer = its ray number (1 = 0 deg = +x, counting CCW seen from above); place each holder from the distances printed.
Optional: stand them on a board with double-sided tape so they can't tip.

The table is the reference: a tread's height = T_REF - (its strip's depth below the frame). Wax or tape the treads
so the glue does not stick the spiral to the form.

    python3 marbles/clock/spiral_form.py            # mdf3 sheets in marbles/gcode + a drawing
"""
import argparse
import math
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
import spiral_run as S  # noqa: E402
from laser_parts import gcode  # noqa: E402

RAYS = tuple(range(0, 360, 45))
GROUP = 3                    # treads per holder
LAYERS = 3                   # identical MDF layers glued per holder (8.5 thick: stands on its own)
BASE_MIN = 8.0               # wood under the lowest tread anywhere
FRAME_TREAD = 10.0           # how far the outer cap reaches under the frame
WALL = 6.0                   # hollowing: walls kept round each part's window
SHEET = (300.0, 292.0)
GAP = 2.0


def ray_treads(B, phi):
    """[(s_in, s_out, depth)] inner to outer along the ray: the strips (innermost = the solid centre, one tread
    wide) then FRAME_TREAD under the frame (depth 0)"""
    hits = S.ray_hits(B["cut"], B["cut_t"], phi)                 # outer first
    tr = [(hits[0][0], hits[0][0] + FRAME_TREAD, 0.0)]
    for (s_o, t_o), (s_i, _) in zip(hits, hits[1:]):
        tr.append((s_i, s_o, -S.z_of(t_o)))
    s_l, t_l = hits[-1]
    tr.append((s_l - (hits[-2][0] - s_l), s_l, -S.z_of(t_l)))
    return sorted(tr)


def stair(treads, lift, T_ref):
    """cap outline in (x from the inner end, height): flat bottom, the treads' heights minus `lift` on top"""
    s0 = treads[0][0]
    top = []
    for s_in, s_out, d in treads:
        h = T_ref - d - lift
        top += [(s_in - s0, h), (s_out - s0, h)]
    return Polygon([(0, 0)] + top + [(treads[-1][1] - s0, 0)])


def hollow(g):
    w = g.buffer(-WALL, join_style=2)
    if w.is_empty or w.area < 60:
        return g
    w = w.buffer(-1.5).buffer(1.5)                       # round the window's corners
    return g.difference(w) if not w.is_empty else g


def dots(g, n, length):
    """n small marking holes in the bottom wall near the outer end"""
    pts = [Point(length - 4 - 3.2 * i, WALL / 2 + 0.3) for i in range(n)]
    return g.difference(unary_union([p.buffer(0.75, 12) for p in pts if p.x > 3]))


def parts(B):
    """{name: (polygon, layers)} - each holder is GROUP treads of one ray at their exact heights above the table,
    hollowed, LAYERS identical layers glued; plus a placement table"""
    treads = {phi: ray_treads(B, phi) for phi in RAYS}
    deepest = max(d for tr in treads.values() for _, _, d in tr)
    T_ref = deepest + BASE_MIN
    out, table = {}, []
    for k, phi in enumerate(RAYS, 1):
        tr = treads[phi]
        groups = [tr[i:i + GROUP] for i in range(0, len(tr), GROUP)]
        if len(groups[-1]) == 1 and len(groups) > 1:            # a lone frame tread joins the group before it
            groups[-2] += groups.pop()
        for j, grp in enumerate(groups, 1):
            g = hollow(stair(grp, 0.0, T_ref))
            L = grp[-1][1] - grp[0][0]
            out[f"r{k}h{j}"] = (dots(g, k, L), LAYERS)
            table.append((k, phi, j, grp[0][0], grp[-1][1], [round(T_ref - d, 1) for _, _, d in grp]))
    return out, table, T_ref


def pair(g):
    """g and g turned 180 deg, its stair dropped into g's as far as GAP allows: one item"""
    x0, y0, x1, y1 = g.bounds
    r = affinity.rotate(g, 180, origin=((x0 + x1) / 2, (y0 + y1) / 2))
    best = None
    for dy in [0.25 * i for i in range(int((y1 - y0) * 4) + 1)]:
        q = affinity.translate(r, 0, (y1 - y0) - dy)
        if q.distance(g) >= GAP:
            best = q
        else:
            break
    return unary_union([g, best])


def pack(items):
    """first-fit-decreasing shelves onto SHEET-sized sheets: [[(name, placed poly)]]"""
    items = sorted(items, key=lambda it: -(it[1].bounds[3] - it[1].bounds[1]))
    W, H = SHEET[0] - 1.0, SHEET[1] - 1.5
    sheets = []                                   # each: {"parts": [], "shelves": [[y, h, x_used]], "top": y}
    for name, g in items:
        x0, y0, x1, y1 = g.bounds
        w, h = x1 - x0, y1 - y0
        spot = None
        for sh in sheets:
            for shelf in sh["shelves"]:
                if h <= shelf[1] and shelf[2] + w <= W:
                    spot = (sh, shelf)
                    break
            if spot:
                break
            if sh["top"] + h <= H:                # a new shelf on this sheet
                shelf = [sh["top"], h, 0.0]
                sh["shelves"].append(shelf)
                sh["top"] += h + GAP
                spot = (sh, shelf)
                break
        if not spot:
            sh = {"parts": [], "shelves": [[0.0, h, 0.0]], "top": h + GAP}
            sheets.append(sh)
            spot = (sh, sh["shelves"][0])
        sh, shelf = spot
        sh["parts"].append((name, affinity.translate(g, shelf[2] - x0 + 0.5, shelf[0] - y0 + 0.5)))
        shelf[2] += w + GAP
    return [sh["parts"] for sh in sheets]


def emit_sheet(placed, mat, idx, n_sheets, out_dir, notes):
    T, kerf, _ = gcode.fit(mat)
    job = gcode.job(mat)
    cuts = []
    for _, g in placed:
        for p in getattr(g, "geoms", [g]):
            for r in p.interiors:
                cuts.append(gcode.Polyline(list(Polygon(r).buffer(-kerf / 2, join_style=2).exterior.coords), True))
            cuts.append(gcode.Polyline(list(Polygon(p.exterior).buffer(kerf / 2, join_style=2).exterior.coords), True))
    cuts = gcode.order(cuts)
    x1 = max(g.bounds[2] for _, g in placed) + kerf
    y1 = max(g.bounds[3] for _, g in placed) + kerf
    stem = gcode.name(f"spiral_form_{idx}of{n_sheets}", x1, y1, mat)
    lines = gcode.preamble(job, title=f"{stem} -- marbles/clock/spiral_form.py: glue-up form, sheet {idx} of {n_sheets}",
                           notes=notes + [f"{len(placed)} layers on this sheet", f"{mat}: T {T}, kerf {kerf}"])
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(out_dir / f"{stem}.gcode", lines)
    mins = sum(LineString(c.points).length * job.passes for c in cuts) / job.feed_mm_per_min
    return p, len(cuts), mins


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--material", default="mdf3")
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    B = S.build()
    P, table, T_ref = parts(B)
    items = []
    for n, (g, c) in P.items():                     # identical outer layers go in 180-degree nested pairs
        while c >= 2:
            items.append((n + " x2", pair(g)))
            c -= 2
        items += [(n, g)] * c
    sheets = pack(items)
    area = sum(g.area for _, g in items)
    n_layers = sum(c for _, c in P.values())
    print(f"form: {len(P)} holders x {LAYERS} layers = {n_layers} layers, {area / 100:.0f} cm2 of {a.material}, "
          f"{len(sheets)} sheet(s); tread height = {T_ref:.1f} - depth below the frame")
    for k, phi, j, s_a, s_b, hs in table:
        print(f"  ray {k} ({phi:3d} deg) holder {j}: {s_a:5.1f} to {s_b:5.1f} out from the centre; tread heights {hs}")
    notes = [f"{LAYERS} identical layers per holder, glued; dots = ray (1 = 0 deg = +x, CCW from above); holder 1 innermost",
             f"tread heights above the table = {T_ref:.1f} - the strip's depth below the frame"]
    for i, sh in enumerate(sheets, 1):
        p, n, mins = emit_sheet(sh, a.material, i, len(sheets), a.out, notes)
        print(f"{p.name}: {n} cuts, ~{mins:.0f} min")
    return P, table, sheets


if __name__ == "__main__":
    main()
