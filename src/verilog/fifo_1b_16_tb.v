`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:06:24 08/15/2016
// Design Name:   fifo_w1_1024_r8_128
// Module Name:   /home/yihan/Work/ECImage/Stimulation/FPGAProject/BioEE_Costi/src/verilog/fifo_1b_16_tb.v
// Project Name:  BioEECosti
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fifo_w1_1024_r8_128
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module fifo_1b_16_tb;

	// Inputs
	reg rst;
	reg wr_clk;
	reg rd_clk;
	reg [0:0] din;
	reg wr_en;
	reg rd_en;

	// Outputs
	wire [7:0] dout;
	wire full;
	wire empty;

	// Instantiate the Unit Under Test (UUT)
	fifo_w1_1024_r8_128 uut (
		.rst(rst), 
		.wr_clk(wr_clk), 
		.rd_clk(rd_clk), 
		.din(din), 
		.wr_en(wr_en), 
		.rd_en(rd_en), 
		.dout(dout), 
		.full(full), 
		.empty(empty)
	);

	initial begin
		// Initialize Inputs
		rst = 0;
		wr_clk = 0;
		rd_clk = 0;
		din = 0;
		wr_en = 0;
		rd_en = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

