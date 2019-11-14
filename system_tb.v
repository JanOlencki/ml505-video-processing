//-----------------------------------------------------------------------------
// system_tb.v
//-----------------------------------------------------------------------------

`timescale 1 ps / 100 fs

`uselib lib=unisims_ver

// START USER CODE (Do not remove this line)

// User: Put your directives here. Code in this
//       section will not be overwritten.

// END USER CODE (Do not remove this line)

module system_tb
  (
  );

  // START USER CODE (Do not remove this line)

  // User: Put your signals here. Code in this
  //       section will not be overwritten.

  // END USER CODE (Do not remove this line)

  real i_system_clk_PERIOD = 10000.000000;
  real i_system_rst_LENGTH = 160000;

  // Internal signals

  reg i_system_clk;
  reg [0:3] i_system_gpio;
  reg [0:3] i_system_gpio_oloop;
  reg [0:31] i_system_gpio_scanner;
  reg [0:31] i_system_gpio_scanner_oloop;
  reg [0:31] i_system_gpio_video;
  reg [0:31] i_system_gpio_video_oloop;
  reg i_system_rst;
  reg i_system_twi_video_sda;
  wire [0:3] o_system_gpio;
  wire [0:31] o_system_gpio_scanner;
  wire [0:31] o_system_gpio_video;
  wire o_system_twi_video_scl;
  wire o_system_twi_video_sda;

  system
    dut (
      .i_system_clk ( i_system_clk ),
      .i_system_rst ( i_system_rst ),
      .i_system_gpio ( i_system_gpio ),
      .o_system_gpio ( o_system_gpio ),
      .i_system_gpio_oloop ( i_system_gpio_oloop ),
      .i_system_gpio_video ( i_system_gpio_video ),
      .o_system_gpio_video ( o_system_gpio_video ),
      .i_system_gpio_video_oloop ( i_system_gpio_video_oloop ),
      .i_system_gpio_scanner ( i_system_gpio_scanner ),
      .o_system_gpio_scanner ( o_system_gpio_scanner ),
      .i_system_gpio_scanner_oloop ( i_system_gpio_scanner_oloop ),
      .i_system_twi_video_sda ( i_system_twi_video_sda ),
      .o_system_twi_video_sda ( o_system_twi_video_sda ),
      .o_system_twi_video_scl ( o_system_twi_video_scl )
    );

  // Clock generator for i_system_clk

  initial
    begin
      i_system_clk = 1'b0;
      forever #(i_system_clk_PERIOD/2.00)
        i_system_clk = ~i_system_clk;
    end

  // Reset Generator for i_system_rst

  initial
    begin
      i_system_rst = 1'b1;
      #(i_system_rst_LENGTH) i_system_rst = ~i_system_rst;
    end

  // START USER CODE (Do not remove this line)

  // User: Put your stimulus here. Code in this
  //       section will not be overwritten.

  // END USER CODE (Do not remove this line)

endmodule

