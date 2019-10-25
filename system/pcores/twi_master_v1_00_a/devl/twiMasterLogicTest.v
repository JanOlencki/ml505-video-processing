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
localparam REG_DATA_WRITE = 32'h0;
localparam REG_DATA_READ = 32'h1;
localparam REG_ADDRESS = 32'h2;
localparam REG_CONTROL = 32'h3;
localparam REG_DIVIDER = 32'h4;
`include "plbTestAssets.v"

// TWI slave mock
reg oSlvSda = 1;
always @*
    iSda = oSda & oSlvSda;

always 
begin
    wait(!oSda && !oSlvSda) 
        $display("%d# TWI: ERROR! Master and slave drive SDA low", $time);
    wait(oSda || oSlvSda);
end


task twiCheckStartAndAddress;
    input sendAddrAck;
    reg [7:0] address;
    integer bitIndex;
begin
    oSlvSda = 1;
    wait(oSda && oScl)
    $display("%d# TWI: Idle state detected", $time);

    @(negedge oSda) 
        if(oScl)
            $display("%d# TWI: Start condition detected", $time);
        else 
            $display("%d# TWI: ERROR! Invalid start detected", $time);
    
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
        @(posedge oScl)
            #0 oSlvSda = 0;
        @(negedge oScl)
            #0 oSlvSda = 1;
        $display("%d# TWI: Address ACK sent", $time);
    end
    else begin
        oSlvSda = 1;
        @(negedge oScl)
        @(negedge oScl)
        $display("%d# TWI: Address ACK not sent", $time);
    end
end
endtask

task twiSingleByteRead; // Read from slave
    input [7:0] data;
    integer bitIndex;
begin
    for(bitIndex = 7; bitIndex >= 0; bitIndex = bitIndex - 1) begin
        #0 oSlvSda = data[bitIndex];
        @(negedge oScl);
    end
    oSlvSda = 1;
    $display("%d# TWI: Data sent [8'h%H]", $time, data);

    @(posedge oScl)
        if(oSda)
            $display("%d# TWI: Master ACK not received", $time);
        else
            $display("%d# TWI: Master ACK received", $time);
    @(negedge oScl);
end
endtask

task twiSingleByteWrite; // Write to slave
    input sendDataAck;    
    reg [7:0] data;
    integer bitIndex;
begin
    for(bitIndex = 7; bitIndex >= 0; bitIndex = bitIndex - 1) begin
        @(posedge oScl)
            #0 data[bitIndex] = oSda;
    end
    $display("%d# TWI: Data received [8'h%H]", $time, data);
                    
    if(sendDataAck) begin
        @(posedge oScl)
            #0 oSlvSda = 0;
        @(negedge oScl)
            #0 oSlvSda = 1;
        $display("%d# TWI: Data ACK sent", $time);
    end
    else begin
        oSlvSda = 1;
        @(negedge oScl)
        @(negedge oScl)
        $display("%d# TWI: Data ACK not sent", $time);
        end
end
endtask

task twiCheckStop;
begin
    @(posedge oSda) 
        if(oScl)
            $display("%d# TWI: Stop condition detected", $time);             
        else
            $display("%d# TWI: ERROR! Invalid stop detected", $time); 
end
endtask

// Main procedural block
reg [7:0] regByte;
reg [31:0] regWord;
integer i;
initial begin
    $display("--- PLB Reset ---");
    plbReset();

    plbReadWord(32'h00, regWord);
    $display("%d# REG = %h", $time, regWord);
    plbReadWord(REG_DIVIDER, regWord);
    $display("%d# REG_DIVIDER = %h", $time, regWord);

    $display("--- PLB Test R/W -- ");
    plbWriteByte(REG_ADDRESS, 8'hBE);
    plbWriteByte(REG_DATA_WRITE, 8'hEF);
    plbReadByte(REG_CONTROL, regByte);
    $display("%d# REG_CONTROL = %h", $time, regByte);
    plbReadByte(REG_ADDRESS, regByte);
    $display("%d# REG_ADDRESS = %h", $time, regByte);
    plbReadByte(REG_DATA_READ, regByte);
    $display("%d# REG_DATA_R = %h", $time, regByte);
    plbReadByte(REG_DATA_WRITE, regByte);
    $display("%d# REG_DATA_W = %h", $time, regByte);
    
    plbWriteWord(REG_DIVIDER, 32'h00000005);
    plbReadWord(REG_DIVIDER, regWord);
    $display("%d# REG_DIVIDER = %h", $time, regWord);

    $display("--- TWI test 1 -- ");
    // Write 8'hEF to 8'hBE with both ACK
    plbWriteByte(REG_ADDRESS, 8'hBE);
    plbWriteByte(REG_DATA_WRITE, 8'hEF);
    fork
        begin
            twiCheckStartAndAddress(1);
            twiSingleByteWrite(1);
            twiCheckStop();
        end
        plbWriteByte(REG_CONTROL, 8'b1000_0000);
    join
    plbReadByte(REG_CONTROL, regByte);
    $display("%d# REG_CONTROL = %h", $time, regByte);
    #100;
    plbReadByte(REG_CONTROL, regByte);
    $display("%d# REG_CONTROL = %h", $time, regByte);

    $display("--- TWI test 2 -- ");    
    // Write 8'h4A to 8'h78 without both ACK
    plbWriteByte(REG_ADDRESS, 8'h78);
    plbWriteByte(REG_DATA_WRITE, 8'h4A);
    fork
        begin
            twiCheckStartAndAddress(0);
            twiSingleByteWrite(0);
            twiCheckStop();
        end
        plbWriteByte(REG_CONTROL, 8'b1000_0000);
    join
    #100;
    plbReadByte(REG_CONTROL, regByte);
    $display("%d# REG_CONTROL = %h", $time, regByte);

    $display("--- TWI test 3 -- ");
    // Read from 8'hC9 with both ACK
    plbWriteByte(REG_ADDRESS, 8'hC9);
    fork
        begin
            twiCheckStartAndAddress(1);
            twiSingleByteRead(8'h6E);
            twiCheckStop();
        end
        plbWriteByte(REG_CONTROL, 8'b1000_0000);
    join
    #100;
    plbReadByte(REG_CONTROL, regByte);
    $display("%d# REG_CONTROL = %h", $time, regByte);
    plbReadByte(REG_DATA_READ, regByte);
    $display("%d# REG_DATA = %h", $time, regByte);

    
    $display("--- TWI test 4 -- ");
    // Read 6 bytes from register 8'A6 in device with address 8'h4E
    fork
        begin
            twiCheckStartAndAddress(1);
            twiSingleByteWrite(1);
            twiCheckStartAndAddress(1);
            twiSingleByteRead(8'hF0);
            twiSingleByteRead(8'hE1);
            twiSingleByteRead(8'hD2);
            twiSingleByteRead(8'hC3);
            twiSingleByteRead(8'hB4);
            twiSingleByteRead(8'hA5);
            twiCheckStop();
        end
        begin
            plbWriteByte(REG_ADDRESS, 8'h4E);
            plbWriteByte(REG_DATA_WRITE, 8'hA6);
            plbWriteByte(REG_CONTROL, 8'b1000_0000);
            
            plbReadByte(REG_CONTROL, regByte); 
            while(regByte & 8'b1000_0000) begin // Check start bit clear
                plbReadByte(REG_CONTROL, regByte);
            end
            while(regByte & 8'b0001_0000) begin // Check is ack done
                plbReadByte(REG_CONTROL, regByte);
            end
            $display("%d# REG_CONTROL = %h", $time, regByte);

            plbWriteByte(REG_ADDRESS, 8'h4E|8'h1);
            for(i = 0; i < 6; i = i + 1) begin
                plbWriteByte(REG_CONTROL, 8'b1000_0000 | {1'b0, i == 6, 6'b0});
                plbReadByte(REG_CONTROL, regByte); 
                while(regByte & 8'b1000_0000) begin // Check start bit clear
                    plbReadByte(REG_CONTROL, regByte);
                end
                while(!(regByte & 8'b0000_0010)) begin // Check is new data received
                    plbReadByte(REG_CONTROL, regByte);
                end
                $display("%d# REG_CONTROL = %h", $time, regByte);
                
                plbReadByte(REG_DATA_READ, regByte);
                $display("%d# REG_DATA = %h", $time, regByte);        
            end
        end
    join

    #100;
    $finish;
end

initial
    #300000 $finish;

endmodule
