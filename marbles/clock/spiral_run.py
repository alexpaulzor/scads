#!/usr/bin/env python3
"""Spiral marble run: one 300 x 300 sheet, ONE spiral cut line (nothing removed but holes).

The sheet hangs UNDER the edge beam (the beam sits on top of its mount edge) and is held as a descending helical
shelf by four STAIR ARMS under it (an X, on 2020s): it drops DROP_REV (10) per revolution, so each strip's edge sits
at the ball's centre height for the ball on the next strip in - the wall meets the ball at its equator. The ball
rolls on the shelf, held out against that wall by its own centripetal force, round and down to the centre.
On the first lap the strip has not yet dropped below the frame, so an ENTRY GUIDE (a flat piece ~10 above the sheet
on spacers, its inner edge over the cut) is the wall until the frame's own edge takes over; before the cut leaves
the beam, the beam's face is the wall.

Layout (machine frame, X0 Y0 = the stock's corner; the MOUNT edge is the front, y = 0, so every cut stays under the
292 mm Y reach; in use that edge is the top, on the beam):
  - mount: M5 10 from the mount edge, every 50 from the corner, into the top 2020
  - the spiral fills the width: an elliptical Archimedean spiral, semi-axes 144 x 135, PITCH 12.7 (1/2"), centred
    so its outer edge clears the mount holes by 7.5. It starts at the point nearest the beam, running PARALLEL to it.
  - the laps stop at B_IN and the cut simply ends: everything inside the last lap is solid (exit bore at the centre).
  - CENTRE GUIDE (a separate piece, WIP v3): lies on that solid centre, 0.5 inside the last lap, bolted through the
    sheet (and the exit flange underneath) by its M5 holes. Its channel picks the ball up at the bridge (where the
    last strip joins the centre) and curls it into the bore along the gentlest curve the space allows (searched:
    largest smallest turning radius, the channel never coming back within 4 mm of itself). A 2nd copy stacked on it
    is the spacer: a taller wall. It only works if the step at the last lap (how far the strip outside it sits
    above the centre) is more than the guide's height, about 2 mm for one layer (sheet thickness - 0.75; see ROADMAP P207): otherwise a ball on the previous
    lap grazes the guide's edge.
  - entry: a cropped wire-track flange stands on the sheet at the start (lower wires moved toward the sides so every
    notch and stitch hole stays closed: entry_flange()), its bore centred so a ball on those wires is at shelf level, above the
    surface, so a ball resting on the tunnel's bottom wires is already at shelf level: it rolls straight off the wire
    ends onto the shelf, parallel to the beam. The flange bolts to the side of a short 2020 post, held to the beam by
    a corner bracket through a mount hole.

    python3 marbles/clock/spiral_run.py                    # ply3, mdf3, birch3: sheet + entry flange
    python3 marbles/clock/spiral_run.py --material birch3 --pitch 12
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
from laser_parts import gcode  # noqa: E402  (quickcut's gcode core)
sys.path.insert(0, str(HERE))
from short_parts import wire_pattern, FLANGE_ANGLES  # noqa: E402  (the shared 8-notch flange pattern)

STOCK = 300.0                  # stock width (X)
STOCK_H = 300.0                # stock height (Y)
ENTRY_RUN = 0.0                # extra flat width left of the spiral for the entry run (round variant)
BALL_R = 19.05 / 2
PITCH = 12.7                   # 1/2"
MOUNT_Y, MOUNT_STEP, M5 = 10.0, 50.0, 5.0
SIDE = 6.0                     # wood outside the spiral at the sides
Y_LO, Y_HI = MOUNT_Y + M5 / 2 + 7.5, 290.0      # the outer cut's lowest point (7.5 clear of the mount holes) and highest
# the spiral shrinks as it goes, so the outer lap touches each side at a different radius: size and place it so the
# lap's LEFT (3/4 turn), RIGHT (1/4 turn) and TOP (1/2 turn) extremes land on the stock limits
A0 = (STOCK - 2 * SIDE + PITCH) / 2                     # x semi-axis at the start
B0 = (Y_HI - Y_LO + PITCH / 2) / 2                      # y semi-axis at the start
CX = SIDE + A0 - 0.75 * PITCH                           # x centre
CY = Y_LO + B0


def configure(round_=False, entry_run=0.0, stock_h=300.0):
    """round_: a circular spiral sized by the height (290 across), with entry_run of extra flat sheet to its left (the
    ball's run along the top rail before the ramp starts); the stock width follows. Otherwise the original 300 x 300
    elliptical fill."""
    global STOCK, STOCK_H, Y_HI, ENTRY_RUN, A0, B0, CX, CY
    STOCK_H, Y_HI = stock_h, stock_h - 10.0
    B0 = (Y_HI - Y_LO + PITCH / 2) / 2
    if round_:
        A0 = B0
        ENTRY_RUN = entry_run
        CX = SIDE + entry_run + A0 - 0.75 * PITCH            # the lap's left extreme (3/4 turn) lands entry_run in
        STOCK = math.ceil(CX + A0 - 0.25 * PITCH + SIDE)     # its right extreme (1/4 turn) + SIDE
    else:
        STOCK, ENTRY_RUN = 300.0, 0.0
        A0 = (STOCK - 2 * SIDE + PITCH) / 2
        CX = SIDE + A0 - 0.75 * PITCH
    CY = Y_LO + B0
B_IN = 46.0                    # the laps stop here (y semi-axis): the centre inside the LAST lap is solid
GUIDE_GAP = 0.5                # the centre guide's outer edge sits this far inside the last lap of the cut
GUIDE_LAYERS = 1               # guide layers on the sheet (2 = guide + a same-shape spacer: a taller wall)
CHAN_CLR = 1.0                 # channel half-width = BALL_R + this
MIN_WOOD = 4.0                 # thinnest guide wood kept (slivers thinner than this are dropped)
# wire-track flange pattern (feeder.scad tunnel flange)
TUN_WIRE, TUN_RW, TUN_FBORE, TUN_HOLE, TUN_NOTCH_OUT, TUN_SR, FLANGE_BOLT = 2.05, 11.025, 23.1, 2.35, 12.2, 18.99, 20.0
FLANGE_HALF = 26.5
# ball resting on the two lower wires (225 / 315 deg) sits this far below the tunnel axis
BALL_DROP = TUN_RW * math.sin(math.radians(45)) - math.sqrt((BALL_R + TUN_WIRE / 2) ** 2 - (TUN_RW * math.cos(math.radians(45))) ** 2)
NO_DROP_AXIS = BALL_R + BALL_DROP          # axis height above the shelf for a no-drop hand-off
EXIT_GAP = 12.0                            # the flange's downstream face this far before the cut starts
HEAD_CLEAR = 11.5                          # a button-head M5 (9.5 x 2.75) clears a ball centred this far away
CUT_CLEAR = M5 / 2 + 4                     # and keeps 4 of wood to the cut


def ellipse_pt(ra, rb, t):
    th = -math.pi / 2 + t
    return (CX + ra * math.cos(th), CY + rb * math.sin(th))


def spiral(pitch=PITCH):
    """(cut points, ball-centre points along the laps, laps, cut length, t_end): CCW from the point nearest the beam,
    plain laps down to B_IN, then the cut simply stops (no curl: the centre guide takes the ball from there)"""
    k = pitch / (2 * math.pi)
    t_end = (B0 - B_IN) / k
    cut, ts, t = [], [], 0.0
    while t <= t_end:
        ra, rb = A0 - k * t, B0 - k * t
        cut.append(ellipse_pt(ra, rb, t)); ts.append(t)
        t += 0.5 / max(min(ra, rb), 5.0)
    cut.append(ellipse_pt(A0 - k * t_end, B0 - k * t_end, t_end)); ts.append(t_end)
    ball = []
    for i in range(1, len(cut) - 1):               # ball centre: BALL_R inward of the wall (left of travel, CCW)
        (x0, y0), (x1, y1) = cut[i - 1], cut[i + 1]
        d = math.hypot(x1 - x0, y1 - y0)
        nx, ny = -(y1 - y0) / d, (x1 - x0) / d
        ball.append((cut[i][0] + BALL_R * nx, cut[i][1] + BALL_R * ny))
    return cut, ball, t_end / (2 * math.pi), LineString(cut).length, t_end


def guide_path(t_end, pitch, hold_deg, curl_deg):
    """ball-centre path on the centre: from the bridge (where the last strip joins the centre, t_end) the ball keeps
    rolling against the LAST lap (the step) for hold_deg, then curls in to the bore centre over curl_deg, the radius
    shrinking with the spiral's own slope at the start (no kink) and a quadratic term that brings it to 0 at the end."""
    k = pitch / (2 * math.pi)
    off = BALL_R + GUIDE_GAP
    def wall(t):                                    # the last lap's radii at the same angle
        return A0 - k * (t - 2 * math.pi), B0 - k * (t - 2 * math.pi)
    pts = []
    h = math.radians(hold_deg); phi = math.radians(curl_deg)
    wa, wb = wall(t_end + h)
    ra0, rb0 = wa - off, wb - off
    qa, qb = (ra0 - k * phi) / phi ** 2, (rb0 - k * phi) / phi ** 2
    n = 600
    for i in range(n + 1):
        f = (h + phi) * i / n
        t = t_end + f
        if f <= h:
            ra, rb = (w - off for w in wall(t))
        else:
            g = f - h
            ra, rb = ra0 - k * g - qa * g * g, rb0 - k * g - qb * g * g
        pts.append(ellipse_pt(max(ra, 0), max(rb, 0), t))
    return pts


def min_turn_radius(pts, span=6):
    best = 1e9
    for i in range(span, len(pts) - span):
        (x0, y0), (x1, y1), (x2, y2) = pts[i - span], pts[i], pts[i + span]
        a, b, c = math.dist((x0, y0), (x1, y1)), math.dist((x1, y1), (x2, y2)), math.dist((x0, y0), (x2, y2))
        area = abs((x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)) / 2
        if area > 1e-9:
            best = min(best, a * b * c / (4 * area))
    return best


def guide(cut, t_end, pitch, hold_deg, curl_deg):
    """the separate centre guide: the area inside the last lap (closed across the bridge), less the ball channel.
    Returns (guide polygon, channel polygon, ball path)"""
    k = pitch / (2 * math.pi)
    last = [p for p, t in zip(cut, _ts(t_end, pitch)) if t >= t_end - 2 * math.pi]
    region = Polygon(last).buffer(-GUIDE_GAP, join_style=2)
    path = guide_path(t_end, pitch, hold_deg, curl_deg)
    chan = LineString(path).buffer(BALL_R + CHAN_CLR, 48)
    g = region.difference(chan).buffer(-MIN_WOOD / 2, join_style=1).buffer(MIN_WOOD / 2, join_style=1)
    if g.geom_type == "MultiPolygon":
        g = max(g.geoms, key=lambda q: q.area)
    return g, chan, path


def _ts(t_end, pitch):
    k = pitch / (2 * math.pi)
    ts, t = [], 0.0
    while t <= t_end:
        ts.append(t)
        t += 0.5 / max(min(A0 - k * t, B0 - k * t), 5.0)
    ts.append(t_end)
    return ts


def best_curl(cut, t_end, pitch):
    """hold / curl angles: the gentlest curl (largest smallest turning radius) whose channel never comes back
    within MIN_WOOD of itself"""
    best = None
    for hold in range(0, 271, 15):
        for curl in range(90, 361, 15):
            path = guide_path(t_end, pitch, hold, curl)
            w = 2 * (BALL_R + CHAN_CLR) + MIN_WOOD
            arc = [0.0]
            for q0, q1 in zip(path, path[1:]):
                arc.append(arc[-1] + math.dist(q0, q1))
            ok = all(math.dist(path[i], path[j]) >= w or arc[j] - arc[i] < w * math.pi / 2
                     for i in range(0, len(path), 8) for j in range(i + 8, len(path), 8))
            if not ok:
                continue
            r = min_turn_radius(path[:-25])
            if best is None or r > best[2]:
                best = (hold, curl, r)
    return best


def guide_bolts(g, path, cut):
    """M5 through guide + sheet (+ exit flange when inside it): >= 6.5 from the cut, the guide's edges and its
    channel (4 of wood), >= 13.5 from the ball path (a button head on the guide clears the ball), spread out"""
    pl, cl = LineString(path), LineString(cut)
    inner = g.buffer(-(M5 / 2 + MIN_WOOD))
    cands = []
    for ix in range(-60, 61, 1):
        for iy in range(-50, 51, 1):
            p = Point(CX + ix, CY + iy)
            if inner.contains(p) and p.distance(pl) >= 13.5 and p.distance(cl) >= M5 / 2 + MIN_WOOD:
                cands.append(p)
    flange = [p for p in cands if abs(p.x - CX) <= FLANGE_HALF - 5 and abs(p.y - CY) <= FLANGE_HALF - 5]
    picked = []
    for pool, want in ((flange, 2), (cands, 4)):
        while len(picked) < want and pool:
            q = max(pool, key=lambda p: min([p.distance(o) for o in picked] or [p.distance(Point(CX, CY)) * 0.1 + 1e3]))
            if picked and min(q.distance(o) for o in picked) < 20:
                break
            picked.append(q)
    return [(p.x, p.y) for p in picked]


DROP_REV = 10.0          # the sheet drops this much per revolution: the outer strip's edge then sits at the ball's
                         # centre height for the ball on the next strip in (its wall meets the ball at the equator)
ARM_ANGLES = (45, 135, 225, 315)   # stair arms: rays from the spiral centre (the X)
ARM_S0 = 40.0            # arms start this far out (clear of the exit flange + its tunnel at the centre)
ARM_OUT = 15.0           # and run this far past the first lap, under the frame
ARM_BASE = 30.0          # plate below the lowest step; M5 row 10 above its bottom edge (a 2020 along it)
ENTRY_SPAN = 180.0       # entry guide: covers the first lap from the start through this many degrees (by then the
                         # strip is 5 below the frame: the frame edge is a wall of its own; 270 would not fit a sheet)
ENTRY_W = 14.0           # entry guide band width outside the cut
BEAM_Y = 20.0            # the edge beam (on TOP of the sheet) covers y 0 .. 20


def z_of(t):
    """the strip whose outer edge is the cut at parameter t: its underside, below the frame's underside"""
    return -DROP_REV * t / (2 * math.pi)


def ray_hits(cut, cut_t, phi_deg):
    """[(s, t)] where the ray from the centre at phi crosses the cut, outermost first"""
    phi = math.radians(phi_deg)
    far = (CX + 400 * math.cos(phi), CY + 400 * math.sin(phi))
    ray = LineString([(CX, CY), far])
    out = []
    for i in range(len(cut) - 1):
        seg = LineString([cut[i], cut[i + 1]])
        if seg.intersects(ray):
            q = seg.intersection(ray)
            if q.geom_type != "Point":
                continue
            f = Point(cut[i]).distance(q) / max(seg.length, 1e-9)
            out.append((math.dist((CX, CY), (q.x, q.y)), cut_t[i] + f * (cut_t[i + 1] - cut_t[i])))
    return sorted(out, reverse=True)


def stair_arm(cut, cut_t, phi_deg, z_floor):
    """one stair arm: a plate standing on edge along the ray at phi, (s out from the centre, z up; z = 0 the frame's
    underside). Each step carries one strip at its height, the risers sit under the cuts; M5 row 10 above the
    bottom edge (z_floor) every 20, into a 2020. Returns (polygon, steps [(s_in, s_out, z)], m5)."""
    hits = ray_hits(cut, cut_t, phi_deg)
    s_max = hits[0][0] + ARM_OUT
    steps = [(hits[0][0], s_max, 0.0)]                         # the frame
    for (s_o, t_o), (s_i, _) in zip(hits, hits[1:] + [(ARM_S0, None)]):
        steps.append((max(s_i, ARM_S0), s_o, z_of(t_o)))
    steps = [st for st in steps if st[1] > st[0]]
    top = []
    for s_in, s_out, z in sorted(steps):                       # inner to outer
        top += [(s_in, z), (s_out, z)]
    poly = Polygon([(ARM_S0, z_floor)] + top + [(s_max, z_floor)])
    m5 = [(x, z_floor + 10) for x in [ARM_S0 + 10 + 20 * i for i in range(int((s_max - ARM_S0 - 20) // 20) + 1)]]
    return poly.difference(unary_union([Point(m).buffer(M5 / 2, 32) for m in m5])), steps, m5


TRIM_MARGIN = 9.0       # trimmed outline: frame kept outside the first lap's cut


def piece_outline(trim=None):
    """the spiral piece's outline. Untrimmed: the full stock rectangle. Trimmed (TRIM set): the mount-edge half
    stays rectangular, the far half follows the first lap TRIM_MARGIN outside its cut, freeing the far corners"""
    rect = box(0, 0, STOCK, STOCK_H)
    trim = TRIM if trim is None else trim
    if not trim:
        return rect
    k = PITCH / (2 * math.pi)
    lap = [ellipse_pt(A0 - k * t + TRIM_MARGIN, B0 - k * t + TRIM_MARGIN, t) for t in [i * 2 * math.pi / 360 for i in range(361)]]
    g = unary_union([box(0, 0, STOCK, CY), Polygon(lap)]).intersection(rect)
    return g.buffer(4).buffer(-4)


TRIM = False


def entry_guide(cut, cut_t):
    """the entry guide: a flat piece held ~10 above the sheet on spacers, its inner edge over the first lap's cut, so
    the incoming ball is kept on the first strip while that strip has not yet dropped far enough below the frame to
    make a wall of its own. Starts where the cut leaves the edge beam (the beam's face is the wall before that).
    Returns (guide polygon, support M5 [(x, y)] - the same holes go in the sheet's frame)."""
    span = math.radians(ENTRY_SPAN)
    first = Polygon([p for p, t in zip(cut, cut_t) if t <= 2 * math.pi])
    arc = [p for p, t in zip(cut, cut_t) if t <= span]
    band = LineString(arc).buffer(ENTRY_W + 0.5, cap_style=2, join_style=1).difference(first.buffer(0.5))
    band = band.difference(box(-10, -10, 400, BEAM_Y + 0.5))
    stock = piece_outline()
    frame = stock.difference(first)
    ok = frame.buffer(-(M5 / 2 + 4)).difference(box(-10, -10, 400, BEAM_Y + 6))   # spacers clear the beam
    near = LineString(arc).buffer(40)
    cands = [Point(x, y) for x in range(0, 301, 2) for y in range(0, 301, 2)
             if ok.contains(Point(x, y)) and near.contains(Point(x, y))]
    al = LineString(arc)
    picked = []
    for frac in (0.12, 0.5, 0.9):                               # spread along the guide: nearest frame spot to each
        target = al.interpolate(frac, normalized=True)
        if cands:
            q = min(cands, key=lambda p: p.distance(target))
            if all(q.distance(o) > 30 for o in picked):
                picked.append(q)
    lobes = []
    for q in picked:
        hub = q.buffer(M5 / 2 + 5, 32)
        lobes.append(hub.union(Polygon(list(hub.exterior.coords)).convex_hull)
                     .union(LineString([(q.x, q.y), al.interpolate(al.project(q)).coords[0]]).buffer(M5 / 2 + 5)))
    g = unary_union([band] + lobes).difference(first.buffer(0.5)).difference(box(-10, -10, 400, BEAM_Y + 0.5))
    if g.geom_type == "MultiPolygon":
        g = max(g.geoms, key=lambda q: q.area)
    g = g.buffer(1, join_style=1).buffer(-1, join_style=1).difference(unary_union([q.buffer(M5 / 2, 32) for q in picked]))
    return g, [(q.x, q.y) for q in picked]


SCREW_IN = PITCH / 2    # layer screws: centred on the shelf (half a pitch in from the step); they come up from below and stop under the top surface
SCREW_STEP = 100.0      # ... every this far along the lap (~8-9 on the outer lap, ~3-4 on the inner)
PILOT_D = 2.5           # M3 tap drill (tapped top layer)
SLOT_W, SLOT_TRAVEL = 3.3, 3.0   # clearance slots in the other layers, along the lap: 3.3 wide, 3 of travel (6.3 long)
RELIEF_D = 3.0          # stress-relief hole at each end of the spiral cut: the strips flex, a slit's sharp end would crack


def holes(cut, bolts, extra=()):
    """[(closed points, label)] on the sheet: the exit bore (enclosed), the guide bolts, the mount row, and a relief
    hole centred on each end of the spiral cut"""
    out = [(list(Point(CX, CY).buffer(TUN_FBORE / 2, 96).exterior.coords), "exit bore")]
    out += [(list(Point(cut[i]).buffer(RELIEF_D / 2, 32).exterior.coords), "relief") for i in (0, -1)]
    out += [(list(Point(p).buffer(M5 / 2, 48).exterior.coords), "guide M5") for p in bolts]
    mount = [(10 + MOUNT_STEP * i, MOUNT_Y) for i in range(int((STOCK - 20) // MOUNT_STEP) + 1)]
    out += [(list(Point(p).buffer(M5 / 2, 48).exterior.coords), "mount M5") for p in mount]
    out += [(list(Point(p).buffer(M5 / 2, 48).exterior.coords), "entry guide M5") for p in extra]
    return out, mount


def screw_points(cut, avoid):
    """(point, tangent) for the layer screws: along the cut every SCREW_STEP, SCREW_IN in from it on the inner side
    (the lap whose outer edge this cut is), skipping spots within 4 mm (edge to edge) of the other holes / cut ends"""
    line = LineString(cut)
    out, s_ = [], SCREW_STEP / 2
    while s_ < line.length - SCREW_STEP / 2:
        p0, p1 = line.interpolate(s_ - 0.5), line.interpolate(s_ + 0.5)
        tx, ty = p1.x - p0.x, p1.y - p0.y
        d = math.hypot(tx, ty)
        tx, ty = tx / d, ty / d
        c = line.interpolate(s_)
        q = Point(c.x - ty * SCREW_IN, c.y + tx * SCREW_IN)            # left of travel (CCW) = toward the centre
        if all(q.distance(Polygon(h)) > 4 + SLOT_W / 2 + SLOT_TRAVEL / 2 for h in avoid):
            out.append(((q.x, q.y), (tx, ty)))
        s_ += SCREW_STEP
    return out


def screw_cuts(pts, kind):
    """closed outlines: kind 'pilot' (tap-drill holes) or 'slot' (clearance slots along the lap)"""
    if kind == "pilot":
        return [list(Point(p).buffer(PILOT_D / 2, 24).exterior.coords) for p, _ in pts]
    h = SLOT_TRAVEL / 2
    return [list(LineString([(p[0] - t[0] * h, p[1] - t[1] * h), (p[0] + t[0] * h, p[1] + t[1] * h)]).buffer(SLOT_W / 2, 16).exterior.coords)
            for p, t in pts]


EXIT_REPORT = []


def exit_flange(bolts):
    """the wire-track flange that goes UNDER the sheet's exit bore: bore, wire notches, stitch holes as the standard
    flange, bolted through the guide bolts that land on it; the wire pattern is turned to clear them"""
    plate = box(-FLANGE_HALF, -FLANGE_HALF, FLANGE_HALF, FLANGE_HALF).buffer(-2, join_style=2).buffer(2, 16)
    rel = [(x - CX, y - CY) for x, y in bolts if abs(x - CX) < FLANGE_HALF and abs(y - CY) < FLANGE_HALF]
    holes = [Point(b).buffer(M5 / 2, 48) for b in rel]

    def score(rot):                                  # the 4 wire notches + stitches must all fit; then most extras
        cuts, rep = wire_pattern((0, 0), plate, rel, rot=rot)
        core = sum(1 for a, r in rep if r and round(a - rot) % 90 == 45)
        return (core, len(rep), sum(1 for _, r in rep if r)), cuts, rep
    rot = max(range(0, 90, 1), key=lambda r: score(r)[0])
    _, wc, rep = score(rot)
    cuts = [Point(0, 0).buffer(TUN_FBORE / 2, 96)] + wc + holes
    EXIT_REPORT[:] = [rot] + rep
    return plate.difference(unary_union(cuts)), rel


def ball_drop(alpha_deg):
    """a ball resting on two wires at +-alpha below horizontal (on the TUN_RW circle): its centre sits this far below
    the tunnel axis (None if the wires are too far apart to hold it)"""
    a = math.radians(alpha_deg)
    half = TUN_RW * math.cos(a)
    reach = BALL_R + TUN_WIRE / 2
    if half >= reach:
        return None
    return TUN_RW * math.sin(a) - math.sqrt(reach ** 2 - half ** 2)


def entry_flange():
    """the cropped wire-track flange (u across the tunnel, v up from the sheet). Its bottom edge sits on the sheet.
    The two LOWER wires move from 45 deg toward the sides (+-ALPHA below horizontal, the steepest that still keeps
    every notch and stitch hole closed with FLANGE_MIN_WOOD), so the bore centre is ball_drop(ALPHA) + BALL_R up:
    a ball on those wires is at shelf level and rolls straight off onto the shelf. The other notches of the 8
    pattern are added where they fit. Returns (shape, bolts, v0, alpha, report)."""
    best = None
    for k in range(0, 57):
        alpha = 45 - 0.5 * k
        d = ball_drop(alpha)
        if d is None:
            break
        v0 = BALL_R + d
        plate = box(-FLANGE_HALF, 0, FLANGE_HALF, v0 + FLANGE_HALF).buffer(-2, join_style=2).buffer(2, 16)
        plate = plate.union(box(-FLANGE_HALF + 2, 0, FLANGE_HALF - 2, 2))
        bolts = [(sx * FLANGE_BOLT, v0 + sy * FLANGE_BOLT) for sx in (-1, 0, 1) for sy in (0, 1) if (sx, sy) != (0, 0)]
        angles = (45, 135, 180 + alpha, 360 - alpha, 0, 90, 180)
        wc, rep = wire_pattern((0, v0), plate, bolts, angles=angles)
        got = {round(a, 1): r for a, r in rep}
        if all(got.get(round(a, 1)) for a in angles[:4]):
            best = (alpha, v0, plate, bolts, wc, rep)
            break
    alpha, v0, plate, bolts, wc, rep = best
    cuts = [Point(0, v0).buffer(TUN_FBORE / 2, 96)] + wc + [Point(b).buffer(M5 / 2, 48) for b in bolts]
    g = plate.difference(unary_union(cuts))
    if g.geom_type == "MultiPolygon":
        g = max(g.geoms, key=lambda q: q.area)
    return g, bolts, v0, alpha, rep


def emit(path_stem, polys_closed, opens, mat, title, notes, out_dir, shift=(0.0, 0.0), outline=None):
    T, kerf, _ = gcode.fit(mat)
    job = gcode.job(mat, min_segment_mm=0.3)
    cuts = [gcode.Polyline(list(Polygon(p).buffer(-kerf / 2, join_style=2).exterior.coords), True) for p in polys_closed]
    cuts += [gcode.Polyline(o, False) for o in opens]
    if outline is not None:
        cuts.append(gcode.Polyline(list(outline.buffer(kerf / 2, join_style=2).exterior.coords), True))
    cuts = gcode.order(cuts)
    cuts = [gcode.Polyline([(x + shift[0], y + shift[1]) for x, y in c.points], c.closed) for c in cuts]
    lines = gcode.preamble(job, title=title, notes=notes + [f"{mat}: T {T}, kerf {kerf}"])
    for i, c in enumerate(cuts, 1):
        lines += gcode.cut(c, job, i, len(cuts))
    p = gcode.write(out_dir / f"{path_stem}_{mat}.gcode", lines)
    mins = sum(LineString(c.points).length * job.passes for c in cuts) / job.feed_mm_per_min
    return p, len(cuts), mins


def build(pitch=PITCH):
    cut, ball, laps, length, t_end = spiral(pitch)
    hold, curl, rmin = best_curl(cut, t_end, pitch)
    g, chan, path = guide(cut, t_end, pitch, hold, curl)
    bolts = guide_bolts(g, path, cut)
    cut_t = _ts(t_end, pitch)
    eg, eg_m5 = entry_guide(cut, cut_t)
    hole_list, mount = holes(cut, bolts, eg_m5)
    ex, ex_bolts = exit_flange(bolts)
    z_floor = z_of(t_end) - ARM_BASE
    arms = {phi: stair_arm(cut, cut_t, phi, z_floor) for phi in ARM_ANGLES}
    return dict(cut=cut, cut_t=cut_t, ball=ball, laps=laps, length=length, t_end=t_end, hold=hold, curl=curl, rmin=rmin,
                guide=g, chan=chan, path=path, bolts=bolts, holes=hole_list, mount=mount, exit=ex, exit_bolts=ex_bolts,
                entry_guide=eg, entry_m5=eg_m5, arms=arms, z_floor=z_floor)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--material", nargs="+", default=["ply3", "mdf3", "birch3"])
    ap.add_argument("--pitch", type=float, default=PITCH)
    ap.add_argument("--round", action="store_true", help="circular spiral (290 across) + an entry run beside it")
    ap.add_argument("--entry-run", type=float, default=20.0, help="with --round: extra flat sheet left of the spiral, mm")
    ap.add_argument("--stock-h", type=float, default=300.0, help="stock height (291 = inside the 292 mm Y reach)")
    ap.add_argument("--trim", action="store_true", help="cut an outline, trimmed to follow the spiral away from the mount edge")
    ap.add_argument("--screws", choices=["none", "pilot", "slot"], default="none",
                    help="layer screws on the sheet: pilot = M3 tap holes (tapped top layer), slot = clearance slots (layers below)")
    ap.add_argument("--parts", nargs="+", default=["sheet", "centre", "entry_guide", "stairs", "entry_flange", "exit_flange"])
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    configure(a.round, a.entry_run, a.stock_h)
    global TRIM
    TRIM = a.trim
    B = build(a.pitch)
    sheet_name = gcode.name("spiral_run" + ("_round" if a.round else "") + ("_trim" if a.trim else "")
                            + ("" if a.screws == "none" else "_" + a.screws),
                            STOCK, piece_outline().bounds[3] if a.trim else Y_HI, "x").rsplit("_", 1)[0]
    screw_pts = screw_points(B["cut"], [h for h, _ in B["holes"]]) if a.screws != "none" else []
    sheet_holes = [h for h, _ in B["holes"]] + (screw_cuts(screw_pts, a.screws) if screw_pts else [])
    if screw_pts:
        print(f"layer screws: {len(screw_pts)} x {a.screws}, {SCREW_IN:g} in from the step, every {SCREW_STEP:g} along each lap")
    fl, fl_bolts, v0, alpha, fl_rep = entry_flange()
    print(f"spiral: {B['laps']:.2f} laps, {B['length'] / 1000:.2f} m of cut; centre guide: hold {B['hold']} deg on the last "
          f"lap, curl {B['curl']} deg into the bore, tightest turn r {B['rmin']:.1f} (ball centre); {len(B['bolts'])} guide M5, "
          f"{len(B['exit_bolts'])} through the exit flange")
    print(f"entry flange: lower wires at +-{alpha:g} deg below horizontal, bore centre {v0:.2f} above the sheet; notches/stitch "
          f"{[(round(a, 1), r) for a, r in fl_rep]}")
    print(f"exit flange: pattern turned {EXIT_REPORT[0]} deg; notches/stitch {[(round(a, 1), r) for a, r in EXIT_REPORT[1:]]}")
    for mat in a.material:
        if "sheet" in a.parts:
            p, n, mins = emit(sheet_name, sheet_holes, [B["cut"]], mat,
                              f"spiral_run v3 -- marbles/clock/spiral_run.py: ONE spiral cut on {STOCK:g} x {STOCK_H:g} stock (no outline cut)"
                              + (f"; round, {ENTRY_RUN:g} mm entry run left of it" if a.round else ""),
                              [f"pitch {a.pitch:g}, {B['laps']:.2f} laps; {B['length'] / 1000:.2f} m of cut; the cut stops, the centre is solid",
                               "X0 Y0 = the stock's corner, the MOUNT edge toward the front (Y0); in use that edge is the top",
                               "centre: exit bore 23.1 (enclosed) + the centre guide's M5 holes (they also hold the exit flange underneath)"],
                              a.out, outline=piece_outline() if a.trim else None)
            print(f"{p.name}: {n} cuts, ~{mins:.0f} min")
        if "centre" in a.parts:
            g = B["guide"]
            x0, y0, x1, y1 = g.bounds
            cuts = [list(r.coords) for r in g.interiors] + [list(Point(b).buffer(M5 / 2, 48).exterior.coords) for b in B["bolts"]]
            p, n, mins = emit(gcode.name("spiral_centre_guide", x1 - x0 + 0.1, y1 - y0 + 0.1, mat).rsplit("_", 1)[0],
                              cuts, [], mat,
                              "spiral_centre_guide -- marbles/clock/spiral_run.py: the separate centre piece (cut 1 per layer)",
                              [f"lies on the sheet's solid centre, inside the last lap; its channel takes the ball off the last shelf "
                               f"and curls {B['curl']} deg into the exit bore (tightest turn r {B['rmin']:.0f})",
                               "same M5 pattern as the sheet's centre holes: guide + sheet (+ exit flange) bolt together",
                               "a 2nd copy stacked on top = the spacer layer (a taller wall)"],
                              a.out, shift=(-x0 + 0.05, -y0 + 0.05), outline=Polygon(g.exterior.coords))
            print(f"{p.name}: {n} cuts, ~{mins:.1f} min")
        if "entry_guide" in a.parts:
            eg = B["entry_guide"]
            x0, y0, x1, y1 = eg.bounds
            p, n, mins = emit(gcode.name("spiral_entry_guide", x1 - x0 + 0.1, y1 - y0 + 0.1, mat).rsplit("_", 1)[0],
                              [list(r.coords) for r in eg.interiors], [], mat,
                              "spiral_entry_guide -- marbles/clock/spiral_run.py: wall over the first lap until it has dropped",
                              [f"lies ~10 above the sheet (spacers, e.g. 2 M5 nuts = 8) on the sheet's {len(B['entry_m5'])} entry-guide M5;"
                               f" inner edge over the first lap's cut for {ENTRY_SPAN:g} deg from where the cut leaves the edge beam"],
                              a.out, shift=(-x0 + 0.05, -y0 + 0.05), outline=Polygon(eg.exterior.coords))
            print(f"{p.name}: {n} cuts, ~{mins:.1f} min")
        if "stairs" in a.parts:
            for phi, (arm, steps, m5) in B["arms"].items():
                ag = affinity.translate(arm, 0, -B["z_floor"])
                x0, y0, x1, y1 = ag.bounds
                p, n, mins = emit(gcode.name(f"spiral_stair_{phi}", x1 - x0 + 0.1, y1 - y0 + 0.1, mat).rsplit("_", 1)[0],
                                  [list(r.coords) for r in ag.interiors], [], mat,
                                  f"spiral_stair_{phi} -- marbles/clock/spiral_run.py: stair arm under the spiral at {phi} deg",
                                  [f"stands on edge along the ray at {phi} deg from the spiral centre, inner end {ARM_S0:g} out; "
                                   f"steps {DROP_REV:g} per lap (at this angle: " + ", ".join(f"{-z:.1f}" for _, _, z in sorted(steps, key=lambda q: -q[1])) + " below the frame)",
                                   f"M5 row 10 above the bottom edge into a 2020; the frame-level step is {-B['z_floor']:.1f} above the bottom edge"],
                                  a.out, shift=(-x0 + 0.05, -y0 + 0.05), outline=Polygon(ag.exterior.coords))
                print(f"{p.name}: {n} cuts, ~{mins:.1f} min")
        if "entry_flange" in a.parts:
            g2 = fl.buffer(0)
            x0, y0 = g2.bounds[0], g2.bounds[1]
            p, n, mins = emit(gcode.name("spiral_entry_flange", g2.bounds[2] - x0 + 0.1, g2.bounds[3] - y0 + 0.1, mat).rsplit("_", 1)[0],
                              [list(r.coords) for r in g2.interiors], [], mat,
                              "spiral_entry_flange -- marbles/clock/spiral_run.py: cropped wire-track flange, bottom edge on the sheet",
                              [f"bore centre {v0:.2f} above the bottom edge; lower wires at +-{alpha:g} deg below horizontal: a ball on them is at shelf level",
                               "all notches and stitch holes closed; bolts to the side of a 2020 post (M5 at u -20)"],
                              a.out, shift=(-x0 + 0.05, -y0 + 0.05), outline=Polygon(g2.exterior.coords))
            print(f"{p.name}: {n} cuts, ~{mins:.1f} min")
        if "exit_flange" in a.parts:
            ex = B["exit"]
            p, n, mins = emit(gcode.name("spiral_exit_flange", 2 * FLANGE_HALF + 0.1, 2 * FLANGE_HALF + 0.1, mat).rsplit("_", 1)[0],
                              [list(r.coords) for r in ex.interiors], [], mat,
                              "spiral_exit_flange -- marbles/clock/spiral_run.py: wire-track flange under the exit bore",
                              ["bore / notches / stitch holes as the standard flange; M5 = the centre guide bolts that land on it"],
                              a.out, shift=(FLANGE_HALF + 0.05, FLANGE_HALF + 0.05), outline=Polygon(ex.exterior.coords))
            print(f"{p.name}: {n} cuts, ~{mins:.1f} min")


if __name__ == "__main__":
    main()
