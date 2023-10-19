// Mark's random jigsaw puzzle generator

$fn=36;

puzzle_height = 150;
puzzle_width = 207;
puzzle_thickness = 3;       // thickness including carved-out text
debossed_text_depth = 1.5;
frame_border_width = 15;

use_prongs = true;

separation_gap = 0.4;       // piece separation distance - use tiny value and let Slic3r separate them

twistage_factor = 4;        // lower means more randomized intersection locations
prong_depth_factor = 8;     // lower means deeper prongs
prong_centering_factor = 7; // lower means prongs closer to borders
prong_sizing_factor = 2.8;    // higher means smaller prongs
prong_sizing_variation = 1.5;  // ratio of smallest to largest (higher=more variation)
prong_neck_width_degrees = 90;  
prong_max_angle = 25;       // maximum prong angle from horiz/vertical

num_rows = 5;
num_cols = 5;
num_pieces = num_rows * num_cols;

avg_row_height = puzzle_height / num_rows;
avg_col_width = puzzle_width / num_cols;

// embossed text
text_size = 29;
text_spacing = 40;
text_font = "Ink Free:style=Regular";


text_line1 = "Is This A";
text_line2 = "Proper";
text_line3 = "Hoco Sign?";
text_line4 = "Sign?";

// random intersection location for each piece
x_int_rand_max = avg_col_width/twistage_factor;
x_int_rand_seed = rands(0,100,1)[0];
x_int_rand_values = rands(-x_int_rand_max/2,x_int_rand_max/2,num_pieces+num_cols,x_int_rand_seed);

y_int_rand_max = avg_row_height/twistage_factor;
y_int_rand_seed = rands(0,100,1)[0];
y_int_rand_values = rands(-y_int_rand_max/2,y_int_rand_max/2,num_pieces+num_rows,y_int_rand_seed);

function rand_x_int(row,col) = -puzzle_width/2 + col*avg_col_width +
    ((col==0 || col>=num_cols)? 0 : x_int_rand_values[row*num_cols+col]);

function rand_y_int(row,col) = -puzzle_height/2 + row*avg_row_height +
    ((row==0 || row>=num_rows)? 0 : y_int_rand_values[row*num_cols+col]);
    
// random prong offsets from mean
x_prong_rand_max = avg_col_width/prong_centering_factor;
x_prong_rand_seed = rands(0,100,1)[0];
x_prong_rand_values = rands(-x_prong_rand_max/2,x_prong_rand_max/2,num_pieces+num_cols,x_prong_rand_seed);

y_prong_rand_max = avg_row_height/prong_centering_factor;
y_prong_rand_seed = rands(0,100,1)[0];
y_prong_rand_values = rands(-y_prong_rand_max/2,y_prong_rand_max/2,num_pieces+num_rows,y_prong_rand_seed);

prong_size_rand_max = avg_row_height/prong_sizing_factor;
prong_size_rand_seed = rands(0,100,1)[0];
prong_size_rand_values = rands(prong_size_rand_max/prong_sizing_variation,(avg_col_width+avg_row_height)/2/prong_sizing_factor,num_pieces+num_rows,prong_size_rand_seed);

prong_depth_rand_max = avg_row_height/prong_depth_factor;
prong_depth_rand_seed = rands(0,100,1)[0];
prong_depth_rand_values = rands(-(avg_col_width+avg_row_height)/2/prong_depth_factor,(avg_col_width+avg_row_height)/2/prong_depth_factor,num_pieces+num_rows,prong_depth_rand_seed);


// create a section of pie with angle up to 180 degrees
module pie_section(radius,angle) {
    rotate([0,0,-angle/2])      // center will be aligned with x axis
    difference() {
        // start with circle
        circle(radius);

        // trim off lower half entirely
        translate([0,-radius,0])
            square([radius*2,radius*2],true);
        
        // cut upper half down to desired angle
        rotate([0,0,angle])
            translate([-radius*2,0,0])
                square([radius*4,radius*2],false);
    }
}

