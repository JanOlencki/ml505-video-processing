    `include "common.v"

module fifoInterfaceLogic #(
    parameter DATA_WIDTH = 32,
    parameter PLB_DATA_WIDTH = 32,
    parameter PLB_REG_COUNT = 2
)(
    (* KEEP = "TRUE" *)  input [DATA_WIDTH-1 : 0] iData,
    input iEmpty,
    output reg oReadEn,

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

localparam PLB_READS_COUNT = (DATA_WIDTH-1)/PLB_DATA_WIDTH + 1;
reg [`CLOG2(PLB_READS_COUNT):0] currentRead;
(* KEEP = "TRUE" *) reg [PLB_READS_COUNT*PLB_DATA_WIDTH-1 : 0] dataBuff;
reg emptyBuff;
reg newRead;

assign oPlbWrAck = |iPlbWrCE;
assign oPlbRdAck = |iPlbRdCE;
always @(posedge iPlbClk) begin
    if(iPlbReset == 1) begin
        currentRead <= 0;
        dataBuff <= 0;
        emptyBuff <= 0;
        oReadEn <= 0;
        newRead <= 1;
    end
    else begin
        if(currentRead == 0) begin
            dataBuff <= iData;
            emptyBuff <= iEmpty;
        end

        oReadEn <= 0;
        if(iPlbRdCE == 2'b10) begin
            newRead <= 0;
            if(newRead) begin
                currentRead <= currentRead + 1;
                dataBuff <= {dataBuff[(PLB_READS_COUNT-1)*PLB_DATA_WIDTH-1 : 0], {PLB_DATA_WIDTH{1'b0}}};
                if(currentRead == 0) begin
                    oReadEn <= 1;
                end
                if(currentRead == PLB_READS_COUNT-1) begin
                    currentRead <= 0;
                end    
            end
        end
        else begin
            newRead <= 1;
        end
    end
end

always @* begin
    if(iPlbRdCE == 2'b10) begin
        oPlbData <= dataBuff[PLB_READS_COUNT*PLB_DATA_WIDTH-1 : (PLB_READS_COUNT-1)*PLB_DATA_WIDTH];
    end
    else if(iPlbRdCE == 2'b01) begin
        oPlbData <= {currentRead, emptyBuff};
    end
    else 
        oPlbData <= 0;
end

assign oPlbError = 0;

endmodule
