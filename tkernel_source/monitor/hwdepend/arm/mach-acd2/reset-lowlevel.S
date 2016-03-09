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
 *----------------------------------------------------------------------
 */

/*
 *	reset.S
 *
 *       EM1-D512: initial setting after a reset.
 *
 *	reset-lowlevel.S
 *	Board initial, should place to arch/arm/mach-acd2/.
 */

#define	_in_asm_source_

#include <machine.h>
#include <tk/sysdef.h>
#include <sys/sysinfo.h>

#include <mach/em1d512.h>
#include <setup_em1d512.h>

/*
 * macro for setting up registers
 */

/*----------------------------------------------------------------------
        T-Monitor boot processing
----------------------------------------------------------------------*/
	.section .startup
	.globl	startup_entry_lowlevel
startup_entry_lowlevel:
@ Machine/Board initial




// Setup clock divider
// automatic frequency change function is off
// Setup PLL1 (PLL3 is operating)
// We assume Power ON mode: In other mode setting, we simply take it for granted that PLL has been configured already
// Setup power mode
// Setup PLL2 (needs to be configured in Normal Mode)
// Setup pin multiplexer
// release reset of the internal modules
// supplying clock to modules.
// Setup Bus controller
// initialization of DDR memory
// creation of temporary page table
// Mapping of FlashROM area (0x70000000 - 0x72000000 --> 0x00000000 -)
@ End of Machine/Board initial

	bx	lr
	.pool

	// memory map setup (CS0-3)
	//
	// 0x00000000 +----------------------------+
	//            | Bank0/CS0 (not used)       |
	// 0x10000000 +----------------------------+
	//            | Bank1/CS1 (not used)       |
	// 0x20000000 +----------------------------+
	//            | Bank2/CS2 (not used)       |
	// 0x28000000 +----------------------------+
	//            | Bank2/CS3 (LAN controller) |
	// 0x30000000 +----------------------------+
	
        // set up LAN controller
        // Assuming the use of 83.333 MHz (12ns/1clk), we set the following values.
	//	CSint=1clk (Read+1clk=24ns, Write+2clk=36ns)
	//	T0=0clk (0ns), T1=3clk(36ns), T2=2clk(24ns)
/*----------------------------------------------------------------------
        Reset processing
----------------------------------------------------------------------*/
	.text
	.balign	4
	.globl	reset_entry_lowlevel
	.type	reset_entry_lowlevel, %function
reset_entry_lowlevel:
	bx	lr
	.pool
