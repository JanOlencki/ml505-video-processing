module systemTop (
    input iTopClk,
    input iTopRst_neg,
    inout [0:7] iobufSysGpio,
    inout ioBufSysTwi0Sda,
    output oBufSysTwi0Scl,
    output oDviRst,
    output [11:0] oDviData,
    output oDviClk_p,
    output oDviClk_n,
    output oDviHsync,
    output oDviVsync,
    output oDviDe
);

wire iTopRst = ~iTopRst_neg;
wire topClkPllLocked;

wire sysClk;
wire sysRst;
wire [0:7] iSysGpio;
wire [0:7] oSysGpio;
wire [0:7] tSysGpio;
wire iSysTwi0Sda;
wire oSysTwi0Sda;
wire oSysTwi0Scl;

wire videoRst;
wire videoClk_0;
wire videoClk_90;
wire videoClk_180;

topClkPll topClkPllInst (
    .CLKIN_IN(iTopClk), 
    .RST_IN(iTopRst), 
    .CLKIN_IBUFG_OUT(sysClk), 
    .CLKOUT0_OUT(videoClk_0), 
    .CLKOUT1_OUT(videoClk_90), 
    .CLKOUT2_OUT(videoClk_180), 
    .LOCKED_OUT(topClkPllLocked)
);

assign sysRst = iTopRst;
(* BOX_TYPE = "user_black_box" *) system systemInst (
    .i_system_clk(sysClk),
    .i_system_rst(sysRst),
    .i_system_gpio(iSysGpio),
    .o_system_gpio(oSysGpio),
    .t_system_gpio(tSysGpio),
    .i_system_twi_0_sda(iSysTwi0Sda),
    .o_system_twi_0_sda(oSysTwi0Sda),
    .o_system_twi_0_scl(oSysTwi0Scl)
);

genvar i;
generate
    for(i = 0; i < 8; i = i+1) begin : instantiationBufGpio
        IOBUF instBufGpio (
            .O(iSysGpio[i]),
            .IO(iobufSysGpio[i]),
            .I(oSysGpio[i]),
            .T(tSysGpio[i])
        );
    end
endgenerate
IOBUF instBufSda (
    .O(iSysTwi0Sda),
    .IO(ioBufSysTwi0Sda),
    .I(oSysTwi0Sda),
    .T(oSysTwi0Sda)
);
OBUFT instBufScl (
    .O(oBufSysTwi0Scl),
    .I(oSysTwi0Scl),
    .T(oSysTwi0Scl)
);

assign videoRst = iTopRst | ~topClkPllLocked;
assign oDviRst = ~videoRst;
assign oDviClk_p = videoClk_0;
assign oDviClk_n = videoClk_180;

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
    .iClk_0(videoClk_0),
    .iClk_90(videoClk_90),
    .iRst(videoRst),
    .oData(oDviData),
    .oHsync(oDviHsync),
    .oVsync(oDviVsync),
    .oDe(oDviDe)
);

endmodule


