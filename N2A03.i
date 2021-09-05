;@ ASM header for the N2A03 emulator
;@

						;@ N2A03.s
	n2a03ptr	.req r12
	.struct 0
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

n2a03Regs:
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

n2A03DMA:		.byte 0
n2A03Status:	.byte 0
n2A03IOReg:		.byte 0
n2A03FCounter:	.byte 0

n2A03State:					;@

control:		.byte 0
sq0Freq:		.byte 0
dmcLoadCounter:	.byte 0
input0:			.byte 0
input1:			.byte 0
output0:		.byte 0
n2A03Padding1:	.space 2

irqRoutine:		.long 0		;@

n2a03Size:

;@----------------------------------------------------------------------------

