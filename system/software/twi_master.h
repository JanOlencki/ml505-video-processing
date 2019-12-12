#include "xil_io.h"
#include "xil_types.h"

typedef struct  {
	u32 baseAddress;
} TWIMaster;

typedef enum {
	NO_ERROR,
	ADDR_ACK_ERROR,
	REG_ADDR_ACK_ERROR,
	DATA_ACK_ERROR
} TWIMasterError;

#define TWI_MASTER_DATA_WRITE_REG_OFFSET 0
#define TWI_MASTER_DATA_READ_REG_OFFSET 1
#define TWI_MASTER_ADDRESS_REG_OFFSET 2
#define TWI_MASTER_CONTROL_REG_OFFSET 3
#define TWI_MASTER_DIVIDER_REG_OFFSET 4

#define TWI_MASTER_START_CALL_BIT_OFFSET 7
#define TWI_MASTER_SEND_MASTER_ACK_BIT_OFFSET 6
#define TWI_MASTER_ACK_NOT_DONE_BIT_OFFSET 4
#define TWI_MASTER_DATA_ACK_ERROR_BIT_OFFSET 3
#define TWI_MASTER_ADDR_ACK_ERROR_BIT_OFFSET 2
#define TWI_MASTER_NEW_DATA_RECEIVED_BIT_OFFSET 1
#define TWI_MASTER_BUSSY_BIT_OFFSET 0

#define TWI_MASTER_START_CALL_BIT_MASK (1<<TWI_MASTER_START_CALL_BIT_OFFSET)
#define TWI_MASTER_SEND_MASTER_ACK_BIT_MASK (1<<TWI_MASTER_SEND_MASTER_ACK_BIT_OFFSET)
#define TWI_MASTER_ACK_NOT_DONE_BIT_MASK (1<<TWI_MASTER_ACK_NOT_DONE_BIT_OFFSET)
#define TWI_MASTER_DATA_ACK_ERROR_BIT_MASK (1<<TWI_MASTER_DATA_ACK_ERROR_BIT_OFFSET)
#define TWI_MASTER_ADDR_ACK_ERROR_BIT_MASK (1<<TWI_MASTER_ADDR_ACK_ERROR_BIT_OFFSET)
#define TWI_MASTER_NEW_DATA_RECEIVED_BIT_MASK (1<<TWI_MASTER_NEW_DATA_RECEIVED_BIT_OFFSET)
#define TWI_MASTER_BUSSY_BIT_MASK (1<<TWI_MASTER_BUSSY_BIT_OFFSET)

#define twiMasterReadDataWriteReg(baseAddr) Xil_In8((baseAddr) + TWI_MASTER_DATA_WRITE_REG_OFFSET)
#define twiMasterReadDataReadReg(baseAddr) Xil_In8((baseAddr) + TWI_MASTER_DATA_READ_REG_OFFSET)
#define twiMasterReadAddressReg(baseAddr) Xil_In8((baseAddr) + TWI_MASTER_ADDRESS_REG_OFFSET)
#define twiMasterReadControlReg(baseAddr) Xil_In8((baseAddr) + TWI_MASTER_CONTROL_REG_OFFSET)
#define twiMasterReadDividerReg(baseAddr) Xil_In32((baseAddr) + TWI_MASTER_DIVIDER_REG_OFFSET)

#define twiMasterWriteDataWriteReg(baseAddr, data) Xil_Out8((baseAddr) + TWI_MASTER_DATA_WRITE_REG_OFFSET, (data))
#define twiMasterWriteDataReadReg(baseAddr, data) Xil_Out8((baseAddr) + TWI_MASTER_DATA_READ_REG_OFFSET, (data))
#define twiMasterWriteAddressReg(baseAddr, data) Xil_Out8((baseAddr) + TWI_MASTER_ADDRESS_REG_OFFSET, (data))
#define twiMasterWriteControlReg(baseAddr, data) Xil_Out8((baseAddr) + TWI_MASTER_CONTROL_REG_OFFSET, (data))
#define twiMasterWriteDividerReg(baseAddr, data) Xil_Out32((baseAddr) + TWI_MASTER_DIVIDER_REG_OFFSET, (data))

void twiMasterInit(TWIMaster *instance, u32 instanceBaseAddr, u32 divider);
u8 twiMasterIsBussy(TWIMaster *instance);
TWIMasterError twiMasterReadTransaction(TWIMaster *instance, u8 twiAddr, u8 regAddr, u8 data[], u8 bytesCount);
TWIMasterError twiMasterWriteTransaction(TWIMaster *instance, u8 twiAddr, u8 regAddr, u8 data[], u8 bytesCount);

char* toBin(int num, int bits, char *string);