// make a line of width "separation_gap" between points (x1,y1) and (x2,y2)
module make_squiggly_line(row,col,x1,y1,x2,y2) {
    if (use_prongs) {       
        x_mean = (x1+x2)/2;
        y_mean = (y1+y2)/2;       
        x_dist = x2-x1;
        y_dist = y2-y1;
        idx = row*num_cols+col;
        prong_diameter = prong_size_rand_values[idx];
        vertical = (y_dist > x_dist);
        
        // pick random prong (x,y) coordinates and size
        x_prong = x_mean + (vertical? prong_depth_rand_values[idx] : x_prong_rand_values[idx]);
        y_prong = y_mean + (vertical? y_prong_rand_values[idx] : prong_depth_rand_values[idx]);
        neck_angle = rands(-prong_max_angle,prong_max_angle,1)[0] + (vertical?0:90) + ((rands(0,2,1)[0] > 1)?180:0);
        
        // make a partial circle for the prong
        difference() {
            translate([x_prong,y_prong,0])
                circle(prong_diameter/2+separation_gap/2);
            translate([x_prong,y_prong,0])
                circle(prong_diameter/2-separation_gap/2);
            
            // notch out a portion to make a partial circle
            translate([x_prong,y_prong,0])
                rotate([0,0,neck_angle])
                    pie_section(prong_diameter/2+separation_gap,prong_neck_width_degrees);
        }
        
        x1_prong_base = x_prong + (prong_diameter/2)*cos(neck_angle+prong_neck_width_degrees/2);
        x2_prong_base = x_prong + (prong_diameter/2)*cos(neck_angle-prong_neck_width_degrees/2);      
        y1_prong_base = y_prong + (prong_diameter/2)*sin(neck_angle+prong_neck_width_degrees/2);
        y2_prong_base = y_prong + (prong_diameter/2)*sin(neck_angle-prong_neck_width_degrees/2);
        
        flip_base = ( (vertical && (y1_prong_base > y2_prong_base)) ||
                      (!vertical && (x1_prong_base > x2_prong_base)) );
        
        // join ends of the partial circle to the corners
        hull() {
            translate([x1,y1,0])
                square([separation_gap,separation_gap],true);
            translate([flip_base?x2_prong_base:x1_prong_base,flip_base?y2_prong_base:y1_prong_base,0])
                square([separation_gap,separation_gap],true);
        }
        hull() {
            translate([flip_base?x1_prong_base:x2_prong_base,flip_base?y1_prong_base:y2_prong_base,0])
                square([separation_gap,separation_gap],true);
            translate([x2,y2,0])
                square([separation_gap,separation_gap],true);
        }
    } else {
        // simple straight lines between intersections
        hull() {
            translate([x1,y1,0])
                square([separation_gap,separation_gap],true);
            translate([x2,y2,0])
                square([separation_gap,separation_gap],true);
        }
    }
}

// cut top border of one single piece
module piece_upper_border(row,col) {
    if (row < num_rows-1) {
        ul_x = rand_x_int(row+1,col);
        ul_y = rand_y_int(row+1,col);
        ur_x = rand_x_int(row+1,col+1);
        ur_y = rand_y_int(row+1,col+1);
        make_squiggly_line(row,col,ul_x,ul_y,ur_x,ur_y);
    }
}

// cut right border of one single piece
module piece_right_border(row,col) {
    if (col < num_cols-1) {
        lr_x = rand_x_int(row,col+1);
        lr_y = rand_y_int(row,col+1);
        ur_x = rand_x_int(row+1,col+1);
        ur_y = rand_y_int(row+1,col+1);
        make_squiggly_line(row,col,lr_x,lr_y,ur_x,ur_y);
    }
}

// cut top and right side of each piece
module make_piece(row,col) {
    piece_upper_border(row,col);
    piece_right_border(row,col);
}

module debossed_text() {
    translate([0,text_spacing-text_size/2,puzzle_thickness-debossed_text_depth/2+0.01])
        linear_extrude(height=debossed_text_depth,center=true)
            text(text_line1,size=text_size,halign="center",font=text_font);
        
    translate([0,-text_size/2,puzzle_thickness-debossed_text_depth/2+0.01])
        linear_extrude(height=debossed_text_depth,center=true)
            text(text_line2,size=text_size,halign="center",font=text_font);
        
    translate([0,-text_spacing-text_size/2,puzzle_thickness-debossed_text_depth/2+0.01])
        linear_extrude(height=debossed_text_depth,center=true)
            text(text_line3,size=text_size,halign="center",font=text_font);
    
}

module ebossed_text() 
translate([0,0,10])
{
    translate([0,text_spacing-text_size/2,puzzle_thickness-debossed_text_depth/2+0.01])
        linear_extrude(height=debossed_text_depth,center=true)
            text(text_line1,size=text_size,halign="center",font=text_font);
        
    translate([0,-text_size/2,puzzle_thickness-debossed_text_depth/2+0.01])
        linear_extrude(height=debossed_text_depth,center=true)
            text(text_line2,size=text_size,halign="center",font=text_font);
        
    translate([0,-text_spacing-text_size/2,puzzle_thickness-debossed_text_depth/2+0.01])
        linear_extrude(height=debossed_text_depth,center=true)
            text(text_line3,size=text_size,halign="center",font=text_font);
    
}


module frame_border() {
    for (i=[-1:2:1]) {
        translate([i*(puzzle_width/2-frame_border_width/2),0,puzzle_thickness])
            rotate([0,5*i,0])
                cube([frame_border_width,puzzle_height,puzzle_thickness],true);
          
        translate([0,i*(puzzle_height/2-frame_border_width/2),puzzle_thickness])
            rotate([-5*i,0,0])
                cube([puzzle_width,frame_border_width,puzzle_thickness],true);
    }
}

{
			
    difference() {
        // extrude to a 3D puzzle
        translate([0,0,puzzle_thickness/2]) {
            linear_extrude(height=puzzle_thickness,center=true) {
                difference() {
                    // start with a rectangle
                    translate([0,0,0])
                        square([puzzle_width,puzzle_height],true);
                
                    // cut lines between them to make pieces
                    for (row=[0:num_rows-1]) {
                        for (col=[0:num_cols-1]) {
                            make_piece(row,col);
																												
																												
                        }
																								
                    }
                }
            }
        }

        
        // carve out text message
        color("black")
        //debossed_text();
								
        
        // carve out a frame border
        color("black")
        frame_border();

    }
				

}