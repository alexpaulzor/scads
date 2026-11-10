#!/usr/bin/env python3
"""Black acrylic feed x pass calibration: cnc_vibes' elliptical ring test (spiral_cal.generate), sized small and slow
for 3 mm black acrylic on the 10 W diode, shifted so the plate's bottom-left is X0 Y0 (positive coords only), finished
by quickcut (frame pass, park, validation).

5 rings, inner slow -> outer fast (feed = perimeter / loop time), each split into 4 sectors cut 1..4 times. Read which
(feed x passes) sectors dropped out cleanly; labels are etched. Range chosen from published starting points for 10 W
diodes on 3 mm black acrylic: 100 % power, roughly 150-250 mm/min, 2-4 passes.

    python3 marbles/acrylic_cal.py          # -> marbles/gcode/acrylic_cal_<W>x<H>_acrylic3.gcode
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
VIBES = Path("/home/user/cnc_vibes") if Path("/home/user/cnc_vibes").exists() else HERE.parents[1] / "cnc_vibes"
sys.path.insert(0, str(VIBES / "cnc_calibrate"))
sys.path.insert(0, str(VIBES / "quickcut"))
import spiral_cal  # noqa: E402
import gcode as qc  # noqa: E402

RINGS, MIN_R, MAX_R, LOOP_S, PASSES, ASPECT = 5, 4.0, 16.0, 26.0, [1, 2, 3, 4], 1.35
MARGIN = 2.0


def main():
    lines, b, feeds, T, meta = spiral_cal.generate(RINGS, MIN_R, MAX_R, LOOP_S, 100.0, passes=PASSES, aspect=ASPECT,
                                                   engrave_power=spiral_cal.ENGRAVE_POWER_PCT,
                                                   engrave_feed=spiral_cal.ENGRAVE_FEED)
    xs, ys = [], []
    for l in lines:
        if re.match(r"G[0123]\b", l):
            for ax, store in (("X", xs), ("Y", ys)):
                m = re.search(ax + r"(-?[\d.]+)", l)
                if m:
                    store.append(float(m.group(1)))
    dx, dy = MARGIN - min(xs), MARGIN - min(ys)

    def shift(l):
        if not re.match(r"G[0123]\b", l):
            return l
        l = re.sub(r"X(-?[\d.]+)", lambda m: f"X{float(m.group(1)) + dx:.3f}", l)
        return re.sub(r"Y(-?[\d.]+)", lambda m: f"Y{float(m.group(1)) + dy:.3f}", l)
    out = [shift(l).replace("origin CENTER", "origin = plate bottom-left") for l in lines]
    w, h = max(xs) - min(xs) + 2 * MARGIN, max(ys) - min(ys) + 2 * MARGIN
    name = qc.name("acrylic_cal", w, h, "acrylic3")
    head = [f"; {name} -- marbles/acrylic_cal.py: black acrylic feed x pass test, X0 Y0 = plate bottom-left",
            f"; feeds mm/min (inner->outer): {feeds}; passes per sector (CCW from the warmup join): {meta['counts']}",
            "; air assist ON; ventilate (acrylic fumes); stay with the machine (acrylic can flame)"]
    p = qc.write(HERE / "gcode" / f"{name}.gcode", head + out, validate=False)
    print(f"{p.name}: {w:.1f} x {h:.1f} mm; feeds {feeds} mm/min; sector pass counts {meta['counts']}")


if __name__ == "__main__":
    main()
