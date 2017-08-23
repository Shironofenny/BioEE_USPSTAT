`timescale 1ns / 1ps
`default_nettype none

module BioEE_clkdivider(

	input wire clkin,
	input wire [31:0] integerdivider,  //even numbers only
	
	input wire enable,
	output wire clkout
	
   );


reg [30:0] clk_counter;
reg clkout_reg;

assign clkout = clkout_reg;

initial begin
	clk_counter <= 31'd00;
	clkout_reg <= 1'b0;
end

always @(posedge clkin) begin
	if ( (enable==1'b1) && (clk_counter == integerdivider[31:1]) ) begin
		clk_counter <= 31'd1;
		clkout_reg <= ~clkout_reg;
	end else begin
		clk_counter <= clk_counter + 31'd1;
	end
end


endmodule

