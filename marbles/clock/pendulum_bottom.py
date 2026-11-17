#!/usr/bin/env python3
"""Close-up of the BOTTOM of the pendulum lift: how Claude understands it now, and the proposed interleaving fingers
between the entry flange (on F) and M's double outside keeper. Renders only, no G-code.

World axes: x = across the rig (the two ball lanes at x = +-20, F's spine at x = 0), y = through the layers
(+y = F's sieve side, where the flanges are), z = up along the pendulum. Plates are the real outlines from
short_parts.py (ply3, 21.2 holes).

    python3 marbles/clock/pendulum_bottom.py      # -> marbles/views/pend_bottom_{now,fingers_closed,fingers_open}.png
"""
import math
import subprocess
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import short_parts as S  # noqa: E402

S.HOLE_CUT = 21.2
T = 2.63                       # ply3
BALL = 19.05
STROKE = 36.0
# layer planes (y), from the section Alex confirmed: F at y -10..10, M's side beams 10 toward +y
Y_FKEEP = -10.0 - T            # F's double (spine) keeper, on F's -y face
Y_MSIEVE = -T                  # M's single sieves, on M's -y face (y 0)
Y_FSIEVE = 10.0                # F's spine sieve + the interface, on F's +y face
Y_MKEEP = 20.0                 # M's double outside keeper, on M's +y face (y 20)
FLANGE_GAP = 0.9               # today: the flange stands off past M's keeper so M can slide under it
TOOTH_P = S.DBL_W / 4          # finger pitch across the flange width (4 fingers)
TOOTH_H = 42.0                 # finger height: still interleaved when opened by the full stroke
TOOTH_R = 1.5                  # rounded tips / valleys
TOOTH_CLR = 7.0                # tips to valleys when closed (M at the bottom of its stroke): 1.46 between the flanks


def teeth(x0, x1, base, up, phase):
    """a row of rounded isosceles fingers between x0..x1, bases on z = base, pointing up (+1) or down (-1);
    phase 0 or 0.5 (half a pitch offset)"""
    out, n = [], int(math.ceil((x1 - x0) / TOOTH_P)) + 2
    for i in range(-1, n):
        c = x0 + (i + phase + 0.5) * TOOTH_P
        tri = Polygon([(c - TOOTH_P / 2, base), (c + TOOTH_P / 2, base), (c, base + up * TOOTH_H)])
        out.append(tri)
    g = unary_union(out).intersection(box(x0, min(base, base + up * TOOTH_H) - 1, x1, max(base, base + up * TOOTH_H) + 1))
    return g.buffer(-TOOTH_R, join_style=1).buffer(TOOTH_R, join_style=1)


def to_world(g, u0, width):
    """part frame (u along the pendulum, v across) -> world (x across, z up): x = v - width / 2, z = u0 + u"""
    return affinity.affine_transform(g, [0, 1, 1, 0, -width / 2, u0])


def scad_poly(g):
    gs = [p for p in getattr(g, "geoms", [g]) if p.area > 1]
    out = []
    for g in gs:
        pts = [[round(x, 2), round(y, 2)] for x, y in g.exterior.coords]
        holes = [[[round(x, 2), round(y, 2)] for x, y in r.coords] for r in g.interiors]
        allp = pts + [q for h in holes for q in h]
        paths, k = [list(range(len(pts)))], len(pts)
        for h in holes:
            paths.append(list(range(k, k + len(h))))
            k += len(h)
        out.append(f"polygon(points={allp}, paths={paths});")
    return " ".join(out)


def plate(g, y0, col, alpha=1.0):
    """a plate in the x-z plane, from y0 to y0 + T"""
    return (f'color("{col}", {alpha}) translate([0,{y0 + T:.2f},0]) rotate([90,0,0]) linear_extrude({T}) {{ {scad_poly(g)} }}')


def beam(x0, x1, y0, y1, z0, z1, col="silver", alpha=1.0):
    return f'color("{col}", {alpha}) translate([{x0},{y0},{z0}]) cube([{x1 - x0},{y1 - y0},{z1 - z0}]);'


