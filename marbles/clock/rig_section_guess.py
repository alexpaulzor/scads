#!/usr/bin/env python3
"""Top-down section of the lift rig as Claude currently understands it (for Alex to correct). Not a design.
v2 (2026-11-14): F and M offset ~10 mm front-to-back; M's single sieves ride in F's side slots, F's spine sieve rides
in M's side beams' inside slots."""
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle

T = 3.2                      # sieve / keeper thickness (MDF)
OFF = 10.0                   # M's beams sit this far toward +y (up the page) from F
fig, ax = plt.subplots(figsize=(12, 8))
def beam(x, y, col, lab):
    ax.add_patch(Rectangle((x - 10, y - 10), 20, 20, fc=col, ec="k", lw=1.2))
    for (sx, sy, w, h) in ((x - 10, y - 3, 6, 6), (x + 4, y - 3, 6, 6), (x - 3, y - 10, 6, 6), (x - 3, y + 4, 6, 6)):
        ax.add_patch(Rectangle((sx, sy), w, h, fc="w", ec="0.4", lw=.6))       # the 4 T-slots
    ax.text(x, y, lab, ha="center", va="center", fontsize=9, weight="bold")
beam(0, 0, "#c0c0c0", "F")
beam(-40, OFF, "#d8d8d8", "M")
beam(40, OFF, "#d8d8d8", "M")
# F's spine sieve: on F's +y face, edges in M's inside slots (slot centre plane y = OFF)
ax.add_patch(Rectangle((-36, 10), 72, T, fc="#c9a46a", ec="k"))
ax.text(0, 15.5, "F's spine sieve (double): bolted to F, edges ride in M's inside slots", ha="center", fontsize=8)
# M's single sieves: on M's -y face, inner edge in F's side slot (slot centre plane y = 0)
for s in (-1, 1):
    ax.add_patch(Rectangle((min(s * 6, s * 50), -T + 0), abs(s * 50 - s * 6), T, fc="#e0c08a", ec="k"))
ax.text(0, -6.5, "M's single sieves: bolted to each M beam, inner edge rides in F's side slot", ha="center", fontsize=8)
# keepers
ax.add_patch(Rectangle((-30, -10 - T), 60, T, fc="#b08850", ec="k"))
ax.text(0, -18, "F's double keeper (spine keeper), on F's -y face", ha="center", fontsize=8)
ax.add_patch(Rectangle((-50, OFF + 10), 100, T, fc="#8c6a3c", ec="k", alpha=.7))
ax.text(0, OFF + 10 + T + 2.5, "M's double keeper: across both M beams, outside bolts, on M's +y face", ha="center", fontsize=8)
# balls in the lanes
for s in (-1, 1):
    ax.add_patch(Circle((s * 20, 5), 9.5, fc="#999", ec="k", alpha=.75))
ax.text(0, -60, "ball lanes: between F and each M beam (x), between the keepers (y)?", ha="center", fontsize=8)
# SK8 on F's keeper
ax.add_patch(Rectangle((-7, -10 - T - 33), 14, 33, fc="#bbb", ec="k", hatch="//"))
ax.add_patch(Circle((0, -10 - T - 20), 4, fc="w", ec="k"))
ax.text(9, -40, "SK8 bolted through F's keeper into F\n8 mm pivot shaft runs left-right, 20 out", fontsize=8)
ax.text(-110, 45, "LOOKING DOWN on the rig.  Which way is the front of the clock: +y (up the page) or -y?", fontsize=10, weight="bold")
ax.text(-110, 38, "Where are F's top and bottom double flanges: on the -y side (with F's keeper) or the +y side?", fontsize=9)
ax.set_xlim(-112, 112); ax.set_ylim(-65, 50); ax.set_aspect("equal"); ax.axis("off")
plt.savefig(Path(__file__).resolve().parent.parent / "views" / "rig_section_guess.png", dpi=110, bbox_inches="tight")
