module systemTop (
    input iTopClk,
    input iTopRst_neg,
    output [7:0] oLedGreen,
    input [7:0] iDipSwitch,
    inout ioBufTwiVideoSda,
    output oBufTwiVideoScl,
    input iVgaClk,
    input iVgaHsync,
    input iVgaVsync,
    input [7:0] iVgaDataRed,
    input [7:0] iVgaDataGreen,
    input [7:0] iVgaDataBlue,
    output oDviClk_p,
    output oDviClk_n,
    output oDviRst,
    output oDviDe,
    output oDviHsync,
    output oDviVsync,
    output [11:0] oDviData
);

wire iTopRst = ~iTopRst_neg;

wire sysClk;
wire sysRst;
wire iSysTwiVideoSda;
wire oSysTwiVideoSda;
wire oSysTwiVideoScl;
wire [31:0] sysVideoStatus;
wire [31:0] sysVideoControl;

wire videoClk_0;
wire videoClk_90;
wire videoClk2x_0;
wire videoClk2x_90;
wire videoClk2x_180;
wire videoClkLocked;
wire videoRst;
wire dviRst;

assign sysClk = iTopClk;
assign sysRst = iTopRst;
(* BOX_TYPE = "user_black_box" *) system systemInst (
    .i_system_clk(sysClk),
    .i_system_rst(sysRst),
    .i_system_gpio(iDipSwitch[3:0]),
    .o_system_gpio(oLedGreen[3:0]),
    .i_system_twi_video_sda(iSysTwiVideoSda),
    .o_system_twi_video_sda(oSysTwiVideoSda),
    .o_system_twi_video_scl(oSysTwiVideoScl),
    .i_system_gpio_video(sysVideoStatus),
    .o_system_gpio_video(sysVideoControl)
);
IOBUF instBufSda (
    .O(iSysTwiVideoSda),
    .IO(ioBufTwiVideoSda),
    .I(oSysTwiVideoSda),
    .T(oSysTwiVideoSda)
);
OBUFT instBufScl (
    .O(oBufTwiVideoScl),
    .I(oSysTwiVideoScl),
    .T(oSysTwiVideoScl)
);

videoClkPll instance_name (
    .CLKIN1_IN(iVgaClk), 
    .RST_IN(videoRst), 
    .CLKOUT0_OUT(videoClk_0), 
    .CLKOUT1_OUT(videoClk_90), 
    .CLKOUT2_OUT(videoClk2x_0), 
    .CLKOUT3_OUT(videoClk2x_90), 
    .CLKOUT4_OUT(videoClk2x_180), 
    .LOCKED_OUT(videoClkLocked)
);

assign videoRst = iTopRst | sysVideoControl[0];
assign dviRst = videoRst | ~videoClkLocked | sysVideoControl[1];
assign oDviRst = ~videoRst;
assign oDviClk_p = videoClk2x_0;
assign oDviClk_n = videoClk2x_180;
assign sysVideoStatus = {28'b0, videoClkLocked, dviRst, videoRst};
assign oLedGreen[7:4] = {3'b0, videoClkLocked};

dviOutStreamer #(
    .H_ACTIVE_COUNT(800),
    .H_FRONT_PORCH(40),
    .H_SYNC(128),
    .H_BACK_PORCH(88),
    .V_ACTIVE_COUNT(600),
    .V_FRONT_PORCH(1),
    .V_SYNC(4),
    .V_BACK_PORCH(23)
) dviOutStreamerInst (
    .iClk_0(videoClk2x_0),
    .iClk_90(videoClk2x_90),
    .iRst(dviRst),
    .oData(oDviData),
    .oHsync(oDviHsync),
    .oVsync(oDviVsync),
    .oDe(oDviDe)
);

endmodule


