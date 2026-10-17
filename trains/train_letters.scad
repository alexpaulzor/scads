include <brio_train.scad>; 


letter_base_h = 100;
std_small_r = 86;
std_large_r = 185;
letter_h = letter_base_h + 20;
std_long_l = 136;
std_short_l = letter_base_h;
tight_cross_l = std_small_r;
std_mini_l = 53;

q2 = sqrt(2) / 2;

// switch(angleR = 45, radiusR = 86, endR = "nest",
//        angleL = 45, radiusL = 86, endL = "nest",
//        lengthS = 0, endS = "none",
//        endCommon = "nest",
//        both_sides = true);
// // */

// arc(angle = -180,
//           radius = 86,
//           end1 = "nest",
//           end2 = "plug",
//           grooves = true,
//           both_sides = true,
//           cutout = true,
//           cutout_corr = 0,
//           part_chamfers = true);

// ! track_dogbone();

// track(length = 25,
//       cutout = true,
//       end1 = "plug",
//       end2 = "nest",
//       part_chamfers = true,
//       grooves = true);

module tight_split_half() {
   switch(angleR = 45, radiusR = letter_h, endR = "nest",
           angleL = 45, radiusL = 0, endL = "nest",
           lengthS = letter_base_h, endS = "nest",
           endCommon = "nest",
           both_sides = true);
}

// ! tight_split_half();

module tight_split(use_stl=true) {
    if (use_stl) {
        import("tight_split.stl");
    } else {
        difference() {
            union() {
                tight_split_half();
                translate([0, letter_base_h, 0])
                    mirror([0, 1, 0])
                    tight_split_half();
            }
            translate([(letter_h)+track_width, 0, 0])
                rotate_extrude(angle = -45, convexity = 10)
                    translate([-(letter_base_h + 20)-track_width, 0 , 0])
                        grooves(both_sides=true);
            translate([0, letter_base_h, 0])
                mirror([0, 1, 0])
                translate([(letter_h)+track_width, 0, 0])
                rotate_extrude(angle = -45, convexity = 10)
                    translate([-letter_h-track_width, 0 , 0])
                        grooves(both_sides=true);
            translate([0, letter_base_h, 0])
                rotate([90, 0, 0])
                linear_extrude(letter_base_h)
                    grooves(both_sides=true);
            translate([-1, -20, -1])
                cube([track_width + 2, 20, track_height + 2]);
            translate([-1, letter_base_h, -1])
                cube([track_width + 2, 20, track_height + 2]);
            translate([track_width, 0, 0])
                rotate([0, 0, 90])
                install_nest(nest_rotate = 0, length = 0);
            translate([track_width, 0, 0])
                rotate([0, 0, 90])
                install_nest(nest_rotate = 180, length = letter_base_h);
        }
    }
}

// ! tight_split(use_stl=false);

module plate_tight_split(use_stl=true) {
    tight_split(use_stl);

    translate([0, letter_base_h/2 - 1, 0])
        cube([50, 2, 0.5]);
    translate([track_width - 4, letter_base_h - 5, 0])
        cube([10, 10, 0.5]);
    translate([track_width - 4, -5, 0])
        cube([10, 10, 0.5]);
}

// ! plate_tight_split(use_stl=true);

module std_long(use_stl=true) {
    if (use_stl) {
        import("std_long.stl");
    } else {
        track(
            length = std_long_l,
            cutout = true,
            end1 = "nest",
            end2 = "nest",
            part_chamfers = true,
            grooves = true
        );
    }
}

// ! std_long(use_stl=false);

module std_short(use_stl=true) {
    if (use_stl) {
        import("std_short.stl");
    } else {
        track(
            length = std_short_l,
            cutout = true,
            end1 = "nest",
            end2 = "nest",
            part_chamfers = true,
            grooves = true
        );
    }
}

// ! std_short(use_stl=false);

module std_small_r_st(use_stl=true) {
    if (use_stl) {
        import("std_small_r_st.stl");
    } else {
        track(
            length = std_small_r,
            cutout = true,
            end1 = "nest",
            end2 = "nest",
            part_chamfers = true,
            grooves = true
        );
    }
}

// ! std_small_r_st(use_stl=false);

module std_mini(use_stl=true) {
    if (use_stl) {
        import("std_mini.stl");
    } else {
        track(
            length = std_mini_l,
            cutout = true,
            end1 = "nest",
            end2 = "nest",
            part_chamfers = true,
            grooves = true
        );
    }
}

