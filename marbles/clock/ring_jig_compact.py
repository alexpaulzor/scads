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
# a la carte: tilt-out mandrels and slide-in backplates, 4- and 8-wire (the S split and the paired files are parked)
WIRES = {4: (45, 135, 225, 315), 8: (0, 45, 90, 135, 180, 225, 270, 315)}
RW = RING_ID / 2 - WD / 2            # wire centre radius (in a mandrel notch)
SLOT_W = WD + 0.15


def mandrel_tilt(angles):
    """mandrel disc (ring ID, M3 rod hole) whose notches each run on out to the rim along +-y from the wire: with the rod
    out, tip the disc edge-on about its x axis (marked by the two rim nicks) and every wire slides out of its notch along
    that channel, then the disc comes out between the wires. The wires never have to move."""
    r = RING_ID / 2
    g = Point(0, 0).buffer(r, 128)
    cuts = [Point(0, 0).buffer(ROD_R, 48)]
    for a in angles:
        t = math.radians(a)
        wx, wy = RW * math.cos(t), RW * math.sin(t)
        cuts.append(affinity.rotate(box(r - WD, -SLOT_W / 2, r + 1, SLOT_W / 2), a, origin=(0, 0)))      # the notch
        if abs(wy) > 1e-6:                                                                              # escape channel
            y1 = math.copysign(r + 1, wy)
            cuts.append(box(wx - SLOT_W / 2, min(wy, y1), wx + SLOT_W / 2, max(wy, y1)))
    for x in (r, -r):                                                                                   # tilt-axis nicks
        cuts.append(Point(x, 0).buffer(0.8, 16))
    return g.difference(unary_union(cuts))


EXPOSE_CLEAR = 6.0    # exposed-wire variant: open this far either side of the wire's surface
CENTRE_HOLE = 3.00    # hole variant: closed centre hole (as cut), the bolt goes in axially and comes out before sliding


def backplate_slide(angles, offset, centre="slot", expose=None):
    """ring-OD + 2 disc that slides on from one side: every slot runs parallel to the slide direction, open at the
    leading edge (with a flared mouth), out to the furthest wire on its line. Slots run at `offset` deg to the wires
    (22.5 for 8 wires keeps the wood between slots >= 3.8). 4-wire plate: an M3 rod slot down the middle too."""
    R = RING_OD / 2 + 1
    g = Point(0, 0).buffer(R, 128)
    lines = {}
    for a in angles:
        t = math.radians(a - offset)
        y = round(RW * math.sin(t), 3)
        lines[y] = max(lines.get(y, -99), RW * math.cos(t))
    cuts = []
    for y, xmax in lines.items():
        cuts.append(LineString([(-R - 1, y), (xmax, y)]).buffer(SLOT_W / 2, 24, cap_style=1))
        cuts.append(Polygon([(-R - 1, y - SLOT_W / 2 - 1.2), (-R + 2.5, y - SLOT_W / 2), (-R + 2.5, y + SLOT_W / 2), (-R - 1, y + SLOT_W / 2 + 1.2)]))
    room = 0.0 not in lines and min(abs(y) for y in lines) - SLOT_W / 2 - ROD_R >= 4
    if centre == "slot" and room:
        cuts.append(LineString([(-R - 1, 0), (0, 0)]).buffer(ROD_R, 24, cap_style=1))
    elif centre == "hole":
        cuts.append(Point(0, 0).buffer(CENTRE_HOLE / 2, 48))
    plate = affinity.rotate(g.difference(unary_union(cuts)), offset, origin=(0, 0))
    if expose is not None:
        # open round one wire: from its inner surface out to the rim, EXPOSE_CLEAR either side of it; symmetric about
        # that wire's radial line, so the plate flipped over that line exposes the same wire with its slots the other way
        c = WD / 2 + EXPOSE_CLEAR
        win = affinity.rotate(box(RW - WD / 2, -c, R + 2, c), expose, origin=(0, 0))
        others = [Point(RW * math.cos(math.radians(a)), RW * math.sin(math.radians(a))) for a in angles if a != expose]
        wood = min(p.distance(win) for p in others) - SLOT_W / 2
        plate = plate.difference(win)
        return plate, wood
    return plate, sorted(lines)


