`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:08:30 08/15/2016
// Design Name:   fifo_w16_r1_64
// Module Name:   /home/yihan/Work/ECImage/Stimulation/FPGAProject/BioEE_Costi/src/verilog/fifo_w16_r1_64_tb.v
// Project Name:  BioEECosti
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fifo_w16_r1_64
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module fifo_w16_r1_64_tb;

	// Inputs
	reg rst;
	reg wr_clk;
	reg md_clk;
	reg rd_clk;
	reg [15:0] din;
	reg wr_en;
	reg rd_en;

	// Outputs
	wire dout;
	wire full;
	wire empty;

	// Instantiate the Unit Under Test (UUT)
	fifo_w16_r1_64 uut (
		.rst(rst), 
		.wr_clk(wr_clk), 
		.md_clk(md_clk),
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
		md_clk = 0;
		rd_clk = 0;
		din = 0;
		wr_en = 0;
		rd_en = 0;

		// Wait 100 ns for global reset to finish
		#100 rst = 0;
        
		// Add stimulus here
		#2502 wr_en = 1;
		rd_en = 1;
		#0 din = 16'hFFFF;
		#320 din = 16'hFFFF;
		#320 din = 16'h0000;
		#320 din = 16'hBBBB;
		
	end
      
	always
		#10 rd_clk = ~rd_clk;
	
	always
		#80 md_clk = ~md_clk;
	
	always
		#160 wr_clk = ~wr_clk;
      
endmodule

