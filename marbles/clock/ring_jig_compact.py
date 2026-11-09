#!/usr/bin/env python3
"""Compact single-layer wire-ring jig (D shape) + spacing spiders. No etching.

JIG (veneer plywood by default): one D-shaped plate stuck to scrap backing.
  - The FLAT EDGE is exactly one ring's wire length (pi x wire centreline diameter): lay the
    wire along it and snip at the corner.
  - A round hole = ring outside diameter + clearance; the CORE (= ring inside diameter) is cut
    in place inside it, already centred: a spider shape (notches, M5 centre) with the iron hole
    carved out of it too. Stick the plate and the core down together, or pin the core with M5.
  - A 15 mm iron hole centred on the wire's circle, at the top of the dome.
  - At least 10 mm of wood round the ring hole, at least 4 round the iron hole.
SPIDERS (veneer plywood by default): discs = ring inside diameter with notches one wire deep at the
  straight-wire angles and an M5 centre hole; string them on an M5 rod as a mandrel.

    python3 marbles/clock/ring_jig_compact.py      # -> marbles/gcode/ring_jig_d_<W>x<H>_ply3.gcode, ring_mandrel_<W>x<H>_ply3.gcode
"""
import argparse
import math
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import emit_cut, load_profile, material_fit, preamble, gcode  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("--jig-material", default="ply3")
ap.add_argument("--spider-material", default="ply3")
ap.add_argument("--wire", type=float, default=2.05)
ap.add_argument("--bore", type=float, default=20.0, help="clear bore for the ball inside the straight wires")
ap.add_argument("--groove-clr", type=float, default=0.3)
ap.add_argument("--iron", type=float, default=15.0)
ap.add_argument("--wall", type=float, default=10.0, help="wood round the ring hole")
ap.add_argument("--angles", type=float, nargs="+", default=[45, 135, 225, 315])
ap.add_argument("--spiders", type=int, default=1, help="mandrel discs in the mandrel file")
ap.add_argument("--centre-y", type=float, default=None,
                help="ring centre this far above the flat edge (30 = on the upper of two stacked 2020s; default: wall)")
ap.add_argument("--mount-y", type=float, default=None,
                help="M5 rail-mount holes this far above the flat edge (10 = into the lower 2020's slot)")
ap.add_argument("--base", action="store_true", help="also write the plain base layer (outline + mount M5 + centre M5)")
ap.add_argument("--tag", default="", help="suffix for the file names")
ap.add_argument("--iron-clear", type=float, default=0.0,
                help="extra diameter on THIS layer's iron hole (e.g. 4 for the acrylic in a ply/acrylic/ply sandwich)")
IRON_CLEAR_MAX = 4.0     # the dome is always sized for the largest iron hole, so every layer has the same outline
args = ap.parse_args()

WD = args.wire
RING_ID = args.bore + 2 * WD
RING_CL = RING_ID + WD
RING_OD = RING_ID + 2 * WD
CUT_LEN = math.pi * RING_CL
HOLE = RING_OD + args.groove_clr
WEB = 4.0


def jig_and_core():
    r_iron = RING_CL / 2 + (args.iron + IRON_CLEAR_MAX) / 2   # largest iron hole's far edge from the centre
    R = max(HOLE / 2 + args.wall, r_iron + WEB)   # dome radius
    yc = args.centre_y if args.centre_y else HOLE / 2 + args.wall   # wood between the hole and the flat edge
    c = (CUT_LEN / 2, yc)
    outline = unary_union([box(0, 0, CUT_LEN, 0.01), Point(c).buffer(R, 128)]).convex_hull.intersection(box(0, 0, CUT_LEN, 1000))
    iron = Point(c[0], c[1] + RING_CL / 2).buffer((args.iron + args.iron_clear) / 2, 96)
    plate = outline.difference(unary_union([Point(c).buffer(HOLE / 2, 128), iron] + [Point(m).buffer(2.5, 48) for m in mounts(outline)]))
    # core: a spider (notches + M5 centre, so it can also be bolted/pinned to the backing) with the
    # iron hole carved out, cut in place inside the plate's hole with the bite lined up
    core = spider().difference(Point(0, RING_CL / 2).buffer((args.iron + args.iron_clear) / 2, 96))
    core = affinity.translate(core, *c)
    return plate, core, R, yc, outline


def mounts(outline):
    """M5 rail-mount holes at y = mount_y, as far out toward the ends as WEB of wood to the outline allows"""
    if not args.mount_y:
        return []
    out = []
    for side in (0, 1):
        for i in range(int(CUT_LEN / 2 / 0.25)):
            x = 2.5 + WEB + 0.25 * i
            x = x if side == 0 else CUT_LEN - x
            if outline.buffer(-(2.5 + WEB)).contains(Point(x, args.mount_y)):
                out.append((x, args.mount_y))
                break
    return out


