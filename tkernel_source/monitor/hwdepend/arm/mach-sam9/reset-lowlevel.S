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
 *	Board initial, should place to arch/arm/mach-asm9/.
 */

#define	_in_asm_source_

#include <machine.h>
#include <tk/sysdef.h>
#include <sys/sysinfo.h>

#include <mach/asm9260.h>
#include <setup_em1d512.h>

/*----------------------------------------------------------------------
        T-Monitor boot processing
----------------------------------------------------------------------*/
	.section .startup
	.globl	startup_entry_lowlevel
	.globl	serial_putchar
startup_entry_lowlevel:
	mov	r6, lr
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
	mov	r0, #'1'
	bl	serial_putchar
	mov	lr, r6
	bx	lr

serial_putchar:
1:	ldr	r7, =0xFFFFEE00			@ Wait for the transmitter to be ready
	ldr	r7, [r7, #0x14] 
	and	r7, #(1<<9)
	cmp	r7, #0
	beq	1b

	ldr	r7, =0xFFFFEE00
	strb	r0, [r7, #0x1C]

	bx	lr
	.pool

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
