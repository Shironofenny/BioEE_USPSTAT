`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:59:28 08/16/2016
// Design Name:   dacOKInterface
// Module Name:   /home/yihan/Work/ECImage/Stimulation/FPGAProject/BioEE_Costi/src/verilog/dacOKInterface_tb.v
// Project Name:  BioEECosti
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: dacOKInterface
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module dacOKInterface_tb;

	// Inputs
	reg rst;
	reg ti_clk;
	reg clk;
	reg din_en;
	reg [7:0] din;
	reg set_trig;

	// Outputs
	wire ack_data;
	wire ack_set;
	wire dac_din;
	wire dac_cs;

	// Instantiate the Unit Under Test (UUT)
	dacOKInterface uut (
		.rst(rst), 
		.ti_clk(ti_clk), 
		.clk(clk), 
		.din_en(din_en), 
		.din(din), 
		.set_trig(set_trig), 
		.ack_data(ack_data), 
		.ack_set(ack_set), 
		.dac_din(dac_din), 
		.dac_cs(dac_cs)
	);

	initial begin
		// Initialize Inputs
		rst = 1;
		ti_clk = 0;
		clk = 0;
		din_en = 0;
		din = 0;
		set_trig = 0;

		// Wait 100 ns for global reset to finish
		#100 rst = 0;
        
		// Add stimulus here
		#602 din_en = 1;
		din <= 8'hFF;
		#20 din <= 8'h00;
		#20 din <= 8'hAA;
		#20 din_en = 0;
		
		// After receiving ack_data
		#500 set_trig <= 1;
		#20 set_trig <= 0;

	end
	
	always
		#10 ti_clk = ~ti_clk;
		
	always
	   #50 clk = ~clk;
      
endmodule