def base_layer(plate_outline, c):
    return plate_outline.difference(unary_union([Point(m).buffer(2.5, 48) for m in mounts(plate_outline)] + [Point(c).buffer(2.5, 48)]))


def spider():
    g = Point(0, 0).buffer(RING_ID / 2, 128)
    r = RING_ID / 2
    w = WD + 0.15
    cuts = [affinity.rotate(box(r - WD, -w / 2, r + 1, w / 2), a, origin=(0, 0)) for a in args.angles]
    cuts.append(Point(0, 0).buffer(2.5, 48))
    return g.difference(unary_union(cuts))


def write(name_base, polys, material, note):
    """polys are cut in list order, each one's holes before its outline (put parts that sit inside
    another part's hole first)"""
    T, KERF, _ = material_fit(material)
    s2g, motion, mat, job = load_profile(material, 1000, None)
    gs = [p.buffer(KERF / 2, join_style=2) for p in polys]
    x0 = min(g.bounds[0] for g in gs); y0 = min(g.bounds[1] for g in gs)
    x1 = max(g.bounds[2] for g in gs); y1 = max(g.bounds[3] for g in gs)
    order = []
    for g in gs:
        g = affinity.translate(g, -x0, -y0)
        order += sorted([list(r.coords) for r in g.interiors], key=lambda pl: abs(Polygon(pl).area))
        order.append(list(g.exterior.coords))
    name = f"{name_base}_{math.ceil(x1 - x0 - 1e-9)}x{math.ceil(y1 - y0 - 1e-9)}_{material}"
    cuts = [s2g.Polyline(pl, True) for pl in order]
    lines = [f"; {name} -- marbles/clock/ring_jig_compact.py: {note}",
             f"; {mat['id']} (T {T}) recipe {job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}; kerf {KERF}; "
             f"X0 Y0 = bottom-left; {x1 - x0:.2f} x {y1 - y0:.2f} mm", ";"]
    lines += preamble(s2g, job)
    for i, c in enumerate(cuts, 1):
        lines += emit_cut(s2g, motion, c, i, len(cuts), job)
    out = HERE.parent / "gcode" / f"{name}.gcode"
    out.parent.mkdir(parents=True, exist_ok=True)
    gcode.write(out, lines)
    print(f"wrote {out.name}: {x1 - x0:.2f} x {y1 - y0:.2f} mm ({material})")
    return out


plate, core, R, yc, outline = jig_and_core()
print(f"wire {WD}, bore {args.bore}: ring ID {RING_ID:.2f}, OD {RING_OD:.2f}, cut length pi x {RING_CL:.2f} = {CUT_LEN:.2f}")
print(f"jig: flat edge {CUT_LEN:.2f} (the cut-length gauge), hole d{HOLE:.2f}, dome radius {R:.2f}, "
      f"wood: hole to flat edge {yc - HOLE / 2:.2f}, hole to dome {R - HOLE / 2:.2f}, "
      f"iron hole d{args.iron + args.iron_clear:g} to dome {R - RING_CL / 2 - (args.iron + args.iron_clear) / 2:.2f}; groove {(HOLE - RING_ID) / 2:.2f} for a {WD} wire")
ms = mounts(outline)
if args.centre_y or ms:
    print(f"mount: ring centre {yc:g} above the flat edge; M5 at {[(round(x, 2), y) for x, y in ms]}; "
          f"wood M5 to ring hole {min(Point(m).distance(Point(CUT_LEN / 2, yc)) for m in ms) - 2.5 - HOLE / 2:.2f}" if ms else "")
gap = 3.0
write("ring_jig_d" + args.tag, [core, plate], args.jig_material,
      "core (spider shape minus the iron hole) cut in place inside the D plate's hole, then the D plate (flat edge = wire cut length)"
      + (f"; ring centre {yc:g} up, M5 rail holes {args.mount_y:g} up" if args.mount_y else ""))
if args.base:
    write("ring_jig_base" + args.tag, [base_layer(outline, (CUT_LEN / 2, yc))], args.jig_material,
          "plain base layer for the sandwich: D outline, M5 rail holes, M5 at the ring centre")
sp = [] if args.spiders < 1 else [affinity.translate(spider(), RING_ID / 2 + i * (RING_ID + gap), RING_ID / 2) for i in range(args.spiders)]
if sp:
    write("ring_mandrel" if args.spiders == 1 else f"ring_mandrel_x{args.spiders}", sp, args.spider_material,
          f"mandrel / spacing spider x{args.spiders}, notches at {args.angles} deg, M5 centre")
