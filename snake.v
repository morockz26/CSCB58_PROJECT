module snake
        (
                CLOCK_50,                                                //        On Board 50 MHz
                // Your inputs and outputs here
        KEY,
        SW,
                  LEDR,
                // The ports below are for the VGA output.  Do not change.
                VGA_CLK,                                                   //        VGA Clock
                VGA_HS,                                                        //        VGA H_SYNC
                VGA_VS,                                                        //        VGA V_SYNC
                VGA_BLANK_N,                                                //        VGA BLANK
                VGA_SYNC_N,                                                //        VGA SYNC
                VGA_R,                                                   //        VGA Red[9:0]
                VGA_G,                                                         //        VGA Green[9:0]
                VGA_B                                                   //        VGA Blue[9:0]
        );


        input                        CLOCK_50;                                //        50 MHz
        input   [9:0]   SW;
        input   [3:0]   KEY;
        output [3:0] LEDR;


        // Declare your inputs and outputs here
        // Do not change the following outputs
        output                        VGA_CLK;                                   //        VGA Clock
        output                        VGA_HS;                                        //        VGA H_SYNC
        output                        VGA_VS;                                        //        VGA V_SYNC
        output                        VGA_BLANK_N;                                //        VGA BLANK
        output                        VGA_SYNC_N;                                //        VGA SYNC
        output        [9:0]        VGA_R;                                   //        VGA Red[9:0]
        output        [9:0]        VGA_G;                                         //        VGA Green[9:0]
        output        [9:0]        VGA_B;                                   //        VGA Blue[9:0]
        
        wire reset_n;
        assign reset_n = KEY[0];
        
        wire left, right;
        assign left = KEY[2];
        assign right = KEY[1];
        
        // Create the colour, x, y and writeEn wires that are inputs to the controller.
        wire [2:0] colour;
        wire [7:0] x;
        wire [6:0] y;
        wire writeEn;
        assign writeEn = 1'b1;


        // Create an Instance of a VGA controller - there can be only one!
        // Define the number of colours as well as the initial background
        // image file (.MIF) for the controller.
        vga_adapter VGA(
                        .resetn(reset_n),
                        .clock(CLOCK_50),
                        .colour(colour),
                        .x(x),
                        .y(y),
                        .plot(writeEn),
                        /* Signals for the DAC to drive the monitor. */
                        .VGA_R(VGA_R),
                        .VGA_G(VGA_G),
                        .VGA_B(VGA_B),
                        .VGA_HS(VGA_HS),
                        .VGA_VS(VGA_VS),
                        .VGA_BLANK(VGA_BLANK_N),
                        .VGA_SYNC(VGA_SYNC_N),
                        .VGA_CLK(VGA_CLK));
                defparam VGA.RESOLUTION = "160x120";
                defparam VGA.MONOCHROME = "FALSE";
                defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
                defparam VGA.BACKGROUND_IMAGE = "black.mif";
                        
        // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
        // for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
    datapath d0(
          .clk(CLOCK_50),
               .reset_n(reset_n),
                .move_left(move_left),
                         .move_up(move_up),
                         .move_down(move_down),
                         .move_right(move_right),
                         .colour(3'b111), // white
                .data_result_x(x),
                .data_result_y(y),
                         .colour_snake(colour)
           );
                          
         wire move_left, move_right, move_up, move_down;
         
         assign LEDR[3] = move_left;
         assign LEDR[2] = move_up;
         assign LEDR[1] = move_down;
         assign LEDR[0] = move_right;


    // Instansiate FSM control
     control c0(
           .clk(CLOCK_50),
           .left(left),
                          .right(right),
           .move_left(move_left),
                          .move_up(move_up),
                          .move_down(move_down),
                          .move_right(move_right)
       );
    
endmodule


module control(
    input clk,
    input left,
         input right,
    output reg  move_left, move_up, move_down, move_right
    );


    reg [5:0] current_state, next_state; 
    
    localparam  S_RIGHT    = 5'd0,
                S_UP       = 5'd1,
                S_LEFT     = 5'd2,
                S_DOWN     = 5'd3,
                                         S_RIGHT_WAIT    = 5'd4,
                S_UP_WAIT       = 5'd5,
                S_LEFT_WAIT     = 5'd6,
                S_DOWN_WAIT     = 5'd7;
    
    // Next state logic aka our state table
    always@(negedge left, negedge right)
    begin: state_table 
            case (current_state)
                S_RIGHT: begin
                                                 if (left == 1'b0)     // If key 2 is pressed
                                                      next_state = S_UP_WAIT; // Go to Up state
                                                                 else if (right == 1'b0)  
                                                      next_state = S_DOWN_WAIT;
                                                                 else
                                                                     next_state = S_RIGHT;
                                                                end
                S_UP:         begin
                                                                if (left == 1'b0)     // If key 2 is pressed
                                                      next_state = S_LEFT_WAIT; // Go to left state
                                                                else if (right == 1'b0)  
                                                      next_state = S_RIGHT_WAIT;
                                                                 else
                                                                     next_state = S_UP;
                                                                end
                S_LEFT: begin
                                                                if (left == 1'b0)     // If key 2 is pressed
                                                      next_state = S_UP_WAIT; // Go to down state
                                                                else if (right == 1'b0)  
                                                      next_state = S_DOWN_WAIT;
                                                                 else
                                                                     next_state = S_LEFT;
                                                                end
                S_DOWN: begin
                                                                if (left == 1'b0)     // If key 2 is pressed
                                                      next_state = S_LEFT_WAIT; // Go to            default:     next_state = S_RIGHT; left state
                                                                else if (right == 1'b0)  
                                                      next_state = S_RIGHT_WAIT;
                                                                 else
                                                                     next_state = S_DOWN;
                                                                end
                                                S_RIGHT_WAIT: next_state = S_RIGHT;
                                                S_UP_WAIT: next_state = S_UP;
                                                S_LEFT_WAIT: next_state = S_LEFT;
                                                S_DOWN_WAIT: next_state = S_DOWN;
          default:     next_state = S_RIGHT;
        endcase
    end // state_table
   
//                move_left = 1'b0;
//      move_right = 1'b0;
//      move_down = 1'b0;
//                move_up = 1'b0;
                
    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
         move_right <= 1'b0;
                   move_down <= 1'b0;
                        move_up <= 1'b0;
                        move_left <= 1'b0;


        case (current_state)
            S_RIGHT:
                                begin
                                        move_right <= 1'b1;
                                end
            S_UP:
                                begin
                                        move_up <= 1'b1;
                                end
            S_LEFT:
                                begin
                                        move_left <= 1'b1;
                                end
            S_DOWN:
                                begin
                                        move_down <= 1'b1;
                                end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        current_state <= next_state;
    end // state_FFS
        
endmodule


module datapath(
    input clk,
    input reset_n,
    input move_left, move_right, move_up, move_down,
         input [2:0] colour,
         
    output [7:0] data_result_x,
    output [6:0] data_result_y,
         output reg [2:0] colour_snake
    );
    
    // input registers
    reg [7:0] x;
    reg [6:0] y;
    reg [2:0] c; 
    reg [21:0] counter;
    reg [3:0] framecount;
    wire update;
    reg [1:0] snake_counter;
    reg draw_snake;
	
	//Snake piece locations (max length 256 squares)
	reg [7:0] piece_x [255:0];
	reg [6:0] piece_y [255:0];
	
	//background colour
	reg [2:0] background = 3'b111;


         // Start Game
         initial begin
            x <= 7'd80;
            y <= 6'd60;
            colour_snake <= 3'b111;
            draw_snake <= 1'b0;
                end


	genvar i;
	generate
	   for (i=0; i<=255; i=i+1) begin : generate_snakes
	   snake_piece piece(
			.in_x(piece_x[i]),
			.in_y(piece_y[i]),
			.update(update),
			.clk(clk),
			.out_x(piece_x[i+1]),
			.out_y(piece_x[i+1])
	   );
	end 
	endgenerate


    // Initializes a snake that is 4 pixels long
    always @(posedge clk) // triggered every time clock rises
    begin
            if (draw_snake == 1'b0)
        begin
            if (snake_counter == 5'b11)
                draw_snake <= 1'b1;
            else
            begin
                x <= x + 1'b1;
                snake_counter <= snake_counter + 1'b1;
            end
        end
    end


         
    // Registers a, b, c, x with respective input logic
    always@(posedge clk) begin
        if(!reset_n) begin
            x <= 8'b0; 
            y <= 7'b0;
            c <= 3'b0;
        end
        else begin
            if(move_right && update && draw_snake)
            begin
                piece_x[0] <= piece_x[0] + 1'b1; // Move snake right
            end
            else if(move_left && update && draw_snake)
            begin
                piece_x[0] <= piece_x[0] - 1'b1; // Move snake left
            end
            else if(move_up && update  && draw_snake)
            begin
                piece_y[0] <= piece_y[0] - 1'b1; // Move snake up
            end
            else if(move_down && update && draw_snake)
            begin
                piece_y[0] <= piece_y[0] + 1'b1; // Move snake down
            end
        end
    end


    always @(posedge clk) // triggered every time clock rises
    begin
                // Count for 15 frames per second - 15 Hz
                // Want the snake to move at 4 pixel per second
      if (counter == 22'd3333332)
                begin
                counter <= 22'b0;
                end
      else
                begin
         counter <= counter + 1'b1;
                end
    end
         
         assign update = (counter == 22'd3333332) ? 1'b1 : 1'b0; // Update every 15 frames per second
    
         //Output result register
         
    //assign data_result_x = x; //+ counter[1:0];
    //assign data_result_y = y; //+ counter[3:2];
	
	
	genvar j;
	generate
	   for (j=0; j<=draw_snake; j=j+1) begin : draw_snakes
			assign data_result_x = piece_x[i];
			assign data_result_y = piece_y[i];
			assign colour_out = c;
			
			if(j == draw_snake)
				assign colour_out = background;
	end 
	endgenerate
    
endmodule


//Module for each part of the snake
module snake_piece(
    input [7:0] in_x,
    input [6:0] in_y,
    input update,
	input clk,
    output reg [7:0] out_x,
    output reg [6:0] out_y,
    output [2:0] colour_snake
    );
        
    //saves its own location
    reg [7:0] this_x;
    reg [6:0] this_y;
                
    //updates location and passes on location to next part of snake when moving
    always @(posedge clk) // triggered every time clock rises
	begin
		if (update == 1'b1)
		begin
			out_x <= this_x;
			out_y <= this_y;
			this_x <= in_x;
			this_y <= in_y;
		end
	end
endmodule