// ! std_mini(use_stl=false);

module curve90(use_stl=true) {
    if (use_stl) {
        import("curve90.stl");
    } else { 
        track_arc(angle = 90,
                  radius = std_small_r,
                  end1 = "nest",
                  end2 = "nest",
                  grooves = true,
                  both_sides = true,
                  cutout = true,
                  cutout_corr = 0,
                  part_chamfers = true);
    }
}

// ! curve90(use_stl=false);
// ! curve90(use_stl=true);

module plate_curve90() {
    translate([0, track_width * q2, 0])
        rotate([0, 0, -45])
        curve90();
    * translate([track_width + 20, track_width * q2, 0])
        rotate([0, 0, -45])
        curve90();

    % cube([300, 300, 1]);
}

// ! plate_curve90();

module y45(use_stl=true) {
    if (use_stl) {
        import("y45.stl");
    } else { 
        switch(
            angleR = 45, radiusR = std_small_r, endR = "nest",
            angleL = 45, radiusL = std_small_r, endL = "nest",
            lengthS = 0, endS = "nest",
            endCommon = "nest",
            both_sides = true);
    }
}

// ! y45(use_stl=false);

module split45(use_stl=true) {
    if (use_stl) {
        import("split45.stl");
    } else { 
        switch(
            angleR = 45, radiusR = std_small_r, endR = "nest",
            angleL = 45, radiusL = 0, endL = "nest",
            lengthS = letter_base_h, endS = "nest",
            endCommon = "nest",
            both_sides = true);
    }
}

// ! split45(use_stl=false);

module plate_split45() {
    split45();

    translate([track_width - 3.6, letter_base_h - 13, 0])
        cube([3, 5, 0.3]);
}

// ! plate_split45();

module curve45(use_stl=true) {
    if (use_stl) {
        import("curve45.stl");
    } else { 
        track_arc(angle = 45,
                  radius = std_small_r,
                  end1 = "nest",
                  end2 = "nest",
                  grooves = true,
                  both_sides = true,
                  cutout = true,
                  cutout_corr = 0,
                  part_chamfers = true);
    }
}

// ! curve45(use_stl=false);

module curve_long45(use_stl=true) {
    if (use_stl) {
        import("curve_long45.stl");
    } else { 
        track_arc(angle = 45,
                  radius = std_large_r,
                  end1 = "nest",
                  end2 = "nest",
                  grooves = true,
                  both_sides = true,
                  cutout = true,
                  cutout_corr = 0,
                  part_chamfers = true);
    }
}

// ! curve_long45(use_stl=false);

module tight_cross(use_stl=true) {
    if (use_stl) {
        import("tight_cross.stl");
    } else { 
        translate([track_width/2, tight_cross_l/2, 0])
        _intersection(
            angle = 90,
            lengthA = tight_cross_l,
            lengthB = tight_cross_l,
            end1A = "nest",
            end2A = "nest",
            end1B = "nest",
            end2B = "nest",
            both_sides = false
        );
    }
}

// ! tight_cross(use_stl=false);
// ! tight_cross(use_stl=true);

module letter_k() {
    translate([0, letter_base_h, 0])
        rotate([0, 0, -90])
        std_short();

    translate([0, letter_base_h, 0])
        tight_split(use_stl=true);
    
    translate([0, letter_base_h*3, 0])
        rotate([0, 0, -90])
        std_short();

    translate([track_width + 7.2 + track_width*q2, letter_base_h*2 + 13.2 - track_width*q2, 0])
        rotate([0, 0, 45])
        std_long();
    translate([track_width + 7.1, letter_base_h + 15 - track_width*q2, 0])
        rotate([0, 0, -45])
        std_long();
}

// ! letter_k();

module letter_a() {
    translate([track_width, letter_base_h*2, 0])
        mirror([1, 0, 0]) 
        curve90();
    translate([std_small_r*2 + track_width, letter_base_h*2, 0])
        curve90();
    translate([0, letter_base_h, 0]) {
        split45();
    }

    translate([std_small_r*2 + 2*track_width, letter_base_h, 0]) {
        mirror([1, 0, 0]) 
        split45();
    }

    translate([std_small_r + track_width, letter_base_h, 0])
        rotate([0, 0, -45])
        translate([-std_small_r, 0, 0])
        mirror([1, 0, 0]) 
        curve90();

