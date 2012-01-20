length = 31.35;
width= 7.8;
height= 5.8;

toothwidth = 3.15;

brick_width = 5.0625;
end_thickness = 1.2;
middle_thickness = 2.9;

module tooth()
{
	difference()
	{

		cube([3.21,width,height]);

		//1. Zahn
		translate([0,-0.1,4-0.9]) cube([0.3,width+0.2,1.8]);
		translate([-1.55,-0.1,3.88]) rotate([0,23,0]) cube([2,width+0.2,3]);

		//2. Zahn
		translate([2.2+0.5,-0.1,4-0.9]) cube([1/2+0.1,width+0.2,3]);
		translate([2.7,-0.1,3.1]) rotate([0,-23,0]) cube([1,width+0.2,3]);
		translate([2.2,-0.1,5.1]) cube([0.8,width+0.2,1.8]);
	}

}

		

module toothbrick4()
{

	difference()
	{

		union()
		{
			tooth();   				//1
			translate([toothwidth,0,0]) tooth();
			translate([2*toothwidth,0,0]) tooth();
			translate([3*toothwidth,0,0]) tooth();
			translate([4*toothwidth,0,0]) tooth();	//5
			translate([5*toothwidth,0,0]) tooth();
			translate([6*toothwidth,0,0]) tooth();
			translate([7*toothwidth,0,0]) tooth();
			translate([8*toothwidth,0,0]) tooth();	
			translate([9*toothwidth,0,0]) tooth();	//10
			
		}
	
	//cut end
	translate([length,0,0]) cube([10,10,10]);	
	
	//cut top
	translate([-0.5,-0.5,5.6]) cube([33,10,2]);

	//cut hole for bricks
	translate([end_thickness,1.15,-0.1]) cube([31.35-2*end_thickness,5.5,2.6]);
	
	}

	//bridges between the bricks
	translate([end_thickness+brick_width,0,0]) cube([middle_thickness,7.8,3]); 
	translate([end_thickness+brick_width*2+middle_thickness,0,0]) cube([middle_thickness,7.8,3]); 
	translate([end_thickness+brick_width*3+middle_thickness*2,0,0]) cube([middle_thickness,7.8,3]); 
}




toothbrick4();
translate([length , 0, 0]) toothbrick4();
translate([2*length, 0, 0]) toothbrick4();
translate([0, width + 2, 0]) {
	toothbrick4();
	translate([length , 0, 0]) toothbrick4();
	translate([2*length, 0, 0]) toothbrick4();
}
translate([0, 2 * width + 4, 0]) {
	toothbrick4();
	translate([length , 0, 0]) toothbrick4();
	translate([2*length, 0, 0]) toothbrick4();
}
