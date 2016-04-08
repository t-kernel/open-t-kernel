/*
 * original: tkernel_source/monitor/cmdsvc/src/armv6/monhdr.S
 * 
 * store registers to __stack_regs and branch to monitor.
 * initial for arm926ej-s core
 */

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
 *	monhdr.S
 *
 *       Monitor handler (after ARMv6)
 */


#include <machine.h>
#include <sys/sysinfo.h>
#include <asm/cpudep.h>

/*
 * Monitor entry (registered as default handler)
 *		+---------------+
 *       sp  -> |R3             | <- only in the case of interrupt
 *		+---------------+
 *		|R12=ip		|
 *              |R14=lr         | <- return address from exception / interupt
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       r3 = varies according machine type and situation (only in the case of interrupt)
 *       ip = vector table address
 *       lr = indeterminate
 */
	.text
	.align	2
	.globl	_defaultHdr
	.type	_defaultHdr, %function
_defaultHdr:

	b	Csym(entMonitor)	// call entMonitor(vec)
/*
 * save registers
 * __stack_regs_limit[0x00-0x0F] usr,     r0-r14, cpsr
 * __stack_regs_limit[0x18-0x1F] fiq,     r0-r14, cpsr
 * __stack_regs_limit[0x2C-0x2F] irq,    r13-r14, spsr
 * __stack_regs_limit[0x3C-0x3F] abortt, r13-r14, spsr
 * __stack_regs_limit[0x4C-0x4F] svc,    r13-r14, spsr
 * __stack_regs_limit[0x5C-0x5F] undef,  r13-r14, spsr
 * TODO: cp15
 */

/*
 * usr mode -> return
 * svc mode -> go
 * the caller must have it's own stack and the registers saved to it's own stack.
 */

 	@ check mode, r4, 5, 6, 7
	push	{r4, r5, r6, r7, lr} 
	mrs	r7, cpsr

	and	r6, r7, #0x1F
	cmp	r6, #0x10		@ usr: Normal program execution mode
	popeq	{r4, r5, r6, r7, pc}


	cmp	r6, #0x13
	bne	100f
	beq	200f

100:
	bic	r7, #0x1F
	orr	r7, #0x13		@ svc: A protected mode for the operating system
	msr	cpsr, r7

	bl	entMonitor		@ don't switch modes in 'entMonitor'

	mrs	r7, spsr
	msr	cpsr, r7
	pop	{r4, r5, r6, r7, pc}

200:
	bl	entMonitor
	pop	{r4, r5, r6, r7, pc}



/* ------------------------------------------------------------------------ */

/*
 * calling an external program
 * W callExtProg( FP entry )
 */
	.text
	.balign	4
	.globl	Csym(callExtProg)
	.type	Csym(callExtProg), %function
Csym(callExtProg):
	stmfd	sp!, {r4-r10, fp, lr}	// save registers
	blx	r0			// call entry(void)
	ldmfd	sp!, {r4-r10, fp, pc}	// restore registers