    translate([0, letter_base_h, 0])
        rotate([0, 0, -90])
        std_short();
    translate([212, letter_base_h, 0])
        rotate([0, 0, -90])
        std_short();
}

// ! letter_a();

module letter_r() {
    translate([0, letter_base_h, 0])
        rotate([0, 0, -90])
        std_short();

    translate([0, letter_base_h, 0])
        tight_split(use_stl=true);

    translate([std_small_r + track_width + 10.3, letter_base_h + 24, 0])
        rotate([0, 0, -45])
        translate([-std_small_r, 0, 0])
        mirror([1, 0, 0]) 
        curve45();

    translate([track_width + std_small_r + 10, letter_base_h*2 + track_width + 10, 0])
        rotate([0, 0, -90])
        curve90();

    translate([0, letter_base_h*2 + std_long_l, 0])
        rotate([0, 0, -90])
        std_long();
    
    translate([track_width + std_small_r + 10, letter_base_h*2 + std_small_r * 2 + 10 + track_width, 0])
        rotate([0, 0, -90])
        mirror([1, 0, 0])
        curve90();
        
    translate([track_width, letter_base_h*2 + std_small_r + 10 + track_width, 0])
        rotate([0, 0, 0])
        mirror([1, 0, 0])
        curve90();
    translate([track_width + 7.1, letter_base_h + 15 - track_width*q2, 0])
        rotate([0, 0, -45])
        std_long();
}

// ! letter_r();

module letter_s() {
    translate([0, track_width, 0])
        rotate([0, 0, -90])
        curve90();
    translate([std_small_r, track_width + std_small_r, 0])
        rotate([0, 0, 0])
        curve90();
    translate([0, std_small_r*2 + track_width*2, 0])
        rotate([0, 0, 90])
        mirror([1, 0, 0])
        curve90();
    translate([-std_small_r, std_small_r*3 + track_width*2, 0])
        mirror([1, 0, 0])
        curve90();
}

// ! letter_s();

// letter_o_leg_l = 100;

module letter_o() {


    // rotate([0, 0, 90])
        // tight_split();
    // translate([-letter_base_h + letter_h * q2 + track_width * sqrt(2) / 2, letter_base_h * q2 + 4.45 - track_width * sqrt(2) / 2, 0])
    //     rotate([0, 0, 45])
    //     track(
    //         length = letter_o_leg_l,
    //         cutout = true,
    //         end1 = "nest",
    //         end2 = "nest",
    //         part_chamfers = true,
    //         grooves = true
    //     );
    // translate([-letter_base_h + letter_h * q2 + letter_o_leg_l * sqrt(2) / 2, letter_base_h * q2 + 4.45 + letter_o_leg_l * sqrt(2) / 2, 0])
    //     rotate([0, 0, -45])
    //     curve90();

    // translate([
    //         28 + -letter_base_h + letter_h * q2 + letter_o_leg_l * sqrt(2) / 2, 
    //         64 + std_small_r + letter_base_h * q2 + 4.45 + letter_o_leg_l * sqrt(2) / 2, 
    //         0
    // ])
    //     rotate([0, 0, 135])
    //     track(
    //         length = letter_o_leg_l,
    //         cutout = true,
    //         end1 = "nest",
    //         end2 = "nest",
    //         part_chamfers = true,
    //         grooves = true
    //     );
    // translate([std_small_r, track_width + std_small_r, 0])
    //     rotate([0, 0, 0])
    //     track_arc(angle = 90,
    //           radius = std_small_r,
    //           end1 = "nest",
    //           end2 = "nest",
    //           grooves = true,
    //           both_sides = true,
    //           cutout = true,
    //           cutout_corr = 0,
    //           part_chamfers = true);
    // translate([0, 0, 0])
    //     rotate([0, 0, 90])
    //     track_arc(angle = -90,
    //           radius = std_small_r,
    //           end1 = "nest",
    //           end2 = "nest",
    //           grooves = true,
    //           both_sides = true,
    //           cutout = true,
    //           cutout_corr = 0,
    //           part_chamfers = true);
    // translate([-std_small_r - track_width, track_width + std_small_r, 0])
    //     rotate([0, 0, 0])
    //     track_arc(angle = -90,
    //           radius = std_small_r,
    //           end1 = "nest",
    //           end2 = "nest",
    //           grooves = true,
    //           both_sides = true,
    //           cutout = true,
    //           cutout_corr = 0,
    //           part_chamfers = true);
}

