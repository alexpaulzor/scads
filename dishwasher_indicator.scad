

sign_th = 2;
sign_l = 100;
handle_od = 15.7;
font = "Black Ops One:style=Regular";
tsize = 18;

module dw_sign() {
    difference() {
        cylinder(r=handle_od/2 + sign_th, h=sign_l, center=true, $fn=128);
        union() {
            rotate([0, -90, 180])
                linear_extrude(handle_od)
                text("CLEAN", font=font, size=tsize, halign="center", valign="center");
            # rotate([0, -90, 0])
                linear_extrude(handle_od)
                text("DIRTY", font=font, size=tsize, halign="center", valign="center");
            
        }   
        cylinder(r=handle_od/2, h=sign_l, center=true, $fn=64);
        translate([0, handle_od, 0])
            cube([0.5, handle_od * 2, sign_l], center=true);
    }
}

dw_sign();
