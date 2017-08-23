`default_nettype none
`timescale 1ns / 1ps

module fifo16w16r_2048(
	input  [15:0] din,
	input         rd_clk,
	input         rd_en,
	input         rst,
	input         wr_clk,
	input         wr_en,
	output [15:0] dout,
	output        empty,
	output        full,
	output [10:0] rd_data_count,
	output [10:0] wr_data_count
);
// synthesis attribute box_type fifo16w16r_2048 "black_box"
endmodule

module BioEE_sdram_fifo (
	
	input wire			resetin,
	
	input wire				write_clk,
	input wire [15:0] 	datain,
	input wire				write_en,
	
	input wire				read_clk,
	output wire [15:0]	dataout,
	input wire				read_en,
	output wire 			read_ready,
	
	output wire				fill_level_trigger,
	
	// ---------------------------------
	
	input  wire        sdram_clk,

	output wire        sdram_cke,
	output wire        sdram_cs_n,
	output wire        sdram_we_n,
	output wire        sdram_cas_n,
	output wire        sdram_ras_n,
	output wire        sdram_ldqm,
	output wire        sdram_udqm,
	output wire [1:0]  sdram_ba,
	output wire [12:0] sdram_a,
	inout  wire [15:0] sdram_d
   
	// ---------------------------------
	
	);


reg         sdramreset;

reg         sdram_rden;
reg         sdram_wren;

// SDRAM controller / negotiator connections
reg         cmd_pageread;
reg         cmd_pagewrite;
wire        cmd_ack;
wire        cmd_done;
reg  [14:0] rowaddr;

// SDRAM controller / FIFO connections.
wire [15:0] infifo_dout;
wire        infifo_read;
wire [10:0] infifo_status;
wire        infifo_empty;
wire        infifo_full;

wire [15:0] outfifo_din;
wire			outfifo_write;
wire [10:0] outfifo_status;
wire        outfifo_empty;
wire        outfifo_full;

reg         fault_ofull, fault_ifull, fault_oempty, fault_iempty;

assign sdram_cke = 1'b1;
assign sdram_ldqm = 1'b0;
assign sdram_udqm = 1'b0;

