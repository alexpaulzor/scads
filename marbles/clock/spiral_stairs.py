#!/usr/bin/env python3
"""Stair supports under the round spiral (the 287 x 291 trimmed one, acrylic + ply layers): SHELVED (a smooth beam under
the outside edge is enough), preview only, no G-code.

  - BASE: 4 short 2020 beams in a pinwheel round the exit hole (each beam's end butts the long face of the next),
    corner brackets in the outside corners, turned 45 deg so two opposite beams run under the spiral's two inner
    centre bolts (their M5 go down through the centre guide, disc and exit flange into the beam); the other two
    beams need one new hole each in the disc (marked).
  - STAIRS: one per beam, a zig-zag plate standing on the beam's outer side face (2 M5 into its slot near the disc),
    climbing outward one step per lap: RISE per step (shelf top to shelf top), each tread the lap's width along the
    line, the zig-zag band STROKE wide (perpendicular) under the inner corners: no solid corner under it.
Heights: 0 = the disc's underside (the beams' tops, less the exit flange where it is sandwiched).

    python3 marbles/clock/spiral_stairs.py            # writes spiral_stairs.scad + renders in marbles/views
"""
import math
import subprocess
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import spiral_run as S  # noqa: E402

RISE = 15.0
STROKE = 30.0
T_STACK = 3.0 + 2.63         # acrylic top + one ply3 layer
T_FLANGE = 2.63
BEAM = 20.0
BEAM_L = 95.0                # each pinwheel beam's length
PLY = 2.63                   # stair plate (ply3)
ROT = 135.0                  # pinwheel turn: beam 0's outward normal ends up at 45 deg


def setup():
    S.configure(True, 20.0, 291.0, 0.0)
    S.TRIM = True
    B = S.build()
    k = B["t_end"]
    z = lambda t: RISE * (k - t) / (2 * math.pi)          # noqa: E731  underside height of the strip with outer edge t
    return B, z


def pinwheel(B):
    """4 beams (polygons in plan, spiral coords) + their outward normals and the stair line offsets"""
    b = B["bolts"]
    r_in = min(math.dist(p, (S.CX, S.CY)) for p in b)              # the inner bolts' radius
    h = r_in - BEAM / 2                                             # bolt on the beam's centreline
    beams = []
    for i in range(4):
        loc = box(-h, -h - BEAM, BEAM_L - h, -h)                    # beam 0 in the pinwheel frame
        g = affinity.rotate(affinity.rotate(loc, 90 * i, origin=(0, 0)), ROT, origin=(0, 0))
        g = affinity.translate(g, S.CX, S.CY)
        ang = math.radians(ROT + 90 * i)
        along = (math.cos(ang), math.sin(ang))                      # beam direction (outward along its length)
        normal = (math.cos(ang - math.pi / 2), math.sin(ang - math.pi / 2))   # its outer side face
        beams.append(dict(poly=g, along=along, normal=normal, face=h + BEAM))
    return beams, h


def strip_height_at(B, z, p):
    """the underside height of the spiral where point p is"""
    cx, cy = S.CX, S.CY
    ang = math.degrees(math.atan2(p[1] - cy, p[0] - cx))
    hits = S.ray_hits(B["cut"], B["cut_t"], ang)                   # outer first
    r = math.dist(p, (cx, cy))
    outer = [t for s_, t in hits if s_ > r]
    if not outer:
        return z(0.0) if hits else 0.0                              # outside the first lap: the frame
    return z(outer[-1])                                             # the nearest cut outside p


