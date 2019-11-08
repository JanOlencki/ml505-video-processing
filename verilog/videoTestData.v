`include "verilog/common.v"

module videoTestData #(
    parameter H_ACTIVE = 24,
    parameter H_TOTAL = 32,
    parameter V_ACTIVE = 16,
    parameter V_TOTAL = 24
)(
    input iClk,
    input iRst,
    input iPixelSync,
    input iPixelActive,
    input [7:0] iDataRed,
    input [7:0] iDataGreen,
    input [7:0] iDataBlue,
    input iTestData,
    output oPixelSync,
    output oPixelActive,
    output reg [7:0] oDataRed,
    output reg [7:0] oDataGreen,
    output reg [7:0] oDataBlue
);

wire pixelSub;
wire [`CLOG2(H_TOTAL):0]  hpixel;
wire [`CLOG2(V_TOTAL):0]  vpixel;
reg [8:0] frameIndex;

reg [7:0] testPatternLuminance;
reg testPatternRed;
reg testPatternGreen;
reg testPatternBlue;

videoClockGenerator #(
    .H_ACTIVE(H_ACTIVE),
    .H_TOTAL(H_TOTAL),
    .V_ACTIVE(V_ACTIVE),
    .V_TOTAL(V_TOTAL),
    .SYNC_DELAY_H(0),
    .SYNC_DELAY_V(0)
) videoClockGeneratorInst (
    .iClk(iClk),
    .iRst(iRst),
    .iPixelSync(iPixelSync),
    .oPixelSub(pixelSub),
    .oHpixel(hpixel),
    .oVpixel(vpixel),
    .oPixelSync(oPixelSync),
    .oPixelActive(oPixelActive)
);

always @(posedge iClk or posedge iRst) begin
    if(iRst) begin
        frameIndex <= 0;
    end
    else begin 
        if(iPixelSync) begin
            frameIndex <= frameIndex + 1;
        end

        if(!pixelSub) begin
            if(iPixelActive) begin
                if(iTestData) begin
                    oDataRed <= {8{testPatternRed}} & testPatternLuminance;
                    oDataGreen <= {8{testPatternGreen}} & testPatternLuminance;
                    oDataBlue <= {8{testPatternBlue}} & testPatternLuminance;
                end
                else begin
                    oDataRed <= iDataRed;
                    oDataGreen <= iDataGreen;
                    oDataBlue <= iDataBlue;
                end
            end
            else begin
                oDataRed <= 0;
                oDataGreen <= 0;
                oDataBlue <= 0;
            end
        end
    end
end

always @* begin
    if(vpixel == 0 || vpixel == V_ACTIVE-1 || hpixel == 0 || hpixel == H_ACTIVE-1) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b111;
        testPatternLuminance <= 8'hFF;
    end
    else if(vpixel == 1 || vpixel == V_ACTIVE-2 || hpixel == 1 || hpixel == H_ACTIVE-2) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b000;
        testPatternLuminance <= 8'h00;
    end
    else if((1 < vpixel && vpixel <= 1+3) || (V_ACTIVE-2-3 <= vpixel && vpixel < V_ACTIVE-2)
            || (1 < hpixel && hpixel <= 1+3) || (H_ACTIVE-2-3 <= hpixel && hpixel < H_ACTIVE-2)) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b111;
        testPatternLuminance <= 8'hFF;
    end
    else if((1 < vpixel && vpixel <= 1+3+3) || (V_ACTIVE-2-3-3 <= vpixel && vpixel < V_ACTIVE-2-3)
           || (1 < hpixel && hpixel <= 1+3+3) || (H_ACTIVE-2-3-3 <= hpixel && hpixel < H_ACTIVE-2-3)) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b000;
        testPatternLuminance <= 8'h00;
    end
    else if(hpixel <= 1+3+3+98*1) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b100; //Red
        testPatternLuminance <= 8'hFF;
    end
    else if(hpixel <= 1+3+3+98*2) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b010; //Green
        testPatternLuminance <= 8'hFF;
    end
    else if(hpixel <= 1+3+3+98*3) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b001; //Blue
        testPatternLuminance <= 8'hFF;
    end
    else if(hpixel <= 1+3+3+98*4) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b111; //Pulsing gray
        testPatternLuminance <= frameIndex[7:0] ^ {8{frameIndex[8]}};
    end
    else if(hpixel <= 1+3+3+98*5) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b111; //Pulsing gray
        testPatternLuminance <= frameIndex[7:0] ^ {8{~frameIndex[8]}};
    end
    else if(hpixel <= 1+3+3+98*6) begin
       {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b110; //Yellow
        testPatternLuminance <= 8'hFF;
    end
    else if(hpixel <= 1+3+3+98*7) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b011; //Cyan
        testPatternLuminance <= 8'hFF;
    end
    else if(hpixel <= 1+3+3+98*8) begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b101; //Magenta
        testPatternLuminance <= 8'hFF;
    end
    else begin
        {testPatternRed, testPatternGreen, testPatternBlue} <= 3'b000;
        testPatternLuminance <= 8'h00;
    end
end
endmodule
