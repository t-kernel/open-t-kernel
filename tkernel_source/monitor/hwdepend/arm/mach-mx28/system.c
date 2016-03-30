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
#include <mach/em1d512.h>

EXPORT	UW	DipSw;		/* DipSw status */

/* hardware dependent functions */
IMPORT	UW	DipSwStatus(void);
IMPORT	void	usbPower(BOOL power);
IMPORT	void	powerOff(void);
IMPORT	void	resetStart(void);

/* interrupt entry point (eitent.S) */
LOCAL void helloworld(unsigned int vec)
{
	static long random = 0;
	volatile int i = 1*1024*1024;

	random++;
	printk("[%u]: Hello World(%u)\n", vec, random);
	while(i--);
}

/* default handler (cmdsvc) */
IMPORT	void	_defaultHdr(void);

/* macros for manipulating cache/MMU/PMIC */
#define	EnbCacheMMU(x)	setCacheMMU(ENB_CACHEMMU)
#define	DisCacheMMU(x)	setCacheMMU(ENB_MMUONLY) /* MMU can't be turned off */

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
#if 0
	out_w(SPn_MODE(SP0), 0x2700);		/* 8bit, CS0, Master, CPU mode */
	out_w(SPn_TIECS(SP0), 0x000f);		/* CS0: follow the specification by SPn_POL */
	out_w(SPn_POL(SP0), SPIPol);
	out_w(SPn_ENCLR(SP0), ~0);		/* interrupt disable */

	out_w(SPn_CONTROL(SP0), 0x0100);	/* start reset */
	waitUsec(10);
	out_w(SPn_CONTROL(SP0), 0x0000);	/* release reset */
	out_w(SPn_CONTROL2(SP0), 0x0000);
#else
	putString("[driver]: pmicInit\n");
#endif

	return;
}

/* wait for data of SPI for PMIC communication */
LOCAL	void	pmicWait(void)
{
#if 0
	W	i;

	for (i = 1000000; i > 0; i--) {
		if (in_w(SPn_RAW_STATUS(SP0)) & 0x0004) break;
		waitUsec(1);
	}
	if (!i) pmicInit();
#else
	printk("[driver]: pmicWait\n");
#endif

	return;
}

/* contro CS line of SPI for PMIC communication */
LOCAL	void	pmicCSassert(BOOL cs)
{

	return;
}

/* read PMIC register */
EXPORT	W	pmicRead(W reg)
{
	W	dat;

	pmicCSassert(TRUE);			/* CS assert */

	pmicWait();


	pmicCSassert(FALSE);			/* CS de-assert */

	return dat;
}

/* write PMIC register */
EXPORT	void	pmicWrite(W reg, W dat)
{
	pmicCSassert(TRUE);			/* CS assert */

	pmicWait();

	pmicWait();

	pmicCSassert(FALSE);			/* CS de-assert */
	printk("[driver]: pmicWrite\n");

	return;
}

/* ------------------------------------------------------------------------ */

/* basic system set up (performed during reset, and Disk Boot) */
EXPORT	void	resetSystem(W boot)
{
	MEMSEG	*mp;
	UW	i, va;
//	extern void svc(unsigned vec);

	printk("%s:%s\n", __FILE__, __func__);
	goto setup_vec;

        /* obtain DipSw status */
	if (!boot) DipSw = DipSwStatus();

	DisCacheMMU();

        /* set up interrupt controller */
	/* CPU: all interrupts disabled */
	/* DSP: all interrupts disabled */
	/* CPU: FIQ disabled */

	/* GPIO: interrupt disabled */
	/* GPIO: FIQ interrupt disabled */
	/* internal interrupt disabled */
	/* inhibit interrupt polarity inversion */
	/* CPU: GPIO interrupt enabled */

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
setup_vec:
        /* set up EIT vectors */
        /* we do not need _defaultHdr absolutely, but just in case set it up */
	for (i=0; i<256; i++) {
		SCArea->intvec[i] = helloworld;
	}
	SCArea->intvec[EIT_DEFAULT]	= helloworld;	/* default handler */
	SCArea->intvec[EIT_UNDEF]	= helloworld;	/* undefined instruction */
	SCArea->intvec[SWI_MONITOR]	= _defaultHdr;	/* SWI - monitor SVC */

//	for (i=0; i<256; i++) {
//		syscall(i);
//	}


	
	return ;

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

	DSB();
	/* I/D TLB invalidate */
	/* invalidate BTC */
	DSB();
	ISB();

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

        /* after this point, delay such as waitUsec() spends more time than the number indicates // */

	/* LED off */
	cpuLED(0x00);

        /* all interrupts disabled */
	/* CPU: all interrupts disabled */
	/* DSP: all interrupts disabled */
	/* FIQ disabled */
	/* internal interrupt disabled */
        /* power on controller initialization */
	pmicInit();

        /* USB power off */
	usbPower(FALSE);

	if (reset >= 0) powerOff();

        /* reset start */
	resetStart();
}

/* ------------------------------------------------------------------------ */
