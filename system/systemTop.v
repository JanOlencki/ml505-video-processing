//-----------------------------------------------------------------------------
// system_top.v
//-----------------------------------------------------------------------------

module systemTop (
    input iSysClk,
    input iSysRst,
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

wire [0:7] iSysGpio;
wire [0:7] oSysGpio;
wire [0:7] tSysGpio;

wire iSysTwi0Sda;
wire oSysTwi0Sda;
wire oSysTwi0Scl;

(* BOX_TYPE = "user_black_box" *) system instSystem (
    .i_system_clk(iSysClk),
    .i_system_rst(iSysRst),
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

assign oDviData = 0;
assign oDviRst = iSysRst;
assign oDviClk_p = iSysClk;
assign oDviClk_n = ~iSysClk;
assign oDviHsync = 0;
assign oDviVsync = 0;
assign oDviDe = 0;

endmodule


