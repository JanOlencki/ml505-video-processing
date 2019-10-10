`timescale 1ns / 1ps

module twiMasterLogicTest;
localparam PLB_DATA_WIDTH = 32;
localparam PLB_REG_COUNT = 2;

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

twiMasterLogic #(
    PLB_DATA_WIDTH, PLB_REG_COUNT, 4
) uut (
    iSda, oSda, oScl,
    iPlbClk, iPlbReset, iPlbData, iPlbBE,
    iPlbRdCE, iPlbWrCE, oPlbData, 
    oPlbRdAck, oPlbWrAck, oPlbError
);

localparam CLK_PER = 10;
`include "plbTestAssets.v"

// TWI slave mock
reg oSlvSda = 1;
always @*
    iSda = oSda & oSlvSda;

task twiSingleByteTransaction;
    input sendAddrAck;
    input sendDataAck;
    input [7:0] data; // Data to read from mock TWI slave
    reg [7:0] address;
    reg [7:0] writeData;
    integer bitIndex;
begin
    $display("%d# TWI: Transaction start", $time);
    oSlvSda = 1;
    wait(oSda && oScl)
    $display("%d# TWI: Idle state detected", $time);

    @(negedge oSda) 
        if(oScl)
            $display("%d# TWI: Start condition detected", $time);
        else 
            $display("%d# TWI: Invalid start detected", $time);
    
    for(bitIndex = 7; bitIndex >= 0; bitIndex = bitIndex - 1) begin
        @(posedge oScl) 
            address[bitIndex] = oSda; 
    end
    $display("%d# TWI: Address received [8'h%H]", $time, address);
    if(address[0])
        $display("%d# TWI: RW received [read]", $time);
    else
        $display("%d# TWI: RW received [write]", $time);
    
    if(sendAddrAck) begin
        @(negedge oScl)
            #0 oSlvSda = 0;
        @(negedge oScl)
            oSlvSda = 1;
        $display("%d# TWI: Address ACK sent", $time);
    end
    else begin
        oSlvSda = 1;
        @(negedge oScl)
        @(negedge oScl)
        $display("%d# TWI: Address ACK not sent", $time);
    end

    if(address[0]) begin
        for(bitIndex = 7; bitIndex >= 0; bitIndex = bitIndex - 1) begin
            #0 oSlvSda = data[bitIndex];
            @(negedge oScl);
        end
        $display("%d# TWI: Data sent [8'h%H]", $time, data);

        @(posedge oScl)
            if(oSda)
                $display("%d# TWI: Master ACK not received", $time);
            else
                $display("%d# TWI: Master ACK received", $time);
    end
    else begin
        for(bitIndex = 7; bitIndex >= 0; bitIndex = bitIndex - 1) begin
            @(posedge oScl)
                #0 writeData[bitIndex] = oSda;
        end
        $display("%d# TWI: Data received [8'h%H]", $time, writeData);
                        
        if(sendDataAck) begin
            @(negedge oScl)
                #0 oSlvSda = 0;
            @(negedge oScl)
                oSlvSda = 1;
            $display("%d# TWI: Data ACK sent", $time);
        end
        else begin
            oSlvSda = 1;
            @(negedge oScl)
            @(negedge oScl)
            $display("%d# TWI: Data ACK not sent", $time);
        end
    end

    @(posedge oSda) 
        if(oScl)
            $display("%d# TWI: Stop condition detected", $time);             
        else
            $display("%d# TWI: Invalid stop detected", $time);
end
endtask

// Main procedural block
reg [7:0] regByte;
reg [31:0] regWord;
initial begin
    $display("--- PLB Reset ---");
    plbReset();

    plbReadWord(32'h00, regWord);
    $display("%d# REG = %h", $time, regWord);
    plbReadWord(32'h04, regWord);
    $display("%d# REG_DIVIDER = %h", $time, regWord);

    $display("--- PLB Test R/W -- ");
    plbWriteByte(32'h01, 8'hBE);
    plbWriteByte(32'h00, 8'hEF);
    plbReadByte(32'h03, regByte);
    $display("%d# REG_STATUS = %h", $time, regByte);
    plbReadByte(32'h02, regByte);
    $display("%d# REG_CONTROL = %h", $time, regByte);
    plbReadByte(32'h01, regByte);
    $display("%d# REG_ADRRESS = %h", $time, regByte);
    plbReadByte(32'h00, regByte);
    $display("%d# REG_DATA = %h", $time, regByte);
    
    plbWriteWord(32'h04, 32'h00000005);
    plbReadWord(32'h04, regWord);
    $display("%d# REG_DIVIDER = %h", $time, regWord);

    $display("--- TWI test 1 -- ");
    // Write 8'hEF to 8'hBE with both ACK
    plbWriteByte(32'h01, 8'hBE);
    plbWriteByte(32'h00, 8'hEF);
    fork
        twiSingleByteTransaction(1, 1, 8'hCB);
        plbWriteByte(32'h02, 8'b0000_0001);
    join
    plbReadByte(32'h03, regByte);
    $display("%d# REG_STATUS = %h", $time, regByte);
    #100
    plbReadByte(32'h03, regByte);
    $display("%d# REG_STATUS = %h", $time, regByte);

    $display("--- TWI test 2 -- ");    
    // Write 8'h4A to 8'h78 without both ACK
    plbWriteByte(32'h01, 8'h78);
    plbWriteByte(32'h00, 8'h4A);
    fork
        twiSingleByteTransaction(0, 0, 8'hCB);
        plbWriteByte(32'h02, 8'b0000_0001);
    join
    #100
    plbReadByte(32'h03, regByte);
    $display("%d# REG_STATUS = %h", $time, regByte);

    $display("--- TWI test 3 -- ");
    // Read from 8'hC9 with both ACK
    plbWriteByte(32'h01, 8'hC9);
    fork
        twiSingleByteTransaction(1, 1, 8'hE3);
        plbWriteByte(32'h02, 8'b0000_0011);
    join
    #100
    plbReadByte(32'h03, regByte);
    $display("%d# REG_STATUS = %h", $time, regByte);
    plbReadByte(32'h00, regByte);
    $display("%d# REG_DATA = %h", $time, regByte);
end

endmodule
