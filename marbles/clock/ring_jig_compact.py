#!/usr/bin/env python3
"""Compact single-layer wire-ring jig (D shape) + spacing spiders. No etching.

JIG (veneer plywood by default): one D-shaped plate stuck to scrap backing.
  - The FLAT EDGE is exactly one ring's wire length (pi x wire centreline diameter): lay the
    wire along it and snip at the corner.
  - A round hole = ring outside diameter + clearance; the CORE (= ring inside diameter) is cut
    in place inside it, already centred: a spider shape (notches, rod hole) with the iron hole
    carved out of it too. Stick the plate and the core down together, or pin the core on the rod.
  - A 15 mm iron hole centred on the wire's circle, at the top of the dome.
  - At least 10 mm of wood round the ring hole, at least 4 round the iron hole.
SPIDERS (veneer plywood by default): discs = ring inside diameter with notches one wire deep at the
  straight-wire angles and a centre hole for the threaded rod (M3 by default), split in two along a yin-yang S so they
  come out of a soldered tube; string them on the rod as a mandrel.
BACKPLATES: discs = ring OUTSIDE diameter with the same rod hole and the same wire slots, open to the rim and flared
  wider toward it so the plate comes off past the soldered joints. Put one on the rod behind a mandrel: the straight wires pass through its slots and the ring sits against
  its face, so the ring stays square and in place while you set up to solder.

    python3 marbles/clock/ring_jig_compact.py      # -> marbles/gcode/ring_jig_d_<W>x<H>_ply3.gcode, ring_mandrel_<W>x<H>_ply3.gcode,
                                                   #    ring_mandrel_back_<W>x<H>_ply3.gcode, ring_mandrel_pair_<W>x<H>_ply3.gcode,
                                                   #    ring_mandrel_pairs_<n>m<n>b_<W>x<H>_ply3.gcode (alternating along x to --pairs-x)
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
ap.add_argument("--angles", type=float, nargs="+", default=[45, 135, 225, 315, 0, 90, 180, 270],
                help="straight-wire angles: default the 8-notch flange interface (short_parts.FLANGE_ANGLES)")
ap.add_argument("--spiders", type=int, default=1, help="mandrel discs in the mandrel file")
ap.add_argument("--backplates", type=int, default=1, help="mandrel backplates (ring-OD discs) in the backplate file")
ap.add_argument("--rod", type=float, default=3.0, help="threaded rod through the mandrel, backplate, jig core and base (mm)")
ap.add_argument("--centre-y", type=float, default=30.0,
                help="ring centre this far above the flat edge (30 = on the upper of two stacked 2020s, as the acrylic layer; 0: wall)")
ap.add_argument("--mount-y", type=float, default=10.0,
                help="M5 rail-mount holes this far above the flat edge (10 = into the lower 2020's slot; 0: none)")
ap.add_argument("--base", action="store_true", help="also write the plain base layer (outline + mount M5 + centre M5)")
ap.add_argument("--tag", default="_rail", help="suffix for the file names")
ap.add_argument("--pairs-x", type=float, default=300.0, help="mandrel + backplate pairs repeated along x out to this (mm)")
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
ROD_R = (args.rod + 0.3) / 2          # rod clearance hole radius
FLARE = 1.5                           # backplate slots widen by this much each side from the wire out to the rim


def jig_and_core():
    r_iron = RING_CL / 2 + (args.iron + IRON_CLEAR_MAX) / 2   # largest iron hole's far edge from the centre
    R = max(HOLE / 2 + args.wall, r_iron + WEB)   # dome radius
    yc = args.centre_y if args.centre_y else HOLE / 2 + args.wall   # wood between the hole and the flat edge
    c = (CUT_LEN / 2, yc)
    outline = unary_union([box(0, 0, CUT_LEN, 0.01), Point(c).buffer(R, 128)]).convex_hull.intersection(box(0, 0, CUT_LEN, 1000))
    iron = Point(c[0], c[1] + RING_CL / 2).buffer((args.iron + args.iron_clear) / 2, 96)
    plate = outline.difference(unary_union([Point(c).buffer(HOLE / 2, 128), iron] + [Point(m).buffer(2.5, 48) for m in mounts(outline)]))
    # core: a spider (notches + rod hole, so it can also be pinned to the backing) with the
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
    return plate_outline.difference(unary_union([Point(m).buffer(2.5, 48) for m in mounts(plate_outline)] + [Point(c).buffer(ROD_R, 48)]))


SPLIT_GAP = 0.1      # the S is cut as a gap this wide (= the kerf): after the kerf offset both halves' paths meet on the S


def s_curve(r):
    """yin-yang S through the centre: straight in from the rim through the top notch (90 deg) to 1.5 below its floor, a
    semicircle to the centre, the opposite semicircle, then straight out through the bottom notch (270 deg); no slivers
    at the rim (the cut leaves it square through the notch floor). Runs 1 past the rim at both ends."""
    y0 = r - WD - 1.5
    h = y0 / 2
    a = [(h * math.cos(math.radians(90 - 180 * i / 60)), h + h * math.sin(math.radians(90 - 180 * i / 60))) for i in range(61)]
    b = [(h * math.cos(math.radians(90 + 180 * i / 60)), -h + h * math.sin(math.radians(90 + 180 * i / 60))) for i in range(1, 61)]
    return LineString([(0, r + 1)] + a + b + [(0, -r - 1)])


def spider(split=False):
    """mandrel disc: ring ID, wire notches, rod hole. split: cut in two along a yin-yang S through the centre (the halves
    mesh; the wires round them hold them together, and they come out one at a time once the rod is pulled)"""
    g = Point(0, 0).buffer(RING_ID / 2, 128)
    r = RING_ID / 2
    w = WD + 0.15
    cuts = [affinity.rotate(box(r - WD, -w / 2, r + 1, w / 2), a, origin=(0, 0)) for a in args.angles]
    cuts.append(Point(0, 0).buffer(ROD_R, 48))
    if split:
        cuts.append(s_curve(r).buffer(SPLIT_GAP / 2, cap_style=2))
    return g.difference(unary_union(cuts))


def backplate():
    """ring-OD disc with the mandrel's rod hole and its wire slots, OPEN to the edge and flared (wider toward the
    rim), so the plate lifts off past the soldered joints; the lands between the slots still carry the ring"""
    g = Point(0, 0).buffer(RING_OD / 2, 128)
    r = RING_ID / 2
    w = WD + 0.15
    R = RING_OD / 2 + 1
    flare = Polygon([(r - WD, -w / 2), (r, -w / 2), (R, -w / 2 - FLARE), (R, w / 2 + FLARE), (r, w / 2), (r - WD, w / 2)])
    cuts = [affinity.rotate(flare, a, origin=(0, 0)) for a in args.angles]
    cuts.append(Point(0, 0).buffer(ROD_R, 48))
    return g.difference(unary_union(cuts))


TW_OD = RING_OD + 2.0  # twist-lock backplate: just over the ring OD (40 was far too big: the wires would not come out)
TW_LEG = 3.6          # sideways leg: the wire travels this far (arc at the wire radius) when you twist the plate
TW_BUMP = 0.3         # entry bump: the leg's outer wall pinches in this much just past the entry (wire snaps past it)


def backplate_twist():
    """bayonet backplate: each wire comes in through a radial slot from the rim (flared like the plain backplate), then
    a sideways leg at the wire's radius; push it on, twist so the wires run into the legs past a small bump, and the
    plate holds every wire down in the mandrel's notches. Twist back to take it off."""
    rw = RING_ID / 2 - WD / 2                 # wire centre radius (in the mandrel's notch)
    w = WD + 0.15
    R = TW_OD / 2 + 1
    g = Point(0, 0).buffer(TW_OD / 2, 128)
    entry = Polygon([(rw - w / 2, -w / 2), (rw + w / 2, -w / 2), (R, -w / 2 - FLARE), (R, w / 2 + FLARE), (rw + w / 2, w / 2), (rw - w / 2, w / 2)])
    entry = unary_union([entry, Point(rw, 0).buffer(w / 2, 32)])
    lt = math.degrees(TW_LEG / rw)
    arc = LineString([(rw * math.cos(math.radians(t * lt / 30)), rw * math.sin(math.radians(t * lt / 30))) for t in range(31)])
    leg = arc.buffer(w / 2, 32)
    tb = math.degrees((w / 2 + 0.8) / rw)    # bump just past the entry slot's edge, on the leg's outer wall
    bump = Point((rw + w / 2) * math.cos(math.radians(tb)), (rw + w / 2) * math.sin(math.radians(tb))).buffer(TW_BUMP + 0.4, 32) \
        .intersection(Point(0, 0).buffer(rw + w / 2 + 1, 64).difference(Point(0, 0).buffer(rw + w / 2 - TW_BUMP, 64)))
    slot = unary_union([entry, leg]).difference(bump)
    cuts = [affinity.rotate(slot, a, origin=(0, 0)) for a in args.angles] + [Point(0, 0).buffer(ROD_R, 48)]
    return g.difference(unary_union(cuts))


