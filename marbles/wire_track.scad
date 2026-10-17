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
* (solder jig moved to wire_jig.scad: two-piece wooden stations, no snap)
* tie_former- form to bend tie wires so they touch every rail and clear
              the marble.

Rail styles (`style`):
* "open2"    - 2 floor rails, `gauge` apart (center-to-center)
* "rail3"    - open2 + one guard rail on +x side (outside of a curve)
* "channel4" - open2 + guard rails on both sides
* "tube3"    - 3 rails at 120 deg (enclosed)
* "tube4"    - open2 + 2 roof rails (enclosed)
* or pass your own list: style = [[-33, 9.15], [33, 9.15], [180, 10.15]]

Clip mounts (`mount`, tab points at `tab_a`, 0 = straight down):
* "screw"     - hole through the tab (2020 / board screw, or thread the clip
                onto a post that runs perpendicular to the clip)
* "post"      - blind socket along the tab for a support wire (3D only)
* "side_post" - through-hole across the tab, in the clip's plane, plus an
                M3 set screw; slide clips up/down a post (3D only)
* "none"

Render from the command line, e.g.:
  openscad -o clip.stl     -D 'part="clip_plate"' -D 'style="tube4"' marbles/wire_track.scad
  openscad -o clip.svg     -D 'part="clip_laser"' marbles/wire_track.scad
  openscad -o former.stl   -D 'part="tie_former"' marbles/wire_track.scad

Other files can `use <wire_track.scad>` and call saddle(style=...),
cap(style=...), track_rails(style) etc. per instance.

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
mount = "screw";
tab_a = 0;
mount_hole_d = 5;
post_d = wire_od;
set_screw_d = 2.5;
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

// Solder jig (wire_jig.scad)
jig_clr = 0.15;
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

// Sorted, normalized rails for a style
function track_rails(s) = sort_rails([for (rl=rails(s)) [norm_a(rl[0]), rl[1]]]);
function saddle_rails_of(rs) = [for (rl=rs) if (abs(rl[0]) <= 90) rl];
function cap_rails_of(rs) = [for (rl=rs) if (abs(rl[0]) > 90) rl];
function has_cap_of(rs) = len(cap_rails_of(rs)) > 0;
function r_out_of(rs) = max([for (rl=rs) rl[1]]) + seat_r + wall;
// Rail center offsets [x, y] from the marble center, rotated by bank
function rail_offsets(s, bank=0) = [for (rl=track_rails(s)) rail_pt([rl[0] + bank, rl[1]])];

// [angular step to next rail, clear gap to next rail] for each rail
function rail_gaps(rs) = [for (i=[0:len(rs)-1])
    let(j = (i + 1) % len(rs),
        da = (rs[j][0] - rs[i][0] + 360) % 360)
    [da == 0 ? 360 : da, norm(rail_pt(rs[j]) - rail_pt(rs[i])) - wire_od]];
function is_enclosed(rs) = all_true([for (g=rail_gaps(rs))
    g[0] < 180 && g[1] < marble_od - escape_margin]);

ext = asin((seat_r + wall) / rail_r);
// [a0, a1] arc the saddle covers; widened so a mount tab at tab_rel attaches
function saddle_span(rs, tab_rel, use_tab) =
    let(sr = saddle_rails_of(rs),
        a0 = has_cap_of(rs) ? -90 : sr[0][0] - ext,
        a1 = has_cap_of(rs) ? 90 : sr[len(sr)-1][0] + ext,
        te = asin(min(1, (tab_w/2) / r_out_of(rs))))
    use_tab && !has_cap_of(rs)
        ? [min(a0, tab_rel - te), max(a1, tab_rel + te)]
        : [a0, a1];

lip_d = sqrt(seat_r * seat_r - neck * neck / 4);

all_rails = track_rails(style);
gaps = rail_gaps(all_rails);
echo(style=style, rails=all_rails, floor_a=floor_a);
echo(gaps=gaps, enclosed=is_enclosed(all_rails), has_cap=has_cap_of(all_rails));
echo(neck=neck, lip_marble_clearance=(rail_r - lip_d) - marble_r, r_out=r_out_of(all_rails));
assert(len(saddle_rails_of(all_rails)) > 0, "need at least one rail below the marble center");
if (has_cap_of(all_rails) && !is_enclosed(all_rails))
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

