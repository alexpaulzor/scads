#!/usr/bin/env python3
"""Top-down section of the lift rig as Claude currently understands it (for Alex to correct). Not a design."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle

fig, ax = plt.subplots(figsize=(11, 7.5))
def beam(x, y, col, lab):
    ax.add_patch(Rectangle((x - 10, y - 10), 20, 20, fc=col, ec="k"))
    ax.text(x, y, lab, ha="center", va="center", fontsize=9, weight="bold")
beam(0, 0, "#c0c0c0", "F\n(13)")
beam(-40, 0, "#d8d8d8", "M")
beam(40, 0, "#d8d8d8", "M")
for x in (-20, 20):
    ax.add_patch(Circle((x, 0), 9.5, fc="#999", ec="k"))
ax.text(0, -22, "ball lanes: 20 between F and each M beam?", ha="center", fontsize=8)
# front face (+y): sieves
ax.add_patch(Rectangle((-32, 10), 64, 3, fc="#c9a46a", ec="k")); ax.text(36, 11.5, "", fontsize=8)
ax.text(0, 17, "F's double sieve (spans both lanes?)", ha="center", fontsize=8)
for x in (-40, 40):
    ax.add_patch(Rectangle((x - 18, 13.5), 36, 3, fc="#e0c08a", ec="k"))
ax.text(0, 24, "M's single sieves, one on each side beam (stand off F's sieve?)", ha="center", fontsize=8)
# back face (-y): keepers
ax.add_patch(Rectangle((-32, -13), 64, 3, fc="#b08850", ec="k"))
ax.text(0, -30, "F's double keeper (spine keeper)", ha="center", fontsize=8)
ax.add_patch(Rectangle((-50, -16.5), 100, 3, fc="#8c6a3c", ec="k", alpha=.6))
ax.text(0, -36, "M's double keeper, bolted to both M side beams: in front of / behind / above F's keeper?", ha="center", fontsize=8)
# SK8 through F's keeper
ax.add_patch(Rectangle((-7, -45), 14, 32, fc="#bbb", ec="k", hatch="//"))
ax.add_patch(Circle((0, -33), 4, fc="w", ec="k"))
ax.text(10, -48, "SK8 on F, through F's keeper\n(8 mm pivot shaft runs left-right here)\nhow does it get past M's keeper?", fontsize=8, va="top")
ax.annotate("flanges top and bottom:\nwhich face?", (0, 13), (-95, 35), arrowprops=dict(arrowstyle="->"), fontsize=8)
ax.annotate("link to M goes here?\n(M's side away from the flanges)", (-40, -17), (-100, -60), arrowprops=dict(arrowstyle="->"), fontsize=8)
ax.text(-100, 45, "LOOKING DOWN on the rig  (front = up the page?)", fontsize=10, weight="bold")
ax.set_xlim(-105, 105); ax.set_ylim(-75, 50); ax.set_aspect("equal"); ax.axis("off")
plt.savefig(HERE := __import__("pathlib").Path(__file__).resolve().parent.parent / "views" / "rig_section_guess.png", dpi=110, bbox_inches="tight")
