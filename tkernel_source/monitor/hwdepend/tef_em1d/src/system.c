/*
 *----------------------------------------------------------------------
 *    T-Kernel 2.0 Software Package
 *
 *    Copyright 2011 by Ken Sakamura.
 *    This software is distributed under the latest version of T-License 2.x.
 *----------------------------------------------------------------------
 *
 *    Released by T-Engine Forum(http://www.t-engine.org/) at 2011/05/17.
 *    Modified by T-Engine Forum at 2011/09/08.
 *    Modified by T-Engine Forum at 2013/03/04.
 *    Modified by TRON Forum(http://www.tron.org/) at 2015/06/01.
 *
 *----------------------------------------------------------------------
 */

/*
 *	system.c
 *
 *       system-related processing
 *
 *       target: EM1D-512
 */

#include "sysdepend.h"
#include <arm/em1d512.h>

EXPORT	UW	DipSw;		/* DipSw status */

/* hardware dependent functions */
IMPORT	UW	DipSwStatus(void);
IMPORT	void	usbPower(BOOL power);
IMPORT	void	powerOff(void);
IMPORT	void	resetStart(void);

/* interrupt entry point (eitent.S) */
IMPORT	void	_gio0Hdr(void);
IMPORT	void	_gio1Hdr(void);
IMPORT	void	_gio2Hdr(void);
IMPORT	void	_gio3Hdr(void);
IMPORT	void	_gio4Hdr(void);
IMPORT	void	_gio5Hdr(void);
IMPORT	void	_gio6Hdr(void);
IMPORT	void	_gio7Hdr(void);

/* default handler (cmdsvc) */
IMPORT	void	_defaultHdr(void);

/* macros for manipulating cache/MMU/PMIC */
#if 0
#define	EnbCacheMMU(x)	setCacheMMU(ENB_CACHEMMU)
#define	DisCacheMMU(x)	setCacheMMU(ENB_MMUONLY) /* MMU can't be turned off */
#else
#define	EnbCacheMMU(x)
#define	DisCacheMMU(x)
#endif

/* ------------------------------------------------------------------------ */

IMPORT	char	__loadaddr;	/* monitor load address */
IMPORT	MEMSEG	NoMemSeg[];	/* memory unused area */
IMPORT	W	N_NoMemSeg;

/*
        power management controller (DA9052) handler routines
*/
#define	SPIPol	0x0092

/* initialize SPI for PMIC communication */
LOCAL	void	pmicInit(void)
{
	// 8bit, CS0, Master, CPU mode
	// CS0: follow the specification by SPn_POL
	// interrupt disable

	// start reset
	// release reset

	return;
}

/* wait for data of SPI for PMIC communication */
LOCAL	void	pmicWait(void)
{
	W	i;

	for (i = 1000000; i > 0; i--) {
		if (in_w(SPn_RAW_STATUS(SP0)) & 0x0004) break;
		waitUsec(1);
	}
	if (!i) pmicInit();

	return;
}

/* contro CS line of SPI for PMIC communication */
LOCAL	void	pmicCSassert(BOOL cs)
{
	waitNsec(200);
	out_w(SPn_POL(SP0), SPIPol ^ (cs ? 0x0001 : 0x0000));
	waitNsec(200);

	return;
}

/* read PMIC register */
EXPORT	W	pmicRead(W reg)
{
	W	dat;

	pmicCSassert(TRUE);			// CS assert

	out_w(SPn_FFCLR(SP0), ~0);		// status flag is cleared
	out_w(SPn_TX_DATA(SP0), (reg << 1) | 1);        // send register number
	out_w(SPn_CONTROL(SP0), 0x0009);	// send start
	pmicWait();

	out_w(SPn_FFCLR(SP0), ~0);		// status flag is cleared
	out_w(SPn_CONTROL(SP0), 0x0005);	// start receive
	pmicWait();
	dat = in_w(SPn_RX_DATA(SP0));		// data received

	pmicCSassert(FALSE);			// CS de-assert

	return dat;
}

/* write PMIC register */
EXPORT	void	pmicWrite(W reg, W dat)
{
	pmicCSassert(TRUE);			// CS assert

	out_w(SPn_FFCLR(SP0), ~0);		// status flag is cleared
	out_w(SPn_TX_DATA(SP0), reg << 1);	// send register number
	out_w(SPn_CONTROL(SP0), 0x0009);	// send start
	pmicWait();

	out_w(SPn_FFCLR(SP0), ~0);		// status flag is cleared
	out_w(SPn_TX_DATA(SP0), dat);		// send data
	out_w(SPn_CONTROL(SP0), 0x0009);	// send start
	pmicWait();

	pmicCSassert(FALSE);			// CS de-assert

	return;
}

/* ------------------------------------------------------------------------ */

