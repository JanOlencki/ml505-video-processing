#include "twi_master.h"



char* toBin(int num, int bits, char *string) {
	int i;
	for(i = bits-1; i >= 0; i--) {
		string[i] = '0'+(num&1);
		num = num >> 1;
	}
	string[bits] = 0;
	return string;
}


void twiMasterInit(TWIMaster *instance, u32 instanceBaseAddr, u32 divider) {
	instance->baseAddress = instanceBaseAddr;
	twiMasterWriteDividerReg(instance->baseAddress, divider);
}

u8 twiMasterIsBussy(TWIMaster *instance) {
	return twiMasterReadControlReg(instance->baseAddress)&TWI_MASTER_BUSSY_BIT_MASK;
}

TWIMasterError twiMasterReadTransaction(TWIMaster *instance, u8 twiAddr, u8 regAddr, u8 data[], u8 bytesCount) {
	u8 controlReg;
	u8 i;
	char strBuf[33];
	while(twiMasterIsBussy(instance));
	twiMasterWriteAddressReg(instance->baseAddress, twiAddr&0xFE);

	twiMasterWriteDataWriteReg(instance->baseAddress, regAddr);
	twiMasterWriteControlReg(instance->baseAddress, TWI_MASTER_START_CALL_BIT_MASK);

	do {
		controlReg = twiMasterReadControlReg(instance->baseAddress);
	} while(controlReg&(TWI_MASTER_START_CALL_BIT_MASK));
	do {
		controlReg = twiMasterReadControlReg(instance->baseAddress);
	} while(controlReg&(TWI_MASTER_ACK_NOT_DONE_BIT_MASK));

	if(controlReg&TWI_MASTER_ADDR_ACK_ERROR_BIT_MASK) {
		return ADDR_ACK_ERROR;
	} else if(controlReg&TWI_MASTER_DATA_ACK_ERROR_BIT_MASK) {
		return REG_ADDR_ACK_ERROR;
	}

	if(bytesCount == 0)
		return NO_ERROR;

	twiMasterWriteAddressReg(instance->baseAddress, twiAddr|0x01);
	for(i = 0; i < bytesCount; i++) {
		twiMasterWriteControlReg(instance->baseAddress, TWI_MASTER_START_CALL_BIT_MASK | ((i+1 != bytesCount)<<TWI_MASTER_SEND_MASTER_ACK_BIT_OFFSET));
		do {
			controlReg = twiMasterReadControlReg(instance->baseAddress);

		} while(controlReg&(TWI_MASTER_START_CALL_BIT_MASK));
		do {
			controlReg = twiMasterReadControlReg(instance->baseAddress);
		} while(!(controlReg&TWI_MASTER_NEW_DATA_RECEIVED_BIT_MASK));
		if(controlReg&TWI_MASTER_ADDR_ACK_ERROR_BIT_MASK) {
			return ADDR_ACK_ERROR;
		}
		data[i] = twiMasterReadDataReadReg(instance->baseAddress);
	}

	return NO_ERROR;
}
TWIMasterError twiMasterWriteTransaction(TWIMaster *instance, u8 twiAddr, u8 regAddr, u8 data[], u8 bytesCount) {
	u8 controlReg;
	u8 i;
	char strBuf[33];

	while(twiMasterIsBussy(instance));
	twiMasterWriteAddressReg(instance->baseAddress, twiAddr&0xFE);
	twiMasterWriteDataWriteReg(instance->baseAddress, regAddr);
	twiMasterWriteControlReg(instance->baseAddress, TWI_MASTER_START_CALL_BIT_MASK);

	do {
		controlReg = twiMasterReadControlReg(instance->baseAddress);
	} while(controlReg&(TWI_MASTER_START_CALL_BIT_MASK));
	do {
		controlReg = twiMasterReadControlReg(instance->baseAddress);
	} while(controlReg&(TWI_MASTER_ACK_NOT_DONE_BIT_MASK));

	if(controlReg&TWI_MASTER_ADDR_ACK_ERROR_BIT_MASK) {
		return ADDR_ACK_ERROR;
	} else if(controlReg&TWI_MASTER_DATA_ACK_ERROR_BIT_MASK) {
		return REG_ADDR_ACK_ERROR;
	}

	for(i = 0; i < bytesCount; i++) {
		twiMasterWriteDataWriteReg(instance->baseAddress, data[i]);
		twiMasterWriteControlReg(instance->baseAddress, TWI_MASTER_START_CALL_BIT_MASK);

		do {
			controlReg = twiMasterReadControlReg(instance->baseAddress);
		} while(controlReg&(TWI_MASTER_START_CALL_BIT_MASK));
		do {
			controlReg = twiMasterReadControlReg(instance->baseAddress);
		} while(controlReg&(TWI_MASTER_ACK_NOT_DONE_BIT_MASK));
		if(controlReg&TWI_MASTER_ADDR_ACK_ERROR_BIT_MASK) {
			return ADDR_ACK_ERROR;
		} else if(controlReg&TWI_MASTER_DATA_ACK_ERROR_BIT_MASK) {
			return DATA_ACK_ERROR;
		}
	}

	return NO_ERROR;
}
