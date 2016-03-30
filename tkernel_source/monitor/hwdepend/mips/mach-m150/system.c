/*
 *----------------------------------------------------------------------
 *    T-Kernel 2.0 Software Package
 *
 *    Copyright 2011 by Ken Sakamura.
 *    This software is distributed under the latest version of T-License 2.x.
 *----------------------------------------------------------------------
 *
 *    Released by T-Engine Forum(http://www.t-engine.org/) at 2011/05/17.
 *    Modified by TRON Forum(http://www.tron.org/) at 2015/06/01.
 *
 *    Modified for APP-M150(MIPS32) at 2015/10/19.
 *
 *----------------------------------------------------------------------
 */

/*
 *	system.c	( T-Monitor for APP-M150 )
 *
 *	 system boot processing
 */

#include <tmonitor.h>

EXPORT	UW	delay64us;

/* Register Stack
	regStack[1-31]	r1 .. r31
		[32-33]	hi,lo
		[34-44]	CP0_IDX,RND,ELO0,ELO1,CTX,PMSK,WIR,BVA,EHI,PSR,OCC
		[45-51] CP0_EPC,PRID,CFG,LLA,TLO,THI,EEPC
		[52,53]	fcr0,fcr31
		[54-85]	f0 .. 31
*/
EXPORT	union {
	UD	d[(86 + 2) / 2];	// Aligned by 8 bytes
	UW	w[86 + 2];
} regStack;

/*
 *	Cache operation
 */
#define	CacheLineSZ	32
#define	DCacheSZ	16384
#define	ICacheSZ	16384

/*
 * sync
 */
Inline	void	_sync ( void )
{
	Asm("sync");
}

/*
 * invalidate btb
 */
Inline	void	_invalidateBTB ( void )
{
	UW	t = 0;

	Asm(	"mfc0 %0, $16, 7\n"
		"nop\n"
		"ori %0,2\n"
		"mtc0 %0, $16, 7" :: "r" (t));
}

EXPORT	void	FlushCacheAll( void )
{
	VB	*p;
#define	KSEG0	((VB*)0x80000000)

	for ( p = KSEG0; p < KSEG0 + DCacheSZ; p += CacheLineSZ ) {
		/* Index Write Back Invalidate (Data) */
		Asm("cache (0 << 2) | 1, (%0)" : : "r"(p));
	}

	_sync();

	Asm("mtc0 $0, $28");	/* Clear Taglo */
	Asm("mtc0 $0, $29");	/* Clear TagHi */

        for ( p = KSEG0; p < KSEG0 + ICacheSZ; p += CacheLineSZ ) {
		/* Index Store Tag (instruction) */
		Asm("cache (2 << 2) | 0, (%0)" :: "r"(p));
	}
	_invalidateBTB();
}

/* Timer Counter Unit */
#define	_TCU(ofs)	( 0xB0002000 + ofs )

#define	OSTBIT		(1 << 15)
#define	TCU_TESR	_TCU(0x14)	/* Enable Set Register:H:W */
#define	TCU_TECR	_TCU(0x18)	/* Enable Clear Register:H:W */
#define	TCU_TFSR	_TCU(0x24)	/* Flag Set Register:W */
#define	TCU_TFCR	_TCU(0x28)	/* Flag Clear Register:W */
#define	TCU_TMSR	_TCU(0x34)	/* Mask Set Register:W */
#define	TCU_TMCR	_TCU(0x38)	/* Mask Clear Register:W */
#define	TCU_TSSR	_TCU(0x2C)	/* Clock Stop Set Register:W */
#define	TCU_TSCR	_TCU(0x3C)	/* Clock Stop Clear Register:W */

/* Operating System Timer */
#define	OST_DR		_TCU(0xE0)	/* Data Register */
#define	OST_CNTL	_TCU(0xE4)	/* Counter Lo 32 Bits Register */
#define	OST_CNTH	_TCU(0xE8)	/* Counter Hi 32 Bits Register */
#define	OST_CSR		_TCU(0xEC)	/* Control Register:H */

/* OSTCSR Bits */
#define	CSR_CNT_MD	(1 << 15)	/* Count Mode: 0: Wrap */
#define	CSR_PS_1	((0) << 3)	/* PreScaller 1/1 */
#define	CSR_EXT_EN	(1 << 2)	/* Select EXTAL */

