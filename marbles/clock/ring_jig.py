#!/usr/bin/env python3
"""Wire-ring soldering jig + spacing spiders for tubular wire track.

TRACK: rings of wire (fixed size) with straight wires soldered along their inside.
  ring inner diameter = BORE + 2 x wire, so the marble sees a clear BORE inside the
  straight wires (BORE = 20: 3/4" ball 19.05 + rolling clearance).
JIG (3 parts, glue or bolt):
  JB base   - solid; etched glue circle for the core; 3 mm pin hole at the ring centre
  JT top    - same outline; hole = ring OD + clearance. With the core it leaves a
              groove one wire wide that holds a ring at exact size while you solder
              the butt joint. Etched cut-length guide (one ring's wire) and labels.
  JC core   - disc = ring ID; glue on the base inside the top's hole (3 mm pin centres it)
  A 15 mm hole through all three, centred on the wire's circumference, clears the
  joint for the iron and keeps wood away from it.
SPIDER SP (several) - disc = ring ID with notches one wire deep at the straight-wire
  positions, M5 centre hole. String them on an M5 threaded rod: the straight wires lie
  in the notches flush with the rim, rings slide over at exact size, the spiders slide
  out of the finished tube. Etched ticks every 15 degrees for other wire layouts.
  Also the forming core: wrap the wire round a spider's rim to pre-bend a ring.

Thickness, kerf from the material profile (mdf_3mm: 3.1 / 0.10). Etch recipe: the
material's own, else --etch-from (unverified on MDF until you test it).

    python3 marbles/clock/ring_jig.py                      # -> marbles/gcode/ring_jig.gcode
    python3 marbles/clock/ring_jig.py --wire 1.6 --angles 30 150 270
"""
import argparse
import json
import math
import subprocess
import sys
import tempfile
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import (ETCH_LEAD_IN_MM, ETCH_MIN_SEG_MM, emit_cut, load_profile,  # noqa: E402
                         material_fit, preamble)

ap = argparse.ArgumentParser()
ap.add_argument("--material", default="plywood_veneer_3ply_3mm")   # wire jigs: veneer plywood
ap.add_argument("--etch-from", default="plywood_baltic_birch_3mm", help="etch recipe if the material has none")
ap.add_argument("--wire", type=float, default=2.05, help="wire diameter (hybrid.scad rail_d)")
ap.add_argument("--bore", type=float, default=20.0, help="clear bore for the marble")
ap.add_argument("--iron", type=float, default=15.0, help="soldering iron clearance hole")
ap.add_argument("--groove-clr", type=float, default=0.3, help="extra on the top's hole so the ring drops in")
ap.add_argument("--notch-clr", type=float, default=0.15, help="extra width on spider notches")
ap.add_argument("--angles", type=float, nargs="+", default=[45, 135, 225, 315],
                help="straight-wire positions, degrees (270 = bottom)")
ap.add_argument("--spiders", type=int, default=4)
ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode" / "ring_jig.gcode")
args = ap.parse_args()

T, KERF, _ = material_fit(args.material)
WD = args.wire
RING_ID = args.bore + 2 * WD
RING_CL = RING_ID + WD                     # wire centreline diameter
RING_OD = RING_ID + 2 * WD
CUT_LEN = math.pi * RING_CL
HOLE_TOP = RING_OD + args.groove_clr
PIN = 3.0
M5 = 5.0
PW, PH = 110.0, 64.0                       # jig plate
C = (32.0, 38.0)                           # ring centre on the plates
IRON_C = (C[0] + RING_CL / 2, C[1])        # iron hole on the wire's circumference
ALIGN = [(8.0, PH - 8.0), (PW - 8.0, PH - 8.0)]
WEB = max(4.0, T)


def circle(c, d, n=128):
    return Point(c).buffer(d / 2, n)


def plate_base():
    cuts = [circle(IRON_C, args.iron), circle(C, PIN)] + [circle(p, M5, 48) for p in ALIGN]
    return box(0, 0, PW, PH).difference(unary_union(cuts))


def plate_top():
    cuts = [circle(C, HOLE_TOP), circle(IRON_C, args.iron)] + [circle(p, M5, 48) for p in ALIGN]
    return box(0, 0, PW, PH).difference(unary_union(cuts))


def core():
    return circle(C, RING_ID).difference(unary_union([circle(IRON_C, args.iron), circle(C, PIN)]))


def spider():
    g = circle((0, 0), RING_ID)
    r = RING_ID / 2
    w = WD + args.notch_clr
    notch = box(r - WD, -w / 2, r + 1, w / 2)
    cuts = [affinity.rotate(notch, a, origin=(0, 0)) for a in args.angles] + [circle((0, 0), M5, 48)]
    return g.difference(unary_union(cuts))