// ! letter_o();

module letter_n() {
    translate([0, 2*letter_base_h, 0])
        rotate([0, 0, -90])
        track(
            length = 2*letter_base_h,
            cutout = true,
            end1 = "nest",
            end2 = "nest",
            part_chamfers = true,
            grooves = true
        );
    translate([std_small_r*2 + track_width, 2*letter_base_h, 0])
        rotate([0, 0, 0])
        track_arc(angle = 90,
              radius = std_small_r,
              end1 = "nest",
              end2 = "nest",
              grooves = true,
              both_sides = true,
              cutout = true,
              cutout_corr = 0,
              part_chamfers = true);
    translate([0, 2*letter_base_h, 0])
        rotate([0, 0, 0])
        track_arc(angle = -90,
              radius = std_small_r,
              end1 = "nest",
              end2 = "nest",
              grooves = true,
              both_sides = true,
              cutout = true,
              cutout_corr = 0,
              part_chamfers = true);
    translate([2*std_small_r + track_width, 2*letter_base_h, 0])
        rotate([0, 0, -90])
        track(
            length = 2*letter_base_h,
            cutout = true,
            end1 = "nest",
            end2 = "nest",
            part_chamfers = true,
            grooves = true
        );
}

// ! letter_n();

module letter_k_connectors() {
    letter_k();
    % translate([track_width, 0, 0])
        rotate([0, 0, 180])
        curve90();
    % translate([track_width, 3 * letter_base_h, 0])
        // rotate([0, 0, 180])
        mirror([1, 0, 0])
        curve90();
    % translate([std_small_r + track_width, -std_small_r - track_width, 0])
        std_short();
    % translate([letter_base_h*2 + std_small_r + track_width, -std_small_r - track_width, 0])
        rotate([0, 0, 90])
        split45();

    % translate([
            track_width + 7.2 + track_width*q2 + std_long_l * q2, 
            letter_base_h*2 + 13.2 - track_width*q2 + std_long_l * q2, 
            0
    ])
        rotate([0, 0, 45])
        std_long();
    % translate([
            track_width + 7.2 + std_long_l * q2, 
            letter_base_h + 15 - track_width*q2 - std_long_l * q2, 
            0
    ])
        rotate([0, 0, -45])
        std_long();
    % translate([
        std_small_r + track_width, 
        3 * letter_base_h +std_small_r, 
        0
    ])
        std_short();
    % translate([
        letter_base_h*2 + std_small_r + track_width, 
        3 * letter_base_h + std_small_r + track_width, 
        0
    ])
        rotate([0, 0, 90])
        mirror([1, 0, 0])
        split45();
}

module letter_a_connectors() {
    letter_a();
    % translate([
        track_width,
        0,
        0
    ])
        rotate([0, 0, 180])
        // mirror([1, 0, 0])
            curve45();

    % translate([
        std_small_r * q2 + 4.5,
        -std_small_r * q2,
        0
    ])
    
        rotate([0, 0, -135])
        translate([track_width, 0, 0])
        mirror([1, 0, 0])
        curve45();
    
    % translate([
        std_small_r * q2 + 1.5,
        // std_small_r + track_width - tight_cross_l, 
        // -std_small_r - (std_small_r*q2 + track_width/2 + 7), 
        -std_small_r * q2 * 2 - track_width * q2 - tight_cross_l,
        0
    ])
        tight_cross();

    % translate([
        std_small_r * q2 + 1.5 + tight_cross_l/2 + track_width/2,
        -std_small_r * q2 * 2 - track_width * q2 - tight_cross_l + tight_cross_l/2 + track_width/2,
        0
    ])
        rotate([0, 0, -90])
        curve90();

    // * translate([
    //     // letter_base_h*2 + std_small_r + track_width + tight_cross_l/2 + track_width/2, 
    //     track_width,
    //     // -std_small_r - tight_cross_l/2 - track_width/2 - (std_small_r*q2 + track_width/2 + 7), 
    //     0,
    //     0
    // ])
    //     rotate([0, 0, 180])
    //     curve90();

    % translate([
        std_small_r * q2 + 1.5 + tight_cross_l/2 + track_width/2*3 + std_small_r,
        -std_small_r * q2 * 2 - track_width * q2 - tight_cross_l + tight_cross_l/2 + track_width/2 + std_small_r,
        0
    ])
        rotate([0, 0, 90])
        std_small_r_st();

    
    % translate([
        std_small_r * q2 + tight_cross_l/2 - 1.5,
        -std_small_r * q2 * 2 - track_width * q2 - tight_cross_l,
        0
    ])
        rotate([0, 0, 180])
        curve90();
    
}

