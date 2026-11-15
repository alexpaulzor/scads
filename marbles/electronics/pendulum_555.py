#!/usr/bin/env python3
"""Schematic: 555 pulse timer for the pendulum's door-lock actuator, through a DC SSR.
~2 s period (one push per full swing), duty set by P1 (about 11 % .. 49 %), period trimmed by RT (1.84 .. 2.22 s).

    python3 marbles/electronics/pendulum_555.py      # -> marbles/electronics/pendulum_555.png / .svg
"""
from pathlib import Path
import schemdraw
import schemdraw.elements as elm

HERE = Path(__file__).resolve().parent
schemdraw.config(fontsize=12)
RAIL = 9.0          # +12 V rail height
GNDY = -8.0         # ground line height

with schemdraw.Drawing(show=False) as d:
    ic = elm.Ic555().at((0, 0)).label("U1 NE555", loc="center", ofst=(0, -0.5))
    d += ic
    P = lambda name: ic.anchors[name]                                                   # noqa: E731
    # +12 V rail
    d += elm.Line().at((-13.5, RAIL)).to((15, RAIL))
    d += elm.Vdd().at((6.5, RAIL)).label("+12 V")
    # pin 8 and pin 4 to the rail
    d += elm.Line().at(P("Vcc")).toy(RAIL); d += elm.Dot()
    d += elm.Line().at(P("RST")).toy(RAIL); d += elm.Dot()
    # pin 7: R1 up to the rail, and the pot's wiper
    n7 = (-3.0, P("DIS")[1])
    d += elm.Line().at(P("DIS")).to(n7); d += elm.Dot()
    d += elm.Resistor().at(n7).up().toy(RAIL).label("R1 4.7k", loc="bottom"); d += elm.Dot()
    d += elm.Line().at(n7).left(2.0)
    pot = elm.Potentiometer().down().anchor("tap").label("P1 50k\n(duty)", loc="top", ofst=0.3)
    d += pot
    # end A (top): R2, D1 down to the timing node
    xa, xb, xn = -8.0, -5.6, -2.2
    ty = -4.2                                                                            # timing node height
    d += elm.Line().at(pot.start).up(0.4)
    d += elm.Line().tox(xa)
    d += elm.Resistor().down(2.8).label("R2 10k", loc="top")
    d += elm.Diode().down().toy(ty).label("D1 1N4148", loc="top")
    d += elm.Line().tox(xb)
    # end B (bottom): R3, RT, D2 (pointing up: current flows from the capacitor back to pin 7)
    d += elm.Line().at(pot.end).toy(pot.end[1] - 0.2)
    d += elm.Resistor().down(2.0).label("R3 56k", loc="bottom")
    d += elm.Line().at((xb, ty + 0.0)).right(0.01)
    rt_top = d.here
    # place RT and D2 between pot end B and the timing node
    d.here = (pot.end[0], pot.end[1] - 2.2)
    d += elm.ResistorVar().down(1.9).label("RT 25k\n(period)", loc="bottom")
    d += elm.Diode().down().toy(ty).reverse().label("D2 1N4148", loc="bottom")
    d += elm.Dot()
    tnode = d.here
    d += elm.Line().at((xa, ty)).tox(tnode[0])
    # timing node to pins 2 and 6, C1 to ground
    d += elm.Line().at(tnode).tox(xn); d += elm.Dot()
    d += elm.Line().toy(P("THR")[1])
    d += elm.Line().tox(P("THR")[0])
    d += elm.Line().at((xn, P("TRG")[1])).tox(P("TRG")[0])
    d += elm.Dot().at((xn, P("TRG")[1]))
    d += elm.Capacitor(polar=True).at((xn, ty)).down().toy(GNDY).label("C1 22µF", loc="bottom")
    # ground line
    d += elm.Line().at((-13.5, GNDY)).to((13, GNDY))
    d += elm.Ground().at((1.75, GNDY))
    d += elm.Line().at(P("GND")).toy(GNDY); d += elm.Dot()
    # pin 5: 10 nF to ground
    d += elm.Line().at(P("CTL")).right(1.0)
    d += elm.Capacitor().down().toy(GNDY).label("C2 10nF", loc="bottom"); d += elm.Dot()
    # pin 3: indicator LED and the SSR input
    ox = 7.5
    d += elm.Line().at(P("OUT")).tox(ox); d += elm.Dot()
    d += elm.Resistor().down(3.0).label("R4 1k", loc="bottom")
    d += elm.LED().down().toy(GNDY).label("LED", loc="bottom"); d += elm.Dot()
    d += elm.Line().at((ox, P("OUT")[1])).tox(9.0)
    # SSR box: input LED inside on the left, output switch on the right
    bx0, bx1, by0, by1 = 9.0, 13.0, -1.6, 4.6
    d.here = (0, 0)
    d += elm.Rect(corner1=(bx0, by0), corner2=(bx1, by1))
    d += elm.Label().at(((bx0 + bx1) / 2, by1 + 0.4)).label("DC solid-state relay")
    d += elm.Line().at((bx0, P("OUT")[1])).right(0.8)
    d += elm.LED().down(2.8).label("IN", loc="bottom")
    d += elm.Line().tox(bx0)
    d += elm.Line().tox(bx0 - 0.6)
    d += elm.Line().toy(GNDY); d += elm.Dot()
    d += elm.Label().at((bx0 - 0.3, P("OUT")[1] + 0.4)).label("+")
    d += elm.Label().at((bx0 - 0.3, P("OUT")[1] - 3.2)).label("−")
    # output side: a switch from OUT+ to OUT-
    d += elm.Switch().at((bx1 - 0.8, P("OUT")[1])).down(2.8).label("OUT", loc="bottom")
    d += elm.Line().at((bx1 - 0.8, P("OUT")[1])).tox(bx1)
    d += elm.Line().at((bx1 - 0.8, P("OUT")[1] - 2.8)).tox(bx1)
    # load: +12 V -> actuator -> SSR OUT ... SSR OUT -> ground, TVS across the SSR output
    lx = 15.0
    d += elm.Line().at((bx1, P("OUT")[1])).tox(lx); d += elm.Dot()
    d += elm.Motor().up().toy(RAIL + 0.01).label("door-lock actuator", loc="bottom")
    d += elm.Line().at((bx1, P("OUT")[1] - 2.8)).tox(lx + 1.2)
    d += elm.Line().at((lx + 1.2, P("OUT")[1] - 2.8)).toy(GNDY)
    d += elm.Line().tox(13)
    d += elm.Line().at((lx, P("OUT")[1])).tox(lx + 1.2)
    d += elm.Zener().at((lx + 1.2, P("OUT")[1])).down(2.8).label("TVS\nSMBJ15A", loc="bottom")
    d += elm.Dot().at((lx + 1.2, P("OUT")[1])); d += elm.Dot().at((lx + 1.2, P("OUT")[1] - 2.8))
    # decoupling at the chip
    for x, part, lab in ((-10.5, elm.Capacitor(polar=True), "C3\n100µF"), (-13.5, elm.Capacitor(), "C4\n100nF")):
        d += elm.Dot().at((x, RAIL))
        d += part.at((x, RAIL)).down().toy(GNDY).label(lab, loc="bottom")
        d += elm.Dot()
    d.save(str(HERE / "pendulum_555.png"), dpi=140)
    d.save(str(HERE / "pendulum_555.svg"))
print("wrote pendulum_555.png / .svg")
