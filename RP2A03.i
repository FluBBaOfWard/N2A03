;@ ASM header for the RP2A03/RP2A07 emulator
;@

#include "ARM6502/M6502.i"

rp2A03SetResetPin = m6502SetResetPin
rp2A03SetNMIPin = m6502SetNMIPin
rp2A03RestoreAndRunXCycles = m6502RestoreAndRunXCycles
rp2A03RunXCycles = m6502RunXCycles

						;@ RP2A03.s
	rp2a03ptr	.req m6502ptr
	.struct 0
rp2A03Start:
m6502Chip:		.space m6502Size
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

rp2A03Status:	.byte 0
dmcLoadCounter:	.byte 0			;@ ch4Dac
input0:			.byte 0
input1:			.byte 0
output0:		.byte 0
rp2A03IrqPending:	.byte 0
rp2A03Padding0:	.space 2

rp2A03Regs:
ch0Duty:		.byte 0			;@ 4000
ch0Sweep:		.byte 0			;@ 4001
ch0Frequency:	.byte 0			;@ 4002
ch0Length:		.byte 0			;@ 4003
ch1Duty:		.byte 0			;@ 4004
ch1Sweep:		.byte 0			;@ 4005
ch1Frequency:	.byte 0			;@ 4006
ch1Length:		.byte 0			;@ 4007
ch2Duty:		.byte 0			;@ 4008
ch2Unused:		.byte 0			;@ 4009
ch2Frequency:	.byte 0			;@ 400A
ch2Length:		.byte 0			;@ 400B
ch3Duty:		.byte 0			;@ 400C
ch3Unused:		.byte 0			;@ 400D
ch3Frequency:	.byte 0			;@ 400E
ch3Length:		.byte 0			;@ 400F
ch4Frequency:	.byte 0			;@ 4010
ch4Dac:			.byte 0			;@ 4011
ch4Address:		.byte 0			;@ 4012
ch4Length:		.byte 0			;@ 4013

rp2A03DMA:		.byte 0			;@ 4014 sprite DMA
rp2A03Control:	.byte 0			;@ 4015
rp2A03IOReg:	.byte 0			;@ 4016
rp2A03FCounter:	.byte 0			;@ 4017

rp2A03Padding1:	.space 8		;@ 4018-401F
rp2A03StateEnd:

rp2A03MemRead:	.long 0			;@ For reads 4020-5FFF
rp2A03MemWrite:	.long 0			;@ For writes 4020-5FFF
rp2A03IORead0:	.long 0			;@ For reads 4016
rp2A03IORead1:	.long 0			;@ For reads 4017
rp2A03IOWrite:	.long 0			;@ For writes 4016
rp2A03End:

rp2A03Size = rp2A03End-rp2A03Start
rp2A03StateSize = rp2A03StateEnd-rp2A03State

;@----------------------------------------------------------------------------