// ! letter_a_connectors();

module letter_r_connectors() {    
    letter_r();

    % rotate([0, 0, -90])
        std_long();

    % translate([
        -std_small_r, 
        -std_small_r - std_long_l, 
        0
    ])
        rotate([0, 0, -90])
        curve90();

    % translate([
        track_width + 7.1 + std_long_l * q2 + track_width*q2, 
        letter_base_h + 15 - std_long_l * q2, 
        0
    ])
        rotate([0, 0, -135])
        curve45();
}

// ! letter_r_connectors();

module letter_s_connectors() {
    letter_s();

    % translate([-std_long_l, 0, 0])
        std_long();
    % translate([0, 4 * std_small_r + 2 * track_width, 0])
        std_long();
    # translate([std_short_l, 4 * std_small_r + 2 * track_width, 0])
        rotate([0, 0, 90])
        split45();
}

// ! letter_s_connectors();

module letter_o_connectors() {
    letter_o();
}

module letter_n_connectors() {
    letter_n();
}

module karson() {
    letter_k_connectors();
    letter_a_offs = [
        letter_base_h*2 + tight_cross_l + 1, 
        std_small_r*q2 + track_width/2 + 7, 
        0
    ];
    translate(letter_a_offs)
        letter_a_connectors();
    letter_r_offset = [
        std_small_r*3 + track_width - tight_cross_l/2 + track_width/2,
        -std_small_r*q2 - track_width,
        0
    ];
    translate(letter_a_offs + letter_r_offset)
        letter_r_connectors();

    letter_s_offs = [
        track_width + 7.1 + std_long_l * q2 + track_width*q2 + std_small_r * q2 + std_long_l, 
        letter_base_h + 10.5 - std_long_l * q2 - std_small_r * q2, 
        0
    ];
    translate(letter_a_offs + letter_r_offset + letter_s_offs)
        letter_s_connectors();
    translate([letter_base_h*12, 0, 0])
        letter_o_connectors();
    translate([letter_base_h*14, 0, 0])
        letter_n_connectors();
}

module dogbone() {
    // % track_dogbone();
    import("dogbone.stl");
}

clr = 0.2;
clip_th = 2;
clip_width = track_width + 2 * (clip_th + clr);
clip_length = 10;
clip_height = track_height + 2 * clr;
clip_hook_r = 2.5;


module clip_hook() {
    rotate([0, 90, 0])
        difference() {
            cylinder(r=clip_hook_r, h=clip_length, center=true, $fn=64);
            translate([clip_hook_r, clip_th, 0])
                cylinder(r=clip_hook_r, h=clip_length + 2, center=true, $fn=64);
            // # rotate([0, 0, 15])
            //     translate([clip_th, 0, 0])
            //     cube([2 * clip_th, clip_th*2 + 2, clip_length + 2], center=true);
        }
}

// ! clip_hook();

module clip_wedge() {
    difference() {
        rotate([90, 0, 0])
            // r=1 because there's a 2mm gap with the oversized dogbones
            cylinder(r=1, h=clip_width, center=true, $fn=4);
        translate([0, 0, clip_th])
            cube([clip_length, track_nest_neck_width + 2, 2*clip_th], center=true);
    }
}

// ! clip_wedge();

module track_clip() {
    for (cy=[-1, 1]){
        translate([
            0, cy * (clip_width/2 - clip_th/2), 
            clip_height/2
        ])
            cube([clip_length, clip_th, clip_height], center=true);
        translate([0, cy * (clip_width/2 - clip_hook_r), clip_height])
            mirror([0, cy > 0 ? 1 : 0, 0])
            clip_hook();
    }
    translate([0, 0, -clip_th/2])
        cube([clip_length, clip_width, clip_th], center=true);
    clip_wedge();

}

// ! track_clip();

module design() {
    % dogbone();
    // printed parts show 2mm gap with dogbone, not sure why.
    // but we'll exploit it happily to make holder clips.
    % translate([-1, -track_width/2, 0])
        rotate([0, 0, 90])
        curve45();
    
    % translate([1, track_width/2, 0])
        rotate([0, 0, -90])
        curve45();

    track_clip();
}

design();
// include <brio_train.scad>; 