def stair(B, z, bm):
    """(profile polygon in (s along the beam from the centre, z), M5 points, treads [(s0, s1, z)], line origin)"""
    off = bm["face"] + PLY / 2
    o = (S.CX + bm["normal"][0] * off, S.CY + bm["normal"][1] * off)
    u = bm["along"]
    line = LineString([o, (o[0] + u[0] * 200, o[1] + u[1] * 200)])
    xs = []
    cut = LineString(B["cut"])
    inter = cut.intersection(line)
    for g in getattr(inter, "geoms", [inter]):
        if g.geom_type == "Point":
            xs.append(math.dist(o, (g.x, g.y)))
    xs = sorted(xs)
    outline = S.piece_outline()
    s_end = max(s for s in [i * 0.5 for i in range(400)] if outline.contains(Point(o[0] + u[0] * s, o[1] + u[1] * s))) - 1
    bounds = [0.0] + xs + [s_end]
    treads = []
    for a, b2 in zip(bounds, bounds[1:]):
        if b2 - a < 1:
            continue
        m = (a + b2) / 2
        treads.append((a, b2, strip_height_at(B, z, (o[0] + u[0] * m, o[1] + u[1] * m)) - (T_FLANGE if b2 < 30 else 0)))
    s0 = 12.0                                                       # foot starts here (clear of the next beam)
    treads = [(max(a, s0), b2, hz) for a, b2, hz in treads if b2 > s0]
    top = []
    for a, b2, hz in treads:
        top += [(a, hz), (b2, hz)]
    inner = [(treads[i + 1][0], treads[i][2]) for i in range(len(treads) - 1)]   # inner corners
    (x1, y1), (x2, y2) = inner[0], inner[-1]
    d = math.hypot(x2 - x1, y2 - y1)
    nx, ny = (y2 - y1) / d, -(x2 - x1) / d                          # perpendicular, pointing down-right (below)
    p1 = (x1 + nx * STROKE - (x2 - x1) * 2, y1 + ny * STROKE - (y2 - y1) * 2)
    p2 = (x2 + nx * STROKE + (x2 - x1) * 2, y2 + ny * STROKE + (y2 - y1) * 2)
    under = Polygon([(s0, -BEAM)] + top + [(top[-1][0], -BEAM)])
    keep = Polygon([p1, p2, (p2[0], 500), (p1[0], 500)])            # above the band's lower line
    foot = box(s0, -BEAM, min(s0 + 50, BEAM_L - (bm["face"] - BEAM) - 2), max(treads[0][2], 0) + 1)
    prof = unary_union([under.intersection(keep), foot.intersection(under)]).buffer(1.5).buffer(-1.5)
    m5 = [(s0 + 10, -BEAM / 2), (s0 + 34, -BEAM / 2)]
    prof = prof.difference(unary_union([Point(p).buffer(2.65, 24) for p in m5]))
    return prof, m5, treads, o


