`timescale 1ns / 1ps

module scannerEAN13Test;

	// Inputs
	reg iClk;
	reg iRst;
	reg iPixelSync;
	reg iPixelActive;
	reg iPixelData;

	// Outputs
	wire oPixelSync;
	wire oPixelActive;
	wire oVideoModule;
	wire oVideoMarker;
	wire oVideoDigit;
	wire [51:0] oDataCode;
	wire oNewData;

	// Instantiate the Unit Under Test (UUT)
	scannerEAN13 #(
    .H_ACTIVE(32),
    .H_TOTAL(48),
    .V_ACTIVE(8),
    .V_TOTAL(16),
    .MIN_MODULE_WIDTH(3),
    .MAX_MODULE_WIDTH(8),
    .TOL_MODULE_WIDTH(1)
) uut (
		.iClk(iClk), 
		.iRst(iRst), 
		.iPixelSync(iPixelSync), 
		.iPixelActive(iPixelActive), 
		.iPixelData(iPixelData), 
		.oPixelSync(oPixelSync), 
		.oPixelActive(oPixelActive), 
		.oVideoModule(oVideoModule), 
		.oVideoMarker(oVideoMarker), 
		.oVideoDigit(oVideoDigit), 
		.oDataCode(oDataCode), 
		.oNewData(oNewData)
	);

	initial begin
		iClk = 0;
		iRst = 1;
		iPixelSync = 0;
		iPixelActive = 0;
		iPixelData = 0;
		#20 iRst = 0;
		
		#10 iPixelSync = 1;
		#10 iPixelSync = 0;
		iPixelActive = 1;
		iPixelData = 0;
		#100 iPixelData = 1;
		#80 iPixelData = 0;
		#80 iPixelData = 1;
		#80 iPixelData = 0;
		#100 iPixelData = 1;

	end

	always begin
		#5 iClk = ~iClk;
	end
      
endmodule

