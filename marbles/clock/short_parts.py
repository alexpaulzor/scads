#!/usr/bin/env python3
"""Sieve and plain keeper pieces, 3 to 10 ball holes long (90 .. 300 mm, 30 per hole).

SIEVE (sieve_<n>h): the lift_sieve strip at any length. 46 wide; ball holes d20 every 30 on
  Y = 30, first 15 from the end. Rail M5 (exactly 5.0) on Y = 10 in every other gap between
  ball holes starting with the first (X = 30, 90, 150 ...); if that misses the last gap, the
  last gap gets one too, so both ends are held (3 holes: 30, 60).
KEEPER (keeper_<n>h): same length, 40 wide.
  - Y = 10 (over the ball column): VIEW SLOTS. The old 3/4" (19.05) hole row with every other
    pair of holes joined: slot 19.05 + 5 = 24.05 long, 5 wide, then 19.05 - 5 = 14.05 solid,
    repeated, centred. 5 wide is far too narrow for a 3/4" ball to catch in.
  - Y = 30 (over the beam): rail M5 at the sieve's M5 positions for that length.
Thickness, kerf and fit come from the material profile (mdf3: 2.82 / 0.10).

    python3 marbles/clock/short_parts.py                 # -> marbles/gcode/{sieve,keeper}_<n>h_<W>x<H>.gcode, n = 3..10
    python3 marbles/clock/short_parts.py --sizes 4 7
"""
import argparse
import json
import math
import re
import sys
from pathlib import Path

from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))

PITCH, HOLE_D, M5 = 30.0, 20.0, 5.0
P34 = 19.05                        # 3/4"
SLOT_W = 5.0
SLOT_L = P34 + SLOT_W              # 24.05
SOLID = P34 - SLOT_W               # 14.05
END_MIN = 5.0                      # wood from a view slot to the end of the piece, at least


def rail_m5_x(n):
    """every other gap between ball holes from the first; plus the last gap if that misses it"""
    gaps = [PITCH * (i + 1) for i in range(n - 1)]
    xs = gaps[::2]
    if gaps and xs[-1] != gaps[-1]:
        xs.append(gaps[-1])
    return xs


