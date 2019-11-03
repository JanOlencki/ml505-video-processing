`include "verilog/common.v"

module vgaToDviConverter(
    input iHsync,
    input iVsync,
    input [7:0] iDataRed,
    input [7:0] iDataGreen,
    input [7:0] iDataBlue,
    input iClk_0,
    input iRst,
    input iTest,
    input iConfigVsync,
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
reg [8:0] frameIndex;

reg [7:0] testPatternLuminance;
reg testPatternRed;
reg testPatternGreen;
reg testPatternBlue;
reg pixelSub;
reg [`CLOG2(H_TOTAL):0]  hPixel;
reg [`CLOG2(V_TOTAL):0]  vPixel;

reg hasHsync;
reg hasVsync;
reg [7:0] dataBufRed;
reg [7:0] dataBufGreen;
reg [7:0] dataBufBlue;
reg [7:0] hsyncBuff;
reg [7:0] vsyncBuff;

always @(posedge iClk_0) begin
    if(iRst) begin
        oData <= 0;
        oHsync <= 1;
        oVsync <= 1;
        oDe <= 0;

        pixelSub <= 0;
        hPixel <= 0;
        vPixel <= 0;
        frameIndex <= 0;

        hasHsync <= 0;
        hasVsync <= 0;
        hsyncBuff <= 0;
        vsyncBuff <= 0;
    end
    else begin      
        pixelSub <= ~pixelSub;
        hsyncBuff <= {hsyncBuff[6:0], iHsync};
        if(!hasHsync) begin
            if(hsyncBuff == 8'h0F) begin
                hasHsync <= 1;
                hPixel <= H_ACTIVE_COUNT+32+3;
                pixelSub <= 1;
            end
        end
        else if(pixelSub) begin
            hPixel <= hPixel + 1;
            if(hPixel == H_TOTAL - 1) begin
                hPixel <= 0;
            end

            if(!hasVsync) begin
                if(vsyncBuff == 8'h0F) begin
                    hasVsync <= 1;
                    vPixel <= V_ACTIVE_COUNT;
                end
            end
            else if(hPixel == H_TOTAL - 1) begin
                vPixel <= vPixel + 1;
                if(vPixel == V_TOTAL - 1) begin
                    vPixel <= 0;
                    frameIndex <= frameIndex + 1;
                end
            end
        end
        else begin
            dataBufRed <= iDataRed;
            dataBufGreen <= iDataGreen;
            dataBufBlue <= iDataBlue;
            vsyncBuff <= {vsyncBuff[6:0], iVsync};
        end

        if(hPixel == H_ACTIVE_COUNT+H_FRONT_PORCH && !pixelSub) begin
            oHsync <= 0;
        end
        else if(hPixel == H_ACTIVE_COUNT+H_FRONT_PORCH+H_SYNC && !pixelSub) begin
            oHsync <= 1;
        end

        if(vPixel == V_ACTIVE_COUNT+V_FRONT_PORCH && !pixelSub) begin
            oVsync <= 0;
        end
        else if(vPixel == V_ACTIVE_COUNT+V_FRONT_PORCH+V_SYNC && !pixelSub) begin
            oVsync <= 1;
        end
        
        if(hPixel < H_ACTIVE_COUNT && vPixel < V_ACTIVE_COUNT) begin
            oDe <= 1;
            if(iTest) begin
                if(pixelSub) begin
                    oData[11:4] <= {8{testPatternRed}} & testPatternLuminance;
                    oData[3:0] <= {4{testPatternGreen}} & testPatternLuminance[7:4];    
                end
                else begin                    
                    oData[11:8] <= {4{testPatternGreen}} & testPatternLuminance[3:0];
                    oData[7:0] <= {8{testPatternBlue}} & testPatternLuminance;
                end
            end                
            else begin
                oData <= pixelSub ? {dataBufRed, dataBufGreen[7:4]} : {dataBufGreen[3:0], dataBufBlue}; 
            end
        end
        else begin
            oDe <= 0;
            oData <= 0;
        end
    end
end

always @* begin
    if(vPixel == 0 || vPixel == V_ACTIVE_COUNT-1 || hPixel == 0 || hPixel == H_ACTIVE_COUNT-1) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b111;
        testPatternLuminance <= 8'hFF;
    end
    else if(vPixel == 1 || vPixel == V_ACTIVE_COUNT-2 || hPixel == 1 || hPixel == H_ACTIVE_COUNT-2) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b000;
        testPatternLuminance <= 8'h00;
    end
    else if((1 < vPixel && vPixel <= 1+3) || (V_ACTIVE_COUNT-2-3 <= vPixel && vPixel < V_ACTIVE_COUNT-2)
            || (1 < hPixel && hPixel <= 1+3) || (H_ACTIVE_COUNT-2-3 <= hPixel && hPixel < H_ACTIVE_COUNT-2)) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b111;
        testPatternLuminance <= 8'hFF;
    end
    else if((1 < vPixel && vPixel <= 1+3+3) || (V_ACTIVE_COUNT-2-3-3 <= vPixel && vPixel < V_ACTIVE_COUNT-2-3)
           || (1 < hPixel && hPixel <= 1+3+3) || (H_ACTIVE_COUNT-2-3-3 <= hPixel && hPixel < H_ACTIVE_COUNT-2-3)) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b000;
        testPatternLuminance <= 8'h00;
    end
    else if(hPixel <= 1+3+3+98*1) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b100; //Red
        testPatternLuminance <= 8'hFF;
    end
    else if(hPixel <= 1+3+3+98*2) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b010; //Green
        testPatternLuminance <= 8'hFF;
    end
    else if(hPixel <= 1+3+3+98*3) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b001; //Blue
        testPatternLuminance <= 8'hFF;
    end
    else if(hPixel <= 1+3+3+98*4) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b111; //Pulsing gray
        testPatternLuminance <= frameIndex[7:0] ^ {8{frameIndex[8]}};
    end
    else if(hPixel <= 1+3+3+98*5) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b111; //Pulsing gray
        testPatternLuminance <= frameIndex[7:0] ^ {8{~frameIndex[8]}};
    end
    else if(hPixel <= 1+3+3+98*6) begin
       {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b110; //Yellow
        testPatternLuminance <= 8'hFF;
    end
    else if(hPixel <= 1+3+3+98*7) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b011; //Cyan
        testPatternLuminance <= 8'hFF;
    end
    else if(hPixel <= 1+3+3+98*8) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b101; //Magenta
        testPatternLuminance <= 8'hFF;
    end
    else begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b000;
        testPatternLuminance <= 8'h00;
    end
end

endmodule