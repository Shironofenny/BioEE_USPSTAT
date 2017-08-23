`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:55:50 08/15/2016
// Design Name:   adcOKInterface
// Module Name:   /home/yihan/Work/ECImage/Stimulation/FPGAProject/BioEE_Costi/src/verilog/adcOKInterface_tb.v
// Project Name:  BioEECosti
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: adcOKInterface
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module adcOKInterface_tb;

	// Inputs
	reg rst;
	reg ti_clk;
	reg sclk;
	reg [15:0] din;
	reg din_en;
	reg dout_en;
	reg adc_dout;

	// Outputs
	wire [15:0] dout;
	wire adc_din;
	wire adc_sclk;
	wire adc_cs;
	wire adc_rst;
	wire buf_full;
	wire dout_clk;
	wire dout_ready;

	// Instantiate the Unit Under Test (UUT)
	adcOKInterface uut (
		.rst(rst), 
		.ti_clk(ti_clk), 
		.sclk(sclk), 
		.din(din),
		.dout(dout), 
		.dout_clk(dout_clk),
		.dout_ready(dout_ready),
		.din_en(din_en), 
		.dout_en(dout_en), 
		.adc_din(adc_din), 
		.adc_dout(adc_dout), 
		.adc_sclk(adc_sclk), 
		.adc_cs(adc_cs), 
		.adc_rst(adc_rst), 
		.buf_full(buf_full)
	);

	initial begin
		// Initialize Inputs
		rst = 1;
		ti_clk = 0;
		sclk = 0;
		din = 0;
		din_en = 0;
		dout_en = 0;
		adc_dout = 0;

		// Wait 100 ns for global reset to finish
		#100 rst = 0;
        
		// Add stimulus here
		#1202 din_en = 1;
		dout_en = 1;
		din = 16'hFFFF;
		#20 din = 16'h9FFA;
		#20 din = 16'h0000;
		#20 din_en = 0;
		
	end
	
	always
		#10 ti_clk = ~ti_clk;
	
	always 
		#25 sclk = ~sclk;
		
	always
		#5 adc_dout = adc_din;
      
endmodule