def write(name_base, polys, material, note):
    """polys are cut in list order, each one's holes before its outline (put parts that sit inside
    another part's hole first)"""
    T, KERF, _ = material_fit(material)
    s2g, motion, mat, job = load_profile(material, 1000, None)
    gs = [q.buffer(KERF / 2, join_style=2) for p in polys for q in getattr(p, "geoms", [p])]   # split halves stay apart
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
sp = [] if args.spiders < 1 else [affinity.translate(spider(split=True), RING_ID / 2 + i * (RING_ID + gap), RING_ID / 2) for i in range(args.spiders)]
if sp:
    write("ring_mandrel" if args.spiders == 1 else f"ring_mandrel_x{args.spiders}", sp, args.spider_material,
          f"mandrel / spacing spider x{args.spiders}, notches at {args.angles} deg, M{args.rod:g} rod hole")
bp = [] if args.backplates < 1 else [affinity.translate(backplate(), RING_OD / 2 + i * (RING_OD + gap), RING_OD / 2) for i in range(args.backplates)]
if bp:
    write("ring_mandrel_back" if args.backplates == 1 else f"ring_mandrel_back_x{args.backplates}", bp, args.spider_material,
          f"mandrel backplate x{args.backplates}: ring OD d{RING_OD:.2f}, flared open wire slots at {args.angles} deg, M{args.rod:g} rod hole")

