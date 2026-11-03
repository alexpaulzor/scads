#!/usr/bin/env python3
"""Cut parts for the rocking ball lift (geometry from lift_demo.scad), 3.2 mm MDF.

All parts are in the rig's side view: u = forward (toward the viewer, the
demo's +y), v = up (+z). Numbers are taken from lift_demo.scad's defaults;
re-run after changing them there and here together.

  backing_plate  the strip with no ball holes except the feed (bottom) and
                 exit (top) openings; replaces the cardboard behind F.
  cam_arm        bolts to the side of F's 2020 at its top; carries the pivot
                 bearing (608) and the horizontal slot the cam pin rides in.
  cam_disc       turns on its own fixed 8 mm shaft (plain 8 mm bore); pin
                 hole at the cam radius, handle hole near the rim.
  m_link         the fixed link from the anchor down to M's top pin (an M5
                 and T-nut in the side slot at the top of M's 2020).
  link_anchor    bolts to the frame above M; a slot lets you tune the link's
                 top point, i.e. where M sits against F.
  keeper         lap plate on a longer bolt through one of F's own M5 holes,
                 stood off by M5 nuts/washers (16 mm: F's front face to just in
                 front of M), lapping M's inner 6 mm edge so M slides up and
                 down but can't pull away. Keep it left of the ball column.

    python3 marbles/clock/lift_parts.py      # writes marbles/gcode/lift_<part>.gcode
"""

import math
import sys
from pathlib import Path

from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import emit_cut, load_profile, preamble  # noqa: E402

MATERIAL = "mdf_3mm"     # 3.2 mm MDF, cut with the 3 mm MDF recipe
KERF = 0.105             # measured on plywood; check on MDF
M5 = 5.0
BEARING = 22.0           # 608 outer diameter, press fit
STRIP_L, STRIP_W, PITCH = 300.0, 46.0, 30.0

# lift_demo.scad defaults (rig frame): y forward, z up
F_BEAM_Y = (-20.0, 0.0)          # F's 2020 front-to-back extent
F_BEAM_TOP = 355.0
P = (111.61, 360.0)              # pivot (y, z)
SLOT_C = (159.98, 360.0)         # cam slot centre on the arm
CAM_R = 10.0
LINK = 100.0


def rr(x0, y0, x1, y1, r=3.0):
    return box(x0, y0, x1, y1).buffer(-r).buffer(r, 16)


def holes(pts, d=M5):
    return unary_union([Point(p).buffer(d / 2, 48) for p in pts])


def backing_plate():
    plate = box(0, 0, STRIP_L, STRIP_W)
    n = int(STRIP_L // PITCH)
    m5 = [(PITCH * (i + 1), 10.0) for i in range(n - 1)][::2]
    openings = [(PITCH / 2, 30.0), (STRIP_L - PITCH / 2, 30.0)]          # feed and exit only
    return plate.difference(holes(m5)).difference(holes(openings, 20.0))


def cam_arm():
    yb0, yb1 = F_BEAM_Y
    pad = rr(yb0, F_BEAM_TOP - 40, yb1 + 6, F_BEAM_TOP + 22, 4)
    ring = Point(P).buffer(BEARING / 2 + 7, 64)
    tip = rr(SLOT_C[0] - CAM_R - 12, SLOT_C[1] - 11, SLOT_C[0] + CAM_R + 12, SLOT_C[1] + 11, 6)
    web = unary_union([LineString([((yb0 + yb1) / 2, F_BEAM_TOP), P]).buffer(9),
                       LineString([P, SLOT_C]).buffer(9)])
    arm = unary_union([pad, ring, tip, web]).buffer(3).buffer(-3)
    mid_y = (yb0 + yb1) / 2                                            # 2020 slot centreline
    cut = unary_union([holes([(mid_y, F_BEAM_TOP - 30), (mid_y, F_BEAM_TOP - 10)]),
                       Point(P).buffer(BEARING / 2, 96),
                       LineString([(SLOT_C[0] - CAM_R, SLOT_C[1]), (SLOT_C[0] + CAM_R, SLOT_C[1])]).buffer(5.5 / 2, 24)])
    return arm.difference(cut)


def cam_disc():
    d = Point(0, 0).buffer(CAM_R + 16, 96)
    # an 8 mm bore (a 608 won't fit: its 22 mm seat would swallow the pin
    # hole 10 mm out); turns on a fixed 8 mm shaft or M8 bolt with a washer
    # each side. Pin hole at the cam radius, handle hole opposite near the rim.
    return d.difference(unary_union([Point(0, 0).buffer(8.1 / 2, 48),
                                     holes([(0, -CAM_R)]), holes([(0, CAM_R + 10)])]))


def m_link():
    bar = LineString([(0, 0), (0, LINK)]).buffer(7, 32)
    return bar.difference(holes([(0, 0), (0, LINK)]))


def link_anchor():
    p = rr(-15, -45, 15, 30, 4)
    slot = LineString([(0, -10), (0, 10)]).buffer(M5 / 2 + 0.2, 24)        # link pin, +/-10 mm of tuning
    return p.difference(slot).difference(holes([(0, -30), (0, 20)]))


def keeper():
    # x 4..19.5 in the rig: from beside F's bolt (x = 10) over M's edge
    # (x 14..20) but short of the ball column (x 20.5+)
    return rr(0, 0, 15.5, 22, 3).difference(holes([(6, 11)]))


PARTS = {
    "backing_plate": (backing_plate, 1, "behind F; feed opening at the bottom hole, exit at the top"),
    "cam_arm": (cam_arm, 3, "glue 3; 608 in the pivot hole; bolts to the side of F's 2020"),
    "cam_disc": (cam_disc, 3, "glue 3; 8 mm bore on a fixed shaft; M5 pin at the cam radius, M5 handle"),
    "m_link": (m_link, 2, "glue 2; 100 mm between M5 holes"),
    "link_anchor": (link_anchor, 2, "glue 2; slot tunes where M sits"),
    "keeper": (keeper, 2, "on F's top and bottom M5 bolts, 16 mm of nuts/washers under each"),
}


def polylines(g):
    gs = [g] if g.geom_type == "Polygon" else list(g.geoms)
    return [list(r.coords) for p in gs for r in [p.exterior] + list(p.interiors)]


def main():
    s2g, motion, mat, job = load_profile(MATERIAL, 1000, None)
    out_dir = HERE.parent / "gcode"
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, (fn, n, note) in PARTS.items():
        g = fn().buffer(KERF / 2, join_style=1)
        x0, y0, x1, y1 = g.bounds
        loops = [[(x - x0, y - y0) for x, y in pl] for pl in polylines(g)]
        loops.sort(key=lambda pl: abs(Polygon(pl).area))
        cuts = [s2g.Polyline(pl, True) for pl in loops]
        lines = [f"; lift_{name} -- marbles/clock/lift_parts.py; cut {n}: {note}",
                 f"; 3.2 mm MDF on the {mat['id']} recipe ({job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}); "
                 f"X0 Y0 = bottom-left; {x1 - x0:.2f} x {y1 - y0:.2f} mm; kerf {KERF}", ";"]
        lines += preamble(s2g, job)
        for i, c in enumerate(cuts, 1):
            lines += emit_cut(s2g, motion, c, i, len(cuts), job)
        lines += s2g._footer()
        (out_dir / f"lift_{name}.gcode").write_text("\n".join(lines))
        print(f"lift_{name}.gcode: {x1 - x0:.2f} x {y1 - y0:.2f} mm, cut {n} ({note})")


if __name__ == "__main__":
    main()
