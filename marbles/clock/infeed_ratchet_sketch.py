#!/usr/bin/env python3
"""Sketch: rocking ratchet in the infeed tunnel (4-wire, wires at 45/135/225/315). Fixed lower jaw with a sawtooth
(ramps gentler than the swing's tilt, so the forward tilt rolls balls up and over; cliffs a ball can't roll back over
at 12 deg), hinged top pawls offset half a pitch that let balls pass forward only.
    python3 marbles/clock/infeed_ratchet_sketch.py   # -> marbles/views/infeed_ratchet.png"""
import math
from pathlib import Path
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

R = 19.05 / 2; RW = 11.025; WD = 2.05
TILT = 12.0
PITCH = 40.0          # two balls per valley ("at least 2 balls in one grab")
CLIFF_SET = 1.0       # the ball can only rise 1.39 off the lower wires before it hits the upper ones (20 bore, 19.05 ball)
N = 3
ZC = -7.8 + math.sqrt((R + WD / 2) ** 2 - 7.8 ** 2)     # ball centre on the two lower wires
Z0 = ZC - R                                              # ball bottom on the wires (valley floor of the jaw)
CLIFF = CLIFF_SET
RAMP = math.degrees(math.atan(CLIFF / PITCH))


def tooth_profile(x0):
    pts = [(x0, Z0 - 3)]
    for k in range(N):
        a = x0 + k * PITCH
        pts += [(a, Z0), (a + PITCH, Z0 + CLIFF), (a + PITCH, Z0)]
    pts += [(x0 + N * PITCH, Z0 - 3)]
    return pts


def ball_on_ramp(x):
    """ball centre on the ramp at contact abscissa x (ramp rises left to right)"""
    s = math.tan(math.radians(RAMP))
    k = int(x // PITCH); u = x - k * PITCH
    zr = Z0 + u * s
    return (x - R * math.sin(math.radians(RAMP)), zr + R * math.cos(math.radians(RAMP)))


def main():
    fig, (a, b) = plt.subplots(2, 1, figsize=(14, 9), gridspec_kw=dict(height_ratios=[1.3, 1]))
    L = N * PITCH
    for z in (7.8, -7.8):
        a.plot([-10, L + 10], [z + WD / 2, z + WD / 2], color="0.6", lw=1); a.plot([-10, L + 10], [z - WD / 2, z - WD / 2], color="0.6", lw=1)
    a.text(L + 12, 7.8, "upper wires\n(135/45)", fontsize=7, va="center"); a.text(L + 12, -7.8, "lower wires\n(225/315)", fontsize=7, va="center")
    for xr in range(0, int(L) + 1, 30):                            # rings, top and bottom snipped
        a.plot([xr, xr], [-14.1, -10.5], color="0.8", lw=3); a.plot([xr, xr], [10.5, 14.1], color="0.8", lw=3)
    a.text(1, 15, "rings: top + bottom segments snipped out (jaw plates pass through the gaps)", fontsize=7, color="0.4")
    tp = tooth_profile(0)
    a.fill([p[0] for p in tp], [p[1] for p in tp], fc="burlywood", ec="saddlebrown")
    a.text(2, Z0 - 2.4, f"FIXED LOWER JAW (ply3, in the bottom gap): steps of {CLIFF:.1f} every {PITCH:g} (ramp {RAMP:.1f} deg)", fontsize=7.5)
    for k in range(N):                                              # two balls per valley
        for j, x in enumerate((k * PITCH + 12, k * PITCH + 12 + 2 * R)):
            c = ball_on_ramp(x)
            a.add_patch(plt.Circle(c, R, fc="steelblue", alpha=.45, ec="k"))
    for k in range(N):                                              # hinged top pawls, half a pitch from the cliffs
        hx = k * PITCH + PITCH / 2 - 6
        a.plot([hx], [13.5], "ko", ms=4)
        a.plot([hx, hx + 9], [13.5, 4.5], color="saddlebrown", lw=4, solid_capstyle="round")
        a.annotate("", (hx + 11, 9), (hx + 4, 3), arrowprops=dict(arrowstyle="<-", color="g", lw=1))
    a.text(PITCH / 2 + 6, 16.5, "HINGED TOP PAWLS (one tooth each): swing up to let a ball go forward, a stop behind\n"
           "each keeps it from swinging back; a rubber band holds them down against gravity when upside down", fontsize=7.5)
    a.annotate("forward", (L - 5, -15), (L - 35, -15), arrowprops=dict(arrowstyle="->", lw=2), fontsize=9, va="center")
    a.set_xlim(-12, L + 28); a.set_ylim(-18, 21); a.set_aspect("equal")
    a.set_title("SIDE SECTION of the infeed tunnel at the jaws (tunnel axis horizontal = the pendulum at mid swing)", fontsize=10)
    # the cycle
    b.axis("off")
    rows = [("pendulum fully LEFT (pickup)", f"tunnel tilted {TILT:g} deg, mouth down: effective ramp slope {RAMP - TILT:+.1f} deg (downhill): "
             "waiting balls roll in, every ball rolls up its ramp and drops over the cliff into the next valley"),
            ("swinging through the middle", "tilt passing 0: balls settle in their valleys against the cliffs"),
            ("pendulum fully RIGHT", f"tilted {TILT:g} deg the other way: balls roll back against the cliff behind them; a {CLIFF:.1f} cliff "
             f"needs 26 deg to roll back over, more than {TILT:g}, so nothing goes back. Pawls hold them seated"),
            ("result", f"one step of {PITCH:g} per full swing = 2 balls into the splitter per swing (2 s), which then split one each "
             "way over the rocking motion. If the valleys are already full, the next waiting ball is just pushed back at the lip")]
    y = 0.95
    for t, d in rows:
        b.text(0.0, y, t, fontsize=10, weight="bold", va="top"); b.text(0.27, y, d, fontsize=9, va="top", wrap=True)
        y -= 0.22
    b.text(0.0, 0.05, "Numbers: ball centre sits 0.70 below the tunnel axis on the two lower wires; the gap between the lower wires is "
           "13.6 wide (room for the jaw plate). A ball can rise only 1.39 before it hits the upper wires, so the steps are 1.0 (a 0.5 step already needs 19 deg).",
           fontsize=8, color="0.3")
    out = Path(__file__).resolve().parent.parent / "views" / "infeed_ratchet.png"
    plt.tight_layout(); plt.savefig(out, dpi=100)
    print(f"{out.name}: pitch {PITCH:g}, ramp {RAMP:.2f}, cliff {CLIFF:.2f}, ball centre {ZC:.2f}")


if __name__ == "__main__":
    main()