/* Timer Clock */
#define EXTAL_Hz	24000000	/* EXTAL 24 MHz */
#define TIMER_CLK	(EXTAL_Hz / 1)	/* PreScaller 1/1 */

/* CPU clock */
#define CPU_CLK		792000000	/* CPU 792 MHz */

#define	LOOP_CYCLE	2
#define	DEFAULT_CNT	( (CPU_CLK / 1000000 / LOOP_CYCLE) * 64)

/*
 * Use OS timer because the MPU Counter (CP0 Register 9) does not work.
 */
LOCAL	UW	CtrlTimer( INT ctl )
{
	if ( ctl > 0 ) {		/* Start Timer */
		/* Supply timer clock */
		out_w(TCU_TSCR, OSTBIT);

		/* Stop timer */
		out_h(OST_CSR, 0);

		/* Choose clock & Mode (No Wrap) */
		out_h(OST_CSR, CSR_CNT_MD | CSR_PS_1 | CSR_EXT_EN);

		/* Mask timer interrupt (disable) */
		out_w(TCU_TFCR, OSTBIT);
		out_w(TCU_TMSR, OSTBIT);

		/* Clear counter */
		out_w(OST_CNTL, 0);
		out_w(OST_CNTH, 0);
		out_w(OST_DR, 0);

		/* Start timer count */
		out_h(TCU_TESR, OSTBIT);

	} else if ( ctl < 0 ) {	/* Stop Timer */
		/* Stop timer */
		out_h(TCU_TECR, OSTBIT);

		/* Stop timer clock */
		out_w(TCU_TSSR, OSTBIT);

	} else {			/* Read Timer Count */
		return in_w(OST_CNTL);	/* Lower 32 bits only */

	}
	return 0;
}

/*
 * Loop wait
 *	disable the inline expansion caused by compiler optimization
 *	to obtain accurate measurement.
 */
__attribute__ ((noinline))
LOCAL	void	WaitLoop( UW count )
{
	Asm("		.set	push		\n"
	"		.set	noreorder	\n"
	"	_loop:	bnez	%0, _loop	\n"
	"		subu	%0, %0, 1	\n"
	"		.set	pop		\n"
	"		.set	reorder		\n"
		: "=r"(count)
		: "0"(count)
	);
}

/*
 * Wait nano/micro/mili seconds
 */
EXPORT	void	waitNsec( UW nsec )
{
	WaitLoop(nsec * delay64us / 64000);
}
EXPORT	void	waitUsec( UW usec )
{
	WaitLoop(usec * delay64us / 64);
}
EXPORT	void	waitMsec( UW msec )
{
	for ( ; msec > 0; msec-- ) waitUsec(1000);
}

/*
 * calculate the loop count for a given time (in microseconds)
 *	interrupt-disabled state is assumed.
 */
EXPORT	void	setupWaitUsec( void )
{
	UW	cnt, sc, ec;

	/* Start timer */
	CtrlTimer(1);
	WaitLoop(1000);

	/* Measure time for 1100000 loops */
	sc = CtrlTimer(0);
	WaitLoop(1100000);
	ec = CtrlTimer(0);
	cnt = ec - sc;

	/* Measure time for 100000 loops */
	sc = CtrlTimer(0);
	WaitLoop(100000);
	ec = CtrlTimer(0);

	/* Delete time for operation except for loops and
	   compute the net time for 1000000 loops */
	cnt -= ec - sc;

	/* Stop timer */
	CtrlTimer(-1);

	/* Compute number of loops for 64 micro second
	 *			1000000 loops
	 *	loop64us = ------------------------- * 64usec
	 *		    cnt * (1000000 / TMRCLK)
	 *	TMRCLK = Timer input clock (Hz)
	 */
	delay64us = ( cnt <= 0 ) ? DEFAULT_CNT :
			( (long long)TIMER_CLK * 64 / cnt );
}

/*
 * Control LED
 *	bit 16: Green Mask (1: No Change)  bit 0: Green value (1:ON)
 *	bit 17: Yellow Mask (1: No Change) bit 1: Yellow Value (1:ON)
 */