def scad(B, z, beams, stairs, out):
    def poly(g):
        g = max(getattr(g, "geoms", [g]), key=lambda q: q.area)
        pts = [[round(x, 2), round(y, 2)] for x, y in g.exterior.coords]
        holes = [[[round(x, 2), round(y, 2)] for x, y in r.coords] for r in g.interiors]
        allp = pts + [q for hh in holes for q in hh]
        paths, kk = [list(range(len(pts)))], len(pts)
        for hh in holes:
            paths.append(list(range(kk, kk + len(hh))))
            kk += len(hh)
        return f"polygon(points={allp}, paths={paths});"
    L = ["$fn=24;"]
    k = S.PITCH / (2 * math.pi)
    cut_t, t_end = B["cut_t"], B["t_end"]
    # strips: outer edge = cut at t, inner = cut at t + 2 pi, underside at z(t)
    ts = [t for t in cut_t if t <= t_end - 2 * math.pi]
    for i0 in range(0, len(ts) - 1, 30):
        part = ts[i0:i0 + 31]
        pts, faces = [], []
        for t in part:
            o = S.ellipse_pt(S.A0 - k * t, S.B0 - k * t, t)
            n = S.ellipse_pt(S.A0 - k * (t + 2 * math.pi), S.B0 - k * (t + 2 * math.pi), t + 2 * math.pi)
            pts += [(o[0], o[1], z(t)), (n[0], n[1], z(t)), (o[0], o[1], z(t) + T_STACK), (n[0], n[1], z(t) + T_STACK)]
        m = len(part)
        for j in range(m - 1):
            a, b2 = 4 * j, 4 * (j + 1)
            faces += [[a, b2, b2 + 1, a + 1], [a + 2, a + 3, b2 + 3, b2 + 2], [a, a + 2, b2 + 2, b2], [a + 1, b2 + 1, b2 + 3, a + 3]]
        faces += [[0, 1, 3, 2], [4 * (m - 1), 4 * (m - 1) + 2, 4 * (m - 1) + 3, 4 * (m - 1) + 1]]
        L.append('color("#222", 0.9) polyhedron(points=' + str([[round(c, 2) for c in p] for p in pts]) + ", faces=" + str(faces) + ");")
    first = Polygon([p for p, t in zip(B["cut"], cut_t) if t <= 2 * math.pi])
    frame = S.piece_outline().difference(first)
    L.append(f'color("#222", 0.9) translate([0,0,{z(0):.2f}]) linear_extrude({T_STACK}) {poly(frame)}')
    last = Polygon([p for p, t in zip(B["cut"], cut_t) if t >= t_end - 2 * math.pi])
    disc = last.difference(Point(S.CX, S.CY).buffer(11.55))
    L.append(f'color("#222", 0.9) translate([0,0,0]) linear_extrude({T_STACK}) {poly(disc)}')
    L.append(f'color("peru") translate([0,0,{T_STACK:.2f}]) linear_extrude(2.63) {poly(B["guide"])}')
    ex = affinity.translate(B["exit"], S.CX, S.CY)
    L.append(f'color("sienna") translate([0,0,{-T_FLANGE}]) linear_extrude({T_FLANGE}) {poly(ex)}')
    for bm in beams:
        L.append(f'color("silver") translate([0,0,{-T_FLANGE - BEAM}]) linear_extrude({BEAM}) {poly(bm["poly"])}')
    # corner brackets: at each beam's start, on the outside of the junction
    for bm in beams:
        c = bm["poly"].exterior.coords
        L.append(f'color("gray") translate([0,0,{-T_FLANGE - BEAM}]) linear_extrude({BEAM}) {poly(bm["poly"].buffer(0))}') if False else None
    for bm, (prof, m5, treads, o) in zip(beams, stairs):
        ang = math.degrees(math.atan2(bm["along"][1], bm["along"][0]))
        L.append(f'color("burlywood") translate([{S.CX + bm["normal"][0] * (bm["face"] + PLY / 2):.2f},'
                 f'{S.CY + bm["normal"][1] * (bm["face"] + PLY / 2):.2f},{-T_FLANGE:.2f}]) rotate([0,0,{ang:.2f}]) '
                 f'rotate([90,0,0]) translate([0,0,{-PLY / 2}]) linear_extrude({PLY}) {poly(prof)}')
    # exit tunnel stub
    L.append(f'color("silver") for (a=[45,135,225,315]) translate([{S.CX}+11*cos(a),{S.CY}+11*sin(a),-80]) cylinder(d=2,h=80);')
    out.write_text("\n".join(L) + "\n")


def main():
    B, z = setup()
    beams, h = pinwheel(B)
    stairs = [stair(B, z, bm) for bm in beams]
    print(f"pinwheel: beams {BEAM_L:g} long, inner hole {2 * h:.1f} square, turned {ROT - 90:g} deg; inner bolts on two beams")
    for i, (prof, m5, treads, o) in enumerate(stairs):
        x0, y0, x1, y1 = prof.bounds
        print(f"stair {i}: {x1 - x0:.0f} long x {y1 - y0:.0f} tall, {len(treads)} treads, heights "
              + ", ".join(f"{t[2]:.0f}" for t in treads))
    out = HERE / "spiral_stairs.scad"
    scad(B, z, beams, stairs, out)
    views = HERE.parent / "views"
    cx, cy = S.CX, S.CY
    for n, cam in (("iso", f"{cx + 250},{cy - 330},{230},{cx},{cy},20"), ("low", f"{cx - 260},{cy - 260},{-60},{cx},{cy},30"),
                   ("side", f"{cx},{cy - 480},{40},{cx},{cy},40")):
        subprocess.run(["xvfb-run", "-a", "openscad", "-o", str(views / f"spiral_stairs_{n}.png"), f"--camera={cam}",
                        "--imgsize=1400,1050", "--projection=p", "--colorscheme=Tomorrow", str(out)], check=True, capture_output=True)
    return B, beams, stairs


if __name__ == "__main__":
    main()
