`timescale 1ns / 1ps

`default_nettype none

module costi_bitfile(
   input  wire [7:0]  hi_in,
   output wire [1:0]  hi_out,
   inout  wire [15:0] hi_inout,
   
   output wire        i2c_sda,
   output wire        i2c_scl,
   output wire        hi_muxsel,
   
   input  wire        clk1,
   input  wire        clk2,
   output wire [7:0]  led,
   input  wire        button,

	inout  wire [57:0] xbus,
	inout  wire [57:0] ybus,

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
   	
   );


//========================================================================
// DUMMY PLACEHOLDER SIGNAL ASSIGNMENTS
//========================================================================

assign i2c_sda = 1'bz;
assign i2c_scl = 1'bz;
assign hi_muxsel = 1'b0;

//========================================================================
// GLOOOOOOOOBAAAAAAAAAL REEEEEEEEESET!!!!! c(^v^)c
//========================================================================

wire global_reset;

//========================================================================
// OPAL KELLY INTERFACE SIGNAL DECLARATIONS
//========================================================================

wire        ti_clk;
wire [30:0] ok1;
wire [16:0] ok2;

wire [15:0]	bioee_triggerin_40;
wire [15:0]	bioee_triggerout_60;
wire [15:0] bioee_wirein_00, bioee_wirein_01;
wire [15:0] bioee_wireout_20;
wire [15:0] bioee_pipein_80, bioee_pipein_81;

wire        bioee_pipein_write_80, bioee_pipein_write_81;

wire [15:0] btpipeO_adc_data;
wire        btpipeO_adc_block;
wire        btpipeO_adc_read;
wire        btpipeO_adc_ready;

//========================================================================
// OPAL KELLY INTERFACE INSTANTIATIONS
//========================================================================

// ENDPOINT ADDRESS MAP  
// Endpoint Type	Address Range	Sync/Async	Data Type	 
// Wire In          0x00 - 0x1F	Asynchronous	Signal state	   
// Wire Out         0x20 - 0x3F	Asynchronous	Signal state	   
// Trigger In       0x40 - 0x5F	Synchronous	One-shot	   
// Trigger Out      0x60 - 0x7F	Synchronous	One-shot	   
// Pipe In          0x80 - 0x9F	Synchronous	Multi-byte transfer	   
// Pipe Out         0xA0 - 0xBF	Synchronous	Multi-byte transfer	 

okHostInterface okHI(
      .hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout),
		.ti_clk(ti_clk), .ok1(ok1), .ok2(ok2));

