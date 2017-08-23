`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:35:08 08/15/2016 
// Design Name: 
// Module Name:    adc_ok_interface 
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
module adcOKInterface(
    input wire rst,
    input wire ti_clk,
    input wire sclk,
    input wire [15:0] din,
    output wire [15:0] dout,
	 output wire dout_clk,
	 output wire dout_ready,
    input wire din_en,
    input wire dout_en,
    output wire adc_din,
    input wire adc_dout,
    output wire adc_sclk,
    output wire adc_cs,
    output wire adc_rst,
	 output wire adc_frq_exception
    );

assign adc_rst = ~rst;

//========================================================================
// Local Clock Generation
// --------------------------------------------------------
// The scheme of the clock goes as follows:
//        Data input 16      -> Mid stage 8 -> ADC Data in
// ti_clk (48M), random data ->   1/8 SCLK  -> SCLK
// --------------------------------------------------------
// ADC Data out -> Mid stage 8 ->  SDRAM storage
//      SCLK    ->   1/8 SCLK  ->  1/16 SCLK
// --------------------------------------------------------
// One possible problem with this scheme is that if ADC control data
// (data input 16bit) overflows the FIFO of the first stage. Since SCLK
// has a maximum frequency of 20MHz, this might happen (20M/8 << 48M).
// However, the design choice is still made so, since the ADC should be
// configured only once every 16~18 SCLK cycles (see datasheet). There
// must exist a way to solve this potential overflow problem.
//========================================================================

wire sclk1F8;
wire sclk1F16;
wire sclkBar;
wire dout_empty;

assign sclkBar = ~sclk;
assign dout_clk = sclk1F16;
assign dout_ready = ~dout_empty;
assign adc_sclk = sclk;

BioEE_clkdivider divider1F8 ( .clkin(sclk), 
										.integerdivider(32'd8), 
										.enable(1'b1),
										.clkout(sclk1F8) );
										
BioEE_clkdivider divider1F16 ( .clkin(sclk), 
										 .integerdivider(32'd16), 
										 .enable(1'b1),
										 .clkout(sclk1F16) );

//========================================================================
// Data input-output flow
//========================================================================

wire adc_rd_en;
wire adc_wr_en;
wire fifoInEmpty;
wire fifoOutFull;
wire fifoDout;
wire bufferFull;

wire adcOutFifoRst;
wire adcOutFifoManualRst;
wire [9:0] wr_data_count;

reg adc_rd_en_reg;
reg adc_wr_en_reg;
reg adc_cs_reg;
reg [4:0] cycleCounter;

reg adc_frq_exception_reg;
reg adcOutFifoManualRst_reg;

assign adc_cs = adc_cs_reg;
assign adc_rd_en = adc_rd_en_reg;
assign adc_wr_en = adc_wr_en_reg;
assign adc_frq_exception = adc_frq_exception_reg;

assign adcOutFifoManualRst = adcOutFifoManualRst_reg;

initial begin
	cycleCounter <= 5'd0;
	adc_rd_en_reg <= 1'b0;
	adc_wr_en_reg <= 1'b0;
	adc_cs_reg <= 1'b1;
	adc_frq_exception_reg <= 1'b0;
	adcOutFifoManualRst_reg <= 1'b0;
end

// The following pseudo-FSM generates the control signal CS, as well as
// Data input of the ADC by shielding the fifo output using rd_en.

always @(posedge sclk or posedge rst) begin
	if (rst) begin
		adc_rd_en_reg <= 1'b0;
		adc_wr_en_reg <= 1'b0;
		adc_cs_reg <= 1'b1;
		cycleCounter <= 5'd0;
		adc_frq_exception_reg <= 1'b0;
		adcOutFifoManualRst_reg <= 1'b0;
	end else begin
		if (cycleCounter == 5'd0) begin
			adc_cs_reg <= 0;
			if (!fifoInEmpty)
				adc_rd_en_reg <= 1'b1;
			if (!fifoOutFull)
				adc_wr_en_reg <= 1'b1;
			cycleCounter <= cycleCounter + 5'd1;
		end
		else if (cycleCounter == 5'd16) begin
			adc_cs_reg <= 1'b1;
			adc_rd_en_reg <= 1'b0;
			adc_wr_en_reg <= 1'b0;
			cycleCounter <= cycleCounter + 5'd1;
		end
		else if (cycleCounter == 5'd19) begin
			if (wr_data_count[2:0] != 3'b000) begin
				adcOutFifoManualRst_reg <= 1'b1;
				adc_frq_exception_reg <= 1'b1;
				cycleCounter <= cycleCounter + 5'd1;
			end else begin
				cycleCounter <= 5'd0;
			end
		end
		else if (cycleCounter == 5'd25) begin
			cycleCounter <= 5'd0;
			adcOutFifoManualRst_reg <= 1'b0;
			adc_frq_exception_reg <= 1'b0;
		end 
		else begin
			cycleCounter <= cycleCounter + 5'd1;
		end
	end
end

fifo_w16_r1_64 adcDataInBuffer (
			.rst(rst),
			.wr_clk(ti_clk),
			.md_clk(sclk1F8),
			.rd_clk(sclk),
			.din(din),
			.wr_en(din_en),
			.rd_en(adc_rd_en),
			.dout(fifoDout),
			.full(bufferFull),
			.empty(fifoInEmpty)
			);
			
assign adc_din = fifoDout & adc_rd_en;

// The following code uses adc_cs as the wr_en of the read FIFO. The clock 
// used here is the inversion of SCLK. This should cause nothing but a 90
// degree shift in the first stage of the FIFO. This should not be a problem.

fifo_w1_r16_1024 adcDataOutBuffer (
			.rst(rst),
			.wr_clk(sclkBar),
			.md_clk(sclk1F8),
			.rd_clk(sclk1F16),
			.din(adc_dout),
			.wr_en(adc_wr_en),
			.rd_en(dout_en),
			.dout(dout),
			.full(fifoOutFull),
			.empty(dout_empty),
			.wr_data_count(wr_data_count)
			);

endmodule
