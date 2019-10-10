module twiMasterLogic #(
    parameter PLB_DATA_WIDTH = 32,
    parameter PLB_REG_COUNT = 2
)(
    input iSda,
    output reg oSda,
    output reg oScl,

    input iPlbClk,
    input iPlbReset,
    input [0 : PLB_DATA_WIDTH - 1] iPlbData,
    input [0 : PLB_DATA_WIDTH/8 - 1] iPlbBE,
    input [0 : PLB_REG_COUNT - 1] iPlbRdCE,
    input [0 : PLB_REG_COUNT - 1] iPlbWrCE,
    output reg [0 : PLB_DATA_WIDTH - 1] oPlbData,
    output reg oPlbRdAck,
    output reg oPlbWrAck,
    output oPlbError
);

localparam IDLE = 4'd0, START = 4'd1, ADDRESS = 4'd2, SLV_ADDR_ACK = 4'd3, 
    WRITE = 4'd4, SLV_DATA_ACK = 4'd5, READ = 4'd6, MASTER_ACK = 4'd7, 
    STOP = 4'd8;

reg [3:0] state;
reg [2:0] bitIndex;
reg [7:0] address;
reg [7:0] data;
reg [31:0] counter;
reg [31:0] divider;
reg [1:0] bitStage;
reg isBussy;
reg isAddrAckError;
reg isDataAckError;
reg onDataReceived;
`ifdef DEBUG
    reg [16*8-1 : 0] stateASCII;
    always @*
        case (state)
            IDLE:           stateASCII <= {"0"+bitStage, "#IDLE", {10{" "}}};
            START:          stateASCII <= {"0"+bitStage, "#START", {9{" "}}};
            ADDRESS:        stateASCII <= {"0"+bitStage, "#ADDRESS", {7{" "}}};
            SLV_ADDR_ACK:   stateASCII <= {"0"+bitStage, "#SLV_ADDR_ACK", {2{" "}}};
            WRITE:          stateASCII <= {"0"+bitStage, "#WRITE", {9{" "}}};
            SLV_DATA_ACK:   stateASCII <= {"0"+bitStage, "#SLV_DATA_ACK", {2{" "}}};
            READ:           stateASCII <= {"0"+bitStage, "#READ", {10{" "}}};
            MASTER_ACK:     stateASCII <= {"0"+bitStage, "#MASTER_ACK", {4{" "}}};
            STOP:           stateASCII <= {"0"+bitStage, "#STOP", {10{" "}}};
        default: stateASCII <= "unknown"; 
    endcase;
`endif

reg onStartSet;
reg regRW;
reg [6:0] regAddress;
reg [7:0] regData;
reg [31:0] regDivider;

always @(posedge iPlbClk) begin
    if(iPlbReset == 1 || (state == IDLE && !onStartSet)) begin
        counter <= 0;
        bitStage <= 0;
    end
    else begin
        counter <= counter - 1;
        if(counter == 0) begin
            counter <= regDivider;
            bitStage <= bitStage - 1;
            if(bitStage == 0) begin
                bitStage <= 3;
            end           
        end
    end
end

always @(posedge iPlbClk) begin
    if(iPlbReset == 1) begin
        state <= IDLE;
        isAddrAckError <= 0;
        isDataAckError <= 0;
        onDataReceived <= 0;
    end
    else begin
        onDataReceived <= 0;
        if(counter == 0) begin
            if(bitStage == 0) begin
                case(state)
                    IDLE: if(onStartSet) begin
                            state <= START;
                            divider <= regDivider;
                            data <= regData;
                            address <= {regAddress, regRW};
                            isAddrAckError <= 0;
                            isDataAckError <= 0;
                        end
                    START:
                        state <= ADDRESS;
                    ADDRESS: if(bitIndex == 0)
                            state <= SLV_ADDR_ACK;
                    SLV_ADDR_ACK: if(address[0]) 
                            state <= READ;
                        else
                            state <= WRITE;
                    WRITE: if(bitIndex == 0)
                            state <= SLV_DATA_ACK;
                    READ: if(bitIndex == 0) begin
                            state <= MASTER_ACK;
                            onDataReceived <= 1;
                        end
                    SLV_DATA_ACK:
                            state <= STOP;
                    MASTER_ACK:
                        state <= STOP;
                    STOP:
                        state <= IDLE;        
                    default:
                        state <= IDLE;
                endcase  
            end
            else if(bitStage == 1) begin
                if(state == SLV_ADDR_ACK) begin
                    isAddrAckError <= iSda;
                end
                else if(state == SLV_DATA_ACK) begin
                    isDataAckError <= iSda;
                end
                else if(state == READ) begin
                    data[bitIndex] <= iSda;
                end
            end 
        end
    end