//assign read_ready = ~outfifo_empty;
assign read_ready = (outfifo_status[10:0] >= 11'd1024);

reg [14:0]	sdram_write_rowaddr;
reg [14:0]	sdram_read_rowaddr;




//assign led = ~{4'b0000, fault_ofull, fault_ifull, fault_oempty, fault_iempty};


// These signals come in on TI_CLK from the host interface.  We need
// to make sure to resynchronize them to our state machine clock or
// things strange things can happen (like hopping to unexpected states).
always @(negedge sdram_clk) begin
	//sdram_rden <= ep00wire[0];
	sdram_rden <= 1;
	//sdram_wren <= ep00wire[1];
	sdram_wren <= 1;
	sdramreset <= resetin;

end


// These will register a fault:
//   - Read from a FIFO that is empty
//   - Write to a FIFO that is full
// Since the Host Interface is operating at 48 MHz and the SDRAM is
// much faster than that, it should easily be able to keep up with 
// the PC transfers, so these faults should never occur.
/*
always @(negedge sdram_clk) begin
	if (sdramreset == 1'b1) begin
		fault_ofull <= 1'b0;
		fault_iempty <= 1'b0;
	end else begin
		if ((c0_fifo_write == 1'b1) && (outfifo_full == 1'b1)) begin
			fault_ofull <= 1'b1;
		end
		if ((c0_fifo_read == 1'b1) && (infifo_empty == 1'b1)) begin
			fault_iempty <= 1'b1;
		end
	end
end
*/

/*
always @(posedge write_clk) begin
	if (sdramreset == 1'b1) begin
		fault_ifull <= 1'b0;
		fault_oempty <= 1'b0;
	end else begin
		if ((infifo_write == 1'b1) && (infifo_full == 1'b1)) begin
			fault_ifull <= 1'b1;
		end
		if ((outfifo_read == 1'b1) && (outfifo_empty == 1'b1)) begin
			fault_oempty <= 1'b1;
		end
	end
end
*/

//------------------------------------------------------------------------
// SDRAM transfer negotiator
//   This block handles communication between the SDRAM controller and
//   the FIFOs.  The FIFOs act as a simplified cache, holding at least
//   a full page on-chip while the PC reads the FIFO.  This dramatically
//   increases DRAM access performance since full pages can be read very
//   quickly.  Since the PC transfers are slower than the DRAM, there is
//   no fear of underrun.
//------------------------------------------------------------------------
parameter n_idle = 0,
          n_wackwait = 1,
          n_rackwait = 2,
			 n_busy = 3;
integer staten;
always @(negedge sdram_clk) begin
	if (sdramreset == 1'b1) begin
		staten <= n_idle;
		cmd_pagewrite <= 1'b0;
		cmd_pageread <= 1'b0;
		rowaddr <= 15'h0000;
		sdram_read_rowaddr <= 15'h0000;
		sdram_write_rowaddr <= 15'h0000;
	end else begin
		cmd_pagewrite <= 1'b0;
		cmd_pageread <= 1'b0;

		case (staten)
			n_idle: begin
				staten <= n_idle;

				//if (sdram_write_rowaddr > 15'h2000) begin
				//	sdram_write_rowaddr <= sdram_write_rowaddr - 15'h1000;
				//	sdram_read_rowaddr <= sdram_read_rowaddr - 15'h1000;
				//end


				// If SDRAM WRITEs are enabled, trigger a block write whenever
				// the Pipe In buffer is at least 1/4 full (1 page, 512 words).
				if ((sdram_wren == 1'b1) && (infifo_status[10:7] >= 4'b0100)) begin
					staten <= n_wackwait;
					rowaddr <= sdram_write_rowaddr;
				end

				// If SDRAM READs are enabled, trigger a block read whenever
				// the Pipe Out buffer has room for at least 1 page (512 words).
				else if ((sdram_write_rowaddr != sdram_read_rowaddr) && (sdram_rden == 1'b1) && (outfifo_status[10:7] <= 4'b1000)) begin
					staten <= n_rackwait;
					rowaddr <= sdram_read_rowaddr;
				end
			end


			n_wackwait: begin
				cmd_pagewrite <= 1'b1;
				staten <= n_wackwait;
				if (cmd_ack == 1'b1) begin
					rowaddr <= rowaddr + 1;
					sdram_write_rowaddr <= sdram_write_rowaddr + 1;
					staten <= n_busy;
				end
			end
			

			n_rackwait: begin
				cmd_pageread <= 1'b1;
				staten <= n_rackwait;
				if (cmd_ack == 1'b1) begin
					rowaddr <= rowaddr + 1;
					sdram_read_rowaddr <= sdram_read_rowaddr + 1;
					staten <= n_busy;
				end
			end
			

			n_busy: begin
				staten <= n_busy;
				if (cmd_done == 1'b1) begin
					staten <= n_idle;
				end
			end

		endcase
	end
end


//------------------------------------------------------------------------
//------------------------------------------------------------------------

// how many kbytes to fill before triggering? Was 15'd32
// And I (Yihan Zhang) thought it is too high for real time updates, so I changed it to 1
assign fill_level_trigger = ((sdram_write_rowaddr-sdram_read_rowaddr) > 15'd1);


//------------------------------------------------------------------------
// SDRAM CONTROLLER
//------------------------------------------------------------------------
sdramctrl c0 (
		.clk(~sdram_clk),
		.clk_read(~sdram_clk),
		.reset(sdramreset),
		.cmd_pagewrite(cmd_pagewrite),
		.cmd_pageread(cmd_pageread),
		.cmd_ack(cmd_ack),
		.cmd_done(cmd_done),
		.rowaddr_in(rowaddr),
		.fifo_din(infifo_dout),
		.fifo_read(infifo_read),
		.fifo_dout(outfifo_din),
		.fifo_write(outfifo_write),
		.sdram_cmd({sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n}),
		.sdram_ba(sdram_ba),
		.sdram_a(sdram_a),
		.sdram_d(sdram_d));





//------------------------------------------------------------------------
// OUTSIDE FIFOS
//------------------------------------------------------------------------
fifo16w16r_2048 infifo (
		.rst(sdramreset), .rd_data_count(infifo_status), .wr_data_count(),
		.empty(infifo_empty), .full(infifo_full),
		.wr_clk(write_clk), .wr_en(write_en), .din(datain),
		.rd_clk(~sdram_clk), .rd_en(infifo_read), .dout(infifo_dout));

fifo16w16r_2048 outfifo (
		.rst(sdramreset), .rd_data_count(), .wr_data_count(outfifo_status),
		.empty(outfifo_empty), .full(outfifo_full),
		.wr_clk(~sdram_clk), .wr_en(outfifo_write), .din(outfifo_din),
		.rd_clk(read_clk), .rd_en(read_en), .dout(dataout));

endmodule
