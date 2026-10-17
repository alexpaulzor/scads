/*

Wire marble run construction kit.

Builds on marbles.scad / marbles2.scad (same marble_od, wire_od, clr,
grip_ratio). Every part is generated from one cross-section: a list of
rails, each [angle, radius] around the marble's center, where angle 0 is
straight down and +angle swings toward +x.

Parts:
* clip      - snap-on cross-tie for mocking up track. Rails press in from
              the marble side. Open styles are a single U "saddle"; enclosed
              styles add a "cap" that pins/zip-ties to the saddle's ears.
              Printable (3D) or laser-cuttable (2D, kerf-compensated).
* jig_comb  - laser-cut plywood comb + slotted base board that holds rails at
              exact positions while you solder permanent ties between combs.
* tie_former- form to bend tie wires so they touch every rail and clear
              the marble.

Rail styles (`style`):
* "open2"    - 2 floor rails, `gauge` apart (center-to-center)
* "rail3"    - open2 + one guard rail on +x side (outside of a curve)
* "channel4" - open2 + guard rails on both sides
* "tube3"    - 3 rails at 120 deg (enclosed)
* "tube4"    - open2 + 2 roof rails (enclosed)
* or pass your own list: style = [[-33, 9.15], [33, 9.15], [180, 10.15]]

Render from the command line, e.g.:
  openscad -o clip.stl     -D 'part="clip_plate"' -D 'style="tube4"' marbles/wire_track.scad
  openscad -o clip.svg     -D 'part="clip_laser"' marbles/wire_track.scad
  openscad -o jig.svg      -D 'part="jig_laser"'  marbles/wire_track.scad
  openscad -o former.stl   -D 'part="tie_former"' marbles/wire_track.scad

*/

base_fn = 64;

marble_od = 16.2;
wire_od = 2.1;
// Total clearance between 2 parts (i.e. half each side if within)
clr = 0.4;
// Ratio of snap neck width to wire_od (same idea as marbles2 grip_ratio)
grip_ratio = 0.85;

part = "design";
style = "open2";
// Center-to-center distance between the two floor rails (marbles2 track_inside_w)
gauge = 10;
// Extra radial room for guard/roof rails so the marble doesn't bind
run_clr = 1.0;
// Rotate the rails relative to the mount tab, for banked curves
bank = 0;
// Enclosed check: largest allowed gap between rails is marble_od - escape_margin
escape_margin = 1.0;

// Clip
clip_th = 5;
wall = 2;
// Radial clearance kept between the snap lips and a resting marble
lip_clr = 0.2;
seat_r = wire_od/2 + 0.1;
neck = wire_od * grip_ratio;
// "screw" (hole for 2020 / board), "post" (vertical socket for a support
// wire, 3D only), or "none"
mount = "screw";
mount_hole_d = 5;
post_d = wire_od;
tab_w = 10;
tab_l = 10;
ear_l = 6;
ear_h = 5;
zip_w = 3;
zip_d = 1;
ear_pin_d = wire_od + clr;

// Laser
// Beam kerf, mm. Unverified starting value: measure a test cut and update.
kerf = 0.1;
sheet_th = 3;

// Solder jig
jig_clr = 0.15;
n_combs = 3;
comb_pitch = 40;
jig_tie_room = 3;
jig_tab_w = 6;

// Tie former
tie_clr = 1.0;
former_h = wire_od * 1.5;
flange_th = 2;
flange_w = wire_od + 3;
former_bolt_d = 5;

marble_r = marble_od/2;
wire_r = wire_od/2;
// Rail center radius where a resting marble touches it
rail_r = marble_r + wire_r;
guard_r = rail_r + run_clr;
floor_a = asin((gauge/2) / rail_r);


