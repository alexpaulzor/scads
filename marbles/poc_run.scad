/*

Proof-of-concept wire marble run on a 300 mm square board.

The track path comes from poc_layout.py (writes poc_path.scad); the lift is
spiral_lift.scad; every clip is a wire_track.scad saddle.

  python3 marbles/poc_layout.py        # regenerate the path after changes
  openscad -o run.png  marbles/poc_run.scad
  openscad -o board_cut.svg  -D 'poc_part="board_cut"'  marbles/poc_run.scad
  openscad -o board_etch.svg -D 'poc_part="board_etch"' marbles/poc_run.scad

The board_etch layer is the track's plan view at 1:1: engrave it (or print
it on paper) and use it as a bending template for the laps.

*/

include <spiral_lift.scad>
include <poc_path.scad>
lift_part = "none";

poc_part = "assembly";

feet_xy = [[12, 12], [poc_board - 12, 12], [12, poc_board - 12],
    [poc_board - 12, poc_board - 12]];

assert(lift_c == poc_lift_c, "poc_path.scad lift center differs from spiral_lift.scad");
assert(abs(poc_exit_x0 - (lift_c[0] + channel_r)) < 0.01,
    "poc_layout.py lift constants differ from spiral_lift.scad (exit)");
assert(abs(poc_entry_x - (lift_c[0] + lift_m)) < 0.01,
    "poc_layout.py lift constants differ from spiral_lift.scad (entry)");
assert(poc_z_exit == z_exit && poc_z_entry == z_entry,
    "poc_layout.py z_exit/z_entry differ from spiral_lift.scad");

function count(v, x) = len([for (c=v) if (c == x) c]);
clip_mounts = [for (c=poc_clips) c[6]];
echo(poc_laps=poc_laps, poc_slope=poc_slope, track_points=len(poc_pts));
echo(clips_side_post=count(clip_mounts, "side_post"), clips_free=count(clip_mounts, "none"),
    clips_stub_post=count(clip_mounts, "post"),
    channel_clips=len([for (z=[z_entry + marble_od + 5 : channel_clip_pitch : z_rails_top - 5]) z]));
if (poc_board > 300)
    echo("WARNING: board is larger than the laser's 300 mm Y travel");


function rail_world(i, o) = poc_pts[i] + concat(poc_right[i] * o[0], o[1]);

module track_rails_3d() {
    for (i=[0:len(poc_seg_style)-1], o=rail_offsets(poc_seg_style[i]))
        hull() {
            translate(rail_world(i, o)) sphere(r=wire_r, $fn=8);
            translate(rail_world(i + 1, o)) sphere(r=wire_r, $fn=8);
        }
}

// Clip frame: clip x -> right of travel, clip y -> up, clip z -> back
module clip_frame(c) {
    multmatrix([
        [c[4], 0, -c[3], c[0]],
        [-c[3], 0, -c[4], c[1]],
        [0, 1, 0, c[2]],
        [0, 0, 0, 1]])
        children();
}

module track_clips() {
    for (c=poc_clips)
        clip_frame(c)
            clip(c[5], 0, c[6], c[7], mount_hole_d, c[6] == "side_post" ? poc_post_d : wire_od);
}

// Short wire stubs from the board up into "post" clip sockets
function stub_h(c) = c[2] - (r_out_of(track_rails(c[5])) + tab_l) + tab_l - 2;
module stubs() {
    for (c=poc_clips)
        if (c[6] == "post")
            translate([c[0], c[1], -board_th])
                cylinder(d=wire_od, h=board_th + stub_h(c), $fn=8);
}

module posts() {
    for (p=poc_posts)
        translate([p[0], p[1], -board_th])
            cylinder(d=poc_post_d, h=p[2] + board_th, $fn=base_fn/4);
}

module board_cut_2d() {
    difference() {
        square([poc_board, poc_board]);
        for (p=poc_posts)
            translate([p[0], p[1]]) circle(d=poc_post_d, $fn=base_fn/2);
        translate(lift_post_xy) circle(d=lift_post_d, $fn=base_fn/2);
        translate(lift_c) circle(d=bushing_od + clr, $fn=base_fn);
        for (s=[-1, 1])
            translate(lift_c + [s * motor_mount_screw_x, 0]) circle(d=m3_d, $fn=base_fn/4);
        for (f=feet_xy)
            translate(f) circle(d=m3_d, $fn=base_fn/4);
        for (c=poc_clips)
            if (c[6] == "post")
                translate([c[0], c[1]]) circle(d=wire_od, $fn=base_fn/4);
    }
}

module board_etch_2d() {
    for (i=[0:len(poc_seg_style)-1], o=rail_offsets(poc_seg_style[i]))
        hull() {
            translate(rail_world(i, o)) circle(r=wire_r / 2, $fn=8);
            translate(rail_world(i + 1, o)) circle(r=wire_r / 2, $fn=8);
        }
}

module poc_assembly() {
    color("burlywood")
        translate([0, 0, -board_th])
        linear_extrude(board_th)
        board_cut_2d();
    color("tan")
        for (f=feet_xy)
            translate(concat(f, -board_th)) mirror([0, 0, 1]) foot();
    color("dimgray") posts();
    color("dimgray") stubs();
    color("silver") track_rails_3d();
    color("orange") track_clips();
    lift_assembly();
    % for (i=[2, len(poc_pts) / 2, len(poc_pts) - 2])
        translate(poc_pts[round(i)]) marble();
}

if (poc_part == "assembly") poc_assembly();
else if (poc_part == "board_cut") offset(delta=kerf/2) board_cut_2d();
else if (poc_part == "board_etch") board_etch_2d();
