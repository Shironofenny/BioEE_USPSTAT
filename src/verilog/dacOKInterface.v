`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:51:26 08/16/2016 
// Design Name: 
// Module Name:    dacOKInterface 
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
module dacOKInterface(
    input wire rst,
    input wire ti_clk,
    input wire clk,
    input wire din_en,
    input wire [7:0] din,
    input wire set_trig,
    output wire ack_data,
    output wire ack_set,
    output wire dac_din,
    output wire dac_cs
    );
	 
	 // Internal signal lines
	 wire fifo_rd_en;
	 wire fifo_empty;
	 wire fifo_dcount3_bar;
	 wire clear_set_status;
	 
	 // Registers
	 reg dac_cs_reg;
	 reg fifo_rd_en_reg;
	 reg ack_standby_data_reg;
	 reg ack_data_reg;
	 reg ack_standby_set_reg;
	 reg ack_set_reg;
	 reg set_reg;
	 reg clear_set_status_reg;
	 reg [5:0] cycleCounter;
	 
	 // Assigning the signals to corresponding registers
	 assign ack_data = ack_data_reg;
	 assign ack_set = ack_set_reg;
	 assign fifo_rd_en = fifo_rd_en_reg;
	 assign clear_set_status = clear_set_status_reg;
	 
	 // Linking the output clock
	 assign dac_cs = dac_cs_reg;
	 
	 // Initialization and reset behavior
	 initial begin
		dac_cs_reg <= 1'b1;
		fifo_rd_en_reg <= 1'b0;
		ack_data_reg <= 1'b0;
		ack_set_reg <= 1'b0;
		set_reg <= 1'b0;
		cycleCounter <= 6'd0;
		ack_standby_data_reg <= 1'b0;
		ack_standby_set_reg <= 1'b0;
		clear_set_status_reg <= 1'b0;
	 end
	 
	 // Reset output triggers at the rising edge of ti_clk
	 always @ (posedge ti_clk or posedge rst) begin
		// Check if reset is requested
		if (rst) begin			
			ack_data_reg <= 1'b0;
			ack_set_reg <= 1'b0;
			ack_standby_data_reg <= 1'b0;
			ack_standby_set_reg <= 1'b0;
			set_reg <= 1'b0;
		end else begin
			if (din_en == 1'b1) begin
				ack_standby_data_reg <= 1'b1;
			end
			if (set_trig == 1'b1) begin
				ack_standby_set_reg <= 1'b1;
			end
			// Reset output triggers at the rising edge of ti_clk
			if (ack_data_reg == 1'b1) begin
				ack_data_reg <= 1'b0;
			end else begin
			// If data stored reaches 3, enable data acknowledge 
				if (fifo_dcount3_bar == 1'b0 && ack_standby_data_reg == 1'b1) begin
					ack_data_reg <= 1'b1;
					ack_standby_data_reg <= 1'b0;
				end
			end
			if (ack_set_reg == 1'b1) begin
			// Reset output triggers at the rising edge of ti_clk
				ack_set_reg <= 1'b0;
			end else begin
				if (clear_set_status == 1'b1 && ack_standby_set_reg == 1'b1) begin
			// If no data is stored, enable data acknowledge 
					ack_set_reg <= 1'b1;
					set_reg <= 1'b0;
					ack_standby_set_reg <= 1'b0;
				end
			end	
			// If a set trigger is received, configure the system into setting mode
			if (set_trig == 1'b1) begin
				set_reg <= 1'b1;
			end
		end
	 end

	 // Since all data are sampled at the positive edge of the clock,
	 // This module is programmed according to the negative edge of the clock
	 // So ideally no change should happen at the rising edge
	 always @ (negedge clk or posedge rst) begin
		if (rst) begin
			cycleCounter <= 6'd0;
			dac_cs_reg <= 1'b1;
			fifo_rd_en_reg <= 1'b0;
			clear_set_status_reg <= 1'b0;
		end else begin
			if (set_reg == 1'b1) begin
				if (cycleCounter == 6'd0) begin
					fifo_rd_en_reg <= 1'b1;
					cycleCounter <= cycleCounter + 6'd1;
				end else if (cycleCounter == 6'd1) begin
					dac_cs_reg <= 1'b0;
					cycleCounter <= cycleCounter + 6'd1;
				end else if (cycleCounter >= 6'd25) begin
					dac_cs_reg <= 1'b1;
					fifo_rd_en_reg <= 1'b0;
					cycleCounter <= 6'd0;
					clear_set_status_reg <= 1'b1;
				end else begin 
					cycleCounter <= cycleCounter + 6'd1;
				end
			end
			else
				clear_set_status_reg <= 1'b0;
		end
	 end
	 
	 // Data buffer. Program empty will be high until it has 3 data in it.
	 fifo_w8_r1_32 dacFifo (
						.rst(rst),
						.wr_clk(ti_clk),
						.rd_clk(~clk), // The data needs to be positive edge stable
						.din(din),
						.wr_en(din_en),
						.rd_en(fifo_rd_en),
						.dout(dac_din),
						.full(),
						.empty(fifo_empty),
						.prog_empty(fifo_dcount3_bar)
						);


endmodule
