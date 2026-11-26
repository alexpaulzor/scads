#!/usr/bin/env python3
"""Sketch: side section of the clock train in front of the escape wheel (half section above the axle).
Escape wheel (seconds pointer at its rim) -> minute Wolfrom 60:1 -> hour Wolfrom 12:1 -> fixed DIAL plate -> hands in
front on concentric tubes; the marble rides in a cage at the hour hand's tip, in a channel in front of the dial.
    python3 marbles/clock/clock_train_section.py   # -> marbles/views/clock_train_section.png"""
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

T = 2.63
fig, ax = plt.subplots(figsize=(14, 8))


def blk(z0, nz, r0, r1, col, lab=None, fs=7, a=1.0):
    ax.add_patch(plt.Rectangle((z0, r0), nz * T, r1 - r0, fc=col, ec="k", lw=.6, alpha=a))
    if lab:
        ax.text(z0 + nz * T / 2, r1 + 2, lab, fontsize=fs, ha="center", rotation=90, va="bottom")


z = 0.0
ax.add_patch(plt.Rectangle((-60, -4), 260, 8, fc="0.35")); ax.text(-58, -11, "FIXED 8 mm axle", fontsize=8)
blk(-14, 1, 4, 122, "burlywood", "escape wheel front ring")
ax.plot([-12.7, -12.7], [112, 128], color="k", lw=3); ax.text(-11, 126, "seconds pointer (on the wheel)", fontsize=7)
ax.add_patch(plt.Rectangle((-12, 107), 30, 6, fc="silver", ec="k")); ax.text(18, 108, "pin ends", fontsize=7)
# minute stage
z = 2
blk(z, 1, 12, 46, "0.6", "carrier"); z += T
blk(z, 1, 11, 23, "goldenrod", "sun 21 (bolted to the wheel)"); blk(z, 1, 21, 59, "peru"); blk(z, 1, 59, 78, "burlywood", "fixed ring 59"); z += T
blk(z, 1, 21, 57, "sienna"); blk(z, 1, 57, 67.6, "tan", "output ring 63 (minutes)"); z += T
blk(z, 1, 12, 46, "0.6"); z += T
m_disc = z; blk(z, 1, 11, 67.6, "tan", "minute disc + 608"); z += T + 1
ax.text(4, 90, "MINUTE STAGE 60:1", fontsize=9, weight="bold")
# hour stage
blk(z, 1, 12, 33, "0.6"); z += T
blk(z, 1, 11, 18, "goldenrod", "sun 18 (on the minute disc)"); blk(z, 1, 18, 36, "peru"); blk(z, 1, 36, 52, "burlywood", "fixed ring 36"); z += T
blk(z, 1, 18, 33, "sienna"); blk(z, 1, 33, 42, "tan", "output ring 48 (hours)"); z += T
blk(z, 1, 12, 33, "0.6"); z += T
h_disc = z; blk(z, 1, 11, 42, "tan", "hour disc + 608"); z += T + 2
ax.text(z - 26, 70, "HOUR STAGE 12:1", fontsize=9, weight="bold")
# dial plate (fixed) + standoffs to the fixed rings
dial = z; blk(z, 1, 30, 104, "khaki", "DIAL (fixed)"); z += T
for zr, r in ((2 + T, 73), (m_disc + T + 1 + T, 47)):
    ax.add_patch(plt.Rectangle((zr, r - 1.5), dial - zr, 3, fc="dimgray")); 
ax.text(m_disc - 10, 76, "standoffs: fixed rings -> dial (outside every moving part)", fontsize=7)
# tubes + hands in front
ax.add_patch(plt.Rectangle((m_disc, 4), z + 22 - m_disc, 3, fc="steelblue")); ax.text(z + 23, 4, "minute tube", fontsize=7)
ax.add_patch(plt.Rectangle((h_disc, 7), z + 8 - h_disc, 3, fc="seagreen")); ax.text(z + 9, 8, "hour tube", fontsize=7)
blk(z + 3, 1, 7, 86, "seagreen", "hour hand -> marble cage at its tip")
ax.add_patch(plt.Circle((z + 3 + T / 2, 86), 9.5, fc="seagreen", alpha=.4, ec="k"))
blk(z + 3 + T + 10, 1, 72, 100, "khaki", "channel front ring (fixed, window)", a=.8)
blk(z + 19, 1, 4, 115, "steelblue", "minute hand")
ax.set_xlim(-62, 120); ax.set_ylim(-15, 140); ax.set_aspect("equal")
ax.set_xlabel("along the axle, mm (viewer to the right)"); ax.set_ylabel("radius, mm")
ax.set_title("SIDE SECTION (half, above the axle): fixed parts hang off the dial; hands in front on tubes; hour hand carries the marble", fontsize=10)
out = Path(__file__).resolve().parent.parent / "views" / "clock_train_section.png"
plt.tight_layout(); plt.savefig(out, dpi=100)
print(out.name, "dial at", round(dial, 1))