def view_slots(L, y, x0=0.0):
    """centred row of view slots (as shapes) along [x0, x0 + L] at height y"""
    m = int((L - 2 * END_MIN + SOLID) // (SLOT_L + SOLID))
    span = m * SLOT_L + (m - 1) * SOLID
    s0 = x0 + (L - span) / 2
    out = []
    for i in range(m):
        a = s0 + i * (SLOT_L + SOLID) + SLOT_W / 2
        out.append(LineString([(a, y), (a + P34, y)]).buffer(SLOT_W / 2, 24))
    return out


def sieve(n):
    L = n * PITCH
    g = box(0, 0, L, 46.0)
    holes = [Point(PITCH / 2 + PITCH * i, 30.0).buffer(HOLE_D / 2, 128) for i in range(n)]
    holes += [Point(x, 10.0).buffer(M5 / 2, 48) for x in rail_m5_x(n)]
    return g.difference(unary_union(holes))


def keeper(n):
    L = n * PITCH
    g = box(0, 0, L, 40.0)
    cuts = view_slots(L, 10.0) + [Point(x, 30.0).buffer(M5 / 2, 48) for x in rail_m5_x(n)]
    return g.difference(unary_union(cuts))


# ---------------------------------------------------------------- DOUBLE sieve / keeper (two lanes in parallel)
# 71.8 wide = a 20 mm beam band in the middle + on each side a 20 mm ball hole and 5.9 of wood outside it.
# x along the length (positions every PITCH, first PITCH/2 from the end), y across.
DBL_BEAM, DBL_WOOD = 20.0, 5.9
DBL_W = round(DBL_BEAM + 2 * (HOLE_D + DBL_WOOD), 6)                       # 71.8
DBL_HOLE_Y = (round(DBL_WOOD + HOLE_D / 2, 6), round(DBL_W - DBL_WOOD - HOLE_D / 2, 6))  # 15.9, 55.9: the two lanes
DBL_M5_Y = round(DBL_W / 2, 6)                                               # 35.9: the beam bolts
FLANGE_BOLT = 20.0      # wire-track flange (feeder.scad tunnel_flange2d): M5 at the corners and mid-sides, 20 off its centre
FLANGE_WEB = 4.0        # keep a flange bolt only with at least this much wood to the edge and to any hole


def flange_bolts(cx, cy):
    """the flange's 8 M5 positions around (cx, cy): 4 corners + 4 mid-sides"""
    d = FLANGE_BOLT
    return [(cx + sx * d, cy + sy * d) for sx in (-1, 0, 1) for sy in (-1, 0, 1) if (sx, sy) != (0, 0)]


def double_sieve(n, kinds=None):
    """(shape, notes, m5 list). kinds: "hole" | "solid" | "flange" per position (default all holes), both lanes.
    "flange": the 20 mm ball hole plus the wire-track flange's M5 pattern where it fits (on the plate, and at
    least FLANGE_WEB of wood to the edge and every hole); the two lanes' flanges share the centre-line bolts.
    The rail M5 (centre line) are kept unless a flange bolt sits within 2 hole diameters of them."""
    kinds = kinds or ["hole"] * n
    L = n * PITCH
    balls, m5, notes = [], [], []
    for i, k in enumerate(kinds):
        x = PITCH / 2 + PITCH * i
        if k in ("hole", "flange"):
            balls += [(x, y) for y in DBL_HOLE_Y]
    ball_cuts = [Point(p).buffer(HOLE_D / 2, 128) for p in balls]
    for i, k in enumerate(kinds):
        if k != "flange":
            continue
        x = PITCH / 2 + PITCH * i
        for y in DBL_HOLE_Y:
            for b in flange_bolts(x, y):
                b = (round(b[0], 6), round(b[1], 6))
                edge = min(b[0], L - b[0], b[1], DBL_W - b[1]) - M5 / 2
                hole = min(Point(b).distance(c) for c in ball_cuts) - M5 / 2
                if edge >= FLANGE_WEB and hole >= FLANGE_WEB:
                    m5.append(b)
                else:
                    notes.append(f"flange at ({x:g}, {y:g}): bolt ({b[0]:g}, {b[1]:g}) left out "
                                 + ("(off the plate)" if edge < 0 else f"({min(edge, hole):.2f} of wood)"))
    m5 = sorted(set(m5))
    for rx in rail_m5_x(n):
        if all(abs(rx - bx) > 2 * M5 for bx, by in m5 if by == DBL_M5_Y):
            m5.append((rx, DBL_M5_Y))
    cuts = ball_cuts + [Point(p).buffer(M5 / 2, 48) for p in m5]
    return box(0, 0, L, DBL_W).difference(unary_union(cuts)), sorted(set(notes)), sorted(m5)


# wire-track flange, doubled: one plate for both lanes, cropped to the double sieve's width, the bores at
# the lanes' centres, bolted through the T pattern that fits the double sieve's flange position. Wire
# geometry as feeder.scad's tunnel flange (12 ga straights at 45/135/225/315 deg round a 20 mm bore).
TUN_WIRE, TUN_BORE, TUN_CLR, TUN_SEAT = 2.05, 20.0, 0.3, 0.5
TUN_RW = TUN_BORE / 2 + TUN_WIRE / 2                         # straight-wire centre radius 11.025
TUN_HOLE = TUN_WIRE + TUN_CLR                                # notch width / stitch hole 2.35
TUN_NOTCH_OUT = TUN_RW + TUN_HOLE / 2                        # 12.2
TUN_FBORE = 2 * (TUN_RW + TUN_WIRE / 2 - TUN_SEAT)           # 23.1
TUN_SR = (TUN_NOTCH_OUT + FLANGE_BOLT * math.sqrt(2) - M5 / 2) / 2   # single flange's stitch radius 18.99
FLANGE_HALF = FLANGE_BOLT + M5 / 2 + 4.0                     # 26.5: the single flange's half size (feeder.scad CAP_HW)


def double_flange(x_c=45.0):
    """(shape, notes, m5). Same frame as double_sieve (x along, y across, flange centred on x_c), cropped to
    DBL_W. Outer stitch holes (the two toward each plate edge) come in to the radius that leaves equal wood to
    the edge and to the notch end, since the single flange's radius would leave 1.3 to the edge."""
    m5 = [b for b in double_sieve(3, ["solid", "flange", "hole"])[2]]          # the T pattern
    m5 = [(bx - 45.0 + x_c, by) for bx, by in m5]
    plate = box(x_c - FLANGE_HALF, 0, x_c + FLANGE_HALF, DBL_W).buffer(-2, join_style=2).buffer(2, 16)
    cuts, notes = [], []
    for y in DBL_HOLE_Y:
        cuts.append(Point(x_c, y).buffer(TUN_FBORE / 2, 128))
        for a in (45, 135, 225, 315):
            u = (math.cos(math.radians(a)), math.sin(math.radians(a)))
            cuts.append(LineString([(x_c, y), (x_c + TUN_NOTCH_OUT * u[0], y + TUN_NOTCH_OUT * u[1])]).buffer(TUN_HOLE / 2, cap_style=2))
            outer = (y + u[1] * TUN_SR < y) if y < DBL_W / 2 else (y + u[1] * TUN_SR > y)
            r = TUN_SR
            if outer:   # equal wood: edge = notch web -> (y_edge_dist + NOTCH_OUT) / (1 + sin45)
                r = (min(y, DBL_W - y) + TUN_NOTCH_OUT) / (1 + math.sin(math.radians(45)))
            cuts.append(Point(x_c + r * u[0], y + r * u[1]).buffer(TUN_HOLE / 2, 32))
        rr = (min(DBL_HOLE_Y[0], DBL_W - DBL_HOLE_Y[0]) + TUN_NOTCH_OUT) / (1 + math.sin(math.radians(45)))
    notes.append(f"outer stitch holes at r {rr:.2f} (inner ones at the single flange's {TUN_SR:.2f}): "
                 f"{rr - TUN_HOLE / 2 - TUN_NOTCH_OUT:.2f} of wood to the notch end and to the edge")
    cuts += [Point(p).buffer(M5 / 2, 48) for p in m5]
    return plate.difference(unary_union(cuts)), notes, m5


KS_W, KS_OFF, KS_WOOD, KS_OVERLAP = 6.0, 6.0, 6.0, 6.0   # double keeper view slots: 6 wide, centred 6 off the lane line (6 of wood between rows); the two rows overlap 6 at each end


def keeper_slots(L, y_lane, outer_sign):
    """two staggered rows of view slots for one lane, off its centre line (where a ball's widest point rides):
    one row KS_OFF to the outer side at the even hole positions, the other KS_OFF to the inner side at the odd
    ones. Each slot spans its hole position plus KS_OVERLAP (PITCH + KS_OVERLAP long), so it overlaps the
    other row's slots by KS_OVERLAP at each end; trimmed to END_MIN wood at the ends of the piece."""
    out = []
    n = int(round(L / PITCH))
    for i in range(n):
        c = PITCH / 2 + PITCH * i
        y = y_lane + (outer_sign if i % 2 == 0 else -outer_sign) * KS_OFF
        a = max(c - (PITCH + KS_OVERLAP) / 2, END_MIN) + KS_W / 2
        b = min(c + (PITCH + KS_OVERLAP) / 2, L - END_MIN) - KS_W / 2
        out.append(LineString([(a, y), (b, y)]).buffer(KS_W / 2, 24))
    return out


def double_keeper(n):
    """the double sieve's keeper: 71.8 wide, staggered view slots beside each lane line (mirrored about the
    centre), rail M5 on the centre line"""
    L = n * PITCH
    cuts = keeper_slots(L, DBL_HOLE_Y[0], -1) + keeper_slots(L, DBL_HOLE_Y[1], +1)
    cuts += [Point(x, DBL_M5_Y).buffer(M5 / 2, 48) for x in rail_m5_x(n)]
    return box(0, 0, L, DBL_W).difference(unary_union(cuts))


def double_parts(keys=()):
    """{name: (shape, note)} for the two-lane parts (sieve frame: x along, y across): the interface, the flange,
    and double_sieve_<n>h / double_keeper_<n>h for any n asked for in keys (10 always)"""
    from shapely import affinity
    fl = double_flange()[0]
    fl = affinity.translate(fl, -fl.bounds[0], 0)
    out = {
        "double_interface_3h": (double_sieve(3, ["solid", "flange", "hole"])[0], "3 positions: solid / flange (T bolts) / hole"),
        "double_flange": (fl, "wire-track flange for both lanes"),
    }
    sizes = {10} | {int(m.group(1)) for k in keys if (m := re.match(r"double_(?:sieve|keeper)_(\d+)h$", k))}
    for n in sorted(sizes):
        out[f"double_sieve_{n}h"] = (double_sieve(n)[0], f"{n} positions, rail M5 on the centre line")
        out[f"double_keeper_{n}h"] = (double_keeper(n), "staggered 6 mm view slots 6 off each lane line (rows overlap 6), rail M5 on the centre line")
    return out


def pack_bands(items, sheet_w, sheet_h, xgap, ygap, kerf):
    """greedy shelf packing in priority order, left-justified from x 0: each item goes into the first band (row)
    with room, else a new band if the sheet height allows, else it is skipped. items: [(key, w, h)] with w, h the
    kerf-grown sizes. A row fits when its NOMINAL widths (w - kerf) plus the x gaps fit sheet_w: the stock is only
    reliably sheet_w, with just enough over it for the kerf, so two 150 parts butt together on a 300 board.
    -> ([(key, x, y)], [skipped keys])"""
    bands, placed, skipped = [], [], []          # band = [y, height, used_x (kerfed), used_nominal]
    for key, w, h in items:
        for b in bands:
            if h <= b[1] + 1e-9 and b[3] + xgap + (w - kerf) <= sheet_w + 1e-9:
                x = b[2] + xgap
                placed.append((key, x, b[0])); b[2] = x + w; b[3] += xgap + (w - kerf)
                break
        else:
            y = bands[-1][0] + bands[-1][1] + ygap if bands else 0.0
            if y + h <= sheet_h + 1e-9 and w - kerf <= sheet_w + 1e-9:
                bands.append([y, h, w, w - kerf]); placed.append((key, 0.0, y))
            else:
                skipped.append(key)
    return placed, skipped


def min_web(g):
    best = None
    rs = [LineString(r.coords) for r in g.interiors]
    ext = LineString(g.exterior.coords)
    for i, r in enumerate(rs):
        for o in [ext] + rs[i + 1:]:
            d = r.distance(o)
            best = d if best is None else min(best, d)
    return best


def main():
    from laser_parts import emit_cut, load_profile, material_fit, preamble, gcode
    ap = argparse.ArgumentParser()
    ap.add_argument("--material", default="mdf3")
    ap.add_argument("--sizes", type=int, nargs="+", default=list(range(3, 11)), help="ball holes per piece")
    ap.add_argument("--double-flange", action="store_true", help="only the two-lane wire-track flange")
    ap.add_argument("--double-sheet", nargs="*", metavar="PART",
                    help="nest two-lane parts on one sheet, in this priority order (default: interface flange sieve keeper, twice)")
    ap.add_argument("--sheet", type=float, nargs=2, default=[300.0, 292.0], metavar=("W", "H"),
                    help="stock: only reliably W wide (a hair over, enough for the kerf); H < 292 from the reset zero")
    ap.add_argument("--gap", type=float, default=0.7, help="gap between rows (y)")
    ap.add_argument("--xgap", type=float, default=0.0, help="gap between parts in a row (x): 0 = kerf lines butt")
    ap.add_argument("--tag", default="", help="file name tag: double_sheet<tag>_<W>x<H>_<material>")
    args = ap.parse_args()
    T, KERF, _ = material_fit(args.material)
    s2g, motion, mat, job = load_profile(args.material, 1000, None)
    out_dir = HERE.parent / "gcode"
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"T = {T}, KERF = {KERF}")
    thumbs = []
    if args.double_sheet is not None:
        from shapely import affinity
        alias = {"interface": "double_interface_3h", "flange": "double_flange", "sieve": "double_sieve_10h", "keeper": "double_keeper_10h"}
        def key(k):   # interface | flange | sieve | keeper | sieve5 | keeper3 | full names
            m = re.match(r"(sieve|keeper)(\d+)$", k)
            return f"double_{m.group(1)}_{m.group(2)}h" if m else alias.get(k, k)
        order = [key(k) for k in (args.double_sheet or ["interface", "flange", "sieve", "keeper"] * 2)]
        parts = double_parts(order)
        grown = {k: parts[k][0].buffer(KERF / 2, join_style=2) for k in set(order)}
        dims = {k: (g.bounds[2] - g.bounds[0], g.bounds[3] - g.bounds[1]) for k, g in grown.items()}
        W, H = args.sheet
        placed, skipped = pack_bands([(k, *dims[k]) for k in order], W, H, args.xgap, args.gap, KERF)
        cuts, notes = [], []
        for k, x, y in placed:
            g = affinity.translate(grown[k], x - grown[k].bounds[0], y - grown[k].bounds[1])
            for r in list(g.interiors) + [g.exterior]:
                cuts.append(s2g.Polyline(list(r.coords), True))
            notes.append(f"{k} at x {x:.1f} y {y:.1f} ({dims[k][0]:.1f} x {dims[k][1]:.1f}): {parts[k][1]}")
        cuts = gcode.order(cuts)
        ext_x = max(x + dims[k][0] for k, x, y in placed); ext_y = max(y + dims[k][1] for k, x, y in placed)
        name = f"double_sheet{args.tag}_{math.ceil(W)}x{math.ceil(H)}_{args.material}"
        lines = [f"; {name} -- marbles/clock/short_parts.py --double-sheet: {len(placed)} parts, priority order {' '.join(order)}",
                 *[f"; {n}" for n in notes],
                 *([f"; NOT placed (no room): {' '.join(skipped)}"] if skipped else []),
                 f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
                 f"kerf {KERF}; X0 Y0 = the sheet's bottom-left corner; parts reach x {ext_x:.2f} y {ext_y:.2f}",
                 "; 10-hole parts are the full sheet width: their end cuts run along the stock's own edges", ";"]
        lines += preamble(s2g, job)
        for i, c in enumerate(cuts, 1):
            lines += emit_cut(s2g, motion, c, i, len(cuts), job)
        gcode.write(out_dir / f"{name}.gcode", lines)
        print(f"{name}.gcode: {len(placed)} placed, {len(cuts)} cuts, extent {ext_x:.2f} x {ext_y:.2f}; skipped: {skipped or 'none'}")
        for n in notes:
            print("  " + n)
        for k in sorted(set(order)):
            print(f"  {k}: narrowest web {min_web(parts[k][0]):.2f}")
        return
    if args.double_flange:
        g, notes, m5 = double_flange()
        from shapely import affinity
        gk = affinity.rotate(g, 90, origin=(0, 0)).buffer(KERF / 2, join_style=2)   # longest side along X
        x0, y0, x1, y1 = gk.bounds
        name = f"double_flange_{math.ceil(x1 - x0 - 1e-9)}x{math.ceil(y1 - y0 - 1e-9)}_{args.material}"
        loops = [list(r.coords) for r in gk.interiors]
        cuts = gcode.order([s2g.Polyline([(x - x0, y - y0) for x, y in pl], True) for pl in loops]
                           + [s2g.Polyline([(x - x0, y - y0) for x, y in gk.exterior.coords], True)])
        lines = [f"; {name} -- marbles/clock/short_parts.py --double-flange: wire-track flange for both lanes, "
                 f"{DBL_W:g} wide (the double sieve), bores {TUN_FBORE:.2f} at the lanes, M5 T pattern",
                 f"; {notes[0]}",
                 f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
                 f"kerf {KERF}; X0 Y0 = bottom-left; {x1 - x0:.2f} x {y1 - y0:.2f} mm", ";"]
        lines += preamble(s2g, job)
        for i, c in enumerate(cuts, 1):
            lines += emit_cut(s2g, motion, c, i, len(cuts), job)
        gcode.write((out_dir / f"{name}.gcode"), lines)
        print(f"{name}.gcode: narrowest web {min_web(g):.2f}; {notes[0]}")
        return
    for n in args.sizes:
        for kind, g in (("sieve", sieve(n)), ("keeper", keeper(n))):
            gk = g.buffer(KERF / 2, join_style=2)
            x0, y0, x1, y1 = gk.bounds
            name = f"{kind}_{n}h_{math.ceil(x1 - x0 - 1e-9)}x{math.ceil(y1 - y0 - 1e-9)}_{args.material}"
            loops = [list(r.coords) for r in gk.interiors]
            loops.sort(key=lambda pl: abs(Polygon(pl).area))
            loops.append(list(gk.exterior.coords))
            loops = [[(x - x0, y - y0) for x, y in pl] for pl in loops]
            cuts = [s2g.Polyline(pl, True) for pl in loops]
            note = (f"{n} ball holes, rail M5 at X {rail_m5_x(n)} Y 10" if kind == "sieve" else
                    f"view slots {SLOT_L:g} x {SLOT_W:g} on Y 10 ({len(view_slots(n * PITCH, 10))}), rail M5 at X {rail_m5_x(n)} Y 30")
            lines = [f"; {name} -- marbles/clock/short_parts.py: {kind}, {note}",
                     f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
                     f"kerf {KERF}; X0 Y0 = bottom-left; {x1 - x0:.2f} x {y1 - y0:.2f} mm", ";"]
            lines += preamble(s2g, job)
            for i, c in enumerate(cuts, 1):
                lines += emit_cut(s2g, motion, c, i, len(cuts), job)
            gcode.write((out_dir / f"{name}.gcode"), lines)
            print(f"{name}.gcode: {note}; narrowest web {min_web(g):.2f}")
            thumbs.append({"key": name, "polys": [{"outer": list(g.exterior.coords), "holes": [list(h.coords) for h in g.interiors]}]})
    scenes = HERE.parent / "views" / "scenes"
    scenes.mkdir(parents=True, exist_ok=True)
    json.dump(thumbs, open(scenes / "rail_parts.json", "w"))


if __name__ == "__main__":
    main()
