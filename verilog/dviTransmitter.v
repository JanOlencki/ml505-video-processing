`include "verilog/common.v"

module dviTransmitter #(
    parameter H_ACTIVE = 24,
    parameter H_FRONT_PORCH = 2,
    parameter H_SYNC = 8,
    parameter H_BACK_PORCH = 4,
    parameter H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH,
    parameter V_ACTIVE = 16,
    parameter V_FRONT_PORCH = 2,
    parameter V_SYNC = 4,
    parameter V_BACK_PORCH = 8,
    parameter V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH
)(
    input iClk,
    input iRst,
    input iPixelSync,
    input iPixelActive,
    input [7:0] iDataRed,
    input [7:0] iDataGreen,
    input [7:0] iDataBlue,
    output reg [11:0] oData,
    output reg oHsync,
    output reg oVsync,
    output reg oDe
);

wire pixelSub;
wire [`CLOG2(H_TOTAL):0]  hpixel;
wire [`CLOG2(V_TOTAL):0]  vpixel;

videoClockGenerator #(
    .H_ACTIVE(H_ACTIVE),
    .H_TOTAL(H_TOTAL),
    .V_ACTIVE(V_ACTIVE),
    .V_TOTAL(V_TOTAL),
    .SYNC_DELAY_SUB(0),
    .SYNC_DELAY_H(0),
    .SYNC_DELAY_V(0)
) videoClockGeneratorInst (
    .iClk(iClk),
    .iRst(iRst),
    .iPixelSync(iPixelSync),
    .oPixelSub(pixelSub),
    .oHpixel(hpixel),
    .oVpixel(vpixel),
    .oPixelSync(),
    .oPixelActive()
);

always @(posedge iClk or posedge iRst) begin
    if(iRst) begin
        oData <= 0;
        oHsync <= 1;
        oVsync <= 1;
        oDe <= 0;
    end
    else begin      
        if(hpixel == H_ACTIVE+H_FRONT_PORCH && !pixelSub) begin
            oHsync <= 0;
        end
        else if(hpixel == H_ACTIVE+H_FRONT_PORCH+H_SYNC && !pixelSub) begin
            oHsync <= 1;
        end

        if(vpixel == V_ACTIVE+V_FRONT_PORCH && !pixelSub) begin
            oVsync <= 0;
        end
        else if(vpixel == V_ACTIVE+V_FRONT_PORCH+V_SYNC && !pixelSub) begin
            oVsync <= 1;
        end
        
        if(iPixelActive) begin
            oDe <= 1;
            oData <= pixelSub ? {iDataRed, iDataGreen[7:4]} : {iDataGreen[3:0], iDataBlue}; 
        end
        else begin
            oDe <= 0;
            oData <= 0;
        end
    end
end
endmodule