function rails(s) =
    s == "open2"    ? [[-floor_a, rail_r], [floor_a, rail_r]] :
    s == "rail3"    ? [[-floor_a, rail_r], [floor_a, rail_r], [90, guard_r]] :
    s == "channel4" ? [[-floor_a, rail_r], [floor_a, rail_r],
                       [-90, guard_r], [90, guard_r]] :
    s == "tube3"    ? [[-60, rail_r], [60, rail_r], [180, guard_r]] :
    s == "tube4"    ? [[-floor_a, rail_r], [floor_a, rail_r],
                       [-135, guard_r], [135, guard_r]] :
    s;

// Normalize to (-180, 180]
function norm_a(a) = let(m = (a % 360 + 360) % 360) m > 180 ? m - 360 : m;
function pt(a, r) = [r * sin(a), -r * cos(a)];
function rail_pt(rl) = pt(rl[0], rl[1]);
function reverse(v) = [for (i=[len(v)-1:-1:0]) v[i]];
function arc_pts(r, a0, a1, n=base_fn) = [for (i=[0:n]) pt(a0 + (a1 - a0) * i / n, r)];
function sort_rails(v) = len(v) <= 1 ? v :
    let(p = v[0], rest = [for (i=[1:len(v)-1]) v[i]])
    concat(
        sort_rails([for (x=rest) if (x[0] < p[0]) x]),
        [p],
        sort_rails([for (x=rest) if (x[0] >= p[0]) x]));
function all_true(v) = len([for (x=v) if (!x) x]) == 0;

all_rails = sort_rails([for (rl=rails(style)) [norm_a(rl[0]), rl[1]]]);
saddle_rails = [for (rl=all_rails) if (abs(rl[0]) <= 90) rl];
cap_rails = [for (rl=all_rails) if (abs(rl[0]) > 90) rl];
has_cap = len(cap_rails) > 0;

// [angular step to next rail, clear gap to next rail] for each rail
function rail_gaps(rs) = [for (i=[0:len(rs)-1])
    let(j = (i + 1) % len(rs),
        da = (rs[j][0] - rs[i][0] + 360) % 360)
    [da == 0 ? 360 : da, norm(rail_pt(rs[j]) - rail_pt(rs[i])) - wire_od]];
gaps = rail_gaps(all_rails);
enclosed = all_true([for (g=gaps) g[0] < 180 && g[1] < marble_od - escape_margin]);

r_out = max([for (rl=all_rails) rl[1]]) + seat_r + wall;
ext = asin((seat_r + wall) / rail_r);
saddle_a0 = has_cap ? -90 : saddle_rails[0][0] - ext;
saddle_a1 = has_cap ? 90 : saddle_rails[len(saddle_rails)-1][0] + ext;
lip_d = sqrt(seat_r * seat_r - neck * neck / 4);

echo(style=style, rails=all_rails, floor_a=floor_a);
echo(gaps=gaps, enclosed=enclosed, has_cap=has_cap);
echo(neck=neck, lip_marble_clearance=(rail_r - lip_d) - marble_r, r_out=r_out);
assert(len(saddle_rails) > 0, "need at least one rail below the marble center");
if (has_cap && !enclosed)
    echo("WARNING: style has roof rails but a marble can escape between rails");


module marble() {
    sphere(r=marble_od/2, $fn=base_fn*2);
}

// ! marble();


module arc_band(r1, r2, a0, a1) {
    polygon(concat(arc_pts(r2, a0, a1), reverse(arc_pts(r1, a0, a1))));
}

module trim_half(half) {
    if (half == 0) {
        children();
    } else {
        intersection() {
            children();
            translate([-100, half < 0 ? -200 : 0])
                square([200, 200]);
        }
    }
}

module seat_boss(rl) {
    intersection() {
        translate(rail_pt(rl))
            circle(r=seat_r + wall, $fn=base_fn/2);
        difference() {
            circle(r=r_out, $fn=base_fn*2);
            circle(r=rl[1] - wire_r + lip_clr, $fn=base_fn*2);
        }
    }
}

module seat_cut(rl, snap=true) {
    w = snap ? neck : 2 * seat_r;
    c = rail_pt(rl);
    t = [cos(rl[0]), sin(rl[0])] * w / 2;
    translate(c)
        circle(r=seat_r, $fn=base_fn/2);
    polygon([c + t, c - t, -t, t]);
}

