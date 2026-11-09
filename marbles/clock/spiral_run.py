#!/usr/bin/env python3
"""Spiral marble run: one 300 x 300 sheet, ONE spiral cut line (nothing removed but holes).

Pull the centre down and the sheet between the turns becomes a descending helical shelf (a slinky): each turn sits a
little lower than the one outside it, so the outer turn's edge is a low wall. The ball rolls on the shelf, held out
against that wall by its own centripetal force, round and down to the centre.

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
  - entry: a cropped wire-track flange stands on the sheet at the start, its bore centred NO_DROP_AXIS above the
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

from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from laser_parts import gcode  # noqa: E402  (quickcut's gcode core)

STOCK = 300.0
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


def holes(cut, bolts):
    """[(closed points, label)] on the sheet: the exit bore (enclosed), the guide bolts, the mount row"""
    out = [(list(Point(CX, CY).buffer(TUN_FBORE / 2, 96).exterior.coords), "exit bore")]
    out += [(list(Point(p).buffer(M5 / 2, 48).exterior.coords), "guide M5") for p in bolts]
    mount = [(10 + MOUNT_STEP * i, MOUNT_Y) for i in range(int((STOCK - 20) // MOUNT_STEP) + 1)]
    out += [(list(Point(p).buffer(M5 / 2, 48).exterior.coords), "mount M5") for p in mount]
    return out, mount


def exit_flange(bolts):
    """the wire-track flange that goes UNDER the sheet's exit bore: bore, wire notches, stitch holes as the standard
    flange, bolted through the guide bolts that land on it; the wire pattern is turned to clear them"""
    plate = box(-FLANGE_HALF, -FLANGE_HALF, FLANGE_HALF, FLANGE_HALF).buffer(-2, join_style=2).buffer(2, 16)
    rel = [(x - CX, y - CY) for x, y in bolts if abs(x - CX) < FLANGE_HALF and abs(y - CY) < FLANGE_HALF]
    def feats(rot):
        out = []
        for a in (rot + 45, rot + 135, rot + 225, rot + 315):
            u = (math.cos(math.radians(a)), math.sin(math.radians(a)))
            out.append(LineString([(0, 0), (TUN_NOTCH_OUT * u[0], TUN_NOTCH_OUT * u[1])]).buffer(TUN_HOLE / 2, cap_style=2))
            out.append(Point(TUN_SR * u[0], TUN_SR * u[1]).buffer(TUN_HOLE / 2, 24))
        return out
    rot = max(range(0, 90, 2), key=lambda r: min([unary_union(feats(r)).distance(Point(b)) for b in rel] or [0]))
    cuts = [Point(0, 0).buffer(TUN_FBORE / 2, 96)] + feats(rot) + [Point(b).buffer(M5 / 2, 48) for b in rel]
    return plate.difference(unary_union(cuts)), rel


def entry_flange():
    """the cropped wire-track flange (u across the tunnel, v up from the sheet), bore centre at (0, NO_DROP_AXIS).
    Its bottom edge sits on the sheet: the bore and the two lower wire notches open through it."""
    v0 = NO_DROP_AXIS
    plate = box(-FLANGE_HALF, 0, FLANGE_HALF, v0 + FLANGE_HALF)
    plate = plate.buffer(-2, join_style=2).buffer(2, 16).union(box(-FLANGE_HALF + 2, 0, FLANGE_HALF - 2, 2))
    cuts = [Point(0, v0).buffer(TUN_FBORE / 2, 96)]
    for a in (45, 135, 225, 315):
        u = (math.cos(math.radians(a)), math.sin(math.radians(a)))
        end = TUN_NOTCH_OUT if a < 180 else (v0 + 1) / abs(u[1])          # lower notches run out through the bottom
        cuts.append(LineString([(0, v0), (end * u[0], v0 + end * u[1])]).buffer(TUN_HOLE / 2, cap_style=2))
        s = (TUN_SR * u[0], v0 + TUN_SR * u[1])
        if s[1] - TUN_HOLE / 2 > 4:
            cuts.append(Point(s).buffer(TUN_HOLE / 2, 24))
    bolts = [(sx * FLANGE_BOLT, v0 + sy * FLANGE_BOLT) for sx in (-1, 0, 1) for sy in (0, 1) if (sx, sy) != (0, 0)]
    cuts += [Point(b).buffer(M5 / 2, 48) for b in bolts]
    g = plate.difference(unary_union(cuts))
    if g.geom_type == "MultiPolygon":
        g = max(g.geoms, key=lambda q: q.area)     # slivers between the opened bore and the lower notches fall out
    return g, bolts


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
    hole_list, mount = holes(cut, bolts)
    ex, ex_bolts = exit_flange(bolts)
    return dict(cut=cut, ball=ball, laps=laps, length=length, t_end=t_end, hold=hold, curl=curl, rmin=rmin,
                guide=g, chan=chan, path=path, bolts=bolts, holes=hole_list, mount=mount, exit=ex, exit_bolts=ex_bolts)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--material", nargs="+", default=["ply3", "mdf3", "birch3"])
    ap.add_argument("--pitch", type=float, default=PITCH)
    ap.add_argument("-o", "--out", type=Path, default=HERE.parent / "gcode")
    a = ap.parse_args()
    B = build(a.pitch)
    fl, fl_bolts = entry_flange()
    print(f"spiral: {B['laps']:.2f} laps, {B['length'] / 1000:.2f} m of cut; centre guide: hold {B['hold']} deg on the last "
          f"lap, curl {B['curl']} deg into the bore, tightest turn r {B['rmin']:.1f} (ball centre); {len(B['bolts'])} guide M5, "
          f"{len(B['exit_bolts'])} through the exit flange; no-drop axis {NO_DROP_AXIS:.2f}")
    for mat in a.material:
        p, n, mins = emit("spiral_run_300x290", [h for h, _ in B["holes"]], [B["cut"]], mat,
                          "spiral_run v3 -- marbles/clock/spiral_run.py: ONE spiral cut on 300 x 300 stock (no outline cut)",
                          [f"pitch {a.pitch:g}, {B['laps']:.2f} laps; {B['length'] / 1000:.2f} m of cut; the cut stops, the centre is solid",
                           "X0 Y0 = the stock's corner, the MOUNT edge toward the front (Y0); in use that edge is the top",
                           "centre: exit bore 23.1 (enclosed) + the centre guide's M5 holes (they also hold the exit flange underneath)"],
                          a.out)
        print(f"{p.name}: {n} cuts, ~{mins:.0f} min")
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
        g2 = fl.buffer(0)
        x0, y0 = g2.bounds[0], g2.bounds[1]
        p, n, mins = emit(gcode.name("spiral_entry_flange", g2.bounds[2] - x0 + 0.1, g2.bounds[3] - y0 + 0.1, mat).rsplit("_", 1)[0],
                          [list(r.coords) for r in g2.interiors], [], mat,
                          "spiral_entry_flange -- marbles/clock/spiral_run.py: cropped wire-track flange, bottom edge on the sheet",
                          [f"bore centre {NO_DROP_AXIS:.2f} above the bottom edge: a ball on the tunnel's lower wires is at shelf level",
                           "lower notches open through the bottom edge; bolts to the side of a 2020 post (M5 at u -20)"],
                          a.out, shift=(-x0 + 0.05, -y0 + 0.05), outline=Polygon(g2.exterior.coords))
        print(f"{p.name}: {n} cuts, ~{mins:.1f} min")
        ex = B["exit"]
        p, n, mins = emit(gcode.name("spiral_exit_flange", 2 * FLANGE_HALF + 0.1, 2 * FLANGE_HALF + 0.1, mat).rsplit("_", 1)[0],
                          [list(r.coords) for r in ex.interiors], [], mat,
                          "spiral_exit_flange -- marbles/clock/spiral_run.py: wire-track flange under the exit bore",
                          ["bore / notches / stitch holes as the standard flange; M5 = the centre guide bolts that land on it"],
                          a.out, shift=(FLANGE_HALF + 0.05, FLANGE_HALF + 0.05), outline=Polygon(ex.exterior.coords))
        print(f"{p.name}: {n} cuts, ~{mins:.1f} min")


if __name__ == "__main__":
    main()
