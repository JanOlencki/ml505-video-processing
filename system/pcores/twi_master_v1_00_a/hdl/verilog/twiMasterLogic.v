module twiMasterLogic #(
    parameter PLB_DATA_WIDTH = 32,
    parameter PLB_REG_COUNT = 1
)(
    input iSda,
    output oSda,
    output oScl,

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

reg [7:0] regStatus;
reg [7:0] regControl;
reg [7:0] regAddress;
reg [7:0] regData;

always @(posedge iPlbClk)
begin
    if(iPlbReset == 1) begin
        regData <= 8'h00;
        regAddress <= 8'h00;
        regControl <= 8'h00;
        regStatus <= 8'h00;
    end
    else begin
        if(iPlbWrCE == 1) begin
            if(iPlbBE[0] == 1)
                regData <= iPlbData[0:7];
            if(iPlbBE[1] == 1)
                regAddress <= iPlbData[8:15];
            if(iPlbBE[2] == 1)
                regControl <= iPlbData[16:23];
            if(iPlbBE[3] == 1)
                regStatus <= iPlbData[24:31];
            oPlbWrAck <= 1;
        end
        else
            oPlbWrAck <= 0;
    end
end

always @(posedge iPlbClk) begin 
    if(iPlbRdCE == 1) begin
        oPlbData <= ({regData, regAddress, regControl, regStatus});
        oPlbRdAck <= 1;
    end
    else
        oPlbRdAck <= 0;
end

assign oError = 0;

endmodule