module ear(s, half) {
    x0 = s > 0 ? r_out - wall/2 : -(r_out + ear_l);
    difference() {
        translate([x0, half < 0 ? -ear_h : 0])
            square([ear_l + wall/2, ear_h]);
        // zip tie / wire lashing notch on the outer face
        translate([s * (r_out + ear_l/2), half * ear_h])
            square([zip_w, 2 * zip_d], center=true);
    }
}

module mount_tab() {
    difference() {
        translate([-tab_w/2, -(r_out + tab_l)])
            square([tab_w, r_out + tab_l - (marble_r + run_clr + 0.5)]);
        if (mount == "screw")
            translate([0, -(r_out + tab_l/2)])
                circle(d=mount_hole_d, $fn=base_fn/2);
    }
}

// half: 0 = whole saddle (no cap), -1 = saddle below a cap, +1 = cap
module clip_profile(rs, a0, a1, half=0, snap=true, tab=true) {
    difference() {
        union() {
            rotate([0, 0, bank]) trim_half(half) union() {
                arc_band(marble_r + run_clr, r_out, a0, a1);
                for (rl=rs)
                    seat_boss(rl);
                if (half != 0)
                    for (s=[-1, 1])
                        ear(s, half);
            }
            if (tab && mount != "none")
                mount_tab();
        }
        rotate([0, 0, bank])
            for (rl=rs)
                seat_cut(rl, snap);
    }
}

module saddle_2d(snap=true) {
    clip_profile(saddle_rails, saddle_a0, saddle_a1,
        half=has_cap ? -1 : 0, snap=snap);
}

// ! saddle_2d();

module cap_2d(snap=true) {
    if (has_cap)
        clip_profile(cap_rails, 90, 270, half=1, snap=snap, tab=false);
}

// ! cap_2d();

module ear_pin_holes(half) {
    rotate([0, 0, bank])
        for (s=[-1, 1])
            translate([s * (r_out + ear_l/2), 0, clip_th/2])
                rotate([90, 0, 0])
                cylinder(d=ear_pin_d, h=4 * ear_h, center=true, $fn=base_fn/2);
}

module saddle() {
    difference() {
        linear_extrude(clip_th)
            saddle_2d();
        if (has_cap)
            ear_pin_holes();
        if (mount == "post")
            translate([0, -(r_out + tab_l) - 1, clip_th/2])
                rotate([-90, 0, 0])
                cylinder(d=post_d + clr, h=tab_l, $fn=base_fn/2);
    }
}

// ! saddle();

module cap() {
    if (has_cap)
        difference() {
            linear_extrude(clip_th)
                cap_2d();
            ear_pin_holes();
        }
}

// ! cap();

module clip_plate() {
    saddle();
    translate([0, 2 * r_out + tab_l + 2, 0])
        cap();
}

// ! clip_plate();

module clip_laser() {
    offset(delta=kerf/2) {
        saddle_2d();
        translate([0, 2 * r_out + tab_l + 2])
            cap_2d();
    }
}

// ! clip_laser();


// Bending form: the tie hugs the outside of every rail and stays tie_clr
// away from the marble.
module tie_former_2d() {
    hull() {
        circle(r=marble_r + tie_clr, $fn=base_fn*2);
        for (rl=all_rails)
            translate(rail_pt(rl))
                circle(r=wire_r, $fn=base_fn/2);
    }
}

former_x = max(concat([marble_r + tie_clr], [for (rl=all_rails) abs(rail_pt(rl)[0]) + wire_r]));
former_r_max = max(concat([marble_r + tie_clr], [for (rl=all_rails) rl[1] + wire_r]));

module former_holes_2d() {
    circle(d=former_bolt_d, $fn=base_fn/2);
    // anchor holes to hook the end of the tie wire
    for (s=[-1, 1])
        translate([s * (former_x + wire_r + clr/2), 0])
            circle(d=wire_od + clr, $fn=base_fn/2);
}

