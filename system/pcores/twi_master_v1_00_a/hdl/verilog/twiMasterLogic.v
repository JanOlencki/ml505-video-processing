module twiMasterLogic #(
    parameter DATA_WIDTH = 32,
    parameter REG_COUNT = 1
)(
    input iSda,
    output oSda,
    output oScl,

    input iClk,
    input iReset,
    input [0 : DATA_WIDTH - 1] iData,
    input [0 : DATA_WIDTH/8 - 1] iBE,
    input [0 : REG_COUNT - 1] iRdCE,
    input [0 : REG_COUNT - 1] iWrCE,
    output reg [0 : DATA_WIDTH - 1] oData,
    output reg oRdAck,
    output reg oWrAck,
    output oError
);

reg [7:0] regStatus;
reg [7:0] regControl;
reg [7:0] regAdrress;
reg [7:0] regData;

always @(posedge iClk)
begin
    if(iReset == 1) begin
        regData <= 8'hDA;
        regAdrress <= 8'hAD;
        regControl <= 8'hC0;
        regStatus <= 8'hF0;
    end
    else begin
        if(iWrCE == 1) begin
            if(iBE[0] == 1)
                regData <= iData[0:7];
            if(iBE[1] == 1)
                regAdrress <= iData[8:15];
            if(iBE[2] == 1)
                regControl <= iData[16:23];
            if(iBE[3] == 1)
                regStatus <= iData[24:31];
            oWrAck <= 1;
        end
        else
            oWrAck <= 0;
    end
end

always @(posedge iClk) begin 
    if(iRdCE == 1) begin
        oData <= ({regData, regAdrress, regControl, regStatus});
        oRdAck <= 1;
    end
    else
        oRdAck <= 0;
end

assign IP2Bus_Error = 0;

endmodule
