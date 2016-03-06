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
 *	reset-setupc.S
 *	 Setup C environment.
 */

#define	_in_asm_source_

#include <machine.h>
#include <tk/sysdef.h>
#include <sys/sysinfo.h>

#include <mach/em1d512.h>
#include <setup_em1d512.h>

/*----------------------------------------------------------------------
	What does barebox setupc do?
 *
 * setup_c: copy binary to link address, clear bss and
 * continue executing at new address.
 *
 * This function does not return to the address it is
 * called from, but to the same location in the copied
 * binary.
 *
----------------------------------------------------------------------*/

/*----------------------------------------------------------------------
        T-Monitor boot processing
----------------------------------------------------------------------*/
/*----------------------------------------------------------------------
        Reset processing
----------------------------------------------------------------------*/
	.text
	.balign	4
	.globl	reset_entry_setupc
	.type	reset_entry_setupc, %function
reset_entry_setupc:
@Setup C environment
// initialize data area
	ldr	r1, =__data_org
	ldr	r2, =__data_start
	ldr	r3, =_edata
data_loop:
	ldmia	r1!, {r4-r7}	// copy in unit of 16 bytes
	stmia	r2!, {r4-r7}
	cmp	r2, r3
	blo	data_loop

// clear bss and stack area
	ldr	r2, =__bss_start
	ldr	r3, =__stack_bottom
	ldr	r4, =0
	ldr	r5, =0
	ldr	r6, =0
	ldr	r7, =0
bss_loop:
	stmia	r2!, {r4-r7}	// clear in units of 16 bytes
	cmp	r2, r3
	blo	bss_loop
	bx	lr
@ End of setup C
	.pool
	.end
