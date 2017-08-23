`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:21:09 08/15/2016
// Design Name:   fifo_w1_1024_r16_64
// Module Name:   /home/yihan/Work/ECImage/Stimulation/FPGAProject/BioEE_Costi/src/verilog/fifo_w1_1024_r16_64_tb.v
// Project Name:  BioEECosti
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fifo_w1_1024_r16_64
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module fifo_w1_1024_r16_64_tb;

	// Inputs
	reg rst;
	reg wr_clk;
	reg md_clk;
	reg rd_clk;
	reg din;
	reg wr_en;
	reg rd_en;

	// Outputs
	wire [15:0] dout;
	wire full;
	wire empty;

	// Instantiate the Unit Under Test (UUT)
	fifo_w1_r16_1024 uut (
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
		rst = 1;
		wr_clk = 0;
		md_clk = 0;
		rd_clk = 0;
		din = 0;
		wr_en = 0;
		rd_en = 0;

		// Wait 100 ns for global reset to finish
		#100 rst = 0;
        
		// Add stimulus here
		#602 wr_en = 1;

		din = 1'b1;
		#20 din = 1'b0;
		#20 din = 1'b1;
		#20 din = 1'b0;
		#20 din = 1'b1;
		#20 din = 1'b0;
		#20 din = 1'b1;
		#20 din = 1'b0;
		#20 din = 1'b1;
		#20 din = 1'b1;
		#20 din = 1'b1;
		#20 din = 1'b1;
		#20 din = 1'b0;
		#20 din = 1'b0;
		#20 din = 1'b0;
		#20 din = 1'b0;
		rd_en = 1;
		#20 din = 1'b0;
		#20 din = 1'b1;
		#20 din = 1'b0;
		#20 din = 1'b1;
		#20 din = 1'b0;
		#20 din = 1'b1;
		#20 din = 1'b0;
		#20 din = 1'b1;
		#20 din = 1'b0;
		#20 din = 1'b0;
		#20 din = 1'b0;
		#20 din = 1'b0;
		#20 din = 1'b1;
		#20 din = 1'b1;
		#20 din = 1'b1;
		#20 din = 1'b1;
	
	end
	
	always
		#10 wr_clk = ~wr_clk;
		
	always
		#80 md_clk = ~md_clk;
		
	always
		#160 rd_clk = ~rd_clk;
      
endmodule

