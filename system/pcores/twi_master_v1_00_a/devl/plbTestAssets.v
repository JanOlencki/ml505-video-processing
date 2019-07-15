// Assets for testing IP blocks that comunicate over PLB by IBIF block
// Work correctly with DATA_WIDTH = 32

localparam PLB_ADDRESS_WIDTH = 32;
initial begin
    iPlbClk = 0;
    iPlbReset = 0;
    iPlbData = 0;
    iPlbBE = 0;
    iPlbRdCE = 0;
    iPlbWrCE = 0;
end

always begin
    #(CLK_PER/2) iPlbClk = ~iPlbClk;
end

task plbReset;
begin    
    @(posedge iPlbClk)
    iPlbReset = 1;
    @(posedge iPlbClk)
    #0 iPlbReset = 0;
end
endtask

task plbReadByte;
input [0 : PLB_ADDRESS_WIDTH - 1] address; // Adrress like address in microblaze memory model
output [0:7] data;
reg [0:1] byteIndex;
begin    
    byteIndex = address[PLB_ADDRESS_WIDTH - 2 : PLB_ADDRESS_WIDTH - 1];
    @(posedge iPlbClk)
    iPlbBE = 0;
    iPlbBE[byteIndex] = 1;
    iPlbRdCE = 0;
    iPlbRdCE[address/4] = 1;

    @(posedge iPlbClk && oPlbRdAck == 1)
    data = oPlbData[8*byteIndex +: 8];
    iPlbRdCE = 0;
    iPlbBE = 0;
end
endtask

task plbReadWord;
input [0 : PLB_ADDRESS_WIDTH - 1] address; // Adrress like address in microblaze memory model
output [0:31] data;
begin    
    @(posedge iPlbClk)
    iPlbBE = 4'hF;
    iPlbRdCE = 0;
    iPlbRdCE[address/4] = 1;

    @(posedge iPlbClk && oPlbRdAck == 1)
    data = oPlbData;
    iPlbRdCE = 0;
    iPlbBE = 0;
end
endtask

task plbWriteByte;
input [0 : PLB_ADDRESS_WIDTH - 1] address; // Adrress like address in microblaze memory model
input [0:7] data;
reg [0:1] byteIndex;
begin    
    byteIndex = address[PLB_ADDRESS_WIDTH - 2 : PLB_ADDRESS_WIDTH - 1];
    @(posedge iPlbClk)
    iPlbData = 0;
    iPlbData[8*byteIndex +: 8] = data;
    iPlbBE = 0;
    iPlbBE[byteIndex] = 1;
    iPlbWrCE = 0;
    iPlbWrCE[address/4] = 1;

    @(posedge iPlbClk && oPlbWrAck == 1)
    iPlbWrCE = 0;
    iPlbBE = 0;
    iPlbData = 0;
end
endtask

task plbWriteWord;
input [0 : PLB_ADDRESS_WIDTH - 1] address; // Adrress like address in microblaze memory model
input [0:31] data;
begin    
    @(posedge iPlbClk)
    iPlbData = data;
    iPlbBE = 4'hF;
    iPlbWrCE = 0;
    iPlbWrCE[address/4] = 1;

    @(posedge iPlbClk && oPlbWrAck == 1)
    iPlbWrCE = 0;
    iPlbBE = 0;
    iPlbData = 0;
end
endtask