`include "verilog/common.v"

module scannerEAN13 #(
    parameter H_ACTIVE = 24,
    parameter H_TOTAL = 32,
    parameter V_ACTIVE = 16,
    parameter V_TOTAL = 24,
    parameter MIN_MODULE_WIDTH = 4,
    parameter MAX_MODULE_WIDTH = 16,
    parameter TOL_MODULE_WIDTH = 2
)(
    input iClk,
    input iRst,
    input iPixelSync,
    input iPixelActive,
    input iPixelData,
    output oPixelSync,
    output oPixelActive,
    output reg oVideoModule,
    output reg oVideoMarker,
    output reg oVideoDigit,
    output reg [51:0] oDataCode,
    output reg oNewData
);

wire pixelSub;
wire [`CLOG2(H_TOTAL):0]  hpixel;
wire [`CLOG2(V_TOTAL):0]  vpixel;

videoClockGenerator #(
    .H_ACTIVE(H_ACTIVE),
    .H_TOTAL(H_TOTAL),
    .V_ACTIVE(V_ACTIVE),
    .V_TOTAL(V_TOTAL),
    .SYNC_DELAY_H(2),
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

wire iData = ~iPixelData;
(* KEEP = "TRUE" *) reg [5:0] state;
(* KEEP = "TRUE" *) reg [5:0] newState;
reg nextModule;
reg nextDigit;
localparam IDLE = 6'h01, MARKER_START = 6'h02, GROUP_FIRST = 6'h04, 
        MARKER_MID = 6'h08, GROUP_SECOND = 6'h10, MARKER_END = 6'h20;
localparam DATA_BUFF_WIDTH = 2;
reg [DATA_BUFF_WIDTH-1 : 0] dataBuff;
reg [3:0] moduleIndex;
reg [3:0] digitIndex;
reg [`CLOG2(MAX_MODULE_WIDTH):0] pxIndex;
reg [`CLOG2(MAX_MODULE_WIDTH):0] moduleWidth;
wire [`CLOG2(MAX_MODULE_WIDTH)+1 : 0] moduleWidthAvg = ;
(* KEEP = "TRUE" *) wire dataRising = dataBuff == 2'b01;
(* KEEP = "TRUE" *) wire dataFalling = dataBuff == 2'b10;

always @* begin
    newState = IDLE;
    nextModule = 0;
    nextDigit = 0;
    case(state)
        IDLE:
            if(dataRising) begin
                newState = MARKER_START;
                nextModule = 1;
            end
        MARKER_START: // Modules from 0 to 2 (rising - 0 and 2, falling - 1)
            if(pxIndex >= MAX_MODULE_WIDTH) begin
                newState = IDLE;
            end
            else if((moduleIndex[0] && dataRising) || (!moduleIndex[0] && dataFalling)) begin
                if((moduleIndex[1:0] != 0 && (pxIndex < moduleWidth-TOL_MODULE_WIDTH || pxIndex >= moduleWidth+TOL_MODULE_WIDTH))
                    || pxIndex < MIN_MODULE_WIDTH) begin
                    newState = IDLE; 
                end
                else if(moduleIndex[1:0] != 2'b10) begin
                    newState = MARKER_START;
                    nextModule = 1;
                end
                else begin
                    newState = GROUP_FIRST;
                    nextModule = 1;
                end
            end
            else begin
                newState = MARKER_START;
            end
        GROUP_FIRST:
            if(pxIndex == moduleWidth-1) begin
                newState = GROUP_FIRST;
                nextModule = 1;
                if(moduleIndex == 7) begin
                    nextDigit = 1;
                    if(digitIndex == 5) begin
                        newState = MARKER_MID;
                    end
                end
            end
            else begin
                newState = GROUP_FIRST;
            end
        MARKER_MID:
            if(pxIndex == moduleWidth-1) begin
                nextModule = 1;
                newState = MARKER_MID;
                if(moduleIndex == 5) begin
                    newState = GROUP_SECOND;
                end
            end
            else begin
                newState = MARKER_MID;
            end
        GROUP_SECOND:
            if(pxIndex == moduleWidth-1) begin
                newState = GROUP_SECOND;
                nextModule = 1;
                if(moduleIndex == 7) begin
                    nextDigit = 1;
                    if(digitIndex == 5) begin
                        newState = MARKER_END;
                    end
                end
            end
            else begin
                newState = GROUP_SECOND;
            end
        MARKER_END:
            if(pxIndex == moduleWidth-1) begin
                nextModule = 1;
                newState = MARKER_END;
                if(moduleIndex == 3) begin
                    newState = IDLE;
                end
            end
            else begin
                newState = MARKER_END;
            end
        default: begin
            newState = IDLE;
            nextModule = 1;
        end
    endcase
end

always @(posedge iClk or posedge iRst) begin
    if(iRst) begin
        state <= IDLE;
        dataBuff <= 0;
        pxIndex <= 0;
        moduleIndex <= 0;
        digitIndex <= 0;
    end
    else begin 
        if(iPixelActive) begin
            if(!pixelSub) begin
                dataBuff <= {dataBuff[DATA_BUFF_WIDTH-2 : 0], iData};
                
                state <= newState;
                pxIndex <= pxIndex + 1;
                if(state == IDLE) begin
                    moduleWidthAvg <= 0;
                end
                else if(state == MARKER_START && nextModule) begin
                    if(moduleIndex == 0) begin
                        moduleWidth <= pxIndex+1;
                    end
                    else if(moduleIndex == 1) begin
                        moduleWidthAvg <= moduleWidth + pxIndex+1;
                    end
                end

                if(state == IDLE) begin
                    moduleIndex <= 0;
                    pxIndex <= 0;
                    digitIndex <= 0;
                end
                else if(newState == MARKER_START || newState == GROUP_FIRST || newState == MARKER_MID || newState == GROUP_SECOND || newState == MARKER_END) begin
                    if(state != newState) begin
                        digitIndex <= 0;
                        moduleIndex <= 0;
                        pxIndex <= 1;
                    end
                    else if(nextDigit) begin
                        moduleIndex <= 0;
                        pxIndex <= 0;
                        digitIndex <= digitIndex + 1;
                    end 
                    else if(nextModule) begin
                        moduleIndex <= moduleIndex + 1;
                        pxIndex <= 1;
                    end
                end
            end
        end 
        else begin
            state <= IDLE;
            dataBuff <= 0;
        end
    end
end

always @(posedge iClk) begin
    oVideoMarker <= state == MARKER_START || state == MARKER_MID || state == MARKER_END;
    oVideoModule <= dataBuff[1];
    oVideoDigit <= (state == GROUP_FIRST || state == GROUP_SECOND) && digitIndex[0];
end

endmodule
