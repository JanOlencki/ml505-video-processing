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
#include "xgpio.h"
#include "twi_master.h"

#define TWI_VIDEO_DVI_CODEC_ADDR 0xEC
#define TWI_VIDEO_VGA_CODEC_ADDR 0x98

int main()
{
	TWIMaster twiMasterVideo;
	XGpio videoGpio;
	XGpio scannerGpio;
	char strBuf[33];
	u32 videoConfig;

	u32 scannerData;
	u32 scannerStatus;
	u32 scannerVpx;
	u64 scannerCode;
	u64 scannerCodePrev;
	u32 scannerCodesCount;
	u32 i;

    init_platform();
    twiMasterInit(&twiMasterVideo, XPAR_TWI_MASTER_VIDEO_BASEADDR, 5000);
    XGpio_Initialize(&videoGpio, XPAR_XPS_GPIO_VIDEO_DEVICE_ID);
    XGpio_SetDataDirection(&videoGpio, 1, 0xFFFFFFFF);
    XGpio_SetDataDirection(&videoGpio, 2, 0x00000000);
    XGpio_Initialize(&scannerGpio, XPAR_XPS_GPIO_SCANNER_DEVICE_ID);
	XGpio_SetDataDirection(&scannerGpio, 1, 0xFFFFFFFF);
	XGpio_SetDataDirection(&scannerGpio, 2, 0x00000000);

	XGpio_DiscreteWrite(&scannerGpio, 2, 0x808080);
    videoConfig = (32+3)<<21 | 0<<11;
    XGpio_DiscreteWrite(&videoGpio, 2, videoConfig|0x01);
    for(i = 0; i < 10; i++) asm("NOP");
    XGpio_DiscreteWrite(&videoGpio, 2, videoConfig);
    xil_printf("VideoStatus = %s\n", toBin(XGpio_DiscreteRead(&videoGpio, 1), 32, strBuf));
    xil_printf("VideoControl = %s\n", toBin(XGpio_DiscreteRead(&videoGpio, 2), 32, strBuf));

    xil_printf("DVI: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x00, NULL, 0));
    xil_printf("VGA: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_VGA_CODEC_ADDR, 0x00, NULL, 0));
    xil_printf("RAND: %x\n", twiMasterWriteTransaction(&twiMasterVideo, 0x45, 0x00, NULL, 0));

    xil_printf("Init values\n");

    u8 codecRegs[56];
    u8 sendBuffer[16];

    sendBuffer[0] = 0xC0;
    xil_printf("DVI_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x49|0x80, sendBuffer, 1));
    sendBuffer[0] = 0x09;
    xil_printf("DVI_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x21|0x80, sendBuffer, 1));
    sendBuffer[0] = 0x06;
    sendBuffer[1] = 0x26;
    sendBuffer[2] = 0x30;
    sendBuffer[3] = 0xA0;
    xil_printf("DVI_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x33|0x80, sendBuffer, 4));
    sendBuffer[0] = 0x01;
    xil_printf("DVI_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_DVI_CODEC_ADDR, 0x1C|0x80, sendBuffer, 1));

    sendBuffer[0] = 0x42;
	sendBuffer[1] = 0x00;
	sendBuffer[2] = 0x60;
	xil_printf("VGA_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_VGA_CODEC_ADDR, 0x01, sendBuffer, 3));
    xil_printf("VGA_READ: %x\n", twiMasterReadTransaction(&twiMasterVideo, TWI_VIDEO_VGA_CODEC_ADDR, 0x00, codecRegs, 8));
    for(i = 0; i < 8; i++) {
    	xil_printf("%x = %s\n", i, toBin(codecRegs[i], 8, strBuf));
    }

    //sendBuffer[0] = 0b00001111;
	//xil_printf("VGA_CONFIG: %x\n", twiMasterWriteTransaction(&twiMasterVideo, TWI_VIDEO_VGA_CODEC_ADDR, 0x20, sendBuffer, 1));

	for(i = 0; i < 10000000; i++) {
		asm("NOP");
	}

    xil_printf("VGA_READ: %x\n", twiMasterReadTransaction(&twiMasterVideo, TWI_VIDEO_VGA_CODEC_ADDR, 0x26, codecRegs, 2));
    xil_printf("%x = %d\n", 0x26, (u32)codecRegs[0]<<4|codecRegs[1]);

    xil_printf("VideoStatus = %s\n", toBin(XGpio_DiscreteRead(&videoGpio, 1), 32, strBuf));
    u32 videoStatus;

    xil_printf("ScannerFifo01 = %s\n", toBin(Xil_In32(XPAR_FIFO_INTERFACE_SCANNER_BASEADDR + 0x04), 32, strBuf));
    xil_printf("ScannerFifo00 = %s\n", toBin(Xil_In32(XPAR_FIFO_INTERFACE_SCANNER_BASEADDR + 0x00), 32, strBuf));
    xil_printf("ScannerFifo01 = %s\n", toBin(Xil_In32(XPAR_FIFO_INTERFACE_SCANNER_BASEADDR + 0x04), 32, strBuf));
    xil_printf("ScannerFifo00 = %s\n", toBin(Xil_In32(XPAR_FIFO_INTERFACE_SCANNER_BASEADDR + 0x00), 32, strBuf));
    xil_printf("ScannerFifo01 = %s\n", toBin(Xil_In32(XPAR_FIFO_INTERFACE_SCANNER_BASEADDR + 0x04), 32, strBuf));
    scannerCodesCount = 0;
    scannerCodePrev = 0;
	while(1) {
		videoStatus = XGpio_DiscreteRead(&videoGpio, 1);
		if(!(videoStatus & 0x04)) {
			xil_printf("VideoStatus = %s\n", toBin(videoStatus, 32, strBuf));
		}
		scannerStatus = Xil_In32(XPAR_FIFO_INTERFACE_SCANNER_BASEADDR + 0x04);
		if(!(scannerStatus & 0x01)) {
			//xil_printf("---------------------------------\n");
			//xil_printf("ScannerEmpty = %d, ScannerRegIndex = %d\n", scannerStatus&0x01, scannerStatus>>1);
			scannerData = Xil_In32(XPAR_FIFO_INTERFACE_SCANNER_BASEADDR + 0x00);
			scannerCode = 0;
			scannerCode = ((u64) scannerData&0xFFFFF)<<32;
			scannerVpx = scannerData>>20;

			scannerData = Xil_In32(XPAR_FIFO_INTERFACE_SCANNER_BASEADDR + 0x00);
			scannerCode = scannerCode | scannerData;
			if(scannerCode == scannerCodePrev) {
				scannerCodesCount++;
			} else {
				xil_printf("Code = %x%x decoded in %d lines \n", (u32) (scannerCodePrev>>32), (u32) scannerCodePrev, scannerVpx, scannerCodesCount);
				scannerCodesCount = 1;
			}
			scannerCodePrev = scannerCode;
		}
	}
    return 0;
}
