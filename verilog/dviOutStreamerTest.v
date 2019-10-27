`timescale 1ns / 1ps

module dviOutStreamerTest;
	reg iClk_0;
	reg iClk_90;
	reg iRst;
	wire [11:0] oData;
	wire oHsync;
	wire oVsync;
	wire oDe;

	dviOutStreamer uut (
		.iClk_0(iClk_0), 
		.iClk_90(iClk_90), 
		.iRst(iRst), 
		.oData(oData), 
		.oHsync(oHsync), 
		.oVsync(oVsync), 
		.oDe(oDe)
	);

	initial begin
		iClk_0 = 0;
		iClk_90 = 0;
		iRst = 1;
		#50 iRst = 0;
	end

	always begin
		#5 iClk_0 = ~iClk_0;
		#5 iClk_90 = ~iClk_90;
	end
      
endmodule

