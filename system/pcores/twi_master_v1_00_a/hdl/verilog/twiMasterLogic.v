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
    output oPlbRdAck,
    output oPlbWrAck,
    output oPlbError
);

localparam IDLE = 4'd0, START = 4'd1, ADDRESS = 4'd2, SLV_ADDR_ACK = 4'd3, 
    WRITE = 4'd4, SLV_DATA_ACK = 4'd5, READ = 4'd6, MASTER_ACK = 4'd7, 
    STOP = 4'd8;

reg [3:0] state;
reg [3:0] nextState;
reg [2:0] bitIndex;
reg [31:0] counter;
reg [31:0] divider;
reg [1:0] bitStage;

reg [7:0] address;
reg [7:0] dataRead;
reg [7:0] dataWrite;
reg bussy;
reg ackNotDone;
reg addrAckError;
reg dataAckError;
reg newDataReceived;
reg sendMasterAck;
reg clearStartReg;

reg regNewDataReceived;
reg regSendMasterAck;
reg regStartCall;
reg [7:0] regAddress;
reg [7:0] regDataWrite;
reg [7:0] regDataRead;
reg [31:0] regDivider;

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

    reg [16*8-1 : 0] nextStateASCII;
    always @*
        case (nextState)
            IDLE:           nextStateASCII <= {"IDLE", {12{" "}}};
            START:          nextStateASCII <= {"START", {11{" "}}};
            ADDRESS:        nextStateASCII <= {"ADDRESS", {9{" "}}};
            SLV_ADDR_ACK:   nextStateASCII <= {"SLV_ADDR_ACK", {4{" "}}};
            WRITE:          nextStateASCII <= {"WRITE", {11{" "}}};
            SLV_DATA_ACK:   nextStateASCII <= {"SLV_DATA_ACK", {4{" "}}};
            READ:           nextStateASCII <= {"READ", {12{" "}}};
            MASTER_ACK:     nextStateASCII <= {"MASTER_ACK", {8{" "}}};
            STOP:           nextStateASCII <= {"STOP", {12{" "}}};
        default: stateASCII <= "unknown"; 
    endcase;
