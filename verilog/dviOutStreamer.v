`include "verilog/common.v"

module dviOutStreamer (
    input iClk_0,
    input iClk_90,
    input iRst,
    output reg [11:0] oData,
    output reg oHsync,
    output reg oVsync,
    output reg oDe
);

parameter H_ACTIVE_COUNT = 24;
parameter H_FRONT_PORCH = 2;
parameter H_SYNC = 8;
parameter H_BACK_PORCH = 4;
localparam H_TOTAL = H_ACTIVE_COUNT + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH;
parameter V_ACTIVE_COUNT = 16;
parameter V_FRONT_PORCH = 2;
parameter V_SYNC = 4;
parameter V_BACK_PORCH = 8;
localparam V_TOTAL = V_ACTIVE_COUNT + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH;

reg pixelSub;
reg [`CLOG2(H_TOTAL):0]  hPixel;
wire [`CLOG2(H_TOTAL):0]  hActivePixel;
reg [`CLOG2(V_TOTAL):0]  vPixel;
wire [`CLOG2(V_TOTAL):0]  vActivePixel;

always @(posedge iClk_0) begin
    if(iRst) begin
        pixelSub <= 0;
        hPixel <= 0;
        vPixel <= 0;
    end
    else begin
        pixelSub <= ~pixelSub;

        if(pixelSub) begin
            hPixel <= hPixel + 1;
            if(hPixel == H_TOTAL - 1) begin
                hPixel <= 0;
                vPixel <= vPixel + 1;
                if(vPixel == V_TOTAL - 1) begin
                    vPixel <= 0;
                end
            end
        end
    end
end

assign hActivePixel = hPixel - (H_FRONT_PORCH+H_SYNC+H_BACK_PORCH);
assign vActivePixel = vPixel;

always @(posedge iClk_90) begin
     if(iRst) begin
        oData <= 0;
        oHsync <= 0;
        oVsync <= 0;
        oDe <= 0;
    end
    else begin
        if(H_FRONT_PORCH-1 < hPixel && H_FRONT_PORCH+H_SYNC > hPixel ) 
            oHsync <= 0;
        else
            oHsync <= 1;

        if((V_ACTIVE_COUNT+V_FRONT_PORCH-1) < vPixel && (V_ACTIVE_COUNT + V_FRONT_PORCH+V_SYNC) > vPixel ) 
            oVsync <= 0;
        else
            oVsync <= 1;
        
        if(H_FRONT_PORCH+H_SYNC+H_BACK_PORCH-1 < hPixel && hPixel < H_TOTAL && 0 <= vPixel && vPixel < V_ACTIVE_COUNT) begin
            oDe <= 1;
            if(hActivePixel == 0 || hActivePixel == H_ACTIVE_COUNT-1 || vActivePixel == 0 || vActivePixel == V_ACTIVE_COUNT-1) begin
                oData <= pixelSub ? 12'b11111111_1111 : 12'b1111_11111111;
            end
            else if(hActivePixel == 1 || hActivePixel == H_ACTIVE_COUNT-2 || vActivePixel == 1 || vActivePixel == V_ACTIVE_COUNT-2) begin
                oData <= pixelSub ? 12'b00000000_0000 : 12'b0000_00000000;
            end
            else if(hActivePixel <= 1+3 || hActivePixel >= H_ACTIVE_COUNT-2-3 || vActivePixel <= 1+3 || vActivePixel >= V_ACTIVE_COUNT-2-3) begin
                oData <= pixelSub ? 12'b11111111_1111 : 12'b1111_11111111;
            end
            else if(hActivePixel <= 1+3+3 || hActivePixel >= H_ACTIVE_COUNT-2-3-3 || vActivePixel <=1+3+3 || vActivePixel >= V_ACTIVE_COUNT-2-3-3) begin
                oData <= pixelSub ? 12'b00000000_0000 : 12'b0000_00000000;
            end
            else if(hActivePixel <= 1+3+3+98*1) begin
                oData <= pixelSub ? 12'b11111111_0000 : 12'b0000_00000000;
            end
            else if(hActivePixel <= 1+3+3+98*2) begin
                oData <= pixelSub ? 12'b11111111_1111 : 12'b1111_00000000;
            end
            else if(hActivePixel <= 1+3+3+98*3) begin
                oData <= pixelSub ? 12'b11111111_1111 : 12'b1111_11111111;
            end
            else if(hActivePixel <= 1+3+3+98*4) begin
                oData <= pixelSub ? 12'b11111111_0000 : 12'b0000_11111111;
            end
            else if(hActivePixel <= 1+3+3+98*5) begin
                oData <= pixelSub ? 12'b00000000_0000 : 12'b0000_00000000;
            end
            else if(hActivePixel <= 1+3+3+98*6) begin
                oData <= pixelSub ? 12'b00000000_1111 : 12'b1111_11111111;
            end
            else if(hActivePixel <= 1+3+3+98*7) begin
                oData <= pixelSub ? 12'b00000000_1111 : 12'b1111_00000000;
            end
            else if(hActivePixel <= 1+3+3+98*8) begin
                oData <= pixelSub ? 12'b00000000_0000 : 12'b0000_11111111;
            end
            else begin
                oData <= pixelSub ? 12'b10000000_1000 : 12'b0000_10000000;
            end
        end
        else begin
            oDe <= 0;
            oData <= 12'b000000001111;
        end
    end
end

endmodule