end

always @(posedge iPlbClk) begin
    if(iPlbReset == 1) begin
        bitIndex <= 7;
    end
    else begin
        if(state == ADDRESS || state == WRITE || state == READ) begin
            if(counter == 0 && bitStage == 0)
                bitIndex <= bitIndex - 1;
        end
        else
            bitIndex <= 7;
    end
end

always @* begin
    isBussy <= state != IDLE;

    if(state == START) begin
        oSda <= bitStage[1];
        oScl <= bitStage != 0;
    end
    else if(state == ADDRESS) begin
        oSda <= address[bitIndex];
        oScl <= bitStage == 2 || bitStage == 1;
    end
    else if(state == WRITE) begin
        oSda <= data[bitIndex];
        oScl <= bitStage == 2 || bitStage == 1;
    end
    else if(state == SLV_ADDR_ACK || state == SLV_DATA_ACK || state == READ) begin
        oSda <= 1;
        oScl <= bitStage == 2 || bitStage == 1; 
    end
    else if(state == MASTER_ACK) begin
        oSda <= 0;
        oScl <= bitStage == 2 || bitStage == 1; 
    end
    else if(state == STOP) begin
        oSda <= ~bitStage[1];
        oScl <= bitStage != 3;
    end
    else begin
        oSda <= 1;
        oScl <= 1;
    end
end

always @(posedge iPlbClk) begin
    if(iPlbReset == 1) begin
        onStartSet <= 0;
        regRW <= 0;
        regAddress <= 0;
        regData <= 0;
        regDivider <= 0;
    end
    else begin
        onStartSet <= 0;
        oPlbWrAck <= 0;
        if(onDataReceived) begin
            regData <= data;
        end
        else if(iPlbWrCE == 2'b10) begin
            if(iPlbBE[0] == 1)
                regData <= iPlbData[0:7];
            if(iPlbBE[1] == 1)
                regAddress <= iPlbData[8:14];
            if(iPlbBE[2] == 1) begin
                {regRW, onStartSet} <= iPlbData[22:23];
            end
            oPlbWrAck <= 1;
        end
        else if(iPlbWrCE == 2'b01) begin
            if(iPlbBE[0] == 1)
                regDivider[31:24] <= iPlbData[0:7];
            if(iPlbBE[1] == 1)
                regDivider[23:16] <= iPlbData[8:15];
            if(iPlbBE[2] == 1)
                regDivider[15:8] <= iPlbData[16:23];
            if(iPlbBE[3] == 1)
                regDivider[7:0] <= iPlbData[24:31];
            oPlbWrAck <= 1;
        end
    end
end

always @(posedge iPlbClk) begin 
    oPlbData <= 0;
    oPlbRdAck <= 0;
    if(iPlbRdCE == 2'b10) begin
        oPlbData <= ({regData, regAddress, 1'b0, 6'b0, regRW, 1'b0, 5'b0, isAddrAckError, isDataAckError, isBussy});
        oPlbRdAck <= 1;
    end
    else if(iPlbRdCE == 2'b01) begin
        oPlbData <= regDivider;
        oPlbRdAck <= 1;
    end
end

assign oPlbError = 0;

endmodule
