;@ The internal audio part of the "NES" CPU.

#ifdef __arm__

#include "N2A03.i"
//#include "../ARM6502/M6502.i"		;@ Might be needed later for SPR DMA read

	.global n2A03Reset
	.global n2A03SaveState
	.global n2A03LoadState
	.global n2A03GetStateSize
	.global n2A03Frame
	.global n2A03Mixer
	.global n2A03Read
	.global n2A03Write

.equ PFEED_SN,	0x4000			;@ Periodic Noise Feedback
.equ WFEED_SN,	0x6000			;@ White Noise Feedback

	.syntax unified
	.arm

	.section .itcm
	.align 2
;@----------------------------------------------------------------------------
;@ r0  = mix length.
;@ r1  = mixerbuffer.
;@ r2 -> r5 = pos+freq.
;@ r6  = noise generator.
;@ r7  = noise feedback.
;@ r8  = ch0 volumes.
;@ r9  = ch1 volumes.
;@ r10 = ch2 volumes.
;@ r11 = ch3 volumes.
;@ lr  = mixer reg.
;@ r12  = n2a03ptr.
;@----------------------------------------------------------------------------
n2A03Mixer:				;@ r0=len, r1=dest, r12=n2a03ptr
;@----------------------------------------------------------------------------
	mov r0,r0,lsl#2
	stmfd sp!,{r4-r11,lr}
	ldmia n2a03ptr,{r2-r11}			;@ Load freq/addr0-3, rng, noisefb, vol0-3
;@----------------------------------------------------------------------------
mixLoop:
	mov lr,#0x80000000
	orr lr,lr,#0x00008000
innerMixLoop:
	tst r2,#0x00010000
	addne lr,lr,r8
	adds r2,r2,#0x00200000
	eorcs r2,r2,r2,lsl#16

	tst r3,#0x00010000
	addne lr,lr,r9
	adds r3,r3,#0x00200000
	eorcs r3,r3,r3,lsl#16

	tst r4,#0x00010000
	addne lr,lr,r10
	adds r4,r4,#0x00200000
	eorcs r4,r4,r4,lsl#16

	tst r6,#0x1
	addne lr,lr,r11
	adds r5,r5,#0x00200000
	eorcs r5,r5,r5,lsl#16
	movscs r6,r6,lsr#1
	eorcs r6,r6,r7

	subs r0,r0,#1
	tst r0,#3
	bne innerMixLoop
	cmp r0,#0
	strpl lr,[r1],#4
	bgt mixLoop

	stmia n2a03ptr,{r2-r6}				;@ Writeback freq,addr,rng
	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------

	.section .text
	.align 2
