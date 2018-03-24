//Module for each part of the snake
module snake_piece(
	input [7:0] in_x,
	input [6:0] in_y,
	input update,
	input clk,
	output [7:0] out_x,
	output [6:0] out_y
	);

	//saves its own location
	reg [7:0] this_x;
	reg [6:0] this_y;
	reg [7:0] outx;
	reg [6:0] outy;

	//updates location and passes on location to next part of snake when moving
	always @(posedge clk) // triggered every time clock rises
	begin
		if (update == 1'b1)
		begin
			outx <= this_x;
			outy <= this_y;
			this_x <= in_x;
			this_y <= in_y;
		end
	end

	assign out_x = outx;
	assign out_y = outy;

endmodule