module seat_boss(rl, ro) {
    intersection() {
        translate(rail_pt(rl))
            circle(r=seat_r + wall, $fn=base_fn/2);
        difference() {
            circle(r=ro, $fn=base_fn*2);
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

module ear(s, half, ro) {
    x0 = s > 0 ? ro - wall/2 : -(ro + ear_l);
    difference() {
        translate([x0, half < 0 ? -ear_h : 0])
            square([ear_l + wall/2, ear_h]);
        // zip tie / wire lashing notch on the outer face
        translate([s * (ro + ear_l/2), half * ear_h])
            square([zip_w, 2 * zip_d], center=true);
    }
}

module mount_tab(ro, mount, tab_a, hole_d) {
    rotate([0, 0, tab_a])
        difference() {
            translate([-tab_w/2, -(ro + tab_l)])
                square([tab_w, tab_l + wall]);
            if (mount == "screw")
                translate([0, -(ro + tab_l/2)])
                    circle(d=hole_d, $fn=base_fn/2);
        }
}

// half: 0 = whole saddle (no cap), -1 = saddle below a cap, +1 = cap
module clip_profile(rs, a0, a1, ro, half=0, snap=true, bank=0,
        mount="none", tab_a=0, hole_d=mount_hole_d) {
    difference() {
        union() {
            rotate([0, 0, bank]) trim_half(half) union() {
                arc_band(marble_r + run_clr, ro, a0, a1);
                for (rl=rs)
                    seat_boss(rl, ro);
                if (half != 0)
                    for (s=[-1, 1])
                        ear(s, half, ro);
            }
            if (mount != "none")
                mount_tab(ro, mount, tab_a, hole_d);
        }
        rotate([0, 0, bank])
            for (rl=rs)
                seat_cut(rl, snap);
    }
}

module saddle_2d(style=style, bank=bank, mount=mount, tab_a=tab_a,
        hole_d=mount_hole_d, snap=true) {
    rs = track_rails(style);
    span = saddle_span(rs, tab_a - bank, mount != "none");
    clip_profile(saddle_rails_of(rs), span[0], span[1], r_out_of(rs),
        half=has_cap_of(rs) ? -1 : 0, snap=snap, bank=bank,
        mount=mount, tab_a=tab_a, hole_d=hole_d);
}

// ! saddle_2d();

module cap_2d(style=style, bank=bank, snap=true) {
    rs = track_rails(style);
    if (has_cap_of(rs))
        clip_profile(cap_rails_of(rs), 90, 270, r_out_of(rs),
            half=1, snap=snap, bank=bank);
}

// ! cap_2d();

module ear_pin_holes(ro, bank) {
    rotate([0, 0, bank])
        for (s=[-1, 1])
            translate([s * (ro + ear_l/2), 0, clip_th/2])
                rotate([90, 0, 0])
                cylinder(d=ear_pin_d, h=4 * ear_h, center=true, $fn=base_fn/2);
}

module saddle(style=style, bank=bank, mount=mount, tab_a=tab_a,
        hole_d=mount_hole_d, post_d=post_d) {
    rs = track_rails(style);
    ro = r_out_of(rs);
    boss_r = post_d/2 + wall;
    post_c = ro + tab_l - boss_r;
    difference() {
        union() {
            linear_extrude(clip_th)
                saddle_2d(style, bank, mount, tab_a, hole_d);
            if (mount == "side_post")
                rotate([0, 0, tab_a])
                    translate([0, -post_c, boss_r])
                    rotate([0, 90, 0])
                    cylinder(r=boss_r, h=tab_w, center=true, $fn=base_fn/2);
        }
        if (has_cap_of(rs))
            ear_pin_holes(ro, bank);
        rotate([0, 0, tab_a]) {
            if (mount == "post")
                translate([0, -(ro + tab_l) - 1, clip_th/2])
                    rotate([-90, 0, 0])
                    cylinder(d=post_d + clr, h=tab_l, $fn=base_fn/2);
            if (mount == "side_post") {
                translate([0, -post_c, boss_r])
                    rotate([0, 90, 0])
                    cylinder(d=post_d + clr, h=tab_w + 2, center=true, $fn=base_fn/2);
                // M3 set screw, threads itself into the plastic
                translate([0, -(ro + tab_l) - 1, boss_r])
                    rotate([-90, 0, 0])
                    cylinder(d=set_screw_d, h=boss_r + 1, $fn=base_fn/4);
            }
        }
    }
}

// ! saddle();

module cap(style=style, bank=bank) {
    rs = track_rails(style);
    if (has_cap_of(rs))
        difference() {
            linear_extrude(clip_th)
                cap_2d(style, bank);
            ear_pin_holes(r_out_of(rs), bank);
        }
}

// ! cap();

// Saddle (+ cap if any) as they sit on the track, centered on the marble,
// clip plane centered on z=0.
module clip(style=style, bank=bank, mount=mount, tab_a=tab_a,
        hole_d=mount_hole_d, post_d=post_d) {
    translate([0, 0, -clip_th/2]) {
        saddle(style, bank, mount, tab_a, hole_d, post_d);
        cap(style, bank);
    }
}

module clip_plate(style=style) {
    ro = r_out_of(track_rails(style));
    saddle(style);
    translate([0, 2 * ro + tab_l + 2, 0])
        cap(style);
}

// ! clip_plate();

module clip_laser(style=style) {
    ro = r_out_of(track_rails(style));
    offset(delta=kerf/2) {
        saddle_2d(style);
        translate([0, 2 * ro + tab_l + 2])
            cap_2d(style);
    }
}

// ! clip_laser();


// Bending form: the tie hugs the outside of every rail and stays tie_clr
// away from the marble.
module tie_former_2d(style=style) {
    hull() {
        circle(r=marble_r + tie_clr, $fn=base_fn*2);
        for (rl=track_rails(style))
            translate(rail_pt(rl))
                circle(r=wire_r, $fn=base_fn/2);
    }
}

function former_x(rs) = max(concat([marble_r + tie_clr],
    [for (rl=rs) abs(rail_pt(rl)[0]) + wire_r]));
function former_r_max(rs) = max(concat([marble_r + tie_clr],
    [for (rl=rs) rl[1] + wire_r]));

module former_holes_2d(style=style) {
    fx = former_x(track_rails(style));
    circle(d=former_bolt_d, $fn=base_fn/2);
    // anchor holes to hook the end of the tie wire
    for (s=[-1, 1])
        translate([s * (fx + wire_r + clr/2), 0])
            circle(d=wire_od + clr, $fn=base_fn/2);
}

module tie_former(style=style) {
    difference() {
        union() {
            linear_extrude(flange_th)
                offset(r=flange_w)
                tie_former_2d(style);
            linear_extrude(flange_th + former_h)
                tie_former_2d(style);
        }
        translate([0, 0, -1])
            linear_extrude(flange_th + former_h + 2)
            former_holes_2d(style);
    }
}

// ! tie_former();

// Two laser layers: glue the former onto the flange.
module tie_former_laser(style=style) {
    fx = former_x(track_rails(style));
    offset(delta=kerf/2) {
        difference() {
            offset(r=flange_w)
                tie_former_2d(style);
            former_holes_2d(style);
        }
        translate([2 * (fx + flange_w) + 4, 0])
            difference() {
                tie_former_2d(style);
                former_holes_2d(style);
            }
    }
}

// ! tie_former_laser();


module design(style=style) {
    track_l = 100;
    // track along +y, gravity along -z
    rotate([90, 0, 0]) {
        for (z=[-35, 0, 35])
            translate([0, 0, z]) {
                color("orange") clip(style);
            }
        color("silver")
            for (c=rail_offsets(style, bank))
                translate(c)
                    cylinder(r=wire_r, h=track_l, center=true, $fn=base_fn/2);
        % marble();
    }
}

if (part == "design") design();
else if (part == "saddle") saddle();
else if (part == "cap") cap();
else if (part == "clip_plate") clip_plate();
else if (part == "clip_laser") clip_laser();
else if (part == "tie_former") tie_former();
else if (part == "tie_former_laser") tie_former_laser();