`endif

always @* begin
    case(state)
        IDLE: 
            if(regStartCall)
                nextState <= START;
            else
                nextState <= IDLE;
        START:
            nextState <= ADDRESS;
        ADDRESS:
            if(bitIndex == 0)
                nextState <= SLV_ADDR_ACK;
            else
                nextState <= ADDRESS;
        SLV_ADDR_ACK:
            if(address[0]) 
                nextState <= READ;
            else
                nextState <= WRITE;
        WRITE:
            if(bitIndex == 0)
                nextState <= SLV_DATA_ACK;
            else
                nextState <= WRITE;
        READ:
            if(bitIndex == 0)
                nextState <= MASTER_ACK;
            else
                nextState <= READ;
        SLV_DATA_ACK:
            if(regStartCall) begin
                if(address == regAddress)
                    nextState <= WRITE;
                else
                    nextState <= START;
            end
            else
                nextState <= STOP;
        MASTER_ACK:
            if(regStartCall) begin
                if(address == regAddress)
                    nextState <= READ;
                else
                    nextState <= START;
            end
            else
                nextState <= STOP;
        STOP:
            nextState <= IDLE;        
        default:
            nextState <= IDLE;
    endcase  
end

always @(posedge iPlbClk) begin
    if(iPlbReset == 1 || (state == IDLE && nextState != START)) begin
        counter <= 0;
        bitStage <= 0;
    end
    else begin
        counter <= counter - 1;
        if(counter == 0) begin
            counter <= divider;
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
        addrAckError <= 0;
        dataAckError <= 0;
        newDataReceived <= 0;
        clearStartReg <= 0;
    end
    else begin
        newDataReceived <= 0;
        clearStartReg <= 0;
        if(counter == 0) begin
            if(bitStage == 0) begin
                state <= nextState;
                if(state == IDLE || nextState == IDLE) begin
                    divider <= regDivider;             
                end

                if(state == IDLE && nextState == START) begin
                    addrAckError <= 0;
                    dataAckError <= 0;
                end       
                
                if(nextState == MASTER_ACK) begin
                    newDataReceived <= 1;
                    regDataRead <= dataRead;
                end 
                else if(nextState == START 
                    || (state == SLV_DATA_ACK && nextState == WRITE) 
                    || (state == MASTER_ACK && nextState == READ)) begin
                    clearStartReg <= 1;
                    sendMasterAck <= regSendMasterAck;
                    dataWrite <= regDataWrite;
                    address <= regAddress;
                end
            end
            else if(bitStage == 1) begin
                if(state == SLV_ADDR_ACK) begin
                    addrAckError <= iSda;
                end
                else if(state == SLV_DATA_ACK) begin
                    dataAckError <= iSda;
                end
                else if(state == READ) begin
                    dataRead[7:1] <= dataRead[6:0];
                    dataRead[0] <= iSda;
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
    bussy <= state != IDLE;
    if(state == IDLE || state == STOP)
        ackNotDone <= 0;
    else if(state == SLV_DATA_ACK || state == MASTER_ACK)
        ackNotDone <= bitStage != 0;
    else
        ackNotDone <= 1;

    if(state == START) begin
        oSda <= bitStage[1];
        oScl <= bitStage != 0;
    end
    else if(state == ADDRESS) begin
        oSda <= address[bitIndex];
        oScl <= bitStage == 2 || bitStage == 1;
    end
    else if(state == WRITE) begin
        oSda <= dataWrite[bitIndex];
        oScl <= bitStage == 2 || bitStage == 1;
    end
    else if(state == SLV_ADDR_ACK || state == SLV_DATA_ACK || state == READ) begin
        oSda <= 1;
        oScl <= bitStage == 2 || bitStage == 1; 
    end
    else if(state == MASTER_ACK) begin
        oSda <= ~sendMasterAck;
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

assign oPlbWrAck = |iPlbWrCE;
assign oPlbRdAck = |iPlbRdCE;
always @(posedge iPlbClk) begin
    if(iPlbReset == 1) begin
        regStartCall <= 0;
        regSendMasterAck <= 0;
        regDivider <= 0;
    end
    else begin
        if(iPlbWrCE == 2'b10) begin
            if(iPlbBE[0])
                regDataWrite <= iPlbData[0:7];
            if(iPlbBE[2])
                regAddress <= iPlbData[16:23];
            if(iPlbBE[3]) begin
                if(iPlbData[24])
                    regStartCall <= 1;
                regSendMasterAck <= iPlbData[25];
            end
        end
        else if(iPlbWrCE == 2'b01) begin
            if(iPlbBE[0])
                regDivider[31:24] <= iPlbData[0:7];
            if(iPlbBE[1])
                regDivider[23:16] <= iPlbData[8:15];
            if(iPlbBE[2])
                regDivider[15:8] <= iPlbData[16:23];
            if(iPlbBE[3])
                regDivider[7:0] <= iPlbData[24:31];
        end
        if(clearStartReg)
            regStartCall <= 0;
    end
end

always @(posedge iPlbClk) begin 
    if(iPlbReset == 1) begin
        regNewDataReceived <= 0;
    end 
    else begin
        if(newDataReceived)
            regNewDataReceived <= 1;
        else if(iPlbRdCE == 2'b10 && iPlbBE[1])
            regNewDataReceived <= 0;
    end
end
always @* begin
    if(iPlbRdCE == 2'b10) begin
        oPlbData[0:7] <= regDataWrite;
        oPlbData[8:15] <= regDataRead;
        oPlbData[16:23] <= regAddress;
        oPlbData[24:25] <= {regStartCall, regSendMasterAck};
        oPlbData[26:31] <= {1'b0, ackNotDone, dataAckError, addrAckError, regNewDataReceived, bussy};
    end
    else if(iPlbRdCE == 2'b01) begin
        oPlbData <= {regDivider};
    end
    else 
        oPlbData <= 0;
end

assign oPlbError = 0;

endmodule
