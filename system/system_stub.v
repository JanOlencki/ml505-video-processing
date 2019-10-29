//-----------------------------------------------------------------------------
// system_stub.v
//-----------------------------------------------------------------------------

module system_stub
  (
    i_system_clk,
    i_system_rst,
    i_system_gpio,
    o_system_gpio,
    t_system_gpio,
    i_system_twi_0_sda,
    o_system_twi_0_sda,
    o_system_twi_0_scl,
    i_system_gpio_video,
    o_system_gpio_video
  );
  input i_system_clk;
  input i_system_rst;
  input [0:7] i_system_gpio;
  output [0:7] o_system_gpio;
  output [0:7] t_system_gpio;
  input i_system_twi_0_sda;
  output o_system_twi_0_sda;
  output o_system_twi_0_scl;
  input [0:31] i_system_gpio_video;
  output [0:31] o_system_gpio_video;

  (* BOX_TYPE = "user_black_box" *)
  system
    system_i (
      .i_system_clk ( i_system_clk ),
      .i_system_rst ( i_system_rst ),
      .i_system_gpio ( i_system_gpio ),
      .o_system_gpio ( o_system_gpio ),
      .t_system_gpio ( t_system_gpio ),
      .i_system_twi_0_sda ( i_system_twi_0_sda ),
      .o_system_twi_0_sda ( o_system_twi_0_sda ),
      .o_system_twi_0_scl ( o_system_twi_0_scl ),
      .i_system_gpio_video ( i_system_gpio_video ),
      .o_system_gpio_video ( o_system_gpio_video )
    );

endmodule

