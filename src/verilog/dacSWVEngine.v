`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:19:53 09/13/2016 
// Design Name: 
// Module Name:    dacSWVEngine 
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
module dacSWVEngine(
    input rst,
    input [15:0] data_in,
    input data_update_trig,
    input ti_clk,
	 input start_trig,
    output dac_set,
    output [7:0] dac_data,
    output dac_data_en,
    output [7:0] shield,
	 output disable_wire
    );

reg [12*4-1 : 0] data_register;
reg [16*3-1 : 0] control_register;
reg waiting_data;
reg [2:0] data_address;
reg [7:0] shield_reg;
reg [7:0] dac_data_reg;
reg dac_data_en_reg;
reg [1:0] swv_state;
reg [31:0] time_counter;
reg [15:0] step_counter;
reg enable_reg;
reg disable_reg;
reg [11:0] re_voltage_reg;
reg dac_set_reg;

wire [11:0] adc_ref = data_register[12*4-1 : 12*3];
wire [11:0] e_init = data_register[12*3-1 : 12*2];
wire [11:0] e_raise = data_register[12*2-1 : 12*1];
wire [11:0] e_fall = data_register[12*1-1 : 12*0];

wire [31:0] time_max = control_register[16*3-1 : 16*1];
wire [15:0] step_max = control_register[16*1-1 : 16*0];

wire [11:0] re_voltage = re_voltage_reg[11:0];

wire init_block = waiting_data;
assign disable_wire = disable_reg;
wire enable = enable_reg & ( ~ disable_wire );

assign shield [7:0] = shield_reg [7:0];
assign dac_data [7:0] = dac_data_reg [7:0];
assign dac_data_en = dac_data_en_reg;
assign dac_set = dac_set_reg;

initial begin
	data_register <= 48'd0;
	control_register <= 48'd0;
	waiting_data <= 1'b0;
	data_address <= 3'd0;
	shield_reg <= 8'h00;
	dac_data_reg <= 8'h00;
	dac_data_en_reg <= 1'b0;
	time_counter <= 16'd0;
	step_counter <= 16'd0;
	enable_reg <= 1'b0;
	disable_reg <= 1'b0;
	re_voltage_reg <= 12'd0;
	swv_state <= 2'd0;
	dac_set_reg <= 1'b0;
end

always @ (posedge start_trig or posedge rst or posedge disable_wire) begin
	if (rst) begin
		enable_reg <= 1'b0;
		shield_reg <= 8'h00;
	end else if (disable_wire == 1'b1) begin
		enable_reg <= 1'b0;
		shield_reg <= 8'h00;
	end else if (init_block == 1'b0) begin
		enable_reg <= 1'b1;
		shield_reg <= 8'hFF;
	end
end

always @ (negedge ti_clk or posedge rst) begin
	if (rst) begin
		dac_data_reg <= 8'h00;
		dac_data_en_reg <= 1'b0;
		time_counter <= 32'd0;
		step_counter <= 16'd0;
		re_voltage_reg <= 12'd0;
		swv_state <= 2'd0;
		disable_reg <= 1'b0;
		dac_set_reg <= 1'b0;
	end else begin
		if (enable) begin
			time_counter <= time_counter + 16'd1;
			if (time_counter == 32'd1) begin
				case(swv_state)
					// rise
					2'd0 : begin
						if (step_counter == 16'd0) begin
							re_voltage_reg <= e_init;
						end else begin
							re_voltage_reg <= re_voltage_reg + e_raise;
							swv_state <= 2'd1;
						end
					end
					// fall
					2'd1 : begin
						re_voltage_reg <= re_voltage_reg - e_fall;
						swv_state <= 2'd0;
					end
				endcase
			end else if (time_counter == time_max - 32'd1000) begin
				dac_data_reg <= re_voltage[11:4];
				dac_data_en_reg <= 1'b1;
			end else if (time_counter == time_max - 32'd999) begin
				dac_data_reg <= {re_voltage[3:0], adc_ref[11:8]};
			end else if (time_counter == time_max - 32'd998) begin
				dac_data_reg <= adc_ref[7:0];
			end else if (time_counter == time_max - 32'd997) begin
				dac_data_en_reg <= 1'b0;
			end else if (time_counter == time_max - 32'd2) begin
				dac_set_reg <= 1'b1;
			end else if (time_counter == time_max) begin
				dac_set_reg <= 1'b0;
				time_counter <= 32'd0;
				step_counter <= step_counter + 16'd1;
				if (step_counter == step_max ) begin
					disable_reg <= 1'b1;
					step_counter <= 16'd0;
					swv_state <= 1'b0;
				end
			end
		end else begin
			disable_reg <= 1'b0;
		end
	end
end

always @ (posedge data_update_trig or posedge rst) begin
	if (rst) begin
		waiting_data <= 1'b0;
		data_address <= 3'd0;
		data_register <= 48'd0;
		control_register <= 48'd0;
	end else begin
		case(data_address)
			3'd0 : begin
				data_register[12*4-1 : 12*3] <= data_in[11:0];
				waiting_data <= 1'b1;
				data_address <= 3'd1;
			end
			3'd1: begin
				data_register[12*3-1 : 12*2] <= data_in[11:0];
				data_address <= 3'd2;
			end
			3'd2: begin
				data_register[12*2-1 : 12*1] <= data_in[11:0];
				data_address <= 3'd3;
			end
			3'd3: begin
				data_register[12*1-1 : 12*0] <= data_in[11:0];
				data_address <= 3'd4;
			end
			3'd4: begin
				control_register[16*3-1 : 16*2] <= data_in[15:0];
				data_address <= 3'd5;
			end
			3'd5: begin
				control_register[16*2-1 : 16*1] <= data_in[15:0];
				data_address <= 3'd6;
			end
			3'd6: begin
				control_register[16*1-1 : 16*0] <= data_in[15:0];
				data_address <= 3'd0;
				waiting_data <= 1'b0;
			end
		endcase
	end
end

endmodule
