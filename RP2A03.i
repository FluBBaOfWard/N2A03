;@ ASM header for the RP2A03/RP2A07 emulator
;@

#include "../ARM6502/M6502.i"
						;@ RP2A03.s
	rp2a03ptr	.req r12
	.struct 0
rp2A03State:				;@

ch0Frq:			.short 0
ch0Cnt:			.short 0
ch1Frq:			.short 0
ch1Cnt:			.short 0
ch2Frq:			.short 0
ch2Cnt:			.short 0
ch3Frq:			.short 0
ch3Cnt:			.short 0

rng:			.long 0
noiseFB:		.long 0

ch0Volume:		.long 0
ch1Volume:		.long 0
ch2Volume:		.long 0
ch3Volume:		.long 0

rp2A03Padding:	.space 8

rp2A03Regs:
ch0Duty:		.byte 0
ch0Sweep:		.byte 0
ch0Frequency:	.byte 0
ch0Length:		.byte 0
ch1Duty:		.byte 0
ch1Sweep:		.byte 0
ch1Frequency:	.byte 0
ch1Length:		.byte 0
ch2Duty:		.byte 0
ch2Unused:		.byte 0
ch2Frequency:	.byte 0
ch2Length:		.byte 0
ch3Duty:		.byte 0
ch3Unused:		.byte 0
ch3Frequency:	.byte 0
ch3Length:		.byte 0
ch4Frequency:	.byte 0
ch4Dac:			.byte 0
ch4Address:		.byte 0
ch4Length:		.byte 0

rp2A03DMA:		.byte 0
rp2A03Status:	.byte 0
rp2A03IOReg:	.byte 0
rp2A03FCounter:	.byte 0

control:		.byte 0
sq0Freq:		.byte 0
dmcLoadCounter:	.byte 0
input0:			.byte 0
input1:			.byte 0
output0:		.byte 0
rp2A03IrqPending:	.byte 0
rp2A03Padding1:	.space 1

rp2a03Size:

;@----------------------------------------------------------------------------

