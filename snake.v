module snake(
	input CLOCK_50, // On Board 50 MHz
	// Your inputs and outputs here
	input[3:0] KEY,
	output[3:0] LEDR,
	// The ports below are for the VGA output.  Do not change.
	output VGA_CLK, // VGA Clock
	output VGA_HS, // VGA H_SYNC
	output VGA_VS, // VGA V_SYNC
	output VGA_BLANK_N, // VGA BLANK
	output VGA_SYNC_N, // VGA SYNC
	output[9:0] VGA_R, // VGA Red[9:0]
	output[9:0] VGA_G, // VGA Green[9:0]
	output[9:0] VGA_B // VGA Blue[9:0]
	);

	wire reset_n;
	assign reset_n = KEY[0];

	wire left, right, pause;
	assign pause = KEY[3];
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
		.VGA_CLK(VGA_CLK)
		);

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
		.data_result_x(x),
		.data_result_y(y),
		.colour(colour)
		);

	wire move_left, move_right, move_up, move_down;

	//assign LEDR[3] = move_left;
	//assign LEDR[2] = move_up;
	//assign LEDR[1] = move_down;
	//assign LEDR[0] = move_right;

	// Instansiate FSM control
	control c0(
		.clk(CLOCK_50),
		.resetn(reset_n),
		.pause(pause),
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
	input resetn,
	input pause,
	input left,
	input right,
	output reg  move_left, move_up, move_down, move_right
	);

	reg [5:0] current_state, next_state; 

	localparam  S_RIGHT = 5'd0,
					S_UP = 5'd1,
               S_LEFT = 5'd2,
					S_DOWN = 5'd3,
					S_RIGHT_WAIT = 5'd4,
					S_UP_WAIT = 5'd5,
					S_LEFT_WAIT = 5'd6,
					S_DOWN_WAIT = 5'd7,
					S_PAUSE = 5'd8,
					S_PAUSE_WAIT = 5'd9,
					S_CONTINUE = 5'd10,
					S_CONTINUE_WAIT = 5'd11;
				
	// Next state logic aka our state table
	always@(negedge left, negedge right, negedge pause)
	begin: state_table 
		case (current_state)
			S_RIGHT:
			begin
				if (left == 1'b0)     // If key 2 is pressed
					next_state = S_UP_WAIT; // Go to Up state
				else if (right == 1'b0)  
					next_state = S_DOWN_WAIT;
				else if (pause == 1'b0)
					next_state = S_PAUSE_WAIT;
				else
					next_state = S_RIGHT;
			end
			S_UP:
			begin
				if (left == 1'b0)     // If key 2 is pressed
					next_state = S_LEFT_WAIT; // Go to left state
				else if (right == 1'b0)  
					next_state = S_RIGHT_WAIT;
				else if (pause == 1'b0)
					next_state = S_PAUSE_WAIT;
				else
					next_state = S_UP;
			end
			S_LEFT:
			begin
				if (left == 1'b0)     // If key 2 is pressed
					next_state = S_UP_WAIT; // Go to down state
				else if (right == 1'b0)  
					next_state = S_DOWN_WAIT;
				else if (pause == 1'b0)
					next_state = S_PAUSE_WAIT;
				else
					next_state = S_LEFT;
			end
			S_DOWN:
			begin
				if (left == 1'b0)     // If key 2 is pressed
					next_state = S_LEFT_WAIT; // Go to            default:     next_state = S_RIGHT; left state
				else if (right == 1'b0)  
					next_state = S_RIGHT_WAIT;
				else if (pause == 1'b0)
					next_state = S_PAUSE_WAIT;
				else
					next_state = S_DOWN;
			end
			S_RIGHT_WAIT: next_state = S_RIGHT;
			S_UP_WAIT: next_state = S_UP;
			S_LEFT_WAIT: next_state = S_LEFT;
			S_DOWN_WAIT: next_state = S_DOWN;
			S_PAUSE:
			begin
				if (pause == 1'b0)
					next_state = S_CONTINUE_WAIT;
				else
					next_state = S_PAUSE;
			end
			S_PAUSE_WAIT: next_state = S_PAUSE;
			S_CONTINUE: next_state = S_RIGHT;
			S_CONTINUE_WAIT: next_state = S_CONTINUE;
			default: next_state = S_RIGHT;
		endcase
	end // state_table

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
			S_PAUSE:
			begin
				move_right <= 1'b0;
				move_down <= 1'b0;
				move_up <= 1'b0;
				move_left <= 1'b0;
			end
			// default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
		endcase
	end // enable_signals

	// current_state registers
	always@(posedge clk)
	begin: state_FFs
		if (!resetn)
			current_state = S_RIGHT;
		else
			current_state <= next_state;
	end // state_FFS

endmodule

module datapath(
    input clk,
    input reset_n,
    input move_left, move_right, move_up, move_down,
    output reg [7:0] data_result_x,
    output reg [6:0] data_result_y,
    output reg [2:0] colour
    );

	// input registers
	//reg [7:0] x;
	//reg [6:0] y;
	integer count, count2;
	reg [2:0] col;
	reg [22:0] counter;
	wire update, erase;
	reg [7:0] snake_length;
	reg [7:0] snake_counter;
	reg draw_snake;

	//Snake piece locations (max length 160 squares)
	reg [7:0] piece_x [159:0];
	reg [6:0] piece_y [159:0];

	// Start Game
	initial begin
		snake_length <= 8'b00000100;
		snake_counter <= 8'b00000000;
		piece_x[0] <= 7'd80;
		piece_y[0] <= 6'd60;
		col <= 3'b111;
	end


	always@(posedge clk) begin
		if(!reset_n) begin
			piece_x[0] <= 7'd80; 
			piece_y[0] <= 6'd60;
			col <= 3'b111;
			snake_counter = 8'b00000000;
			snake_length = 8'b00000100;
		end
		else 
		begin
				// update the position of the snake body before changing the head
		    for(count = 159; count > 0; count = count - 1)
				begin
					piece_x[count] <= piece_x[count - 1];
					piece_y[count] <= piece_y[count - 1];
				end
				//update the head
				col <= 3'b111; // Make white
				if(move_right && update)
				begin
					piece_x[0] <= piece_x[0] + 1'b1; // Move snake right
				end		  
				else if(move_left && update)
				begin
					piece_x[0] <= piece_x[0] - 1'b1; // Move snake left
				end
				else if(move_up && update)
				begin        
					piece_y[0] <= piece_y[0] - 1'b1; // Move snake up
				end
				else if(move_down && update)
				begin
					piece_y[0] <= piece_y[0] + 1'b1; // Move snake down		  
				end
		end
		// draw the snake
		for(count2 = 0; count2 < 160 && count2 < snake_length + 1; count2 = count2 + 1)
			begin
				if(count2 <= snake_length)
						col <= 3'b111;
				else
						col <= 3'b000;
				data_result_x <= piece_x[count2];
				data_result_y <= piece_y[count2];
				colour <= col;
			end
	end
   // update the location of all the snake before outputing them
	//assign colour = col;
	//assign data_result_x = piece_x[0];
	//assign data_resul
	//add
	

	always @(posedge clk)
	// triggered every time clock rises
	begin
		// Count for 7.5 frames per second - 7.5 Hz
		// Want the snake to move at 4 pixel per second
		if (counter == 23'd6666665)
		begin
			counter <= 23'b0;
		end
      else
		begin
			counter <= counter + 1'b1;
		end
	end

	assign update = (counter == 23'd6666665) ? 1'b1 : 1'b0; // Update every 7.5 frames per second
	assign erase = (counter == 23'd6666664) ? 1'b1 : 1'b0; // Erase just before updating

endmodule
