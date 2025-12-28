;@ The internal audio part of the "NES" CPU.

#ifdef __arm__

#include "RP2A03.i"

	.global rp2A03Init
	.global rp2A03Reset
	.global rp2A03SetRevision
	.global rp2A03SetIRQPin
	.global rp2A03RunXCycles
	.global rp2A03SaveState
	.global rp2A03LoadState
	.global rp2A03GetStateSize
	.global rp2A03Mixer
	.global rp2A03Read
	.global rp2A03Write

.equ PFEED_SN,	0x4000			;@ Periodic Noise Feedback
.equ WFEED_SN,	0x6000			;@ White Noise Feedback

	.syntax unified
	.arm

#ifndef ARM7SOUND
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
;@ r12  = rp2a03ptr.
;@----------------------------------------------------------------------------
rp2A03Mixer:				;@ r0=len, r1=dest, r2=rp2a03ptr
	.type   rp2A03Mixer STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,r0,lsl#2
	stmfd sp!,{r4-r11,lr}
	add r12,r2,#rp2A03State
	ldmia r12,{r2-r11}	;@ Load freq/addr0-3, rng, noisefb, vol0-3
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

	stmia r12,{r2-r6}		;@ Writeback freq,addr,rng
	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
#endif
	.section .text
	.align 2
;@----------------------------------------------------------------------------
rp2A03Init:					;@ In r0=rp2a03ptr.
	.type   rp2A03Init STT_FUNC
