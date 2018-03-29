module snake(
	input CLOCK_50, // On Board 50 MHz
	// Your inputs and outputs here
	input[3:0] KEY,
	output[3:0] LEDR,
	output [7:0] HEX0,
	output [7:0] HEX1,
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
		.VGA_CLK(VGA_CLK)
		);

	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";

	// Code for datapath, control, and hex display

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
		.colour(colour),
		.score(score)
		);

	wire move_left, move_right, move_up, move_down;
	wire [7:0] score;

	//assign LEDR[3] = move_left;
	//assign LEDR[2] = move_up;
	//assign LEDR[1] = move_down;
	//assign LEDR[0] = move_right;

	// Instansiate FSM control
	control c0(
		.clk(CLOCK_50),
		.resetn(reset_n),
		.left(left),
		.right(right),
		.move_left(move_left),
		.move_up(move_up),
		.move_down(move_down),
		.move_right(move_right)
		);

	hex_display hex0(
		.IN(score[3:0]),
		.OUT(HEX0)
		);
		
	hex_display hex1(
		.IN(score[7:4]),
		.OUT(HEX1)
		);	

endmodule


module control(
	input clk,
	input resetn,
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
					S_DOWN_WAIT = 5'd7;		
				
	// Next state logic aka our state table
	always@(negedge left, negedge right)
	begin: state_table 
		case (current_state)
			S_RIGHT:
			begin
				if (left == 1'b0)     // If key 2 is pressed
					next_state = S_UP_WAIT; // Go to Up state
				else if (right == 1'b0)  
					next_state = S_DOWN_WAIT;
				else
					next_state = S_RIGHT;
			end
			S_UP:
			begin
				if (left == 1'b0)     // If key 2 is pressed
					next_state = S_LEFT_WAIT; // Go to left state
				else if (right == 1'b0)  
					next_state = S_RIGHT_WAIT;
				else
					next_state = S_UP;
			end
			S_LEFT:
			begin
				if (left == 1'b0)     // If key 2 is pressed
					next_state = S_UP_WAIT; // Go to down state
				else if (right == 1'b0)  
					next_state = S_DOWN_WAIT;
				else
					next_state = S_LEFT;
			end
			S_DOWN:
			begin
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
    output [7:0] data_result_x,
    output [6:0] data_result_y,
    output [2:0] colour,
	 output reg [7:0] score
    );

	// input registers
	reg [22:0] counter;
	wire update, erase; // For deciding when to update and erase the snake piece
	
	// Coordinates and extra for the food
	wire spawn_food;
	reg [7:0] food_x;
	reg [6:0] food_y;
	reg [2:0] food_col;

	//Snake piece locations (max length 160 squares) and extra
	reg [7:0] piece_x [159:0];
	reg [6:0] piece_y [159:0];
	reg [7:0] snake_length;
	reg [7:0] snake_counter;
	reg [2:0] col;
	reg update_1 = 1'b0;
	reg [7:0] posX;
	reg [6:0] posY;

	// Start Game
	initial begin
		snake_length <= 8'b00000100;
		snake_counter <= snake_length;
		
		// Initialize snakes position
		piece_x[0] <= 7'd80;
		piece_y[0] <= 6'd60;
		piece_x[1] <= 7'd79;
		piece_y[1] <= 6'd60;
		piece_x[2] <= 7'd78;
		piece_y[2] <= 6'd60;
		piece_x[3] <= 7'd77;
		piece_y[3] <= 6'd60;
		piece_x[4] <= 7'd76;
		piece_y[4] <= 6'd60;
		col <= 3'b111;
		
		// Initialize food
		food_x <= 7'd80;
		food_y <= 7'd60;
		food_col <= 3'b100; // red
		
		// Score starts at 0
		score <= 8'b0;
	end
			
	wire [7:0] wire_piece_x [159:0];
	wire [6:0] wire_piece_y [159:0];

	always@(posedge clk) begin
		if(!reset_n) begin
			piece_x[0] <= 7'd80;
			piece_y[0] <= 6'd60;
			piece_x[1] <= 7'd79;
			piece_y[1] <= 6'd60;
			piece_x[2] <= 7'd78;
			piece_y[2] <= 6'd60;
			piece_x[3] <= 7'd77;
			piece_y[3] <= 6'd60;
			piece_x[4] <= 7'd76;
			piece_y[4] <= 6'd60;
			col <= 3'b111;
			snake_length = 8'b00000100;
			snake_counter = snake_length;
		end
		else 
		begin
			if (collision) // Grow snake on collision
			begin
				snake_counter <= snake_length;
				snake_length <= snake_length + 1'b1;
			end

			if (update || update_1) // Decides when to draw snake and move it
			begin
				update_1 <= 1'b1;
				if (snake_counter == snake_length)
				begin
					piece_x[snake_counter] <= piece_x[snake_counter - 1];
					piece_y[snake_counter] <= piece_y[snake_counter - 1];				
					posX <= piece_x[snake_counter];
					posY <= piece_y[snake_counter];
					col <= 3'b000;
					snake_counter <= snake_counter - 1'b1;
				end
				else if (snake_counter != 1'b0)
				begin
					piece_x[snake_counter] <= piece_x[snake_counter - 1];
					piece_y[snake_counter] <= piece_y[snake_counter - 1];
					posX <= piece_x[snake_counter];
					posY <= piece_y[snake_counter];
					col <= 3'b111;
					snake_counter <= snake_counter - 1'b1;
				end	
				else if (snake_counter == 1'b0)
				begin
					if(move_right)
					begin
						piece_x[0] <= piece_x[0] + 1'b1; // Move snake right
					end		  
					else if(move_left)
					begin
						piece_x[0] <= piece_x[0] - 1'b1; // Move snake left
					end
					else if(move_up)
					begin        
						piece_y[0] <= piece_y[0] - 1'b1; // Move snake up
					end
					else if(move_down)
					begin
						piece_y[0] <= piece_y[0] + 1'b1; // Move snake down		  
					end
					posX <= piece_x[0];
					posY <= piece_y[0];
					col <= 3'b111;
					snake_counter <= snake_length;
					update_1 <= 1'b0;
				end
			end
		end
	end
	
	wire collision;
	assign collision = (food_x == piece_x[0] && food_y == piece_y[0]) ? 1 : 0;
	
	always@(posedge clk)
	begin
		if (!reset_n)
			score <= 8'b0;
		else if (collision) // Check for collision
		begin
			food_col <= 3'b100; // Need to move food to different location
			food_x <=  food_counter_x;
			food_y <= food_counter_y;
			score <= score + 1'b1; // Increase score by 1
		end
		else
		begin
			food_col <= 3'b000;
		end
	end
	
	assign spawn_food = food_col == 3'b100 ? 1 : 0;

	assign colour = spawn_food ? food_col : col;
	assign data_result_x = spawn_food ? food_x : posX;
	assign data_result_y = spawn_food ? food_y : posY;

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
	//assign erase = (counter == 23'd6666664) ? 1'b1 : 1'b0; // Erase just before updating
	
	reg [7:0] food_counter_x;
	reg [6:0] food_counter_y;

	// Our attempt to mak the food respawn randomly
	always@(posedge clk)
	begin
		if (food_counter_x == 8'd160)
			food_counter_x <= 8'd0;
		else
			food_counter_x <= food_counter_x + 1'b1;
			
		if (food_counter_y == 8'd120)
			food_counter_y <= 8'd0;
		else
			food_counter_y <= food_counter_y + 1'b1; 
	end

endmodule