;@----------------------------------------------------------------------------
n2A03Reset:					;@ n2a03ptr = r12 = pointer to struct, r0=irq routine
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r4,lr}

	mov r0,n2a03ptr
	ldr r1,=n2a03Size/4
	bl memclr_					;@ Clear VDP state

	ldmfd sp!,{r0}
	cmp r0,#0
	adreq r0,SetPinDummy
	str r0,[n2a03ptr,#irqRoutine]

	mov r0,#PFEED_SN			;@ Periodic noise
	strh r0,[n2a03ptr,#rng]
	mov r0,#WFEED_SN			;@ White noise
	strh r0,[n2a03ptr,#noiseFB]

	ldmfd sp!,{r4,lr}
	bx lr
;@----------------------------------------------------------------------------
n2A03SaveState:			;@ In r0=destination, r1=n2a03ptr. Out r0=state size.
	.type   n2A03SaveState STT_FUNC
;@----------------------------------------------------------------------------
	mov r2,#n2a03Size
	stmfd sp!,{r2,lr}

	bl memcpy

	ldmfd sp!,{r0,lr}
	bx lr
;@----------------------------------------------------------------------------
n2A03LoadState:			;@ In r0=n2a03ptr, r1=source. Out r0=state size.
	.type   n2A03LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov r2,#n2a03Size
	bl memcpy

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
n2A03GetStateSize:		;@ Out r0=state size.
	.type   n2A03GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#n2a03Size
	bx lr

;@----------------------------------------------------------------------------
n2A03Frame:					;@ n2a03ptr = r12 = pointer to struct
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldmfd sp!,{r4,lr}
	bx lr
;@----------------------------------------------------------------------------
SetPinDummy:
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
n2A03Read:					;@ I/O read  (0x4000-0x4017)
;@----------------------------------------------------------------------------
	sub r1,r1,#0x4000

	cmp r1,#0x15
	beq _4015R
	cmp r1,#0x16
	beq _4016R
	cmp r1,#0x17
	beq _4017R
;@---------------------------
	b empty_IO_R
;@----------------------------------------------------------------------------
_4015R:			;@ $4015: Status read
;@----------------------------------------------------------------------------
	stmfd sp!,{r2,lr}
	mov r0,#0
	ldr r2,[n2a03ptr,#irqRoutine]			;@ Clear IRQ pin on CPU
	blx r2
	ldmfd sp!,{r2,lr}
	// Check remaining length of all channels + interrupts
	ldrb r0,[n2a03ptr,#n2A03Status]
	bx lr
;@----------------------------------------------------------------------------
_4016R:			;@ $4016: Input 0 read
;@----------------------------------------------------------------------------
	ldrb r0,[n2a03ptr,#input0]
	bx lr
;@----------------------------------------------------------------------------
_4017R:			;@ $4017: Input 1 read
;@----------------------------------------------------------------------------
	ldrb r0,[n2a03ptr,#input1]
	bx lr
;@----------------------------------------------------------------------------

;@----------------------------------------------------------------------------
n2A03Write:					;@ I/O write  (0x4000-0x4017)
;@----------------------------------------------------------------------------
	sub r1,r1,#0x4000
	cmp r1,#0x18
	add r2,n2a03ptr,#n2a03Regs
	strbmi r0,[r2,r1]
	ldrmi pc,[pc,r1,lsl#2]
	b empty_IO_W
;@----------------------------------------------------------------------------
writeTbl:
	.long _4000W
	.long _4001W
	.long _4002W
	.long _4003W
	.long _4004W
	.long _4005W
	.long _4006W
	.long _4007W
	.long _4008W
	.long empty_IO_W
	.long _400AW
	.long _400BW
	.long _400CW
	.long empty_IO_W
	.long _400EW
	.long _400FW
	.long _4010W
	.long _4011W
	.long _4012W
	.long _4013W
	.long _4014W
	.long _4015W
	.long _4016W
	.long _4017W
;@----------------------------------------------------------------------------
_4000W:						;@ Pulse 1 Duty, Volume
;@----------------------------------------------------------------------------
	and r0,#0x0F
	orr r0,r0,r0,lsl#4
	orr r0,r0,r0,lsl#16
	mov r0,r0,lsl#4
	str r0,[n2a03ptr,#ch0Volume]
	bx lr
;@----------------------------------------------------------------------------
_4001W:						;@ Pulse 1 Sweep unit
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
_4002W:						;@ Pulse 1 Frequency (low)
;@----------------------------------------------------------------------------
	b setFrq0
	bx lr
;@----------------------------------------------------------------------------
_4003W:						;@ Pulse 1 Length, Frequency (high)
;@----------------------------------------------------------------------------
setFrq0:
	ldrh r0,[n2a03ptr,#ch0Frequency]
	mov r0,r0,lsl#5
	rsb r0,r0,#1
	strh r0,[n2a03ptr,#ch0Frq]
	bx lr

;@----------------------------------------------------------------------------
_4004W:						;@ Pulse 2 Duty, Volume
;@----------------------------------------------------------------------------
	and r0,#0x0F
	orr r0,r0,r0,lsl#4
	orr r0,r0,r0,lsl#16
	mov r0,r0,lsl#4
	str r0,[n2a03ptr,#ch1Volume]
	bx lr
;@----------------------------------------------------------------------------
_4005W:						;@ Pulse 2 Sweep unit
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
_4006W:						;@ Pulse 2 Frequency (low)
;@----------------------------------------------------------------------------
	b setFrq1
	bx lr
;@----------------------------------------------------------------------------
_4007W:						;@ Pulse 2 Length, Frequency (high)
;@----------------------------------------------------------------------------
setFrq1:
	ldrh r0,[n2a03ptr,#ch1Frequency]
	mov r0,r0,lsl#5
	rsb r0,r0,#1
	strh r0,[n2a03ptr,#ch1Frq]
	bx lr

;@----------------------------------------------------------------------------
_4008W:						;@ Triangle Linear counter
;@----------------------------------------------------------------------------
	and r0,#0x0F
	orr r0,r0,r0,lsl#4
	orr r0,r0,r0,lsl#16
	mov r0,r0,lsl#4
	str r0,[n2a03ptr,#ch2Volume]
	bx lr
;@----------------------------------------------------------------------------
_4009W:						;@ Unused
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
_400AW:						;@ Triangle Frequency (low)
;@----------------------------------------------------------------------------
	b setFrq2
;@----------------------------------------------------------------------------
_400BW:						;@ Triangle Length, Frequency (high)
;@----------------------------------------------------------------------------
setFrq2:
	ldrh r0,[n2a03ptr,#ch2Frequency]
	mov r0,r0,lsl#5
	rsb r0,r0,#1
	strh r0,[n2a03ptr,#ch2Frq]
	bx lr

;@----------------------------------------------------------------------------
_400CW:						;@ Noise Volume
;@----------------------------------------------------------------------------
	and r0,#0x0F
	orr r0,r0,r0,lsl#4
	orr r0,r0,r0,lsl#16
	mov r0,r0,lsl#4
	str r0,[n2a03ptr,#ch3Volume]
	bx lr
;@----------------------------------------------------------------------------
_400DW:						;@ Unused
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
_400EW:						;@ Noise Period
;@----------------------------------------------------------------------------
	adr r2,noisePeriodTableNTSC
	mov r0,r0,lsl#1
	ldrh r0,[r2,r0]
	mov r0,r0,lsl#5
	rsb r0,r0,#1
	strh r0,[n2a03ptr,#ch3Frq]
	bx lr
;@----------------------------------------------------------------------------
_400FW:						;@ Noise Length
;@----------------------------------------------------------------------------
	bx lr

;@----------------------------------------------------------------------------
_4010W:						;@ DMC IRQ, Loop, Frequency
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
_4011W:						;@ DMC DAC
;@----------------------------------------------------------------------------
	strb r0,[n2a03ptr,#dmcLoadCounter]
	bx lr

;@----------------------------------------------------------------------------
_4012W:						;@ DMC Sample address
;@----------------------------------------------------------------------------
	bx lr

;@----------------------------------------------------------------------------
_4013W:						;@ DMC Sample Length
;@----------------------------------------------------------------------------
	bx lr

;@----------------------------------------------------------------------------
_4014W:						;@ Transfer 256 bytes from written page to $2004
;@----------------------------------------------------------------------------
	bx lr

;@----------------------------------------------------------------------------
_4015W:						;@ Channel control
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,lr}
	mov r0,#0
	ldr r2,[n2a03ptr,#irqRoutine]			;@ Set IRQ pin on CPU
	blx r2
	ldmfd sp!,{r0,lr}

	mov r1,#0
	tst r0,#1
	streq r1,[n2a03ptr,#ch0Volume]
	tst r0,#2
	streq r1,[n2a03ptr,#ch1Volume]
	tst r0,#4
	streq r1,[n2a03ptr,#ch2Volume]
	tst r0,#8
	streq r1,[n2a03ptr,#ch3Volume]
	bx lr
;@----------------------------------------------------------------------------
_4016W:						;@ $4016: Output 0 write
;@----------------------------------------------------------------------------
	and r0,#0x03
	strb r0,[n2a03ptr,#output0]
	bx lr
;@----------------------------------------------------------------------------
_4017W:						;@ $4017: FrameCounter
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
pulseLengthTable:
	.byte 10,254, 20,  2, 40,  4, 80,  6, 160,  8, 60, 10, 14, 12, 26, 14
	.byte 12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30

noisePeriodTableNTSC:
	.short 4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068
noisePeriodTablePAL:
	.short 4, 8, 14, 30, 60, 88, 118, 148, 188, 236, 354, 472, 708,  944, 1890, 3778

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
