#!/usr/bin/env python3
"""Sketch: infeed ratchet. A FIXED toothed lower jaw (rack) at the end of the waiting track and a row of independently
hinged TOP PAWLS on the pendulum, offset half a pitch. The swing slides the pawls along the rack (>40 overlap at the
peak): a push stroke shoves each ball up its ramp and over the tooth into the next pocket; on the return the pawls hinge
up and ride back over the balls while the concave pocket faces hold them. One ball per pocket.
    python3 marbles/clock/infeed_ratchet_sketch.py   # -> marbles/views/infeed_ratchet.png"""
import math
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from shapely.geometry import Point, Polygon, box  # noqa: E402
from shapely.ops import unary_union  # noqa: E402

BALL = 19.05; BR = BALL / 2
H = 2 / 3 * BALL          # tooth height above the pocket floor (12.7)
P = 26.0                  # pitch: one ball per pocket
RP = BR + 0.3             # concave face: the ball's curve + 0.3
TIP_R = 1.5
N = 5                     # pockets drawn
OVERLAP = 40.0            # pawls overlap the rack at least this much at the peak of the swing


def rack():
    """fixed lower jaw: per pitch, a concave pocket face (holds the ball from going back) then a ramp up to the next tip"""
    teeth = []
    for k in range(N + 1):
        xb = k * P                                      # ball centre in pocket k at (xb, BR)
        xt = xb - math.sqrt(RP ** 2 - (H - BR) ** 2)    # tooth tip x (where the concave face reaches height H)
        x_ramp0 = xb - P                                # ramp starts under the previous ball
        teeth.append(Polygon([(x_ramp0, 0), (xt, H), (xt, 0)]))
    body = unary_union([box(-P - 5, -8, N * P + 5, 0)] + teeth)
    pockets = unary_union([Point(k * P, BR).buffer(RP, 96) for k in range(N + 1)])
    return body.difference(pockets).buffer(TIP_R).buffer(-TIP_R)          # round the tips


def pawl(xb, yh):
    """the top pawl that pushes the ball centred at (xb, BR): hangs from a hinge above, its tip stops 1.5 above the tooth
    tips (H) and its leading face is concave (the ball's curve + 0.3), cupping the ball's upper back; the trailing lower
    corner is ramped so on the return it rides up over the ball behind"""
    y_tip = H + 1.5
    body = Polygon([(xb - 14, yh), (xb - 1, yh), (xb - 1, y_tip), (xb - 9, y_tip), (xb - 14, y_tip + 7)])
    return body.difference(Point(xb, BR).buffer(RP, 96)), (xb - 8, yh - 3)


def main():
    fig, (a, b) = plt.subplots(2, 1, figsize=(14, 10), gridspec_kw=dict(height_ratios=[1.6, 1]))
    r = rack()
    a.fill(*r.exterior.xy, fc="burlywood", ec="saddlebrown")
    a.text(-P, -6, f"FIXED LOWER JAW (frame, end of the waiting track): teeth {H:.1f} tall (2/3 ball), concave pocket faces "
           f"(ball curve + 0.3), pitch {P:g}: one ball per pocket", fontsize=8)
    for k in range(N):
        a.add_patch(plt.Circle((k * P, BR), BR, fc="steelblue", alpha=.5, ec="k"))
    yh = BALL + 10
    for k in range(N):                                    # one pawl behind each ball (pushes it from behind)
        g, hinge = pawl(k * P, yh)
        a.fill(*g.exterior.xy, fc="peru", ec="k", alpha=.9)
        a.plot(*hinge, "wo", ms=5, mec="k")
    a.plot([-P / 2 - 8, (N - 1) * P - P / 2 + 8], [yh + 4, yh + 4], color="0.3", lw=6)
    a.text(-P / 2 - 8, yh + 7, "PENDULUM: a row of independent hinged pawls, one just behind each pocket; each "
           "has a stop so it can't fold back while pushing, and a rubber band to hold it down", fontsize=8)
    a.annotate("push stroke: pawls drive the balls up the ramps and over\nthe tips into the next pockets (one pitch)",
               ((N - 1) * P - 2, yh + 13), ((N - 1) * P - 70, yh + 13), arrowprops=dict(arrowstyle="->", lw=2), fontsize=8, va="center")
    a.annotate("return: pawls hinge up and ride back over the balls;\nthe concave pocket faces hold the balls",
               (-P / 2 - 2, -14), (2 * P, -14), arrowprops=dict(arrowstyle="->", lw=2), fontsize=8, va="center")
    a.set_xlim(-P - 10, N * P + 10); a.set_ylim(-20, yh + 22); a.set_aspect("equal")
    a.set_title("SIDE VIEW in the swing plane (pendulum at the peak of its swing: pawls overlap the rack)", fontsize=10)
    b.axis("off")
    b.text(0, 0.95, "Cycle", fontsize=11, weight="bold", va="top")
    b.text(0, 0.82, f"- Each swing slides the pawl row along the rack by more than one pitch ({P:g}); at the peak the row overlaps the "
           f"rack by > {OVERLAP:g}\n  (more than one pitch), so even a short swing still steps at least one ball and the supply doesn't stall.\n"
           "- Push: every pawl's concave face catches the ball ahead of it and drives it up the ramp; over the tip it drops into the next "
           "pocket.\n- Return: the pawls swing up on their hinges and ride back over the balls; the pocket faces (concave, 2/3 ball tall) "
           "keep the balls from going back.\n- Last pocket: hands the ball to the splitter mouth at the peak; if the pockets are full the "
           "next waiting ball is just pushed back at the lip.", fontsize=9, va="top")
    b.text(0, 0.18, f"Numbers: tooth {H:.1f} tall, pitch {P:g}, ramp {math.degrees(math.atan(H / (P - math.sqrt(RP**2 - (H - BR)**2)))):.0f} deg "
           f"(ramp length {P - math.sqrt(RP**2 - (H - BR)**2):.1f}), pocket face radius {RP:.2f}. The balls ride on the rack, not in a "
           "wire tunnel here, so they can rise the full tooth height: side guides needed.", fontsize=8.5, color="0.3", va="top")
    out = Path(__file__).resolve().parent.parent / "views" / "infeed_ratchet.png"
    plt.tight_layout(); plt.savefig(out, dpi=100)
    print(f"{out.name}: tooth {H:.2f}, pitch {P:g}")


if __name__ == "__main__":
    main()
