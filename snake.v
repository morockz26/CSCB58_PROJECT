module snake(
	input [3:0] KEY
	);

endmodule	
	


// Part 2 skeleton

module lab6b
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire reset_n;
	assign reset_n = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

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
	       .data_in(SW[6:0]),
 	       .ld_x(ld_x),
    	       .ld_y(ld_y),
               .ld_r(writeEn),
			 .colour(SW[9:7]),
 	       .data_result_x(x),
 	       .data_result_y(y),
			 .colour_out(colour)
           );

    // Instansiate FSM control
     control c0(
           .clk(CLOCK_50),
           .reset_n(reset_n),
           .go(KEY[3]),
           .left(KEY[1]),
			  .right(KEY[0]),
           .ld_x(ld_x),
           .ld_y(ld_y),
           .ld_r(writeEn),
       );
    
endmodule

module control(
    input clk,
    input reset_n,
    input go,
    input left,
	 input right,
    output reg  ld_s, ld_l, ld_d, ld_u;
    );

    reg [5:0] current_state, next_state; 
    
    localparam  S_START    = 5'd0,
                S_UP       = 5'd1,
                S_LEFT     = 5'd2,
                S_DOWN     = 5'd3;
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_START: if (negedge left)     // If key 1 is pressed
					              next_state = S_UP; // Go to Up state
								 else if (posedge left)
								     next_state = S_START; // Go to start state
								if (negedge right)  
					              next_state = S_DOWN;
								 else if (posedge right)
								     next_state = S_START;
                S_UP: if (negedge left)     // If key 1 is pressed
					              next_state = S_LEFT; // Go to Up state
								 else if (posedge left)                    
								     next_state = S_UP; // Go to start state
								if (negedge right)  
					              next_state = S_START;
								 else if (posedge right)
								     next_state = S_UP;
                S_LEFT: if (negedge left)     // If key 1 is pressed
					              next_state = S_DOWN; // Go to Up state
								 else if (posedge left)                    
								     next_state = S_LEFT; // Go to start state
								if (negedge right)  
					              next_state = S_UP;
								 else if (posedge right)
								     next_state = S_LEFT;
                S_DOWN: if (negedge left)     // If key 1 is pressed
					              next_state = S_LEFT; // Go to Up state
								 else if (posedge left)                    
								     next_state = S_DOWN; // Go to start state		 colour_background <= 3'b000;
								if (negedge right)  
					              next_state = S_START;
								 else if (posedge right)
								     next_state = S_DOWN;
            default:     next_state = S_START;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_s = 1'b0;
        ld_l = 1'b0;
        ld_d = 1'b0;
		  ld_u = 1'b0;

        case (current_state)
            S_START:
                ld_s = 1'b1;
            S_UP:
                ld_u = 1'b1;
            S_LEFT:
                ld_l = 1'b1;
				S_DOWN:
				    ld_d = 1'b1;
				
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!reset_n)
            current_state <= S_START;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

module datapath(
    input clk,
    input reset_n,
    input [6:0] data_in,
    input ld_x, ld_y,
    input ld_r,
	 input [2:0] colour,
	 
    output [7:0] data_result_x,
    output [6:0] data_result_y,
	 output [2:0] colour_snake,
    );
    
    // input registers
    reg [7:0] x;
    reg [6:0] y;
    reg [2:0] c; 
    reg [4:0] counter;
    
	 // Start Game
	 initial begin
	    x <= 6'd80;
		 y <= 5'd60;
		 colour_snake <= 3'b111;
	end
	 
	 
    // Registers a, b, c, x with respective input logic
    always@(posedge clk) begin
        if(!reset_n) begin
            x <= 8'b0; 
            y <= 7'b0;
			   c <= 3'b0;	
        end
        else begin
            if(ld_x)
            begin
                x[6:0] <= data_in; // load alu_out if load_alu_out signal is high, otherwise load from data_in
                x[7] <= 1'b0;
            end
            if(ld_y)
				begin
				    c <= colour;
                y <= data_in; // load alu_out if load_alu_out signal is high, otherwise load from data_in
			   end
        end
    end

    always @(posedge clk) // triggered every time clock rises
    begin
	     if (ld_r == 1'b1)
		  begin
            if (counter == 5'b10000)
                counter <= 5'b0;
            else
                counter <= counter + 1'b1;
		  end
    end
    // Output result register
	 
    assign data_result_x = x + counter[1:0];
    assign data_result_y = y + counter[3:2];
	 assign colour_out = c;
        
    
endmodule
