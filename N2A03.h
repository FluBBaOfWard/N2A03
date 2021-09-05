#ifndef N2A03_HEADER
#define N2A03_HEADER

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
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

	// n2a03Regs:
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

	u8 n2A03DMA;
	u8 n2A03Status;
	u8 n2A03IOReg;
	u8 n2A03FCounter;

	// n2A03State:					;@

	u8 control;
	u8 sq0Freq;
	u8 dmcLoadCounter;
	u8 input0;
	u8 input1;
	u8 output0;
	u8 n2A03Padding1[2];

	void *irqRoutine;
} N2A03;

void n2A03Reset(void *irqRoutine);

/**
 * Saves the state of the N2A03 chip to the destination.
 * @param  *destination: Where to save the state.
 * @param  *chip: The N2A03 chip to save.
 * @return The size of the state.
 */
int n2A03SaveState(void *destination, const N2A03 *chip);

/**
 * Loads the state of the N2A03 chip from the source.
 * @param  *chip: The N2A03 chip to load a state into.
 * @param  *source: Where to load the state from.
 * @return The size of the state.
 */
int n2A03LoadState(N2A03 *chip, const void *source);

/**
 * Gets the state size of a N2A03.
 * @return The size of the state.
 */
int n2A03GetStateSize(void);

void n2A03Frame(void);
void n2A03Mixer(int length, void *dest);
void n2A03Read(short address);
void n2A03Write(short address, unsigned char value);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // N2A03_HEADER
