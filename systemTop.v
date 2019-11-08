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

localparam H_ACTIVE = 800;
localparam H_FRONT_PORCH = 40;
localparam H_SYNC = 128;
localparam H_BACK_PORCH = 88;
localparam H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH;
localparam V_ACTIVE = 600;
localparam V_FRONT_PORCH = 1;
localparam V_SYNC = 4;
localparam V_BACK_PORCH = 23;
localparam V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH;

wire iTopRst = ~iTopRst_neg;

wire sysClk;
wire sysRst;
wire iSysTwiVideoSda;
wire oSysTwiVideoSda;
wire oSysTwiVideoScl;
wire [31:0] sysVideoStatus;
wire [31:0] sysVideoControl;

wire videoClk2x_0;
wire videoClk2x_90;
wire videoClk2x_270;
wire videoClkLocked;
wire videoRstHard;
wire videoRstSoft;
wire dviTestData;
wire vgaSync, vgaActive;
wire [7:0] vgaDataRed, vgaDataGreen, vgaDataBlue;
wire dviSync, dviActive;
wire [7:0] dviDataRed, dviDataGreen, dviDataBlue;

assign sysClk = iTopClk;
assign sysRst = iTopRst;
(* BOX_TYPE = "user_black_box" *) system systemInst (
    .i_system_clk(sysClk),
    .i_system_rst(sysRst),
    .i_system_gpio(iDipSwitch[3:0]),
    .o_system_gpio(oLedGreen[3:0]),
    .i_system_gpio_oloop(oLedGreen[3:0]),
    .i_system_twi_video_sda(iSysTwiVideoSda),
    .o_system_twi_video_sda(oSysTwiVideoSda),
    .o_system_twi_video_scl(oSysTwiVideoScl),
    .i_system_gpio_video(sysVideoStatus),
    .o_system_gpio_video(sysVideoControl),
    .i_system_gpio_video_oloop(sysVideoControl)
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

videoClkPll videoClkPllInst (
    .CLKIN1_IN(iVgaClk), 
    .RST_IN(videoRstHard), 
    .CLKOUT0_OUT(videoClk2x_0), 
    .CLKOUT1_OUT(videoClk2x_90), 
    .CLKOUT2_OUT(videoClk2x_270),
    .LOCKED_OUT(videoClkLocked)
);
assign videoRstHard = iTopRst | sysVideoControl[0];
assign videoRstSoft = videoRstHard | ~videoClkLocked | sysVideoControl[1] | iDipSwitch[5];
assign oDviRst = ~videoRstHard;
assign oDviClk_p = videoClk2x_90;
assign oDviClk_n = videoClk2x_270;
assign sysVideoStatus = {28'b0, videoClkLocked, videoRstSoft, videoRstHard};
assign oLedGreen[7:4] = {2'b0, videoRstSoft, videoClkLocked};
assign dviTestData = sysVideoControl[2] | iDipSwitch[4];

vgaReceiver #(
    .H_ACTIVE(H_ACTIVE),
    .H_TOTAL(H_TOTAL),
    .V_ACTIVE(V_ACTIVE),
    .V_TOTAL(V_TOTAL)
) vgaReceiverInst (
    .iClk(videoClk2x_0),
    .iRst(videoRstSoft),
    .iHsync(iVgaHsync),
    .iVsync(iVgaVsync),
    .iDataRed(iVgaDataRed),
    .iDataGreen(iVgaDataGreen),
    .iDataBlue(iVgaDataBlue),
    .iHsyncOffset(sysVideoControl[31:21]),
    .iVsyncOffset(sysVideoControl[20:11]),
    .oPixelSync(vgaSync),
    .oPixelActive(vgaActive),
    .oDataRed(vgaDataRed),
    .oDataGreen(vgaDataGreen),
    .oDataBlue(vgaDataBlue)
);

videoTestData #(
    .H_ACTIVE(H_ACTIVE),
    .H_TOTAL(H_TOTAL),
    .V_ACTIVE(V_ACTIVE),
    .V_TOTAL(V_TOTAL)
) videoTestDataInst (
    .iClk(videoClk2x_0),
    .iRst(videoRstSoft),
    .iPixelSync(vgaSync),
    .iPixelActive(vgaActive),
    .iDataRed(vgaDataRed),
    .iDataGreen(vgaDataGreen),
    .iDataBlue(vgaDataBlue),
    .iTestData(dviTestData),
    .oPixelSync(dviSync),
    .oPixelActive(dviActive),
    .oDataRed(dviDataRed),
    .oDataGreen(dviDataGreen),
    .oDataBlue(dviDataBlue)
);

dviTransmitter #(
    .H_ACTIVE(H_ACTIVE),
    .H_FRONT_PORCH(H_FRONT_PORCH),
    .H_SYNC(H_SYNC),
    .H_BACK_PORCH(H_BACK_PORCH),
    .V_ACTIVE(V_ACTIVE),
    .V_FRONT_PORCH(V_FRONT_PORCH),
    .V_SYNC(V_SYNC),
    .V_BACK_PORCH(V_BACK_PORCH)
) dviTransmitterInst (
    .iClk(videoClk2x_0),
    .iRst(videoRstSoft),
    .iPixelSync(dviSync),
    .iPixelActive(dviActive),
    .iDataRed(dviDataRed),
    .iDataGreen(dviDataGreen),
    .iDataBlue(dviDataBlue),
    .oData(oDviData),
    .oHsync(oDviHsync),
    .oVsync(oDviVsync),
    .oDe(oDviDe)
);
endmodule