module tie_former() {
    difference() {
        union() {
            linear_extrude(flange_th)
                offset(r=flange_w)
                tie_former_2d();
            linear_extrude(flange_th + former_h)
                tie_former_2d();
        }
        translate([0, 0, -1])
            linear_extrude(flange_th + former_h + 2)
            former_holes_2d();
    }
}

// ! tie_former();

// Two laser layers: glue the former onto the flange.
module tie_former_laser() {
    offset(delta=kerf/2) {
        difference() {
            offset(r=flange_w)
                tie_former_2d();
            former_holes_2d();
        }
        translate([2 * (former_x + flange_w) + 4, 0])
            difference() {
                tie_former_2d();
                former_holes_2d();
            }
    }
}

// ! tie_former_laser();


// Solder jig: combs stand in a base board; rails thread through (or drop
// into, for open styles) the combs; solder ties in the gaps between combs.
comb_hole_r = seat_r + jig_clr;
comb_x = max([for (rl=all_rails) abs(rail_pt(rl)[0])]) + seat_r + wall + 2;
comb_top = max([for (rl=all_rails) rail_pt(rl)[1]]) + seat_r + wall;
// Base board surface, leaving room under the track for the ties
comb_bot = -(former_r_max + wire_od + jig_tie_room);
comb_tab_x = comb_x - jig_tab_w/2 - 2;

module jig_comb_2d() {
    difference() {
        union() {
            translate([-comb_x, comb_bot])
                square([2 * comb_x, comb_top - comb_bot]);
            for (s=[-1, 1])
                translate([s * comb_tab_x - jig_tab_w/2, comb_bot - sheet_th])
                    square([jig_tab_w, sheet_th + 1]);
        }
        for (rl=all_rails) {
            c = rail_pt(rl);
            translate(c)
                circle(r=comb_hole_r, $fn=base_fn/2);
            // open styles: drop rails in from above
            if (!has_cap)
                translate([c[0] - comb_hole_r, c[1]])
                    square([2 * comb_hole_r, comb_top - c[1] + 1]);
        }
    }
}

// ! jig_comb_2d();

jig_base_l = (n_combs - 1) * comb_pitch + 20;
jig_base_w = 2 * comb_x + 10;

module jig_base_2d() {
    difference() {
        translate([-jig_base_w/2, -10])
            square([jig_base_w, jig_base_l]);
        for (i=[0:n_combs-1], s=[-1, 1])
            translate([s * comb_tab_x, i * comb_pitch])
                square([jig_tab_w, sheet_th], center=true);
    }
}

// ! jig_base_2d();

module jig_laser() {
    offset(delta=kerf/2) {
        jig_base_2d();
        for (i=[0:n_combs-1])
            translate([jig_base_w/2 + comb_x + 4 + i * (2 * comb_x + 4), -comb_bot + sheet_th])
                jig_comb_2d();
    }
}

// ! jig_laser();


module design() {
    track_l = 100;
    // track along +y, gravity along -z
    rotate([90, 0, 0]) {
        for (z=[-35, 0, 35])
            translate([0, 0, z - clip_th/2]) {
                color("orange") saddle();
                color("gold") cap();
            }
        color("silver")
            rotate([0, 0, bank])
            for (rl=all_rails)
                translate(rail_pt(rl))
                    cylinder(r=wire_r, h=track_l, center=true, $fn=base_fn/2);
        % rotate([0, 0, bank])
            marble();
    }
}

if (part == "design") design();
else if (part == "saddle") saddle();
else if (part == "cap") cap();
else if (part == "clip_plate") clip_plate();
else if (part == "clip_laser") clip_laser();
else if (part == "jig_laser") jig_laser();
else if (part == "jig_comb") jig_comb_2d();
else if (part == "jig_base") jig_base_2d();
else if (part == "tie_former") tie_former();
else if (part == "tie_former_laser") tie_former_laser();
