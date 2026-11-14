#!/usr/bin/env python3
"""Front view of the lift rig as Claude understands it (2026-11-14), for Alex to confirm before the link simulator
is rebuilt. Looking straight at the clock face; the rig swings left-right in this plane."""
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle

KT = 2 * 3.2          # F's double keeper (2 x MDF?)  -- to confirm
OFF = 10.0            # M sits this far LEFT of F (toward F's sieve side)
fig, ax = plt.subplots(figsize=(9, 11))
top = 0.0
# F: 2020 spine, keeper on its right face, sieve + flanges on its left face
ax.add_patch(Rectangle((-10, -330), 20, 330, fc="#c0c0c0", ec="k"))
ax.text(0, -170, "F", ha="center", fontsize=12, weight="bold")
ax.add_patch(Rectangle((10, -330), KT, 300, fc="#b08850", ec="k"))
ax.text(10 + KT + 3, -250, "F's double keeper\n(spine keeper)", fontsize=8)
ax.add_patch(Rectangle((-10 - 3.2, -330), 3.2, 320, fc="#c9a46a", ec="k"))
for z in (-40, -300):
    ax.add_patch(Rectangle((-10 - 3.2 - 14, z - 20), 14, 40, fc="#a0a0a0", ec="k"))
ax.text(-60, -300, "double flange\n(bottom)", fontsize=8, ha="right"); ax.text(-60, -40, "double flange\n(top)", fontsize=8, ha="right")
ax.text(-16, -170, "F's spine sieve\n+ flanges (left side)", fontsize=8, ha="right")
# SK8 on F's keeper, pivot shaft (seen end-on: pointing at you)
sx = 10 + KT
ax.add_patch(Rectangle((sx, -40), 20 + 7, 42, fc="#bbb", ec="k", hatch="//"))
ax.add_patch(Circle((sx + 20, -19), 4, fc="w", ec="k", lw=2))
ax.annotate("pivot shaft (end-on), in the SK8 on F's keeper:\n10 + keeper + 20 right of F's centre", (sx + 20, -19), (sx + 35, 30),
            arrowprops=dict(arrowstyle="->"), fontsize=8)
# M: side beams seen end-on? No: from the front, the FRONT side beam hides the back one; drawn offset left by OFF
ax.add_patch(Rectangle((-10 - OFF, -340), 20, 330, fc="#e8e8e8", ec="k", alpha=.55, ls="--"))
ax.text(-OFF - 30, -200, "M's front side beam\n(in front of F, 10 left)", fontsize=8, ha="right")
ax.add_patch(Rectangle((-10 - OFF, -10), 20, 20, fc="#333", ec="k"))
ax.annotate("M's black 150 top beam (end-on: runs front-to-back,\ntying the front and back side beams)", (-OFF, 0), (-150, 45),
            arrowprops=dict(arrowstyle="->"), fontsize=8)
ax.annotate("link to M goes here: top beam or sides,\nwherever the numbers want it", (-OFF - 10, 5), (-150, 90),
            arrowprops=dict(arrowstyle="->"), fontsize=8)
ax.text(-150, -400, "LOOKING AT THE CLOCK FACE.  Left = F's sieve / flange side.  Right = F's keeper + pivot side.\n"
        "M's two side beams: one toward the wall, one 'stage forward' toward you (this one).\nThe rig swings left-right in this view.",
        fontsize=9)
ax.set_xlim(-160, 130); ax.set_ylim(-420, 120); ax.set_aspect("equal"); ax.axis("off")
plt.savefig(Path(__file__).resolve().parent.parent / "views" / "rig_front_guess.png", dpi=110, bbox_inches="tight")