VARIANTS = {}
hole_plate, _ = backplate_slide(WIRES[4], 0.0, centre="hole")
VARIANTS["ring_back_slide_4w_hole3"] = hole_plate
write("ring_back_slide_4w_hole3", [hole_plate], args.spider_material,
      f"4-wire slide-on backplate d{RING_OD + 2:.2f}, closed {CENTRE_HOLE:.2f} centre hole (bolt out before sliding)")
for n, off in ((4, 0.0), (8, 22.5)):
    # which wire to expose: the plate must stay one piece (the window can't cut a tine's root); most wood wins
    best = None
    for ex in WIRES[n]:
        pl, wood = backplate_slide(WIRES[n], off, centre="hole" if n == 4 else "slot", expose=ex)
        if pl.geom_type == "Polygon" and (best is None or wood > best[1]):
            best = (pl, wood, ex)
    pl, wood, ex = best
    print(f"  {n}w exposed: wire at {ex} deg open {EXPOSE_CLEAR:g} each side; wood beside the neighbours' slots "
          f"{wood:.2f}; flip over the {ex} deg line for slots at {(2 * ex - off) % 180:g} deg (vs {off:g})")
    VARIANTS[f"ring_back_slide_{n}w_expose"] = pl
    write(f"ring_back_slide_{n}w_expose", [pl], args.spider_material,
          f"{n}-wire slide-on backplate, wire at {ex} deg exposed ({EXPOSE_CLEAR:g} clear each side)" + (f", {CENTRE_HOLE:.2f} centre hole" if n == 4 else "") + "; flip one for the cross direction")
for n, ang in WIRES.items():
    write(f"ring_mandrel_{n}w", [mandrel_tilt(ang)], args.spider_material,
          f"{n}-wire tilt-out mandrel d{RING_ID:.2f}, M{args.rod:g} rod; notches run out along +-y (tilt about x: rim nicks)")
    off = 0.0 if n == 4 else 22.5
    bp_g, levels = backplate_slide(ang, off)
    write(f"ring_back_slide_{n}w", [bp_g], args.spider_material,
          f"{n}-wire slide-on backplate d{RING_OD + 2:.2f}: {len(levels)} parallel slots at {off:g} deg to the wires, open on one side")


# one sheet: a row of each part (4w mandrel, 8w mandrel, 4w backplate, 8w backplate), as many as fit along x to --pairs-x
def sheet_rows(max_x, gap_xy=3.0):
    parts = [mandrel_tilt(WIRES[4]), mandrel_tilt(WIRES[8]), backplate_slide(WIRES[4], 0.0)[0], backplate_slide(WIRES[8], 22.5)[0]]
    out, y, counts = [], 0.0, []
    for g in parts:
        x0, y0, x1, y1 = g.bounds
        w, h = x1 - x0, y1 - y0
        n = int((max_x - KERF_ROW + gap_xy) // (w + gap_xy))
        out += [affinity.translate(g, -x0 + i * (w + gap_xy), -y0 + y) for i in range(n)]
        counts.append(n)
        y += h + gap_xy
    return out, counts


KERF_ROW = 0.2
rows, cnt = sheet_rows(args.pairs_x)
write(f"ring_tilt_slide_rows_{cnt[0]}m4_{cnt[1]}m8_{cnt[2]}b4_{cnt[3]}b8", rows, args.spider_material,
      f"rows to {args.pairs_x:g}: {cnt[0]} x 4w mandrel, {cnt[1]} x 8w mandrel, {cnt[2]} x 4w slide backplate, {cnt[3]} x 8w slide backplate")


# a 300 mm row (along x, to --pairs-x) of each backplate variant, one file each
for name, g in VARIANTS.items():
    x0, y0, x1, y1 = g.bounds
    w = x1 - x0
    n = int((args.pairs_x - KERF_ROW + gap) // (w + gap))
    write(f"{name}_row{n}", [affinity.translate(g, -x0 + i * (w + gap), -y0) for i in range(n)], args.spider_material,
          f"{n} x {name} in a row to {args.pairs_x:g}")
