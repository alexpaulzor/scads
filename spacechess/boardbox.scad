
SIDE = 40;
HEIGHT = 3;
THICK = 2;
AXLE = 1.75;
OFFS = HEIGHT - THICK/2; // axle offset from square origin
CLR = 0.5; // clearance

hinge_len = (SIDE + 2*OFFS - 2 * HEIGHT - 5*CLR) / 4;

num_steps = 9;
step = 0;
$t = step / num_steps;
echo($t);

module flaps() {
	% children();
}

module hinge_shell(h=SIDE, oversize=false) {
	cylinder(r=HEIGHT, h=h, $fn=36);
}

module axle(h=SIDE) {
	cylinder(r=AXLE/2, h=h, $fn=36);
}

module nub_axle(h=SIDE) {
	rotate([0, 0, 45])
		translate([-THICK/4, -THICK/4, 0])
		cube([THICK/2, THICK/2, h]);
}

module hinge(n=1, invert=0) {
	invert = invert ? 1 : 0;
	difference() {
		// hinge_shell(n*SIDE);
		for (i=[0:2*n-1]) {
			translate([0, 0, HEIGHT + i*SIDE/2 + invert * (hinge_len + CLR/2)]) {
				hinge_shell(hinge_len - CLR/2);
				cube([HEIGHT, HEIGHT, hinge_len - CLR/2]);
			}
		}
		// #
		for (i=[0:2*n-1]) {
			translate([0, 0, HEIGHT + i*SIDE/2 + (invert ? 0 : 1) * (hinge_len + CLR/2)]) {
				hinge_shell(hinge_len + CLR/2, oversize=true);
				// cube([HEIGHT, HEIGHT, hinge_len - CLR/2]);
			}
		}
		translate([0, 0, -OFFS])
			axle(n*SIDE + 2*OFFS);
		// translate([0, 0, n * SIDE - HEIGHT + OFFS])
		// 	hinge_shell(HEIGHT + OFFS);
		// hinge_shell(HEIGHT + OFFS);
		
		// for (i=[0:n-1]) {
		// 	translate([0, 0, 1 + i*SIDE + invert * SIDE/2])
		// 		hinge_shell(SIDE/2 - 2);
		// }
	}
}

module filler(stl=false) {
	if (stl) {
		import("stl/filler.boardbox.stl");
	} else {
		cube([SIDE - 4*THICK, SIDE - 4*THICK, HEIGHT - THICK]);
		for (i=[0, 1]) {
			translate([i*(SIDE-4*THICK), 0, (HEIGHT - THICK)/2])
				rotate([-90, 0, 0])
				nub_axle(SIDE-4*THICK);
			translate([0, i*(SIDE-4*THICK), (HEIGHT - THICK)/2])
				rotate([0, 90, 0])
				nub_axle(SIDE-4*THICK);
		}
	}
}

module square(white=1) {
	translate([0, 0, -HEIGHT/2]) {
		difference() {
			//color("white") 
				cube([SIDE, SIDE, HEIGHT]);
			translate([2*THICK, 2*THICK, THICK])
				filler(true);
		}
		if (!white)
			% translate([THICK, THICK, THICK])
				//color("black") 
				filler(true);
	}

}

module grid(rows, cols, start_white=1) {
	start_white = start_white ? 1 : 0;
	difference() {
		for (row=[0:rows-1]) {
			for (col=[0:cols-1]) {
				translate([OFFS + row*SIDE, OFFS+col*SIDE, -HEIGHT/2])
					square(white=(row+col+start_white) % 2);
			}
		}
		for (row=[0, rows*SIDE + 2*OFFS]) {
			translate([row, -HEIGHT, 0])
				rotate([-90, 0, 0])
				hinge_shell(cols*SIDE + 2 * HEIGHT);
		}
		for (col=[0, cols*SIDE + 2*OFFS]) {
			translate([-HEIGHT, col, 0])
				rotate([0, 90, 0])
				hinge_shell(rows*SIDE + 2 * HEIGHT);
		}
	}
}

module bottom(stl=false, rows=3, cols=6) {
	// 3 x 6 squares, hinges 4 sides
	if (stl) {
		import("stl/bottom.boardbox.stl");
	} else {
		grid(rows, cols);
		for (y=[0, cols*SIDE + 2*OFFS])
			translate([0, y, 0])
				rotate([0, 90, 0])
				rotate([0, 0, y == 0 ? 0 : -90])
				hinge(rows, y==0);
		for (x=[0, rows*SIDE + 2*OFFS])
			translate([x, 0, 0])
				rotate([-90, x == 0 ? 0 : 90, 0])
				hinge(cols, x!=0);
	}
}

