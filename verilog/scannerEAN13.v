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
(* KEEP = "TRUE" *) output reg [51:0] oDataCode,
    output [`CLOG2(V_TOTAL):0] oVpixel,
    output reg oNewData
);

wire pixelSub;
wire [`CLOG2(H_TOTAL):0]  hpixel;
wire [`CLOG2(V_TOTAL):0]  vpixel;
assign oVpixel = vpixel;

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

wire iData = ~iPixelData;
(* KEEP = "TRUE" *) reg [5:0] state;
(* KEEP = "TRUE" *) reg [5:0] newState;
reg nextModule;
reg nextDigit;
localparam IDLE = 6'h01, MARKER_START = 6'h02, GROUP_FIRST = 6'h04, 
        MARKER_MID = 6'h08, GROUP_SECOND = 6'h10, MARKER_END = 6'h20;
localparam DATA_BUFF_WIDTH = 2;
localparam PX_REG_WIDTH = `CLOG2(MAX_MODULE_WIDTH+TOL_MODULE_WIDTH);
reg dataPrev;
reg [3:0] moduleIndex;
reg [3:0] digitIndex;
(* KEEP = "TRUE" *) reg [PX_REG_WIDTH:0] pxIndex;
(* KEEP = "TRUE" *) reg [PX_REG_WIDTH:0] moduleMaxIndex;
(* KEEP = "TRUE" *) wire dataRising = !dataPrev && iData;
(* KEEP = "TRUE" *) wire dataFalling = dataPrev && !iData;
reg [PX_REG_WIDTH-1:0] blackPxCount;
reg [5:0] digitDataBuffer;
wire [6:0] digitData;
reg [3:0] digitDecoded;
reg [1:0] digitType;
reg [4:0] groupDigitsTypeBuffer;
wire [5:0] groupDigitsType;
localparam DIGIT_L = 2'b01, DIGIT_G = 2'b10, DIGIT_R = 2'b11, DIGIT_ERROR = 2'b11;

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
                if((moduleIndex[1:0] != 0 && (pxIndex < moduleMaxIndex-TOL_MODULE_WIDTH || pxIndex > moduleMaxIndex+TOL_MODULE_WIDTH))
                    || pxIndex < MIN_MODULE_WIDTH-1) begin
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
            if(pxIndex == moduleMaxIndex) begin
                newState = GROUP_FIRST;
                nextModule = 1;
                if(moduleIndex == 6) begin
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
            if(pxIndex == moduleMaxIndex) begin
                nextModule = 1;
                newState = MARKER_MID;
                if(moduleIndex == 4) begin
                    newState = GROUP_SECOND;
                end
            end
            else begin
                newState = MARKER_MID;
            end
        GROUP_SECOND:
            if(pxIndex == moduleMaxIndex) begin
                newState = GROUP_SECOND;
                nextModule = 1;
                if(moduleIndex == 6) begin
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
            if(pxIndex == moduleMaxIndex) begin
                nextModule = 1;
                newState = MARKER_END;
                if(moduleIndex == 2) begin
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
        dataPrev <= 1;
        pxIndex <= 0;
        moduleIndex <= 0;
        digitIndex <= 0;
        moduleMaxIndex <= 0;
        oNewData <= 0;
    end
    else begin 
        oNewData <= 0;
        if(iPixelActive) begin
            if(!pixelSub) begin
                dataPrev <= iData;
                
                state <= newState;
                pxIndex <= pxIndex + 1;
                if(state == IDLE) begin
                    moduleMaxIndex <= 0;
                end
                else if(state == MARKER_START && nextModule) begin
                    if(moduleIndex == 0) begin
                        moduleMaxIndex <= pxIndex;
                    end
                    else if(moduleIndex == 1) begin
                        moduleMaxIndex <= (moduleMaxIndex + pxIndex) >> 1;
                    end
                end

                if(state == IDLE ) begin
                    moduleIndex <= 0;
                    pxIndex <= 0;
                    digitIndex <= 0;
                end
                else if(newState == MARKER_START || newState == GROUP_FIRST || newState == MARKER_MID || newState == GROUP_SECOND || newState == MARKER_END) begin
                    if(state != newState) begin
                        digitIndex <= 0;
                        moduleIndex <= 0;
                        pxIndex <= 0;
                    end
                    else if(nextDigit) begin
                        pxIndex <= 0;
                        moduleIndex <= 0;
                        digitIndex <= digitIndex + 1;
                    end 
                    else if(nextModule) begin
                        pxIndex <= 0;
                        moduleIndex <= moduleIndex + 1;
                    end
                end

                if(state == GROUP_FIRST || state == GROUP_SECOND) begin
                    blackPxCount <= blackPxCount + dataPrev;
                    if(nextModule) begin
                        blackPxCount <= 0;
                        digitDataBuffer <= digitData[5:0];
                        if(nextDigit) begin
                            oDataCode[47:0] <= {oDataCode[43:0], digitDecoded};
                            groupDigitsTypeBuffer <= groupDigitsType[4:0];
                            if(state == GROUP_SECOND && digitIndex == 5) begin
                                oNewData <= 1;
                            end
                            else if(state == GROUP_FIRST && digitIndex == 5) begin
                                case (groupDigitsType)
                                    6'b111111: oDataCode[51:48] <= 4'd0;
                                    6'b110100: oDataCode[51:48] <= 4'd1;
                                    6'b110010: oDataCode[51:48] <= 4'd2;
                                    6'b110001: oDataCode[51:48] <= 4'd3;
                                    6'b101100: oDataCode[51:48] <= 4'd4;
                                    6'b100110: oDataCode[51:48] <= 4'd5;
                                    6'b100011: oDataCode[51:48] <= 4'd6;
                                    6'b101010: oDataCode[51:48] <= 4'd7;
                                    6'b101001: oDataCode[51:48] <= 4'd8;
                                    6'b100101: oDataCode[51:48] <= 4'd9;
                                    default: oDataCode[51:48] <= 4'hF;
                                endcase                
                            end
                        end
                    end
                end
            end
        end 
        else begin
            state <= IDLE;
            dataPrev <= 1;
        end
    end
end

always @(posedge iClk) begin
    oVideoMarker <= state == MARKER_START || state == MARKER_MID || state == MARKER_END;
    oVideoModule <= dataPrev;
    oVideoDigit <= (state == GROUP_FIRST || state == GROUP_SECOND) && digitIndex[0];
end

assign digitData = {digitDataBuffer, blackPxCount >= moduleMaxIndex[PX_REG_WIDTH:1]};
assign groupDigitsType = {groupDigitsTypeBuffer, digitType[0]};
always @* begin
    case(digitData) 
        7'b0001101: {digitType, digitDecoded} = {DIGIT_L, 4'd0};
        7'b0011001: {digitType, digitDecoded} = {DIGIT_L, 4'd1};
        7'b0010011: {digitType, digitDecoded} = {DIGIT_L, 4'd2};
        7'b0111101: {digitType, digitDecoded} = {DIGIT_L, 4'd3};
        7'b0100011: {digitType, digitDecoded} = {DIGIT_L, 4'd4};
        7'b0110001: {digitType, digitDecoded} = {DIGIT_L, 4'd5};
        7'b0101111: {digitType, digitDecoded} = {DIGIT_L, 4'd6};
        7'b0111011: {digitType, digitDecoded} = {DIGIT_L, 4'd7};
        7'b0110111: {digitType, digitDecoded} = {DIGIT_L, 4'd8};
        7'b0001011: {digitType, digitDecoded} = {DIGIT_L, 4'd9};

        7'b0100111: {digitType, digitDecoded} = {DIGIT_G, 4'd0};
        7'b0110011: {digitType, digitDecoded} = {DIGIT_G, 4'd1};
        7'b0011011: {digitType, digitDecoded} = {DIGIT_G, 4'd2};
        7'b0100001: {digitType, digitDecoded} = {DIGIT_G, 4'd3};
        7'b0011101: {digitType, digitDecoded} = {DIGIT_G, 4'd4};
        7'b0111001: {digitType, digitDecoded} = {DIGIT_G, 4'd5};
        7'b0000101: {digitType, digitDecoded} = {DIGIT_G, 4'd6};
        7'b0010001: {digitType, digitDecoded} = {DIGIT_G, 4'd7};
        7'b0001001: {digitType, digitDecoded} = {DIGIT_G, 4'd8};
        7'b0010111: {digitType, digitDecoded} = {DIGIT_G, 4'd9};

        7'b1110010: {digitType, digitDecoded} = {DIGIT_R, 4'd0};
        7'b1100110: {digitType, digitDecoded} = {DIGIT_R, 4'd1};
        7'b1101100: {digitType, digitDecoded} = {DIGIT_R, 4'd2};
        7'b1000010: {digitType, digitDecoded} = {DIGIT_R, 4'd3};
        7'b1011100: {digitType, digitDecoded} = {DIGIT_R, 4'd4};
        7'b1001110: {digitType, digitDecoded} = {DIGIT_R, 4'd5};
        7'b1010000: {digitType, digitDecoded} = {DIGIT_R, 4'd6};
        7'b1000100: {digitType, digitDecoded} = {DIGIT_R, 4'd7};
        7'b1001000: {digitType, digitDecoded} = {DIGIT_R, 4'd8};
        7'b1110100: {digitType, digitDecoded} = {DIGIT_R, 4'd9};

        default: {digitType, digitDecoded} = {DIGIT_ERROR, 4'd0};
    endcase
end

endmodule
