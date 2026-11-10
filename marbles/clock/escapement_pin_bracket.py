#!/usr/bin/env python3
# WIP: renders of the stacked-acrylic pallet bracket; that bracket may be replaced by an L-bracket version (pending Alex).
"""3D close-up of one pallet bracket on its anchor arm (OpenSCAD renders): how the bolts run INSIDE the stack.
Local frame: the arm (2020) along +x, its side face toward the pallet at y = +10, the gap's centre plane at z = 0."""
import math
import subprocess
import sys
from pathlib import Path

from shapely import affinity

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import escapement_pin as E  # noqa: E402

T = 3.0


def poly(g):
    out = []
    for p in getattr(g, "geoms", [g]):
        pts = [[round(x, 3), round(y, 3)] for x, y in p.exterior.coords]
        holes = [[[round(x, 3), round(y, 3)] for x, y in r.coords] for r in p.interiors]
        allp = pts + [q for h in holes for q in h]
        paths = [list(range(len(pts)))]
        k = len(pts)
        for h in holes:
            paths.append(list(range(k, k + len(h))))
            k += len(h)
        out.append(f"polygon(points={allp}, paths={paths});")
    return " ".join(out)


def main():
    E.anchor()
    a_b, r_end, beam, outer, inner, bolts = E.ANCHOR_INFO["entry"]
    loc = lambda g: affinity.rotate(g, -a_b, origin=(0, 0), use_radians=False)   # noqa: E731
    o, i = loc(outer), loc(inner)
    bl = [affinity.rotate(__import__("shapely.geometry", fromlist=["Point"]).Point(b), -a_b, origin=(0, 0)) for b in bolts]
    x0, x1 = r_end - 70, r_end
    L = []
    L.append("$fn=40;")
    # the arm: a 2020 segment with the side slot (6.2 opening, T-channel) on its +y face
    L.append(f"module arm() color(\"silver\") difference() {{ translate([{x0},-10,-10]) cube([{x1 - x0},20,20]);"
             f" translate([{x0 - 1},10-1.8,-3.1]) cube([{x1 - x0 + 2},2,6.2]); translate([{x0 - 1},10-6.2,-5.5]) cube([{x1 - x0 + 2},4.4,11]); }}")
    L.append(f"module outer() color(\"#222\",0.92) linear_extrude({T}) {poly(o)}")
    L.append(f"module inner() color(\"#555\",0.95) linear_extrude({T}) {poly(i)}")
    bolt = []
    for b in bl:
        bolt.append(f"translate([{b.x:.2f},0,0]) {{ color(\"gold\") translate([0,10+{E.PAL_WALL},0]) rotate([-90,0,0]) cylinder(d=8.5,h=5);"
                    f" color(\"gold\") translate([0,4,0]) rotate([-90,0,0]) cylinder(d=5,h=6+{E.PAL_WALL}+0.5);"
                    f" color(\"orange\") translate([-5,4.6,-5]) cube([10,3.5,10]); }}")
    L.append("module bolts() { " + " ".join(bolt) + " }")
    L.append("module stack(top=true) { translate([0,0,-7.5]) outer(); for (k=[0:2]) translate([0,0,-4.5+3*k]) inner(); if (top) translate([0,0,4.5]) outer(); }")
    L.append('view = "assembled";')
    L.append('if (view == "assembled") { arm(); stack(false); bolts(); }')
    L.append('if (view == "exploded") { arm(); bolts(); translate([0,0,-7.5-24]) outer(); for (k=[0:2]) translate([0,0,-4.5+3*k+ (k-1)*12]) inner(); translate([0,0,4.5+24]) outer(); }')
    scad = HERE / "escapement_pin_bracket.scad"
    scad.write_text("\n".join(L) + "\n")
    cx, cy = (x0 + x1) / 2 + 10, 20
    views = HERE.parent / "views"
    for v, cam in (("assembled", f"{cx + 40},{cy - 110},{90},{cx},{cy},0"), ("exploded", f"{cx + 60},{cy - 150},{70},{cx},{cy},0")):
        subprocess.run(["xvfb-run", "-a", "openscad", "-o", str(views / f"esc_pin_bracket_{v}.png"), "-D", f'view="{v}"',
                        f"--camera={cam}", "--imgsize=1400,1000", "--projection=p", "--colorscheme=Tomorrow", str(scad)],
                       check=True, capture_output=True)
    print("rendered", [f"esc_pin_bracket_{v}.png" for v in ("assembled", "exploded")])


if __name__ == "__main__":
    main()