module top(stl=false, closed=false, rows=3, cols=6) {
	// 3 x 6 squares, hinges all but 1 long side
	if (stl) {
		import("stl/bottom.boardbox.stl");
	} else {
		grid(rows, cols);
		for (y=[0, cols*SIDE + 2*OFFS])
			translate([0, y, 0])
				rotate([0, 90, 0])
				rotate([0, 0, y == 0 ? 0 : -90])
				hinge(rows, y==0);
		for (x=[0])
			translate([x, 0, 0])
				rotate([-90, x == 0 ? 0 : 90, 0])
				hinge(cols, x!=0);
	}
	closed = closed ? 1 : 0;
	flaps() 
		rotate([closed * -180, 0, 0])
		translate([rows * SIDE + 2 * OFFS, 0, 0])
		rotate([0, 0, 180])
		top_right(stl, rows=rows);
	flaps() 
		translate([0, cols * SIDE + 2 * OFFS, 0])
		rotate([closed * 180, 0, 0])
		top_left(stl, rows=rows);
}

module back(stl=false, closed=false, rows=3, cols=6) {
	// 1 x 6 squares, hinges all sides
	if (stl) {
		import("stl/back.boardbox.stl");
	} else {
		grid(1, cols, false);
		for (y=[0, cols*SIDE + 2*OFFS])
			translate([0, y, 0])
				rotate([0, 90, 0])
				rotate([0, 0, y == 0 ? 0 : -90])
				hinge(1, y==0);
		for (x=[0, 1*SIDE + 2*OFFS])
			translate([x, 0, 0])
				rotate([-90, x == 0 ? 0 : 90, 0])
				hinge(cols, x!=0);
	}
	side_closed = (closed || ($t >= 4/num_steps)) ? 1 : 0;
	top_closed = (closed || ($t >= 9/num_steps)) ? 1 : 0;
	flaps()
		translate([0, cols * SIDE + 2 * OFFS, 0])
		rotate([side_closed * 180, 0, 0]) 
		front_right();
	flaps()
		translate([SIDE + 2*OFFS, 0, 0])
		rotate([side_closed * 180, 0, 180]) 
		front_right();
	flaps()	
		translate([SIDE + 2 * OFFS, 0, 0])
		rotate([0, top_closed * -90, 0])
		top(stl, closed=(closed || ($t >= 7/num_steps)), rows=rows, cols=cols);
}

module front(stl=false, closed=false, rows=3, cols=6) {
	// 1 x 6 squares, hinges all but 1 long side
	if (stl) {
		import("stl/front.boardbox.stl");
	} else {
		grid(1, cols, true);
		for (y=[0, cols*SIDE + 2*OFFS])
			translate([0, y, 0])
				rotate([0, 90, 0])
				rotate([0, 0, y == 0 ? 0 : -90])
				hinge(1, y==0);
		for (x=[0])
			translate([x, 0, 0])
				rotate([-90, x == 0 ? 0 : 90, 0])
				hinge(cols, x!=0);
	}
	closed = closed ? 1 : 0;
	flaps()
		translate([0, cols * SIDE + 2 * OFFS, 0])
		rotate([closed * 180, 0, 0]) 
		front_right(stl);
	flaps()
		translate([SIDE + 2*OFFS, 0, 0])
		rotate([closed * 180, 0, 180]) 
		front_right(stl);
}

module right(stl=false, rows=3) {
	// 3 x 1 squares, on 1 long side only
	if (stl) {
		import("stl/right.boardbox.stl");
	} else {
		grid(rows, 1, false);
		for (y=[0])
			translate([0, y, 0])
				rotate([0, 90, 0])
				rotate([0, 0, y == 0 ? 0 : -90])
				hinge(rows, y==0);
		// for (x=[0, 3 * SIDE + 2 * OFFS])
		// 	translate([x, 0, 0])
		// 		rotate([-90, 0, 0])
		// 		hinge(1, x!=0);
	}
}

module left(stl=false, rows=3) {
	// 3 x 1 squares, hinge on 1 long side only
	// if (stl) {
	// 	import("stl/left.boardbox.stl");
	// } else {
	// 	grid(rows, 1, false);
	// 	for (y=[0])
	// 		translate([0, y, 0])
	// 			rotate([0, 90, 0])
	// 			rotate([0, 0, y == 0 ? 0 : -90])
	// 			hinge(rows, y==0);
	// 	// for (x=[0, 3 * SIDE + 2 * OFFS])
	// 	// 	translate([x, 0, 0])
	// 	// 		rotate([-90, 0, 0])
	// 	// 		hinge(1, x!=0);
	// }
	right(stl, rows);
}

module top_right(stl=false, rows=3) {
	// 3 x 1 squares, on 1 long side only (flushfold)
	if (stl) {
		import("stl/top_right.boardbox.stl");
	} else {
		grid(rows, 1, false);
		for (y=[0])
			translate([0, y, 0])
				rotate([0, 90, 0])
				rotate([0, 0, y == 0 ? 0 : -90])
				hinge(rows, y==0);
		// for (x=[0, 3 * SIDE + 2 * OFFS])
		// 	translate([x, 0, 0])
		// 		rotate([-90, 0, 0])
		// 		hinge(1, x!=0);
	}
}

