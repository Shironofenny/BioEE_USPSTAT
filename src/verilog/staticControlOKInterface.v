`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:21:21 08/17/2016 
// Design Name: 
// Module Name:    staticControlOKInterface 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module staticControlOKInterface(
    input wire rst,
    input wire din,
    output wire dout,
    input wire set_trigger
    );
	 
	 // In fact this is just a D-Flip-Flop triggered by the set_trigger signal
	 
	 reg dout_reg;
	 assign dout = dout_reg;
	 
	 initial
		dout_reg <= 1'b0;
		
	 always @ (posedge rst or posedge set_trigger) begin
		if (rst) begin
			dout_reg <= 1'b0;
		end else begin
			dout_reg <= din;
		end
	 end

endmodule