EXPORT	void	cpuLED( W v )
{
#define	PcPAT1	((_UW*) 0xB0010230)
#define	PcPAT1S	((_UW*) 0xB0010234)
#define	PcPAT1C	((_UW*) 0xB0010238)
#define	PcPAT0S	((_UW*) 0xB0010244)
#define	PcPAT0C	((_UW*) 0xB0010248)

	/* Set GPIO Output for LED */
	// if ( (*PcPAT1 & 0x40040) != 0 ) *PcPAT1C = 0x40040;

	if ( (v & (0x1 << 16)) == 0 ) {	// Green Change
		if ( (v & 0x1) == 0 ) {
			*PcPAT0S = 0x00000040;	// Green OFF
		} else {
			*PcPAT0C = 0x00000040;	// Green ON
		}
	}
	if ( (v & (0x2 << 16)) == 0 ) {	// Yellow Change
		if ( (v & 0x2) == 0 ) {
			*PcPAT0S = 0x00040000;	// Yellow OFF
		} else {
			*PcPAT0C = 0x00040000;	// Yellow ON
		}
	}
}

/*
 * Get DIPSW status
 *	bit4: PSW2, bit3-0: DIPSW4-1
 */
EXPORT	W	dipSW( void )
{
#define	PcPIN	( (_UW*) 0xB0010200 )
	UW	dt, st;

	dt = *PcPIN;
	st = 0;
	if ( (dt & 0x00000020) == 0 ) st |= (1 << 0);	// DIPSW-1
	if ( (dt & 0x00000010) == 0 ) st |= (1 << 1);	// DIPSW-2
	if ( (dt & 0x00002000) == 0 ) st |= (1 << 2);	// DIPSW-3
	if ( (dt & 0x00000080) == 0 ) st |= (1 << 3);	// DIPSW-4
	if ( (dt & 0x00001000) == 0 ) st |= (1 << 4);	// PUSH SW2
	return st;
}

/*
 * Exit  System
 *	reset	<  0 : Reset & Restart
 *		>= 0 : Power OFF
 */
EXPORT	void	sysExit(W reset)
{
#define	LCR	0xB0000004	// Low Power Control Register
#define	TDR	0xB0002000	// WDT Data Reg.
#define	TCER	0xB0002004	// WDT Counter Enable Reg.
#define	TCNT	0xB0002008	// WDT Counter Reg.
#define	TCSR	0xB000200C	// WDT Control Reg.

	/* Flash Cache */
	FlushCacheAll();

	/* LED off */
	cpuLED(0x00);

	if ( reset >= 0 ) {
		/* Power OFF */
		for (;;) {
			out_w(LCR, in_w(LCR) | 0x01);	// Enter SLEEP mode
			for (;;) Asm("wait\n");
		}
	}

	/* Reset start */

#if	1
	/* Generate Watchdog Timer Reset */
	out_w(TCSR, 0x01);		// PCK_EN, PRESCALE 1/1
	out_w(TCNT, 0x00);		// Clear Counter
	out_w(TDR, 0x10);		// Set Reset Time
	out_w(TCER, 0x01);		// Timer Enable
	for (;;) Asm("wait\n");
#else
	_sysReset();
#endif
}

/*
 * Get Register value in regStack
 */
EXPORT	UW	getRegister( W regno )
{
	return regStack.w[regno];
}

/*
 * Set Register value in regStack
 */
EXPORT	W	setRegister( W regno, UW val )
{
	regStack.w[regno] = val;
	return 0;
}

/*
 * Get System Register value in regStack
 */
EXPORT	UW	getCurPC( void )
{
	return regStack.w[45];		// EPC
}
EXPORT	UW	adjCurPC( W adj )
{
	return regStack.w[45] += adj;	// EPC
}
EXPORT	UW	getBadAddr( void )
{
	return regStack.w[41];		// BVA
}
EXPORT	UW	getCurPSR( void )
{
	return regStack.w[43];		// PSR
}

/*
 * Set Boot
 */
EXPORT	void	setBoot( UW pc )
{
	regStack.w[45] = pc;			// EPC
	regStack.w[43] &= ~(SR_ERL|SR_EXL);	// PSR
}

