`timescale 1ns / 1ps

module twiMasterLogicTest;
localparam PLB_DATA_WIDTH = 32;
localparam PLB_REG_COUNT = 1;

reg iSda;
wire oSda;
wire oScl;

reg iPlbClk;
reg iPlbReset;
reg [0 : PLB_DATA_WIDTH - 1] iPlbData;
reg [0 : PLB_DATA_WIDTH/8 - 1] iPlbBE;
reg [0 : PLB_REG_COUNT - 1] iPlbRdCE;
reg [0 : PLB_REG_COUNT - 1] iPlbWrCE;
wire [0 : PLB_DATA_WIDTH - 1] oPlbData;
wire oPlbRdAck;
wire oPlbWrAck;
wire oPlbError;

localparam CLK_PER = 10;
`include "plbTestAssets.v"

twiMasterLogic #(
    PLB_DATA_WIDTH, PLB_REG_COUNT
) uut (
    iSda, oSda, oScl,
    iPlbClk, iPlbReset, iPlbData, iPlbBE,
    iPlbRdCE, iPlbWrCE, oPlbData, 
    oPlbRdAck, oPlbWrAck, oPlbError
);

reg [7:0] regByte;
reg [31:0] regWord;
initial begin
    plbReset();

    plbReadByte(32'h03, regByte);
    $display("REG_STATUS = %h", regByte);

    plbReadByte(32'h02, regByte);
    $display("REG_CONTROL = %h", regByte);

    plbReadByte(32'h01, regByte);
    $display("REG_ADRRESS = %h", regByte);

    plbReadByte(32'h00, regByte);
    $display("REG_DATA = %h", regByte);

    plbReadWord(32'h00, regWord);
    $display("REG = %h", regWord);
    
    plbWriteByte(32'h03, 8'h15);
    plbWriteByte(32'h01, 8'hBB);
    plbReadWord(32'h00, regWord);
    $display("REG = %h", regWord);
    plbWriteWord(32'h00, 32'hDEADBEEF);
    plbReadWord(32'h00, regWord);
    $display("REG = %h", regWord);
end

always @(negedge(oSda) && oScl == 1)
    $display("TWI: Start condition detected");

always @(posedge(oSda) && oScl == 1)
    $display("TWI: Stop condition detected");

endmodule