/* basic system set up (performed during reset, and Disk Boot) */
EXPORT	void	resetSystem(W boot)
{
	MEMSEG	*mp;
	UW	i, va;

        /* obtain DipSw status */
	if (!boot) DipSw = DipSwStatus();

	DisCacheMMU();

        /* set up interrupt controller */
	// CPU: all interrupts disabled
	// DSP: all interrupts disabled
	// CPU: FIQ disabled
	// GPIO: interrupt disabled
	// GPIO: FIQ interrupt disabled
	out_w(0x80018144, 0x0000C000);
	out_w(0x80018b24, 0x00000080);

	// internal interrupt disabled
	// inhibit interrupt polarity inversion
	// CPU: GPIO interrupt enabled

        /* power on controller initialization */
	pmicInit();

        /* USB power on */
	usbPower(TRUE);

        /* clear system common area (vector table, and SysInfo) */
	memset(&SCInfo, 0, sizeof(SysCommonInfo));
	memset(SCArea, 0, sizeof(SysCommonArea));

        /* if monitor is loaded into RAM, exclude the RAM area */
	mp = MemArea(MSA_OS, 1);
	va = (UW)&__loadaddr;
	if (va >= mp->top && va < mp->end) mp->end = va;

        /* exclude the area where ROM disk data is stored */
	va = (UW)ROMInfo->userarea;
	if (va >= mp->top && va < mp->end) mp->end = va;

        /* initialize system common information (SysInfo) */
	SCInfo.ramtop = (void*)mp->top;
	if (va < mp->top || va > mp->end) va = mp->end;
	SCInfo.ramend = (void*)va;

        /* set up EIT vectors */
        // we do not need _defaultHdr absolutely, but just in case set it up
	SCArea->intvec[EIT_DEFAULT]	= _defaultHdr;	// default handler
	SCArea->intvec[EIT_UNDEF]	= _defaultHdr;	// undefined instruction
	SCArea->intvec[SWI_MONITOR]	= _defaultHdr;	// SWI - monitor SVC
	SCArea->intvec[EIT_IRQ(26)]	= _gio6Hdr;	// GPIO branch
	SCArea->intvec[EIT_IRQ(27)]	= _gio7Hdr;
	SCArea->intvec[EIT_IRQ(50)]	= _gio0Hdr;
	SCArea->intvec[EIT_IRQ(51)]	= _gio1Hdr;
	SCArea->intvec[EIT_IRQ(52)]	= _gio2Hdr;
	SCArea->intvec[EIT_IRQ(53)]	= _gio3Hdr;
	SCArea->intvec[EIT_IRQ(79)]	= _gio4Hdr;
	SCArea->intvec[EIT_IRQ(80)]	= _gio5Hdr;
	SCArea->intvec[EIT_GPIO(8)]	= _defaultHdr;	// abort switch

        /* set up initial page table */
	for (i = 0; i < N_MemSeg; ++i) {
		mp = &MemSeg[i];
		if (!mp->pa) continue;

                /* FlashROM has already been mapped, and so do not touch it */
		if (mp->attr == MSA_FROM) continue;

                /* set up in unit of section (1MB) */
		for ( va  = (mp->top & 0xfff00000);
		      va != ((mp->end + 0x000fffff) & 0xfff00000);
		      va += 0x00100000 ) {
			TopPageTable[va / 0x00100000] =
				((mp->pa & 0xfff00000) + va) |
				 (mp->pa & 0x000fffff);
		}
	}

	for (i = 0; i < N_NoMemSeg; ++i) {
		mp = &NoMemSeg[i];

                /* set up in unit of section (1MB) */
		for ( va  = (mp->top & 0xfff00000);
		      va != ((mp->end + 0x000fffff) & 0xfff00000);
		      va += 0x00100000 ) {
			TopPageTable[va / 0x00100000] = 0;
		}
	}

#if 0
	DSB();
	Asm("mcr p15, 0, %0, cr8, c7, 0":: "r"(0));	// I/D TLB invalidate
	Asm("mcr p15, 0, %0, cr7, c5, 6":: "r"(0));	// invalidate BTC
	DSB();
	ISB();
#endif

	EnbCacheMMU();

	return;
}

/* ------------------------------------------------------------------------ */

/*
        system termination: reset / system power off
        reset   0       power off
                -1      reboot
                0xaa55  halt boot and power off
*/
EXPORT	void	sysExit(W reset)
{
	DisCacheMMU();

        // after this point, delay such as waitUsec() spends more time than the number indicates //

	/* LED off */
	cpuLED(0x00);

        /* all interrupts disabled */
	// CPU: all interrupts disabled
	// DSP: all interrupts disabled
	// FIQ disabled
	// internal interrupt disabled

        /* power on controller initialization */
	pmicInit();

        /* USB power off */
	usbPower(FALSE);

	if (reset >= 0) powerOff();

        /* reset start */
	resetStart();
}

/* ------------------------------------------------------------------------ */
