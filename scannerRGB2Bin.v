`include "verilog/common.v"

module scannerRGB2Bin (
    input iClk,
    input iRst,
    input iPixelSync,
    input iPixelActive,
    input [7:0] iDataRed,
    input [7:0] iDataGreen,
    input [7:0] iDataBlue,
    input [7:0] iThreshRed,
    input [7:0] iThreshGreen,
    input [7:0] iThreshBlue,
    output oPixelSync,
    output oPixelActive,
    output reg oDataBin
);

assign oPixelSync = iPixelSync;
assign oPixelActive = iPixelActive;

always @* begin
    if(iPixelActive) begin
        oDataBin <= iDataRed > iThreshRed || iDataGreen > iThreshGreen || iDataBlue > iThreshBlue;
    end
    else begin
        oDataBin <= 0;
    end
    
end

endmodule
