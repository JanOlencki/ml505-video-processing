//-----------------------------------------------------------------------------
// system_stub.v
//-----------------------------------------------------------------------------

module system_stub
  (
    i_system_clk,
    i_system_rst,
    io_system_gpio,
    i_system_twi_0_sda,
    o_system_twi_0_sda,
    o_system_twi_0_scl
  );
  input i_system_clk;
  input i_system_rst;
  inout [0:7] io_system_gpio;
  input i_system_twi_0_sda;
  output o_system_twi_0_sda;
  output o_system_twi_0_scl;

  (* BOX_TYPE = "user_black_box" *)
  system
    system_i (
      .i_system_clk ( i_system_clk ),
      .i_system_rst ( i_system_rst ),
      .io_system_gpio ( io_system_gpio ),
      .i_system_twi_0_sda ( i_system_twi_0_sda ),
      .o_system_twi_0_sda ( o_system_twi_0_sda ),
      .o_system_twi_0_scl ( o_system_twi_0_scl )
    );

endmodule

