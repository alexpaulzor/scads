#!/usr/bin/env python3
"""Feasibility numbers for a motor-cocked spring launcher lifting a steel ball.

Model: a snail cam on a gear motor pulls a spring-loaded plunger back by
`stroke`, then drops it. The plunger and ball accelerate together and the ball
leaves when the plunger hits its stop, rolls along the lane, turns up through
a curve into a vertical tube, and has to arrive at the top with ~0 speed.

Energy the ball needs at launch, per unit of rise:
  optimistic   m*g*h                       (all spin energy recovered)
  conservative m*g*h * (1 + (2/5)/cos^2(c)) (spin from rolling on two rails
               at contact angle c from vertical is lost in the tube)
then times `--loss` for friction/impacts in the curve and tube (a guess;
measure it with a prototype), and divided by the plunger's share of the
spring energy m/(m+M).

Usage: python3 marbles/launcher_calc.py [--ball-d 15.875] [--stroke 25] ...
"""

import argparse
import math

G = 9.81


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--ball-d", type=float, default=15.875, help="mm; 5/8in steel ball")
    p.add_argument("--density", type=float, default=7.85, help="g/cm^3; steel")
    p.add_argument("--wire-d", type=float, default=2.1)
    p.add_argument("--gauge", type=float, default=10, help="rail center spacing, mm")
    p.add_argument("--plunger-g", type=float, default=6,
                   help="moving plunger mass incl. 1/3 of the spring, g (estimate)")
    p.add_argument("--loss", type=float, default=1.5,
                   help="energy multiplier for curve/tube losses (unverified guess)")
    p.add_argument("--stroke", type=float, default=25, help="plunger pull-back, mm")
    p.add_argument("--cam-r0", type=float, default=8, help="snail cam base radius, mm")
    p.add_argument("--curve-r", type=float, default=60, help="lane-to-tube curve radius, mm")
    p.add_argument("--heights", type=float, nargs="+", default=[0.30, 0.45, 0.60, 0.75],
                   help="rise above the launch lane, m")
    a = p.parse_args()

    r = a.ball_d / 2
    m = a.density * 4 / 3 * math.pi * (r / 10) ** 3 / 1000  # kg
    c = math.asin(a.gauge / 2 / (r + a.wire_d / 2))
    spin = (2 / 5) / math.cos(c) ** 2
    eff = m / (m + a.plunger_g / 1000)
    x = a.stroke / 1000
    cam_r1 = (a.cam_r0 + a.stroke) / 1000

    print(f"ball {a.ball_d} mm, mass {m * 1000:.2f} g; rail contact angle {math.degrees(c):.2f} deg")
    print(f"spin energy on rails = {spin:.3f} x translational; plunger transfer = {eff:.3f}")
    print(f"assumed losses x{a.loss}, stroke {a.stroke} mm, cam {a.cam_r0}->{a.cam_r0 + a.stroke:.0f} mm\n")
    print("rise_m  E_ball_mJ(opt..cons)  E_spring_mJ  k_N/mm  F_peak_N  cam_torque_kgcm  "
          "v_launch_m/s  curve_g")
    for h in a.heights:
        e_opt = m * G * h * a.loss
        e_con = e_opt * (1 + spin)
        e_spring = e_con / eff
        k = 2 * e_spring / x ** 2
        f = k * x
        torque = f * cam_r1 / G * 100  # kg*cm
        v = math.sqrt(2 * e_con / (m * (1 + spin)))
        print(f"{h:5.2f}   {e_opt * 1000:7.1f}..{e_con * 1000:<7.1f}      "
              f"{e_spring * 1000:7.1f}    {k / 1000:6.3f}  {f:7.2f}   {torque:10.2f}       "
              f"{v:6.2f}       {v * v / (G * a.curve_r / 1000):5.1f}")


if __name__ == "__main__":
    main()