def scene(kind, m_lift):
    """kind 'now' or 'fingers'; m_lift = how far M is up its stroke (0 = bottom)"""
    L = ["$fn=24;"]
    W2, W = S.DBL_W, 2 * S.SIDE_BEAM + S.FRONT_GAP
    # F: spine 2020, its keeper, its sieve column (interface at the bottom, then a 10-position sieve)
    L.append(beam(-10, 10, -10, 10, 0, 250))
    L.append(plate(to_world(S.double_keeper(8), 0, W2), Y_FKEEP, "burlywood", .55))
    L.append(plate(to_world(S.double_sieve(3, ["solid", "flange", "hole"])[0], 0, W2), Y_FSIEVE, "tan"))
    L.append(plate(to_world(S.double_sieve(5)[0], 90, W2), Y_FSIEVE, "tan"))
    # M: two side beams (x 30..50 and -50..-30, y 0..20), single sieves on their -y face, the outside keeper on +y
    mz = 112.0 + m_lift                         # M's keeper bottom edge (today) at this height
    if kind == "fingers":
        mz = 111.5 + TOOTH_H + TOOTH_CLR + m_lift
    for s in (-1, 1):
        L.append(beam(30 if s > 0 else -50, 50 if s > 0 else -30, 0, 20, mz, 260 + m_lift, "gainsboro"))
        L.append(plate(to_world_single(S.sieve(5), s, mz), Y_MSIEVE, "wheat"))
    mk = S.front_keeper(5, S.FRONT_GAP)
    if kind == "fingers":
        x0 = S.SIDE_BEAM + (S.FRONT_GAP - S.DBL_W) / 2                      # the flange's edges in keeper coords
        mk = unary_union([mk, affinity.affine_transform(teeth(x0, x0 + W2, 0, -1, 0.5), [0, 1, 1, 0, 0, 0])])
    L.append(plate(to_world(mk, mz, W), Y_MKEEP, "peru", .9))
    # the entry flange (with its 40 mm keeper extension), on the interface
    fl = S.double_parts()["double_flange"][0]
    fl = affinity.translate(fl, 18.5, 0)                                    # flange zone centred on position 2 (u 45)
    if kind == "now":
        yf = Y_MKEEP + T + FLANGE_GAP
        spacer_h = yf - (Y_FSIEVE + T)
    else:
        top = fl.bounds[2]
        fl = unary_union([fl, affinity.affine_transform(teeth(0, W2, top, 1, 0.0), [0, 1, 1, 0, 0, 0])])
        yf = Y_MKEEP
        spacer_h = yf - (Y_FSIEVE + T)
    L.append(plate(to_world(fl, 0, W2), yf, "sienna", .95))
    for x, z in ((-20, 25), (0, 25), (20, 25), (0, 45), (0, 65)):        # the flange's 5 T bolts
        L.append(f'color("white") translate([{x},{Y_FSIEVE + T:.2f},{z}]) rotate([-90,0,0]) cylinder(d=8,h={spacer_h:.2f});')
    # balls in the lanes, one at the entry and a column above
    for xb in (-20, 20):
        for z in (45, 75, 105, 135, 165):
            L.append(f'color("lightsteelblue") translate([{xb},{(Y_MSIEVE + Y_FSIEVE + T) / 2:.2f},{z}]) sphere(d={BALL});')
    L.append(f"// spacer {spacer_h:.2f} mm")
    return "\n".join(L), spacer_h


def to_world_single(sv, side, u0):
    """a single sieve (46 wide, the 0..20 band bolted to the beam, holes at v = 30) onto the side beam at x = +-40,
    holes toward the lane at x = +-20"""
    g = affinity.affine_transform(sv, [0, 1, 1, 0, 0, u0])                 # x = v, z = u0 + u
    if side > 0:
        return affinity.translate(affinity.scale(g, -1, 1, origin=(0, 0)), 50, 0)
    return affinity.translate(g, -50, 0)


def render(name, text):
    f = HERE / f"{name}.scad"
    f.write_text(text)
    views = HERE.parent / "views"
    for tag, cam in (("", "190,300,270,0,0,130"), ("_side", "300,45,150,0,10,130")):
        subprocess.run(["xvfb-run", "-a", "openscad", "-o", str(views / f"{name}{tag}.png"), f"--camera={cam}",
                        "--imgsize=1300,1100", "--projection=p", "--colorscheme=Tomorrow", str(f)], check=True, capture_output=True)


def main():
    a, sp_now = scene("now", 0.0)
    render("pend_bottom_now", a)
    b, sp_new = scene("fingers", 0.0)
    render("pend_bottom_fingers_closed", b)
    c, _ = scene("fingers", STROKE)
    render("pend_bottom_fingers_open", c)
    from shapely.geometry import box as _box
    W2, top = S.DBL_W, 111.5
    x0 = S.SIDE_BEAM + (S.FRONT_GAP - S.DBL_W) / 2
    ft = to_world(affinity.affine_transform(teeth(0, W2, top, 1, 0.0), [0, 1, 1, 0, 0, 0]), 0, W2)
    closed, biggest = None, 0.0
    for lift in range(0, int(STROKE) + 1, 3):
        mz = top + TOOTH_H + TOOTH_CLR + lift
        kt = to_world(affinity.affine_transform(teeth(x0, x0 + W2, 0, -1, 0.5), [0, 1, 1, 0, 0, 0]), mz, 100)
        closed = ft.distance(kt) if lift == 0 else closed
        free = _box(-W2 / 2, top, W2 / 2, mz).difference(ft.union(kt))
        lo, hi = 0.0, 30.0
        for _ in range(18):
            m = (lo + hi) / 2
            lo, hi = (m, hi) if not free.buffer(-m / 2).is_empty else (lo, m)
        biggest = max(biggest, lo)
    print(f"fingers: 4 across the flange, pitch {TOOTH_P:.2f}, height {TOOTH_H:g}, tips r{TOOTH_R:g}; closed: {TOOTH_CLR:g} tip to valley, "
          f"{closed:.2f} between the flanks; the biggest ball that fits through at any point of the {STROKE:g} stroke: {biggest:.1f} (ball {BALL})")
    print(f"flange spacers: today {sp_now:.2f} (flange outside M's keeper), with fingers {sp_new:.2f} (flange in M's keeper plane)")


if __name__ == "__main__":
    main()
