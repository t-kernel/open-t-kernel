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
 *	startup.c	( T-Monitor for APP-M150 )
 *
 *	 system boot processing
 */

#include <tmonitor.h>

#define	HI_BAUD_RATE	(115200)
#define	CONS_PORT	(0)

/* ------------------------------------------------------------------------ */

/*
 * Initial Processing after Reset
 */
EXPORT	void	procReset( void )
{
	FP	fp;
	UW	va;

	/* Disable all interupts */

	/* Turn ON all LEDs */
	cpuLED(0x0F);

	/* initialize console serial port */
	initSIO(CONS_PORT, HI_BAUD_RATE);

	/* setting up the initial count for micro-wait */
	setupWaitUsec();

	/* initialize console serial port */
	initSIO(CONS_PORT, HI_BAUD_RATE);

	/* Clear system common area (vector table, and SysInfo) */
	memset(SCArea, 0, sizeof(SysCommonArea));

	/* Initialize system common information (SysInfo) */
	SCInfo.ramtop = (void *)RAM_TOP;
	va = (UW)ROMInfo->userarea;
	if ( va < RAM_TOP || va > RAM_END ) va = RAM_END;
	SCInfo.ramend = (void *)va;
	SCInfo.istkpos = (void *)EIT_STACK;

	/* Set up EIT vectors */
	SCArea->intvec[EIT_DEFAULT]	= _defaultHdr;	// default handler
	SCArea->intvec[EIT_EXC(0)]	= _intHdr;	// Interrupt handler
	SCArea->intvec[EIT_EXC(8)]	= _svcHdr;	// SYSCALL handler
	SCArea->intvec[EIT_IP(2)]	= _ip2Hdr;	// Interrupt (IP 2)
	SCArea->intvec[EIT_IP(3)]	= _ip3Hdr;	// Interrupt (IP 3)
	SCArea->intvec[EIT_IP(4)]	= _ip4Hdr;	// Interrupt (IP 4)
	SCArea->intvec[EIT_IP(5)]	= _ip5Hdr;	// Interrupt (IP 5)
	SCArea->intvec[EIT_IP(6)]	= _ip6Hdr;	// Interrupt (IP 6)
	SCArea->intvec[CALL_MONITOR]	= _defaultHdr;	// M SVC(SYSCALL 37)
	SCArea->intvec[CALL_MONBREAK]	= _defaultHdr;	// M SVC(SYSCALL 42)

	/* Invoke user reset initialization */
	fp = ROMInfo->resetinit;
	if ( fp != NULL ) (*fp)();

	/* Turn ON Green LED */
	cpuLED(0x01);

	/* Kernel entry address */
	fp = ROMInfo->kernel;

	/* Command */
	if ( (dipSW() & 0x10) != 0 || fp == NULL ) {
		DSP(("\n** T-Monitor for APP-M150 **\n"));
		procCommand(&fp);
	}

	/* Invoke the Kernel */
	if ( fp != NULL ) (*fp)();

	sysExit(0);
}

/*
 * T-Monitor Entry
 */
EXPORT	void	entMonitor( UW vec )
{
	UW	pc, v;
	char	*bp;

	switch( vec /= 4 ) {
	case 37:	// T-Monitor Service Call
		// Execute SVC: v0:r2(fn),a0:r4,a1:r5,a2:r6,a3:r7
		v = procSVC(getRegister(2), getRegister(4),
			getRegister(5), getRegister(6), getRegister(7));
		setRegister(2, v);	// Set Result
		break;

	case 42:	// Break Point (SYSCALL 42)
		DSP(("\nBreak pc:%08X psr:%08X\n", adjCurPC(-4), getCurPSR()));
		procCommand(NULL);
		break;

	default:	// Undefined exception/interrupts
		pc = getCurPC();
		if ( vec < 37 ) {
			bp = NULL;
			switch( vec ) {
			case 1:  bp = "NMI/Soft Reset";	break;
			case 6:  bp = "TLB Change";		break;
			case 7:  bp = "TLB Miss(Load)";	break;
			case 8:  bp = "TLB Miss(Store)";	break;
			case 9:  bp = "Address Error(Load)";	break;
			case 10: bp = "Address Error(Store)";	break;
			case 11: bp = "Bus Error(Inst)";	break;
			case 12: bp = "Bus Error(Data)";	break;
			case 14: bp = "Undefined Break";	break;
			case 15: bp = "Reserved Instruction";	break;
			case 16: bp = "CoProcessor Exception";	break;
			case 17: bp = "Integer Overflow";	break;
			case 18: bp = "Trap Exception";	break;
			case 20: bp = "FP Exception";		break;
			default:
				DSP(("\nUndefined Exception VEC-%d", vec));
			}
			if ( vec >= 6 && vec <= 10 )
				DSP(("\n%s ADDR:%08X", bp, getBadAddr()));
			else if ( bp != NULL) DSP(("\n%s", bp));

		} else if ( vec < 56 ) {	// SYSCALL
			DSP(("\nUndefined SYSCALL %d", vec));
			pc -= 4 - ((pc & 1) << 1);

		} else if ( vec < 64 ) {	// Interrupt IP0-7
			DSP(("\nUndefined Interrupt IP%d", 63 - vec));

		} else {			// Interrupt IRQ#0-63
			DSP(("\nUndefined Interrupt IRQ#%d", 127 - vec));
		}
		DSP(("\nPC: %08X  PSR: %08X\n", pc, getCurPSR()));
		procCommand(NULL);
	}
}

