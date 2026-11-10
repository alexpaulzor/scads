#!/usr/bin/env python3
"""3D close-up of one T pallet clamped in its anchor arm's side T-slot (OpenSCAD renders, assembled + exploded).
Local frame: the arm (2020) along +x, its side face toward the pallet at y = +10, the wheel's plane = xy, the gap's
centre plane z = 0. The T (3 mm acrylic) lies on z = 0: its bar drops into the slot onto the floor (y = 4), its stem
comes out through the clamp's 3.1 slot. The clamp (ply3) lies on the face; an M5 + T-nut at each end."""
import subprocess
import sys
from pathlib import Path

from shapely import affinity

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import escapement_pin as E  # noqa: E402


def poly(g):
    out = []
    for p in getattr(g, "geoms", [g]):
        pts = [[round(x, 3), round(y, 3)] for x, y in p.exterior.coords]
        holes = [[[round(x, 3), round(y, 3)] for x, y in r.coords] for r in p.interiors]
        allp = pts + [q for h in holes for q in h]
        paths, k = [list(range(len(pts)))], len(pts)
        for h in holes:
            paths.append(list(range(k, k + len(h))))
            k += len(h)
        out.append(f"polygon(points={allp}, paths={paths});")
    return " ".join(out)


def main():
    E.anchor()
    info = E.ANCHOR_INFO["entry"]
    a_b, u_c = info["a"], info["u_c"]
    t = affinity.rotate(info["t"], -a_b, origin=(0, 0))
    pins = [affinity.rotate(E.pins(0.0), -a_b, origin=(0, 0))]
    x0, x1 = u_c - 45, info["r_b"]
    floor = 10 - E.SLOT_D
    m5x = [u_c - (E.BAR_L / 2 + E.CLAMP_END - 2), u_c + (E.BAR_L / 2 + E.CLAMP_END - 2)]
    L = ["$fn=36;", 'view = "assembled";',
         'ex = view == "exploded" ? 1 : 0;',
         # the arm: 2020 segment, side slot on +y: 6 opening through the lips, wider cavity behind, floor at y = 4
         f"module arm() color(\"silver\") difference() {{ translate([{x0},-10,-10]) cube([{x1 - x0},20,20]);"
         f" translate([{x0 - 1},8.2,-3]) cube([{x1 - x0 + 2},2,6]); translate([{x0 - 1},{floor},-5.5]) cube([{x1 - x0 + 2},{8.2 - floor},11]); }}",
         f"module tpart() {{ color(\"#1a1a1a\") translate([0,0,-3]) linear_extrude(2.95) {poly(t)} color(\"#333\") translate([0,0,0.05]) linear_extrude(2.95) {poly(t)} }}",
         f"module clamp() color(\"burlywood\") translate([{u_c},{floor + E.BAR_H},0]) rotate([-90,0,0]) linear_extrude({E.CLAMP_T}) {poly(E.clamp_part())}",
         "module screws() for (x = [" + ",".join(f"{v:.2f}" for v in m5x) + "]) translate([x,0,0]) {"
         f" color(\"gold\") translate([0,{floor + 1},0]) rotate([-90,0,0]) cylinder(d=5,h={E.BAR_H + E.CLAMP_T + 4});"
         f" color(\"gold\") translate([0,{floor + E.BAR_H + E.CLAMP_T},0]) rotate([-90,0,0]) cylinder(d=8.5,h=5); }}",
         f"module tnuts() for (x = [" + ",".join(f"{v:.2f}" for v in m5x) + f"]) color(\"orange\") translate([x-5,{floor + 0.3},-5]) cube([10,3.5,10]);",
         "arm(); tnuts();",
         "translate([0, 12*ex, 0]) tpart();",
         "translate([0, 26*ex, 0]) clamp();",
         "translate([0, 40*ex, 0]) screws();"]
    scad = HERE / "escapement_pin_bracket.scad"
    scad.write_text("\n".join(L) + "\n")
    views = HERE.parent / "views"
    cx = u_c
    for v, cam in (("assembled", f"{cx - 55},{95},{70},{cx},{8},0"), ("exploded", f"{cx - 75},{130},{90},{cx},{20},0")):
        subprocess.run(["xvfb-run", "-a", "openscad", "-o", str(views / f"esc_pin_tpallet_{v}.png"), "-D", f'view="{v}"',
                        f"--camera={cam}", "--imgsize=1400,1000", "--projection=p", "--colorscheme=Tomorrow", str(scad)],
                       check=True, capture_output=True)
    print("rendered esc_pin_tpallet_assembled.png, esc_pin_tpallet_exploded.png")


if __name__ == "__main__":
    main()
