//-----------------------------------------------------------------------------
// system_top.v
//-----------------------------------------------------------------------------

module systemTop (
   input i_system_clk,
   input i_system_rst,
   inout [0:7] iobuf_system_gpio,
   inout iobuf_system_twi_0_sda,
   output obuf_system_twi_0_scl
);

wire [0:7] i_system_gpio;
wire [0:7] o_system_gpio;
wire [0:7] t_system_gpio;

wire i_system_twi_0_sda;
wire o_system_twi_0_sda;
wire o_system_twi_0_scl;

(* BOX_TYPE = "user_black_box" *) system instSystem (
    .i_system_clk(i_system_clk),
    .i_system_rst(i_system_rst),
    .i_system_gpio(i_system_gpio),
    .o_system_gpio(o_system_gpio),
    .t_system_gpio(t_system_gpio),
    .i_system_twi_0_sda(i_system_twi_0_sda),
    .o_system_twi_0_sda(o_system_twi_0_sda),
    .o_system_twi_0_scl(o_system_twi_0_scl)
);

genvar i;
generate
    for(i = 0; i < 8; i = i+1) begin : instantiationBufGpio
        IOBUF instBufGpio (
            .O(i_system_gpio[i]),
            .IO(iobuf_system_gpio[i]),
            .I(o_system_gpio[i]),
            .T(t_system_gpio[i])
        );
    end
endgenerate

IOBUF instBufSda (
    .O(i_system_twi_0_sda),
    .IO(iobuf_system_twi_0_sda),
    .I(o_system_twi_0_sda),
    .T(o_system_twi_0_sda)
);

OBUFT instBufScl (
    .O(obuf_system_twi_0_scl),
    .I(o_system_twi_0_scl),
    .T(o_system_twi_0_scl)
);

endmodule

