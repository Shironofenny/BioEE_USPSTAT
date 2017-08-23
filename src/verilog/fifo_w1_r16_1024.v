`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:08:23 08/15/2016 
// Design Name: 
// Module Name:    fifo_w1b_1024_r16_64 
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
module fifo_w1_r16_1024(
	  rst,
	  wr_clk,
	  md_clk,
     rd_clk,
     din,
     wr_en,
     rd_en,
     dout,
     full,
     empty,
	  wr_data_count
     );
	  
input rst;
input wr_clk;
input md_clk;
input rd_clk;
input din;
input wr_en;
input rd_en;
output [15:0] dout;
output full;
output empty;
output [9:0] wr_data_count;

// The stage between two fifos making the entire thing 1:16 
wire [7:0] dmid;
wire stage1Read;
wire stage1Empty;
wire stage1Full;
wire stage2Empty;
wire stage2Write;
wire stage2Full;

assign stage1Read = ~stage1Empty;
assign stage2Write = ~stage1Empty;
	  
fifo_w1_r8_1024 fifoStage1 (
					.rst(rst),
					.wr_clk(wr_clk),
					.rd_clk(md_clk),
					.din(din),
					.wr_en(wr_en),
					.rd_en(stage1Read),
					.dout(dmid),
					.full(stage1Full),
					.empty(stage1Empty),
					.wr_data_count(wr_data_count)
					);
					
fifo_w8_r16_128 fifoStage2 (
					.rst(rst),
					.wr_clk(md_clk),
					.rd_clk(rd_clk),
					.din(dmid),
					.wr_en(stage2Write),
					.rd_en(rd_en),
					.dout(dout),
					.full(stage2Full),
					.empty(stage2Empty)
					);

assign empty = stage2Empty;
assign full = stage1Full;

endmodule
