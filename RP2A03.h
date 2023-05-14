#ifndef RP2A03_HEADER
#define RP2A03_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "ARM6502/M6502.h"

typedef struct {
	// rp2A03State:					;@

	u16 ch0Frq;
	u16 ch0Cnt;
	u16 ch1Frq;
	u16 ch1Cnt;
	u16 ch2Frq;
	u16 ch2Cnt;
	u16 ch3Frq;
	u16 ch3Cnt;

	u32 rng;
	u32 noiseFB;

	u32 ch0Volume;
	u32 ch1Volume;
	u32 ch2Volume;
	u32 ch3Volume;

	// rp2a03Regs:
	u8 ch0Duty;
	u8 ch0Sweep;
	u8 ch0Frequency;
	u8 ch0Length;
	u8 ch1Duty;
	u8 ch1Sweep;
	u8 ch1Frequency;
	u8 ch1Length;
	u8 ch2Duty;
	u8 ch2Unused;
	u8 ch2Frequency;
	u8 ch2Length;
	u8 ch3Duty;
	u8 ch3Unused;
	u8 ch3Frequency;
	u8 ch3Length;
	u8 ch4Frequency;
	u8 ch4Dac;
	u8 ch4Address;
	u8 ch4Length;

	u8 rp2A03DMA;
	u8 rp2A03Status;
	u8 rp2A03IOReg;
	u8 rp2A03FCounter;

	u8 control;
	u8 sq0Freq;
	u8 dmcLoadCounter;
	u8 input0;
	u8 input1;
	u8 output0;
	u8 irqPending;
	u8 rp2A03Padding1[1];

} RP2A03;

void rp2A03Init(const RP2A03 *chip);

void rp2A03Reset(const RP2A03 *chip);

/**
 * Saves the state of the RP2A03 chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The RP2A03 chip to save.
 * @return The size of the state.
 */
int rp2A03SaveState(void *destination, const RP2A03 *chip);

/**
 * Loads the state of the RP2A03 chip from the source.
 * @param  *chip: The RP2A03 chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int rp2A03LoadState(RP2A03 *chip, const void *source);

/**
 * Gets the state size of a RP2A03.
 * @return The size of the state.
 */
int rp2A03GetStateSize(void);

void rp2A03Frame(void);
void rp2A03Mixer(int length, void *dest);
void rp2A03Read(short address);
void rp2A03Write(short address, unsigned char value);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // RP2A03_HEADER