module top_left(stl=false, rows=3) {
	// 3 x 1 squares, hinge on 1 long side only (flushfold)
	// if (stl) {
	// 	import("stl/top_left.boardbox.stl");
	// } else {
	// 	grid(rows, 1, true);
	// 	for (y=[0])
	// 		translate([0, y, 0])
	// 			rotate([0, 90, 0])
	// 			rotate([0, 0, y == 0 ? 0 : -90])
	// 			hinge(rows, y==0);
	// 	// for (x=[0, 3 * SIDE + 2 * OFFS])
	// 	// 	translate([x, 0, 0])
	// 	// 		rotate([-90, 0, 0])
	// 	// 		hinge(1, x!=0);
	// }
	top_right(stl, rows);
}

module front_right(stl=false) {
	// 1 x 1 squares, hinge on 1 side only (flushfold)
	if (stl) {
		import("stl/front_right.boardbox.stl");
	} else {
		grid(1, 1, true);
		for (y=[0])
			translate([0, y, 0])
				rotate([0, 90, 0])
				rotate([0, 0, y == 0 ? 0 : -90])
				hinge(1, y==0);
		// for (x=[0, 3 * SIDE + 2 * OFFS])
		// 	translate([x, 0, 0])
		// 		rotate([-90, 0, 0])
		// 		hinge(1, x!=0);
	}
}

// module front_left(stl=false) {
// 	// // 1 x 1 squares, hinge on 1 side only (flushfold)
// 	// if (stl) {
// 	// 	import("stl/front_left.boardbox.stl");
// 	// } else {
// 	// 	grid(1, 1, true);
// 	// 	for (y=[0])
// 	// 		translate([0, y, 0])
// 	// 			rotate([0, 90, 0]) {
// 	// 				hinge(1, y==0);
// 	// 			}
// 	// 	// for (x=[0, 3 * SIDE + 2 * OFFS])
// 	// 	// 	translate([x, 0, 0])
// 	// 	// 		rotate([-90, 0, 0])
// 	// 	// 		hinge(1, x!=0);
// 	// }
// 	front_right(stl);
// }

module design(stl=false, closed=false) {
	closed = closed ? 1 : 0;
	bottom(stl);
	sides_closed = closed || ($t >= 5/num_steps) ? 1 : 0;
	rotate([sides_closed * -90, 0, 0])
		translate([3 * SIDE + 2 * OFFS, 0, 0])
		rotate([0, 0, 180])
		right(stl);
	translate([0, 6 * SIDE + 2 * OFFS, 0])
		rotate([sides_closed * 90, 0, 0])
		left(stl);
	back_closed = closed || ($t>=6/num_steps) ? 1 : 0;
	translate([3 * SIDE + 2*OFFS, 0, 0])
		rotate([0, back_closed * -90, 0])
		back(stl, closed=(closed || ($t>=8/num_steps)));
	front_closed = closed || ($t>=3/num_steps) ? 1 : 0;
	translate([0, 6 * SIDE + 2 * OFFS])
		rotate([0, front_closed * -90, 180])
		front(stl, closed=(closed || ($t>=2/num_steps)));
	// translate(closed * [-SIDE - 2 * OFFS, 0, SIDE + 2 * OFFS])
	// 	translate([4 * SIDE + 4 * OFFS, 0, 0])
	// 	rotate([0, closed * 180, 0])
	// 	top(stl, closed=(closed || ($t >= 0.3)));
}
// stl = true;
// design(stl=stl, closed=true);
// translate([0, -8*SIDE, 0])
// 	design(stl=false, closed=false);
// front();
design();
module test_bottom() {
	bottom(rows=1, cols=1);
}

module test_back(stl=false, closed=false) {
	back(stl, closed=(closed || ($t>=8/num_steps)), rows=1, cols=1);
}

module test_right(stl=false) {
	right(stl, rows=1);
}

module test_front(stl=false, closed=false) {
	front(stl, closed=closed, rows=1, cols=1);
}

module test_front_right(stl=false) {
	front_right(stl);
}

module test_box() {
	stl = false;
	closed = false;
	test_bottom();
	sides_closed = closed || ($t >= 5/num_steps) ? 1 : 0;
	rotate([sides_closed * -90, 0, 0])
		translate([1 * SIDE + 2 * OFFS, 0, 0])
		rotate([0, 0, 180])
		test_right(stl);
	translate([0, 1 * SIDE + 2 * OFFS, 0])
		rotate([sides_closed * 90, 0, 0])
		left(stl, rows=1);
	back_closed = closed || ($t>=6/num_steps) ? 1 : 0;
	translate([1 * SIDE + 2*OFFS, 0, 0])
		rotate([0, back_closed * -90, 0])
		test_back();
	front_closed = closed || ($t>=3/num_steps) ? 1 : 0;
	translate([0, 1 * SIDE + 2 * OFFS])
		rotate([0, front_closed * -90, 180])
		test_front(stl, closed=(closed || ($t>=2/num_steps)));
}
// ! test_box();
// test_bottom();
// test_front_right();
// test_front();


