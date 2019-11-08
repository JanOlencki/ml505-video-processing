`include "verilog/common.v"

module videoClockGenerator #(
    parameter H_ACTIVE = 24,
    parameter H_TOTAL = 32,
    parameter V_ACTIVE = 16,
    parameter V_TOTAL = 24,
    parameter SYNC_DELAY_H = 0,
    parameter SYNC_DELAY_V = 0
)(
    input iClk,
    input iRst,
    input iPixelSync,
    output reg oPixelSub,
    output reg [`CLOG2(H_TOTAL):0] oHpixel,
    output reg [`CLOG2(V_TOTAL):0] oVpixel,
    output reg oPixelSync,
    output reg oPixelActive
);

reg pixelSub;
reg [`CLOG2(H_TOTAL):0] hPixel;
reg [`CLOG2(V_TOTAL):0] vPixel;

always @(posedge iClk or posedge iRst) begin
    if(iRst) begin
        oPixelSub <= 0;
        oHpixel <= 0;
        oVpixel <= 0;
        oPixelSync <= 0;
        oPixelActive <= 0;
    end
    else begin      
        oPixelSync <= oPixelSub && oHpixel == (H_TOTAL-1 + SYNC_DELAY_H)%H_TOTAL && oVpixel == (V_TOTAL-1 + SYNC_DELAY_V)%V_TOTAL;
        oPixelActive <= oHpixel < (H_ACTIVE + SYNC_DELAY_H)%H_TOTAL && oVpixel < (V_ACTIVE + SYNC_DELAY_V)%V_TOTAL;
        
        oPixelSub <= ~oPixelSub;
        if(iPixelSync) begin
            oHpixel <= 0; 
            oVpixel <= 0;
            oPixelSub <= 0;
        end
        else if(oPixelSub) begin
            oHpixel <= oHpixel + 1;
            if(oHpixel == H_TOTAL-1) begin
                oHpixel <= 0;
                oVpixel <= oVpixel + 1;
                if(oVpixel == V_TOTAL-1) begin
                    oVpixel <= 0;
                end
            end
        end
    end
end
endmodule
