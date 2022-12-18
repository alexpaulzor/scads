include <casting.scad>;

sign_th = 2;
sign_l = 66;
handle_od = 15.5;
font = "Times:style=Bold";
// font = "neo latina:style=Regular";
tsize = 14;
clip_w = 8;
clr = 1;


module handle() {
    rotate([0, 90, 0])
        cylinder(r=handle_od/2, h=sign_l*2, center=true, $fn=64);
}

module bounding_cylinder() {
    rotate([0, 90, 0])
        cylinder(r=handle_od*sqrt(2)/2+1, h=sign_l*2, center=true, $fn=64);
}

module dw_sign() {
    difference() {
        union() {
            translate([0, 0, handle_od/2-sign_th])
                linear_extrude(sign_th*2)
                text("CLEAN", font=font, size=tsize, halign="center", valign="center");
            rotate([180, 0, 0])
                translate([0, 0, handle_od/2 - sign_th])
                linear_extrude(sign_th*2)
                text("DIRTY", font=font, size=tsize, halign="center", valign="center");
            translate([0, 
                    handle_od/2, 0])
                 cube([
                    sign_l, sign_th*2, handle_od + 2 * sign_th], center=true);
            translate([0, 
                    -handle_od/2, 0])
                 cube([
                    sign_l, sign_th*2, handle_od + 2 * sign_th], center=true);
        }
        handle();
    }
}

module clip(clr=0) {
    difference() {
        draft_cube2([
            clip_w + clr, sign_th, handle_od
            ], center=true, draft_angle=[10, 0]);
        translate([0, -sign_th/2, 
                handle_od/2 - sign_th - clr/2])
            cube([clip_w*2, sign_th, 
                sign_th/4], center=true); 

        translate([0, -sign_th, handle_od/2 - sign_th/2])
            rotate([-45, 0, 0])
            cube([clip_w*2, sign_th, handle_od-sign_th*2], center=true);
        translate([0, -sign_th, 0])
            rotate([-10, 0, 0])
            cube([clip_w*2, sign_th, handle_od-sign_th*2], center=true);
    }
    

}

// ! clip();

module clip_design() {
    // % clip(-1);
    % clip(1);
    clip();
}

// ! clip_design();

module dirty_clips(clr=0) {
    translate([0, handle_od/2 + sign_th/2, 0])
        clip(clr=clr);
    translate([-sign_l/3, handle_od/2 + sign_th/2, 0])
        clip(clr=clr);
    translate([sign_l/3, handle_od/2 + sign_th/2, 0])
        clip(clr=clr);
    translate([-sign_l/6, -handle_od/2 - sign_th/2, 0])
        rotate([0, 0, 180])
        clip(clr=clr);
    translate([sign_l/6, -handle_od/2 - sign_th/2, 0])
        rotate([0, 0, 180])
        clip(clr=clr);
}

// ! dirty_clips();

module clean_clips(clr=0) {
    rotate([180, 0, 0])
        dirty_clips(clr=clr);
    // translate([0, handle_od/2 + sign_th/2, 0])
    //     clip();
    // translate([-sign_l/3, handle_od/2 + sign_th/2, 0])
    //     clip();
    // translate([sign_l/3, handle_od/2 + sign_th/2, 0])
    //     clip();
    // translate([-sign_l/6, -handle_od/2 - sign_th/2, 0])
    //     rotate([0, 0, 180])
    //     clip();
    // translate([sign_l/6, -handle_od/2 - sign_th/2, 0])
    //     rotate([0, 0, 180])
    //     clip();
}

// ! dirty_clips();

module dirty_side() {
    difference() {
        dw_sign();
        translate([0, 0, handle_od])
            cube([sign_l*2, 2*handle_od, 2*handle_od], center=true);
        clean_clips(clr=clr);
    }
    dirty_clips();
}

// ! dirty_side();

module dirty_side_round() {
    intersection() {
        dirty_side();
        bounding_cylinder();
    }
}

module clean_side() {
    difference() {
        dw_sign();
        // dirty_side();
        translate([0, 0, -handle_od])
            cube([sign_l*2, 2*handle_od, 2*handle_od], center=true);
       dirty_clips(clr=clr);
    }
    clean_clips();
}

// ! clean_side();

module clean_side_round() {
    intersection() {
        clean_side();
        bounding_cylinder();
    }
}

module plate() {
    dirty_side_round();
    translate([0, handle_od + 3 * sign_th, 0])
        rotate([180, 0, 0])
        clean_side_round();
}

! plate();

module square_design() {
    dirty_side();
    clean_side();
    // % dw_sign();    
}

// square_design();

module design() {
    dirty_side_round();
    clean_side_round();
    // % dw_sign();    
}

// design();