def spider_ticks():
    r = RING_ID / 2
    out = []
    for k in range(24):
        a = math.radians(15 * k)
        r0 = r - WD - (2.5 if k % 6 == 0 else 1.2)
        r1 = r - WD - 0.4
        out.append([(r0 * math.cos(a), r0 * math.sin(a)), (r1 * math.cos(a), r1 * math.sin(a))])
    return out


def min_web(g):
    best = None
    for poly in ([g] if g.geom_type == "Polygon" else list(g.geoms)):
        rs = [LineString(rr.coords) for rr in poly.interiors]
        ext = LineString(poly.exterior.coords)
        for i, rr in enumerate(rs):
            for o in [ext] + rs[i + 1:]:
                d = rr.distance(o)
                best = d if best is None else min(best, d)
    return best


def text_loops(s2g, s, size, x, y, halign="left"):
    """outline loops of text via OpenSCAD, placed with its baseline-left at (x, y)"""
    with tempfile.TemporaryDirectory() as td:
        scad = Path(td) / "t.scad"
        svg = Path(td) / "t.svg"
        scad.write_text(f'text("{s}", size={size}, font="Liberation Sans:style=Bold", halign="{halign}");')
        r = subprocess.run(["openscad", "-o", str(svg), str(scad)], capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit(r.stderr)
        lines, u = s2g.parse_svg(svg.read_text())
    return [[(px * u + x, -py * u + y) for px, py in pl.points] for pl in lines]


s2g, motion, mat, job = load_profile(args.material, 1000, None)

# ---- etch layer on the top plate: cut-length guide + labels
etch = []                                   # list of (points, closed)
x0, y0 = 10.0, 9.0
x1 = x0 + CUT_LEN
etch.append(([(x0, y0), (x1, y0)], False))
for xe in (x0, x1):                         # end bars
    etch.append(([(xe, y0 - 4), (xe, y0 + 6)], False))
for i in range(int(CUT_LEN) + 1):
    if i % 5:
        continue
    xt = x0 + i
    etch.append(([(xt, y0), (xt, y0 + (3.0 if i % 10 == 0 else 1.6))], False))
for pl in text_loops(s2g, f"CUT {CUT_LEN:.2f}", 3.2, x0 + CUT_LEN / 2, y0 + 7.5, "center"):
    etch.append((pl, True))
lab = f"RING ID {RING_ID:.2f}  WIRE {WD:g}"
for pl in text_loops(s2g, lab, 2.6, PW - 8, 32, "right"):
    etch.append((pl, True))
for pl in text_loops(s2g, f"BORE {args.bore:g}", 2.6, PW - 8, 26, "right"):
    etch.append((pl, True))
# base: glue circle for the core (etched on the base, which sits under the top)

# ---- report
print(f"T = {T}, KERF = {KERF}; wire {WD}, bore {args.bore}")
print(f"ring: ID {RING_ID:.2f}, centreline {RING_CL:.2f}, OD {RING_OD:.2f}; cut length pi x {RING_CL:.2f} = {CUT_LEN:.2f}")
print(f"top hole {HOLE_TOP:.2f} (OD + {args.groove_clr}); groove {(HOLE_TOP - RING_ID) / 2:.2f} wide for a {WD} wire")
print(f"iron hole d{args.iron:g} centred at {IRON_C} on the wire circumference")
cw = min_web(core())
print(f"core: d{RING_ID:.2f}, pin d{PIN:g}; narrowest web {cw:.2f}")
print(f"spider: d{RING_ID:.2f}, notches {WD + args.notch_clr:.2f} wide x {WD:g} deep at {args.angles} deg, M5 centre; "
      f"narrowest web {min_web(spider()):.2f}")
print(f"plates {PW:g} x {PH:g}; base web {min_web(plate_base()):.2f}, top web {min_web(plate_top()):.2f}")
r_w = RING_ID / 2 - WD / 2
gaps = sorted(args.angles)
gap = max(((gaps[(i + 1) % len(gaps)] - gaps[i]) % 360) for i in range(len(gaps)))
chord = 2 * r_w * math.sin(math.radians(gap / 2)) - WD
print(f"widest opening between straight wires: {gap:g} deg -> {chord:.2f} clear (ball 19.05 must not pass)")

# ---- layout: top plate, base plate above it, core + spiders in a column to the right
GAP = 3.0
parts = []                                  # (name, geom, etch list in part coords)
parts.append(("JT top", plate_top(), etch, (0, 0)))
glue = [(list(circle(C, RING_ID, 96).exterior.coords), True)]
parts.append(("JB base", plate_base(), glue, (0, PH + GAP)))
colx = PW + GAP + RING_ID / 2
parts.append(("JC core", affinity.translate(core(), -C[0], -C[1]), [], (colx, RING_ID / 2)))
for i in range(args.spiders):
    ticks = [(t, False) for t in spider_ticks()]
    parts.append((f"SP spider {i + 1}", spider(), ticks, (colx, RING_ID / 2 + (i + 1) * (RING_ID + GAP))))
placed = []
for name, g, et, (dx, dy) in parts:
    placed.append((name, affinity.translate(g, dx, dy), [([(x + dx, y + dy) for x, y in pts], cl) for pts, cl in et]))

# kerf + move to origin
geoms = [g.buffer(KERF / 2, join_style=2) for _, g, _ in placed]
bx0 = min(g.bounds[0] for g in geoms); by0 = min(g.bounds[1] for g in geoms)
bx1 = max(g.bounds[2] for g in geoms); by1 = max(g.bounds[3] for g in geoms)
sh = lambda pts: [(x - bx0, y - by0) for x, y in pts]
holes, outers, etches = [], [], []
for (name, _, et), gk in zip(placed, geoms):
    for poly in ([gk] if gk.geom_type == "Polygon" else list(gk.geoms)):
        holes += [sh(list(r.coords)) for r in poly.interiors]
        outers.append(sh(list(poly.exterior.coords)))
    etches += [(sh(p), cl) for p, cl in et]
holes.sort(key=lambda pl: abs(Polygon(pl).area))
outers.sort(key=lambda pl: abs(Polygon(pl).area))

# ---- G-code: etch first, then holes, then outlines
er = mat.get("etch")
etch_src = args.material
if not er:
    import yaml
    from materials import SHARED_MATERIALS
    er = {m["id"]: m for m in yaml.safe_load(Path(SHARED_MATERIALS).read_text())}[args.etch_from]["etch"]
    etch_src = f"{args.etch_from} (UNVERIFIED on {args.material})"
etch_s = round(er["power_percent"] / 100 * 1000)
etch_on = "M3" if er.get("mode", "static") == "static" else "M4"
W, H = bx1 - bx0, by1 - by0
lines = [f"; ring_jig -- marbles/clock/ring_jig.py: wire-ring soldering jig (top, base, core) + {args.spiders} spacing spiders",
         f"; ring ID {RING_ID:.2f} (bore {args.bore:g} + 2 x wire {WD:g}), wire cut length {CUT_LEN:.2f}; "
         f"spider notches at {args.angles} deg",
         f"; T = {T} mm on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); kerf {KERF}",
         f"; etch first: {er['power_percent']}% F{er['feed_mm_per_min']} from {etch_src}",
         f"; X0 Y0 = bottom-left; footprint {W:.2f} x {H:.2f} mm", ";"]
lines += preamble(s2g, job)
lines += ["; ===== ETCH ====="]
for i, (pts, cl) in enumerate(etches, 1):
    p = motion.decimate(pts, ETCH_MIN_SEG_MM) if len(pts) > 2 else pts
    if len(p) < 2:
        continue
    lines += [f"; --- etch {i}/{len(etches)} ---", f"G0 X{p[0][0]:.3f} Y{p[0][1]:.3f}", f"{etch_on} S{etch_s}",
              f"F{er['feed_mm_per_min']}"]
    lines += [f"G1 X{x:.3f} Y{y:.3f}" for x, y in p[1:]]
    if cl:
        lines += [f"G1 X{x:.3f} Y{y:.3f}" for x, y in motion.follow_through(p, ETCH_LEAD_IN_MM)]
    lines += ["M5", ""]
lines += ["; ===== CUT ====="]
cuts = [s2g.Polyline(pl, True) for pl in holes + outers]
for i, c in enumerate(cuts, 1):
    lines += emit_cut(s2g, motion, c, i, len(cuts), job)
lines += s2g._footer()
args.out.parent.mkdir(parents=True, exist_ok=True)
args.out.write_text("\n".join(lines))
print(f"wrote {args.out.name}: {W:.2f} x {H:.2f} mm, {len(etches)} etch strokes, {len(cuts)} cuts")

# ---- data for drawings
scenes = HERE.parent / "views" / "scenes"
scenes.mkdir(parents=True, exist_ok=True)
def rings(g):
    gs = [g] if g.geom_type == "Polygon" else list(g.geoms)
    return [{"outer": list(p.exterior.coords), "holes": [list(h.coords) for h in p.interiors]} for p in gs]
json.dump({"T": T, "C": C, "RING_ID": RING_ID, "RING_CL": RING_CL, "RING_OD": RING_OD, "WD": WD, "PW": PW, "PH": PH,
           "IRON_C": IRON_C, "iron": args.iron, "angles": args.angles,
           "top": rings(plate_top()), "base": rings(plate_base()), "core": rings(core()), "spider": rings(spider()),
           "etch_top": [pts for pts, _ in etch], "ticks": spider_ticks(), "W": W, "H": H},
          open(scenes / "ring_jig.json", "w"))
