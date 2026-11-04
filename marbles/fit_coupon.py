#!/usr/bin/env python3
"""Tab-fit coupon for a material profile: which slot width fits this stock?

One plate with 5 slots, 10 long, drawn at T + (-0.10, -0.05, 0, +0.05, +0.10), where T is the
profile's thickness. Under each slot, notches on the plate's bottom edge count 1..5 (left to right),
so slot 3 is "slot = thickness", the current default. Also one tab piece: a 10-wide tab on a 24 x 14
body. Both are kerf-compensated with the profile's kerf, exactly as the real parts are.

Push the tab into each slot. Pick the one that is tight and snug without forcing, then set the
profile's fit block: slot_extra_mm = that slot's offset (e.g. slot 4 -> +0.05) and write what you saw
under `verified:`. If even slot 1 is loose, the kerf is smaller than the profile says; if slot 5 is
still too tight, it's bigger.

    python3 marbles/fit_coupon.py                     # mdf3 -> marbles/gcode/fit_coupon_<W>x<H>_mdf3.gcode
    python3 marbles/fit_coupon.py --material ply3
"""
import argparse
import sys
from pathlib import Path

from shapely import affinity
from shapely.geometry import Polygon, box
from shapely.ops import unary_union

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from laser_parts import emit_cut, load_profile, material_fit, preamble, std_path  # noqa: E402

OFFSETS = [-0.10, -0.05, 0.0, 0.05, 0.10]
SLOT_L, PITCH, MARGIN, PLATE_H = 10.0, 16.0, 6.0, 22.0
NOTCH_W, NOTCH_D, NOTCH_GAP = 1.0, 1.5, 1.0


def coupon(T):
    W = 2 * MARGIN + (len(OFFSETS) - 1) * PITCH + SLOT_L
    plate = box(0, 0, W, PLATE_H)
    cuts = []
    for i, off in enumerate(OFFSETS):
        xc = MARGIN + SLOT_L / 2 + i * PITCH
        w = T + off
        cuts.append(box(xc - SLOT_L / 2, PLATE_H / 2 + 1 - w / 2, xc + SLOT_L / 2, PLATE_H / 2 + 1 + w / 2))
        n = i + 1                                       # index notches on the bottom edge
        span = n * NOTCH_W + (n - 1) * NOTCH_GAP
        for k in range(n):
            x = xc - span / 2 + k * (NOTCH_W + NOTCH_GAP)
            cuts.append(box(x, -0.01, x + NOTCH_W, NOTCH_D))
    plate = plate.difference(unary_union(cuts))
    tab = unary_union([box(0, 0, 24, 14), box(7, 14 - 0.01, 17, 14 + 6)])    # 10-wide tab, 6 long
    return plate, affinity.translate(tab, W + 4, 0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--material", default="mdf3")
    a = ap.parse_args()
    T, KERF, _ = material_fit(a.material)
    s2g, motion, mat, job = load_profile(a.material, 1000, None)
    parts = [g.buffer(KERF / 2, join_style=2) for g in coupon(T)]
    x0 = min(g.bounds[0] for g in parts); y0 = min(g.bounds[1] for g in parts)
    parts = [affinity.translate(g, -x0, -y0) for g in parts]
    loops = []
    for g in parts:
        loops += sorted([list(r.coords) for r in g.interiors], key=lambda pl: abs(Polygon(pl).area))
    loops += [list(g.exterior.coords) for g in parts]
    cuts = [s2g.Polyline(pl, True) for pl in loops]
    widths = ", ".join(f"{i + 1}: {T + o:.2f} ({o:+.2f})" for i, o in enumerate(OFFSETS))
    lines = [f"; fit coupon -- marbles/fit_coupon.py: {mat['id']} T {T}, kerf {KERF}",
             f"; slots (count the notches under each): {widths}; plus one 10-wide tab piece",
             f"; recipe {job.power_percent:g}% F{job.feed_mm_per_min} x{job.passes}; X0 Y0 = bottom-left", ";"]
    lines += preamble(s2g, job)
    for i, c in enumerate(cuts, 1):
        lines += emit_cut(s2g, motion, c, i, len(cuts), job)
    lines += s2g._footer(lines)
    out = std_path(HERE / "gcode", "fit_coupon", lines, mat["id"])
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines))
    print(f"wrote {out.name}: slots {widths}")


if __name__ == "__main__":
    main()
