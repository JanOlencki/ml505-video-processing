`include "verilog/common.v"

module vgaReceiver #(
    parameter H_ACTIVE = 24,
    parameter H_TOTAL = 32,
    parameter V_ACTIVE = 16,
    parameter V_TOTAL = 24
)(
    input iClk,
    input iRst,
    input iHsync,
    input iVsync,
    input [7:0] iDataRed,
    input [7:0] iDataGreen,
    input [7:0] iDataBlue,
    input [`CLOG2(H_TOTAL):0] iHsyncOffset,
    input [`CLOG2(V_TOTAL):0] iVsyncOffset,
    output reg oPixelSync,
    output reg oPixelActive,
    output reg [7:0] oDataRed,
    output reg [7:0] oDataGreen,
    output reg [7:0] oDataBlue
);

reg pixelSub;
reg [`CLOG2(H_TOTAL):0]  hpixel;
reg [`CLOG2(V_TOTAL):0]  vpixel;

reg [`CLOG2(H_TOTAL):0] hsyncOffsetBuff;
reg [`CLOG2(V_TOTAL):0] vsyncOffsetBuff;
reg [7:0] hsyncBuff;
reg [7:0] vsyncBuff;

always @(posedge iClk or posedge iRst) begin
    if(iRst) begin
        pixelSub <= 0;
        hpixel <= 0;
        vpixel <= 0;
        oPixelSync <= 0;
        oPixelActive <= 0;

        hsyncOffsetBuff <= iHsyncOffset;
        vsyncOffsetBuff <= iVsyncOffset;
        hsyncBuff <= 0;
        vsyncBuff <= 0;
    end
    else begin      
        pixelSub <= ~pixelSub;
        hsyncBuff <= {hsyncBuff[6:0], iHsync};
        vsyncBuff <= {vsyncBuff[6:0], iVsync};

        if(hsyncBuff == 8'h0F) begin
            hpixel <= H_ACTIVE + hsyncOffsetBuff; 
            pixelSub <= 1;
        end
        else if(pixelSub) begin
            hpixel <= hpixel + 1;
            if(hpixel == H_TOTAL-1) begin
                hpixel <= 0;
            end
        end
        if(vsyncBuff == 8'h0F) begin
            vpixel <= V_ACTIVE + vsyncOffsetBuff;
        end
        else if(hpixel == H_TOTAL-1 && pixelSub) begin
            vpixel <= vpixel + 1;
            if(vpixel == V_TOTAL-1) begin
                vpixel <= 0;
            end
        end

        oPixelSync <= pixelSub && hpixel == H_TOTAL-1 && vpixel == V_TOTAL-1;
        if(vpixel < V_ACTIVE && hpixel < H_ACTIVE) begin
            oPixelActive <= 1;
            if(!pixelSub) begin
                oDataRed <= iDataRed;
                oDataGreen <= iDataGreen;
                oDataBlue <= iDataBlue;
            end
        end
        else begin
            oPixelActive <= 0;
            oDataRed <= 0;
            oDataGreen <= 0;
            oDataBlue <= 0;
        end
    end
end
endmodule
