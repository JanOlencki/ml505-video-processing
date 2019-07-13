module twiMasterLogic (
    iSda,
    oSda,
    oScl,

    iClk,
    iReset,
    iData,
    iBE,
    iRdCE,
    iWrCE,
    oData,
    oRdAck,
    oWrAck,
    oError
);

parameter DATA_WIDTH = 32;
parameter REG_COUNT = 1;

input iSda;
output oSda;
output oScl;

input iClk;
input iReset;
input [0 : DATA_WIDTH - 1] iData;
input [0 : DATA_WIDTH/8 - 1] iBE;
input [0 : REG_COUNT - 1] iRdCE;
input [0 : REG_COUNT - 1] iWrCE;
output [0 : DATA_WIDTH - 1] oData;
output oRdAck;
output oWrAck;
output oError;

reg [0 : DATA_WIDTH - 1] slv_reg0;
wire [0 : 0] slv_reg_write_sel;
wire [0 : 0] slv_reg_read_sel;
reg [0 : DATA_WIDTH - 1] slv_ip2bus_data;
wire slv_read_ack;
wire slv_write_ack;
integer byte_index, bit_index;

assign
    slv_reg_read_sel  = iRdCE[0:0],
    slv_reg_write_sel = iWrCE[0:0],
    slv_write_ack     = iWrCE[0],
    slv_read_ack      = iRdCE[0];

always @( posedge iClk )
    begin: SLAVE_REG_WRITE_PROC

    if ( iReset == 1 )
        begin
        slv_reg0 <= 0;
        end
    else
        case ( slv_reg_write_sel )
        1'b1 :
            for ( byte_index = 0; byte_index <= (DATA_WIDTH/8)-1; byte_index = byte_index+1 )
            if ( iBE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                slv_reg0[bit_index] <= iData[bit_index];
        default : ;
        endcase

    end

always @( slv_reg_read_sel or slv_reg0 )
    begin: SLAVE_REG_READ_PROC

    case ( slv_reg_read_sel )
        1'b1 : slv_ip2bus_data <= slv_reg0;
        default : slv_ip2bus_data <= 0;
    endcase

    end

assign oData = slv_ip2bus_data;
assign oWrAck = slv_write_ack;
assign oRdAck = slv_read_ack;
assign oError = 0;

endmodule