# mandrel + backplate together: one pair, and pairs repeated along x out to --pairs-x (the length of the strip you cut from)
def pair_row(n_max_x):
    items, x = [], 0.0
    while True:
        for g, d in ((spider(split=True), RING_ID), (backplate_twist(), TW_OD)):
            if x + d + KERF_MAX > n_max_x:
                return items
            items.append(affinity.translate(g, x + d / 2, TW_OD / 2))
            x += d + gap


KERF_MAX = 0.2
if args.spiders > 0 and args.backplates > 0:
    one_pair = [affinity.translate(spider(split=True), RING_ID / 2, TW_OD / 2), affinity.translate(backplate_twist(), RING_ID + gap + TW_OD / 2, TW_OD / 2)]
    TW_NOTE = (f"twist-lock backplate d{TW_OD:g}: radial entry slots, then {TW_LEG:g} sideways legs at the wire radius "
               f"(twist {math.degrees(TW_LEG / (RING_ID / 2 - WD / 2)):.1f} deg) past a {TW_BUMP:g} bump")
    write("ring_mandrel_twist_pair", one_pair, args.spider_material,
          f"1 mandrel d{RING_ID:.2f} + 1 {TW_NOTE}")
    row = pair_row(args.pairs_x)
    n_sp, n_bp = (len(row) + 1) // 2, len(row) // 2
    write(f"ring_mandrel_twist_pairs_{n_sp}m{n_bp}b", row, args.spider_material,
          f"{n_sp} mandrels + {n_bp} twist-lock backplates alternating along x (to {args.pairs_x:g})")
