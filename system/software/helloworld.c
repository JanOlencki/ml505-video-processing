/*
 * Copyright (c) 2009-2012 Xilinx, Inc.  All rights reserved.
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 */

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xil_testio.h"
#include "twi_master.h"

#define TWI_VIDEO_DVI_CODEC_ADDR 0xEC
#define TWI_VIDEO_VGA_CODEC_ADDR 0x98

Xuint8 status;
int main()
{
	char strBuf[33];
	char strBuf2[33];
	u8 i;
	TWIMaster twiMasterVideo;

    init_platform();
    twiMasterInit(&twiMasterVideo, XPAR_TWI_MASTER_0_BASEADDR, 5000);

    xil_printf("DVI: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x00, NULL, 0));
    xil_printf("VGA: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_VGA_CODEC_ADDR, 0x00, NULL, 0));
    xil_printf("RAND: %x\n", twiMasterWriteTransaction(&twiMasterVideo, 0x45, 0x00, NULL, 0));

    xil_printf("Init values\n");

    u8 codecRegs[56];
    u8 sendBuffer[16];

    sendBuffer[0] = 0xC0;
    xil_printf("DVI_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x49+0x00, sendBuffer, 1));
    sendBuffer[0] = 0x09;
    xil_printf("DVI_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x21+0x00, sendBuffer, 1));
    sendBuffer[0] = 0x06;
    xil_printf("DVI_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x33+0x00, sendBuffer, 1));
    sendBuffer[0] = 0x26;
    xil_printf("DVI_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x34+0x00, sendBuffer, 1));
    sendBuffer[0] = 0xA0;
    xil_printf("DVI_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x36+0x00, sendBuffer, 1));

    sendBuffer[0] = 0x01;
    xil_printf("DVI_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x1C+0x00, sendBuffer, 1));


    xil_printf("DVI_READ: %x\n", twiMasterReadTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x1C+0x80, codecRegs, 56));

    for(i = 0; i < 56; i++) {
    	xil_printf("%x = %s\n", i+0x1C, toBin(codecRegs[i], 8, strBuf));
    }
//
//    xil_printf("READ_ERROR: %x\n", twiMasterReadTransaction(&twiMasterVideo, TWI_VIDEO_VGA_CODEC_ADDR, 0x00, codecRegs, 16));
//	for(i = 0; i < 16; i++) {
//		xil_printf("VGA %x = %s\n", 0x0+i, toBin(codecRegs[i], 8, strBuf));
//	}
//
//	sendBuffer[0] = 0b01001100;
//	sendBuffer[1] = 0x00;
//	xil_printf("WRITE_ERROR: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_VGA_CODEC_ADDR, 0x07, sendBuffer, 3));
//
//    xil_printf("READ_ERROR: %x\n", twiMasterReadTransaction(&twiMasterVideo, TWI_VIDEO_VGA_CODEC_ADDR, 0x00, codecRegs, 16));
//	for(i = 0; i < 16; i++) {
//		xil_printf("VGA %x = %s\n", 0x00+i, toBin(codecRegs[i], 8, strBuf));
//	}

//    Xil_Out32(XPAR_TWI_MASTER_0_BASEADDR+4, 250);
//    xil_printf("REG_DIVIDER = %x\n", Xil_In32(XPAR_TWI_MASTER_0_BASEADDR+4));
//
//    Xil_Out8(XPAR_TWI_MASTER_0_BASEADDR, 0x81);
//    xil_printf("REG_DATA = %x\n", Xil_In8(XPAR_TWI_MASTER_0_BASEADDR));
//
//	Xil_Out8(XPAR_TWI_MASTER_0_BASEADDR+3, 0x40);
//	xil_printf("REG_CONT = %s\n", toBin(Xil_In8(XPAR_TWI_MASTER_0_BASEADDR+3), 8, strBuf));
//
//	int addr;
//	for(addr = 0x0; addr <= 0xFF; addr+=2) {
//		Xil_Out8(XPAR_TWI_MASTER_0_BASEADDR+2, addr);
//		Xil_Out8(XPAR_TWI_MASTER_0_BASEADDR+3, 0x80);
//		status = Xil_In8(XPAR_TWI_MASTER_0_BASEADDR+3);
//		while((status = Xil_In8(XPAR_TWI_MASTER_0_BASEADDR+3) )& 1);
//		Xil_In8(XPAR_TWI_MASTER_0_BASEADDR+1);
//		xil_printf("REG_ADDR = %x REG_STATUS = %s %c\n", addr, toBin(Xil_In8(XPAR_TWI_MASTER_0_BASEADDR+3), 8, strBuf), (status&0b100)? ' ': '*');
//	}

	while(1);

    return 0;
}