;@----------------------------------------------------------------------------
	;@ Setup mapping for $4000-$5FFF
	ldr r1,=rp2A03Read
	str r1,[r0,#m6502ReadTbl+8]	;@ RdMem
	ldr r1,=rp2A03Write
	str r1,[r0,#m6502WriteTbl+8];@ WrMem
	mov r1,#0
	str r1,[r0,#m6502MemTbl+8]	;@ MemMap

	ldr r1,=empty_R
	ldr r2,=empty_W
	str r1,[r0,#rp2A03MemRead]
	str r2,[r0,#rp2A03MemWrite]
	str r1,[r0,#rp2A03IORead0]
	str r1,[r0,#rp2A03IORead1]
	str r2,[r0,#rp2A03IOWrite]

	b m6502Init
;@----------------------------------------------------------------------------
rp2A03Reset:				;@ In r0=rp2a03ptr, r1=RP2A03 Revision.
	.type   rp2A03Reset STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r1,rp2a03ptr,lr}
	mov rp2a03ptr,r0
	bl m6502Reset

	add r0,rp2a03ptr,#rp2A03State
	mov r1,#0
	ldr r2,=rp2A03StateSize/4
	bl memset					;@ Clear APU state

	mov r0,#PFEED_SN			;@ Periodic noise
	str r0,[rp2a03ptr,#rng]
	mov r0,#WFEED_SN			;@ White noise
	str r0,[rp2a03ptr,#noiseFB]

	ldmfd sp!,{r0}
	bl rp2A03SetRevision

	ldmfd sp!,{rp2a03ptr,lr}
	bx lr
;@----------------------------------------------------------------------------
rp2A03SaveState:		;@ In r0=destination, r1=rp2a03ptr. Out r0=state size.
	.type   rp2A03SaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,lr}
	bl m6502SaveState
	ldmfd sp!,{r0,r1}
	add r0,r0,#m6502StateSize
	add r1,r1,#rp2A03State
	mov r2,#rp2A03StateSize
	bl memcpy

	ldmfd sp!,{lr}
	mov r0,#m6502StateSize+rp2A03StateSize
	bx lr
;@----------------------------------------------------------------------------
rp2A03LoadState:			;@ In r0=rp2a03ptr, r1=source. Out r0=state size.
	.type   rp2A03LoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,lr}
	bl m6502LoadState
	ldmfd sp!,{r0,r1}
	add r0,r0,#rp2A03State
	add r1,r1,#m6502StateSize
	mov r2,#rp2A03StateSize
	bl memcpy

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
rp2A03GetStateSize:			;@ Out r0=state size.
	.type   rp2A03GetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	mov r0,#m6502StateSize+rp2A03StateSize
	bx lr

;@----------------------------------------------------------------------------
rp2A03SetRevision:			;@ rp2a03ptr = r10
;@----------------------------------------------------------------------------
	cmp r0,#REV_RP2A07			;@ PAL?
	movne r0,#REV_RP2A03		;@ Nope use NTSC
	strb r0,[rp2a03ptr,#rp2A03Revision]
	ldreq r0,=4156*2*3
	ldrne r0,=3728*2*3
	str r0,[rp2a03ptr,#frameCntConst]
	bx lr
;@----------------------------------------------------------------------------
rp2A03Frame:				;@ rp2a03ptr = r10
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	ldmfd sp!,{r4,lr}
	bx lr
;@----------------------------------------------------------------------------
rp2A03SetIRQPin:			;@ rp2a03ptr = r10
;@----------------------------------------------------------------------------
	cmp r0,#0
	ldrb r0,[rp2a03ptr,#rp2A03IrqPending]
	biceq r0,r0,#IRQ_EXTERN
	orrne r0,r0,#IRQ_EXTERN
	strb r0,[rp2a03ptr,#rp2A03IrqPending]
	b m6502SetIRQPin
;@----------------------------------------------------------------------------
rp2A03RunXCycles:			;@ r0 = number of cycles to run
;@----------------------------------------------------------------------------
	ldr r1,[rp2a03ptr,#rp2A03FrmCount]
	subs r1,r1,r0
	ldrls r2,[rp2a03ptr,#frameCntConst]
	addls r1,r1,r2
	str r1,[rp2a03ptr,#rp2A03FrmCount]
	bhi noPeriodExe
	stmfd sp!,{r0,lr}
	ldrb r1,[rp2a03ptr,#frmCntPeriod]
	ldrb r2,[rp2a03ptr,#rp2A03FCntCtr]
	tst r2,#0x80
	moveq r0,#4
	movne r0,#5
	add r1,r1,#1
	cmp r1,r0
	moveq r1,#0
	strb r1,[rp2a03ptr,#frmCntPeriod]
	cmpne r1,#2
	bleq clockAPULength

	cmp r2,#0
	bne noFrmExe

	ldrb r0,[rp2a03ptr,#rp2A03Status]
	orr r0,r0,#0x40						;@ Set Frame IRQ status
	strb r0,[rp2a03ptr,#rp2A03Status]
	ldrb r0,[rp2a03ptr,#rp2A03IrqPending]
	orr r0,r0,#IRQ_FRAME				;@ Set FRAME IRQ
	strb r0,[rp2a03ptr,#rp2A03IrqPending]
	bl m6502SetIRQPin
noFrmExe:
	ldmfd sp!,{r0,lr}
noPeriodExe:

	ldr r1,[rp2a03ptr,#rp2A03DMCCount]	;@ DMC Channel Enabled?
	cmp r1,#0
	beq m6502RunXCycles
	subs r1,r1,r0
	movmi r1,#0
	str r1,[rp2a03ptr,#rp2A03DMCCount]
	bhi m6502RunXCycles
	ldrb r1,[rp2a03ptr,#ch4Frequency]
	tst r1,#0x40						;@ DMC Loop Enabled?
	bne restartDMC
	tst r1,#0x80						;@ DMC IRQ Enabled?
	ldrb r1,[rp2a03ptr,#rp2A03Status]
	bic r1,r1,#0x10						;@ DMC not active now
	orrne r1,r1,#0x80
	strb r1,[rp2a03ptr,#rp2A03Status]
	beq m6502RunXCycles
	stmfd sp!,{r0,lr}
	ldrb r0,[rp2a03ptr,#rp2A03IrqPending]
	orr r0,r0,#IRQ_DPCM					;@ Set DMC IRQ
	strb r0,[rp2a03ptr,#rp2A03IrqPending]
	bl m6502SetIRQPin
	ldmfd sp!,{r0,lr}
	b m6502RunXCycles

restartDMC:
	stmfd sp!,{r0,lr}
	bl startDMC
	ldmfd sp!,{r0,lr}
	b m6502RunXCycles

;@----------------------------------------------------------------------------
clockAPULength:
;@----------------------------------------------------------------------------
	ldr r0,[rp2a03ptr,#ch0Length]
	ldrb r1,[rp2a03ptr,#ch0Duty]
	mvn r1,r1,lsl#19				;@ Length Counter Halt?
	and r1,r1,#0x01000000
	rsbs r0,r1,r0,ror#8
	biccc r0,r0,#0xFF000000
	ldrb r1,[rp2a03ptr,#ch1Duty]
	mvn r1,r1,lsl#19				;@ Length Counter Halt?
	and r1,r1,#0x01000000
	rsbs r0,r1,r0,ror#8
	biccc r0,r0,#0xFF000000
	ldrb r1,[rp2a03ptr,#ch2Duty]
	mvn r1,r1,lsl#17				;@ Length Counter Halt?
	and r1,r1,#0x01000000
	rsbs r0,r1,r0,ror#8
	biccc r0,r0,#0xFF000000
	ldrb r1,[rp2a03ptr,#ch3Duty]
	mvn r1,r1,lsl#19				;@ Length Counter Halt?
	and r1,r1,#0x01000000
	rsbscc r0,r1,r0,ror#8
	biccc r0,r0,#0xFF000000
	str r0,[rp2a03ptr,#ch0Length]
;@----------------------------------------------------------------------------
clockAPUEnvelope:
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
rp2A03Read:					;@ I/O read  (0x4000-0x5FFF)
;@----------------------------------------------------------------------------
	sub r1,addy,#0x4000

	cmp r1,#0x15
	beq _4015R
	cmp r1,#0x16
	beq _4016R
	cmp r1,#0x17
	beq _4017R
	cmp r1,#0x20
	ldrpl pc,[rp2a03ptr,#rp2A03MemRead]	;@ 0x4020-5FFF
;@---------------------------
	b empty_R
;@----------------------------------------------------------------------------
_4015R:						;@ $4015: Status read
;@----------------------------------------------------------------------------
	;@ Check remaining length of all channels + interrupts
	ldrb r0,[rp2a03ptr,#rp2A03Status]
	bic r1,r0,#0x40				;@ Clear Frame IRQ status
	strb r1,[rp2a03ptr,#rp2A03Status]
	and r0,r0,#0xF0
#ifdef ARM7SOUND
	stmfd sp!,{r0,lr}
	bl _4015r
	and r1,r0,#0x0F
	ldmfd sp!,{r0,lr}
	orr r0,r0,r1
#else
	ldr r1,[rp2a03ptr,#ch0Length]
	tst r1,#0x000000FF
	orrne r0,r0,#1
	tst r1,#0x0000FF00
	orrne r0,r0,#2
	tst r1,#0x00FF0000
	orrne r0,r0,#4
	tst r1,#0xFF000000
	orrne r0,r0,#8
#endif
	stmfd sp!,{r0,lr}
	ldrb r0,[rp2a03ptr,#rp2A03IrqPending]
	bic r0,r0,#IRQ_FRAME		;@ Clear Frame IRQ
	strb r0,[rp2a03ptr,#rp2A03IrqPending]
	bl m6502SetIRQPin			;@ Update IRQ pin on CPU
	ldmfd sp!,{r0,pc}
;@----------------------------------------------------------------------------
_4016R:						;@ $4016: Input 0 read
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov lr,pc
	ldr pc,[rp2a03ptr,#rp2A03IORead0]
	strb r0,[rp2a03ptr,#input0]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
_4017R:						;@ $4017: Input 1 read
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	mov lr,pc
	ldr pc,[rp2a03ptr,#rp2A03IORead1]
	strb r0,[rp2a03ptr,#input1]
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------

;@----------------------------------------------------------------------------
rp2A03Write:					;@ I/O write  (0x4000-0x5FFF)
;@----------------------------------------------------------------------------
	sub r1,addy,#0x4000
	cmp r1,#0x20
	add r2,rp2a03ptr,#rp2A03Regs
	strbmi r0,[r2,r1]
	ldrmi pc,[pc,r1,lsl#2]
	ldr pc,[rp2a03ptr,#rp2A03MemWrite]	;@ 0x4020-5FFF
;@----------------------------------------------------------------------------
#ifdef ARM7SOUND
writeTbl:
	.long soundwrite	;@ pAPU Pulse #1 Control Register 0x4000
	.long soundwrite	;@ pAPU Pulse #1 Ramp Control Register 0x4001
	.long soundwrite	;@ pAPU Pulse #1 Fine Tune (FT) Register 0x4002
	.long soundwrite	;@ pAPU Pulse #1 Coarse Tune (CT) Register 0x4003
	.long soundwrite	;@ pAPU Pulse #2 Control Register 0x4004
	.long soundwrite	;@ pAPU Pulse #2 Ramp Control Register 0x4005
	.long soundwrite	;@ pAPU Pulse #2 Fine Tune Register 0x4006
	.long soundwrite	;@ pAPU Pulse #2 Coarse Tune Register 0x4007
	.long soundwrite	;@ pAPU Triangle Control Register #1 0x4008
	.long empty_W
	.long soundwrite	;@ pAPU Triangle Frequency Register #1 0x400a
	.long soundwrite	;@ pAPU Triangle Frequency Register #2 0x400b
	.long soundwrite	;@ pAPU Noise Control Register #1 0x400c
	.long empty_W
	.long soundwrite	;@ pAPU Noise Frequency Register #1 0x400e
	.long soundwrite	;@ pAPU Noise Frequency Register #2 0x400f
	.long sndWr4010		;@ pAPU Delta Modulation Control Register 0x4010
	.long soundwrite	;@ pAPU Delta Modulation D/A Register 0x4011
	.long soundwrite	;@ pAPU Delta Modulation Address Register 0x4012
	.long sndWr4013		;@ pAPU Delta Modulation Data Length Register 0x4013
	.long _4014W		;@ $4014: Sprite DMA transfer
	.long sndWr4015
	.long _4016W
	.long sndWr4017
	.long empty_W
	.long empty_W
	.long empty_W
	.long empty_W
	.long empty_W
	.long empty_W
	.long empty_W
	.long empty_W
sndWr4010:
	stmfd sp!,{r0,addy,lr}
	bl soundwrite
	ldmfd sp!,{r0,addy,lr}
	b _4010W
sndWr4013:
	stmfd sp!,{r0,addy,lr}
	bl soundwrite
	ldmfd sp!,{r0,addy,lr}
	b _4013W
sndWr4015:
	stmfd sp!,{r0,addy,lr}
	bl soundwrite
	ldmfd sp!,{r0,addy,lr}
	b _4015W
sndWr4017:
	stmfd sp!,{r0,addy,lr}
	bl soundwrite
	ldmfd sp!,{r0,addy,lr}
	b _4017W
#else
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
	.long empty_W
	.long _400AW
	.long _400BW
	.long _400CW
	.long empty_W
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
	.long empty_W
	.long empty_W
	.long empty_W
	.long empty_W
	.long empty_W
	.long empty_W
	.long empty_W
	.long empty_W
#endif
;@----------------------------------------------------------------------------
_4000W:						;@ Pulse 1 Duty, Volume
;@----------------------------------------------------------------------------
	and r0,#0x0F
	orr r0,r0,r0,lsl#4
	orr r0,r0,r0,lsl#16
	mov r0,r0,lsl#4
	str r0,[rp2a03ptr,#ch0Volume]
	bx lr
;@----------------------------------------------------------------------------
_4001W:						;@ Pulse 1 Sweep unit
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
_4002W:						;@ Pulse 1 Frequency (low)
;@----------------------------------------------------------------------------
	add r1,rp2a03ptr,#rp2A03State
	ldrh r0,[r1,#ch0Frequency-rp2A03State]
	mov r0,r0,lsl#5
	rsb r0,r0,#1
	strh r0,[r1,#ch0Frq-rp2A03State]
	bx lr
;@----------------------------------------------------------------------------
_4003W:						;@ Pulse 1 Length, Frequency (high)
;@----------------------------------------------------------------------------
	ldrb r1,[rp2a03ptr,#rp2A03Control]
	tst r1,#1					;@ Ch0 enabled?
	adr r1,pulseLengthTable
	ldrbne r0,[r1,r0,lsr#3]
	strbne r0,[rp2a03ptr,#ch0Length]
	b _4002W
;@----------------------------------------------------------------------------
_4004W:						;@ Pulse 2 Duty, Volume
;@----------------------------------------------------------------------------
	and r0,#0x0F
	orr r0,r0,r0,lsl#4
	orr r0,r0,r0,lsl#16
	mov r0,r0,lsl#4
	str r0,[rp2a03ptr,#ch1Volume]
	bx lr
;@----------------------------------------------------------------------------
_4005W:						;@ Pulse 2 Sweep unit
;@----------------------------------------------------------------------------
	bx lr
;@----------------------------------------------------------------------------
_4006W:						;@ Pulse 2 Frequency (low)
;@----------------------------------------------------------------------------
	add r1,rp2a03ptr,#rp2A03State
	ldrh r0,[r1,#ch1Frequency-rp2A03State]
	mov r0,r0,lsl#5
	rsb r0,r0,#1
	strh r0,[r1,#ch1Frq-rp2A03State]
	bx lr
;@----------------------------------------------------------------------------
_4007W:						;@ Pulse 2 Length, Frequency (high)
;@----------------------------------------------------------------------------
	ldrb r1,[rp2a03ptr,#rp2A03Control]
	tst r1,#2					;@ Ch1 enabled?
	adr r1,pulseLengthTable
	ldrbne r0,[r1,r0,lsr#3]
	strbne r0,[rp2a03ptr,#ch1Length]
	b _4006W

;@----------------------------------------------------------------------------
_4008W:						;@ Triangle Linear counter
;@----------------------------------------------------------------------------
	and r0,#0x0F
	orr r0,r0,r0,lsl#4
	orr r0,r0,r0,lsl#16
	mov r0,r0,lsl#4
	str r0,[rp2a03ptr,#ch2Volume]
	bx lr
;@----------------------------------------------------------------------------
_400AW:						;@ Triangle Frequency (low)
;@----------------------------------------------------------------------------
	add r1,rp2a03ptr,#rp2A03State
	ldrh r0,[r1,#ch2Frequency-rp2A03State]
	mov r0,r0,lsl#5
	rsb r0,r0,#1
	strh r0,[r1,#ch2Frq-rp2A03State]
	bx lr
;@----------------------------------------------------------------------------
_400BW:						;@ Triangle Length, Frequency (high)
;@----------------------------------------------------------------------------
	ldrb r1,[rp2a03ptr,#rp2A03Control]
	tst r1,#4					;@ Ch2 enabled?
	adr r1,pulseLengthTable
	ldrbne r0,[r1,r0,lsr#3]
	strbne r0,[rp2a03ptr,#ch2Length]
	b _400AW

;@----------------------------------------------------------------------------
_400CW:						;@ Noise Volume
;@----------------------------------------------------------------------------
	and r0,#0x0F
	orr r0,r0,r0,lsl#4
	orr r0,r0,r0,lsl#16
	mov r0,r0,lsl#4
	str r0,[rp2a03ptr,#ch3Volume]
	bx lr
;@----------------------------------------------------------------------------
_400EW:						;@ Noise Period
;@----------------------------------------------------------------------------
	ldrb r1,[rp2a03ptr,#rp2A03Revision]
	cmp r1,#REV_RP2A07			;@ PAL?
	adreq r2,noisePeriodTablePAL
	adrne r2,noisePeriodTableNTSC
	mov r0,r0,lsl#1
	ldrh r0,[r2,r0]
	mov r0,r0,lsl#5
	rsb r0,r0,#1
	add r1,rp2a03ptr,#rp2A03State
	strh r0,[r1,#ch3Frq-rp2A03State]
	bx lr
;@----------------------------------------------------------------------------
_400FW:						;@ Noise Length
;@----------------------------------------------------------------------------
	ldrb r1,[rp2a03ptr,#rp2A03Control]
	tst r1,#8					;@ Ch3 enabled?
	adr r1,pulseLengthTable
	ldrbne r0,[r1,r0,lsr#3]
	strbne r0,[rp2a03ptr,#ch3Length]
	bx lr

;@----------------------------------------------------------------------------
_4010W:						;@ DMC IRQ, Loop, Frequency
;@----------------------------------------------------------------------------
	tst r0,#0x80				;@ DMC IRQ enable
	bxne lr
	ldrb r0,[rp2a03ptr,#rp2A03Status]
	bic r0,r0,#0x80
	strb r0,[rp2a03ptr,#rp2A03Status]
	ldrb r0,[rp2a03ptr,#rp2A03IrqPending]
	bic r0,r0,#IRQ_DPCM			;@ Clear DMC IRQ
	strb r0,[rp2a03ptr,#rp2A03IrqPending]
	b m6502SetIRQPin			;@ Update IRQ pin on CPU
;@----------------------------------------------------------------------------
_4011W:						;@ DMC DAC
;@----------------------------------------------------------------------------
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
	ldr r1,=513*3*CYCLE		;@ 513/514 is the right number...
	sub cycles,cycles,r1
	stmfd sp!,{r3-r6,lr}

	and r1,r0,#0xe0
	add r2,rp2a03ptr,#m6502MemTbl
	ldr r2,[r2,r1,lsr#3]
	and r0,r0,#0xff
	add r3,r2,r0,lsl#8	@ r3=DMA source
	ldr r4,=0x2004		@ DMA destination
	ldr r6,[rp2a03ptr,#m6502WriteTbl+4]
	mov r5,#0x100
dmaLoop:
	ldrb r0,[r3],#1
	mov addy,r4
	blx r6
	subs r5,r5,#1
	bne dmaLoop

	ldmfd sp!,{r3-r6,lr}
	bx lr

;@----------------------------------------------------------------------------
_4015W:						;@ Channel control
;@----------------------------------------------------------------------------
	and r0,r0,#0x1F
	ands r1,r0,#0x01
	streq r1,[rp2a03ptr,#ch0Volume]
	strbeq r1,[rp2a03ptr,#ch0Length]
	ands r1,r0,#0x02
	streq r1,[rp2a03ptr,#ch1Volume]
	strbeq r1,[rp2a03ptr,#ch1Length]
	ands r1,r0,#0x04
	streq r1,[rp2a03ptr,#ch2Volume]
	strbeq r1,[rp2a03ptr,#ch2Length]
	ands r1,r0,#0x08
	streq r1,[rp2a03ptr,#ch3Volume]
	strbeq r1,[rp2a03ptr,#ch3Length]

	strb r0,[rp2a03ptr,#rp2A03Control]
	ldrb r1,[rp2a03ptr,#rp2A03Status]
	orr r2,r0,#0x40
	and r1,r1,r2
	ands r2,r0,#0x10
	orr r0,r1,r2
	strb r0,[rp2a03ptr,#rp2A03Status]

	streq r2,[rp2a03ptr,#rp2A03DMCCount]
	stmfd sp!,{lr}
	eor r1,r1,r2
	ands r1,r1,r2
	blne startDMC
	ldmfd sp!,{lr}

	ldrb r0,[rp2a03ptr,#rp2A03IrqPending]
	bic r0,r0,#IRQ_DPCM			;@ Clear DMC IRQ
	strb r0,[rp2a03ptr,#rp2A03IrqPending]
	b m6502SetIRQPin			;@ Update IRQ pin on CPU
;@----------------------------------------------------------------------------
_4016W:						;@ $4016: Output 0 write
;@----------------------------------------------------------------------------
	and r0,#0x07				;@ Only lowest 3 bits.
	strb r0,[rp2a03ptr,#output0]
	ldr pc,[rp2a03ptr,#rp2A03IOWrite]
;@----------------------------------------------------------------------------
_4017W:						;@ $4017: FrameCounter
;@----------------------------------------------------------------------------
	and r0,r0,#0xC0
	strb r0,[rp2a03ptr,#rp2A03FCntCtr]
	mov r1,#0
	strb r1,[rp2a03ptr,#frmCntPeriod]
	ldr r1,[rp2a03ptr,#frameCntConst]
	str r1,[rp2a03ptr,#rp2A03FrmCount]
	stmfd sp!,{r0,lr}
	tst r0,#0x80
	blne clockAPULength
	ldmfd sp!,{r0,lr}
	tst r0,#0x40
	bxeq lr
	ldrb r0,[rp2a03ptr,#rp2A03Status]
	bic r0,r0,#0x40				;@ Clear Frame IRQ status
	strb r0,[rp2a03ptr,#rp2A03Status]
	ldrb r0,[rp2a03ptr,#rp2A03IrqPending]
	bic r0,r0,#IRQ_FRAME		;@ Clear Frame IRQ
	strb r0,[rp2a03ptr,#rp2A03IrqPending]
	b m6502SetIRQPin			;@ Update IRQ pin on CPU
;@----------------------------------------------------------------------------
startDMC:
;@----------------------------------------------------------------------------
	ldrb r0,[rp2a03ptr,#rp2A03Revision]
	ldrb r1,[rp2a03ptr,#ch4Frequency]
	cmp r0,#REV_RP2A07			;@ PAL?
	adreq r2,dmcPeriodTablePAL
	adrne r2,dmcPeriodTableNTSC
	and r1,r1,#0xF
	mov r1,r1,lsl#1
	ldrb r0,[rp2a03ptr,#ch4Length]
	ldrh r1,[r2,r1]
	mov r0,r0,lsl#4			;@ x16 bytes
	add r0,r0,#1			;@ +1 byte
	mov r0,r0,lsl#3			;@ x8 bits
	mul r0,r1,r0			;@ x rate
	add r0,r0,r0,lsl#1		;@ x3 because PPU cycles
	str r0,[rp2a03ptr,#rp2A03DMCCount]
	bx lr
;@----------------------------------------------------------------------------
pulseLengthTable:
	.byte 10,254, 20,  2, 40,  4, 80,  6, 160,  8, 60, 10, 14, 12, 26, 14
	.byte 12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30

dmcPeriodTableNTSC:
	.short 428, 380, 340, 320, 286, 254, 226, 214, 190, 160, 142, 128, 106, 84, 72, 54
dmcPeriodTablePAL:
	.short 398, 354, 316, 298, 276, 236, 210, 198, 176, 148, 132, 118,  98, 78, 66, 50
noisePeriodTableNTSC:
	.short 4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068
noisePeriodTablePAL:
	.short 4, 8, 14, 30, 60, 88, 118, 148, 188, 236, 354, 472, 708,  944, 1890, 3778

;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