okWireIn ep00 (.ok1(ok1), .ok2(ok2), .ep_addr(8'h00), .ep_dataout(bioee_wirein_00));
okWireIn ep01 (.ok1(ok1), .ok2(ok2), .ep_addr(8'h01), .ep_dataout(bioee_wirein_01));

okWireOut ep20 (.ok1(ok1), .ok2(ok2), .ep_addr(8'h20), .ep_datain(bioee_wireout_20));

okTriggerIn ep40 (.ok1(ok1), .ok2(ok2), .ep_addr(8'h40), 
						.ep_clk(ti_clk), .ep_trigger(bioee_triggerin_40));

okTriggerOut ep60 (.ok1(ok1), .ok2(ok2), .ep_addr(8'h60), 
						.ep_clk(ti_clk), .ep_trigger(bioee_triggerout_60));

okPipeIn ep80 (.ok1(ok1), .ok2(ok2), .ep_addr(8'h80), .ep_dataout(bioee_pipein_80), .ep_write(bioee_pipein_write_80)); 
okPipeIn ep81 (.ok1(ok1), .ok2(ok2), .ep_addr(8'h81), .ep_dataout(bioee_pipein_81), .ep_write(bioee_pipein_write_81)); 
	
okBTPipeOut epA0 (.ok1(ok1), .ok2(ok2),
	.ep_addr(8'ha0), .ep_read(btpipeO_adc_read), 
	.ep_blockstrobe(btpipeO_adc_block),  .ep_datain(btpipeO_adc_data),
	.ep_ready(btpipeO_adc_ready));

//========================================================================
// Spreadsheet (alias) for certain wires
//========================================================================

assign global_reset = bioee_wirein_00[15];

wire controlUpdateTrigger;
wire switchControl1;
wire switchControl2;
wire switchControl3;
wire switchControl4;

assign controlUpdateTrigger = bioee_triggerin_40[0];

assign switchControl1 = bioee_wirein_00[0];
assign switchControl2 = bioee_wirein_00[1];
assign switchControl3 = bioee_wirein_00[2];
assign switchControl4 = bioee_wirein_00[3];

wire [15:0] dacSWVData;
assign dacSWVData[15:0] = bioee_wirein_01[15:0];

wire dac1SetTrigger;
wire dac2SetTrigger;
wire dac2SWVSetTrigger;
wire dataUpdateTrigger, swvStartTrigger;

assign dac1SetTrigger = bioee_triggerin_40[1];
assign dac2SetTrigger = bioee_triggerin_40[1] | dac2SWVSetTrigger;
assign dataUpdateTrigger = bioee_triggerin_40[2];
assign swvStartTrigger = bioee_triggerin_40[3];

wire dac1AckDataTrigger;
wire dac1AckSetTrigger;
wire dac2AckDataTrigger;
wire dac2AckSetTrigger;

wire adcFillLevelTrigger;
wire adcFrequencyExceptionTrigger;

assign bioee_triggerout_60[0] = dac1AckDataTrigger;
assign bioee_triggerout_60[1] = dac1AckSetTrigger;
assign bioee_triggerout_60[2] = dac2AckDataTrigger;
assign bioee_triggerout_60[3] = dac2AckSetTrigger;

assign bioee_triggerout_60[4] = adcFrequencyExceptionTrigger;

assign bioee_triggerout_60[7] = adcFillLevelTrigger;

wire       dac1WriteEnable, dac2WriteEnable;
wire 		  dacSWVEnable;
wire [7:0] dac1InputData, dac2InputData;
wire [7:0] dac2Shield, dac2SWVData;

assign dac1WriteEnable     = bioee_pipein_write_81;
assign dac2WriteEnable		= (bioee_pipein_write_81 & (~dac2Shield[0])) | (dacSWVEnable & dac2Shield[0]);
assign dac1InputData [7:0] = bioee_pipein_81 [15:8];
assign dac2InputData [7:0] = (bioee_pipein_81 [7:0] & (~dac2Shield)) | ( dac2SWVData & dac2Shield );

//========================================================================
// Clock generation
//========================================================================

wire CLK100M;

dcm_sys sdramDCM (
    .CLKIN_IN(clk1), 
    .RST_IN(global_reset), 
    .CLKIN_IBUFG_OUT(), 
    .CLK0_OUT(CLK100M),
    .LOCKED_OUT() );
	 
// This DCM seems to down count the clock into 100MHz

wire sdramCLK100M = CLK100M;

// LED clock, merely a boring indicator that the program is working
wire ledCLK1Hz;
BioEE_clkdivider ledCLKDivider ( .clkin(CLK100M), 
											.integerdivider(32'd100000000), 
											.enable(1'b1),
											.clkout(ledCLK1Hz) );

// ADC clock. This is the clock feed into ADC as SCLK
wire adcCLK500K;

BioEE_clkdivider adcCLKDivider ( .clkin(CLK100M), 
											.integerdivider(32'd250), 
											.enable(1'b1),
											.clkout(adcCLK500K) );
							
// DAC clock. This is the clock feed into DAC as CLK							
wire dacCLK500K;

BioEE_clkdivider dacCLKDivider ( .clkin(CLK100M), 
											.integerdivider(32'd250), 
											.enable(1'b1),
											.clkout(dacCLK500K) );
								

//========================================================================
// I/O Mapping
//========================================================================

// All wire names with i/o direction with respect to the module,
// instead of that of the FPGA

wire dacCLK;
wire [1:0] dacDin;
wire [1:0] dacLoad;

wire adcChipSelBar;
wire adcTM;
wire adcDin;
wire adcDout;
wire adcSCLK;
wire adcResetBar;
wire [3:0] switchSel;
wire [3:0] dummyLogic;

OBUF OBUF_Y1 ( .I(dacCLK), .O(ybus[1]) );
OBUF OBUF_Y3_Y7[1:0] ( .I(dacDin[1:0]), .O({ybus[7], ybus[3]}) );
OBUF OBUF_Y5_Y9[1:0] ( .I(dacLoad[1:0]), .O({ybus[9], ybus[5]}) );
OBUF OBUF_Y19 ( .I(adcChipSelBar), .O(ybus[19]) );
OBUF OBUF_Y21 ( .I(adcTM), .O(ybus[21]) );
OBUF OBUF_Y23 ( .I(adcDin), .O(ybus[23]) );
IBUF OBUF_Y25 ( .I(ybus[25]), .O(adcDout) );
OBUF OBUF_Y27 ( .I(adcSCLK), .O(ybus[27]) );
OBUF OBUF_Y29 ( .I(adcResetBar), .O(ybus[29]) );
OBUF OBUF_Y31_Y37[3:0] ( .I(switchSel[3:0]), .O({ybus[37], ybus[31], ybus[33], ybus[35]}) );
OBUF OBUF_Y39_Y45[3:0] ( .I(dummyLogic[3:0]), .O({ybus[45], ybus[43], ybus[41], ybus[39]}) );

//========================================================================
// Control Logic
//  -- Includes the switches and dummylogic settings
//========================================================================

staticControlOKInterface switchInterface1 (
			.rst(global_reset),
			.din(switchControl1),
			.dout(switchSel[0]),
			.set_trigger(controlUpdateTrigger)
			);

staticControlOKInterface switchInterface2 (
			.rst(global_reset),
			.din(switchControl2),
			.dout(switchSel[1]),
			.set_trigger(controlUpdateTrigger)
			);

staticControlOKInterface switchInterface3 (
			.rst(global_reset),
			.din(switchControl3),
			.dout(switchSel[2]),
			.set_trigger(controlUpdateTrigger)
			);

staticControlOKInterface switchInterface4 (
			.rst(global_reset),
			.din(switchControl4),
			.dout(switchSel[3]),
			.set_trigger(controlUpdateTrigger)
			);

wire [11:0] test_wire;

assign dummyLogic[0] = test_wire[0];
assign dummyLogic[1] = dac2AckDataTrigger;
assign dummyLogic[2] = dacDin[1];
assign dummyLogic[3] = dacLoad[1];



//========================================================================
// ADC
//  -- ADC module occupies 1 input port (pipein 80) and 1 output port
//     (BTPipeOut A0). The output is through SDRAM.
//========================================================================

wire [15:0] adcOutputData;
wire        adcOutputCLK;
wire        adcOutputReady;

adcOKInterface adcController (
		.rst(global_reset),
		.ti_clk(ti_clk), 
		.sclk(adcCLK500K), 
		.din(bioee_pipein_80),
		.dout(adcOutputData), 
		.dout_clk(adcOutputCLK),
		.dout_ready(adcOutputReady),
		.din_en(bioee_pipein_write_80), 
		.dout_en(adcOutputReady),
		.adc_din(adcDin), 
		.adc_dout(adcDout), 
		.adc_sclk(adcSCLK), 
		.adc_cs(adcChipSelBar), 
		.adc_rst(adcResetBar),
		.adc_frq_exception(adcFrequencyExceptionTrigger)
		);

// Fifo buffer it through SDRAM here again (but why? everyone is doing this though.... Data rate doesn't seems to be an issue here)

BioEE_sdram_fifo sdramController(
	.datain(adcOutputData),
	.write_clk(adcOutputCLK),
	.write_en(adcOutputReady),
	
	.resetin(global_reset),
	
	.read_clk(ti_clk),
	.read_en(btpipeO_adc_read),
	.dataout(btpipeO_adc_data[15:0]),
	.read_ready(btpipeO_adc_ready),
	.fill_level_trigger(adcFillLevelTrigger),
	
	.sdram_clk(sdramCLK100M),
	.sdram_cke(sdram_cke),
	.sdram_cs_n(sdram_cs_n),
	.sdram_we_n(sdram_we_n),
	.sdram_cas_n(sdram_cas_n),
	.sdram_ras_n(sdram_ras_n),
	.sdram_ldqm(sdram_ldqm),
	.sdram_udqm(sdram_udqm),
	.sdram_ba(sdram_ba),
	.sdram_a(sdram_a),
	.sdram_d(sdram_d)
	);


//========================================================================
// DAC
//  -- DAC module occupies 1 input port (pipein 81)
//  -- Two DACs are working simutaniously, and the first DAC (controlling
//		 the two working electrodes) uses the first 8 bits from MSB, and the
//		 second DAC (controlling the RE and the reference voltage for the
//		 ADC) uses the rest of the 8 bits.
//========================================================================

assign dacCLK = dacCLK500K;

dacOKInterface dac1Controller(
						.rst( global_reset ), 
						.ti_clk( ti_clk ), 
						.clk( dacCLK ), 
						.din_en( dac1WriteEnable ), 
						.din( dac1InputData [7:0] ), 
						.set_trig( dac1SetTrigger ), 
						.ack_data( dac1AckDataTrigger ), 
						.ack_set( dac1AckSetTrigger ), 
						.dac_din( dacDin[0] ), 
						.dac_cs( dacLoad[0] )
						);
						
dacOKInterface dac2Controller(
						.rst( global_reset ), 
						.ti_clk( ti_clk ), 
						.clk( dacCLK ), 
						.din_en( dac2WriteEnable ), 
						.din( dac2InputData [7:0] ), 
						.set_trig( dac2SetTrigger ),
						.ack_data( dac2AckDataTrigger ), 
						.ack_set( dac2AckSetTrigger ), 
						.dac_din( dacDin[1] ), 
						.dac_cs( dacLoad[1] )
						);

dacSWVEngine dac2SWVModifier(
						.rst( global_reset ),
						.data_in( dacSWVData[15:0] ),
						.data_update_trig( dataUpdateTrigger ),
						.ti_clk( ti_clk ),
						.start_trig( swvStartTrigger ),
						.dac_set( dac2SWVSetTrigger ),
						.dac_data( dac2SWVData ),
						.dac_data_en( dacSWVEnable ),
						.shield( dac2Shield ),
						.disable_wire( test_wire[0] )
						);

//========================================================================
// LED indicators
//========================================================================

wire [7:0] led_signals = {	ledCLK1Hz,
									dac2Shield[0],
									test_wire[0],
									1'b0,
									1'b0,
									1'b0,
									1'b0,
									1'b0};
										
OBUF OBUF_led[7:0] ( .I(~led_signals[7:0]), .O(led[7:0]) );

endmodule




