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

/*
 * save registers
 * __stack_regs_limit[0x00-0x0F] usr,     r0-r14, cpsr
 * __stack_regs_limit[0x18-0x1F] fiq,     r0-r14, cpsr
 * __stack_regs_limit[0x2C-0x2F] irq,    r13-r14, spsr
 * __stack_regs_limit[0x3C-0x3F] abortt, r13-r14, spsr
 * __stack_regs_limit[0x4C-0x4F] svc,    r13-r14, spsr
 * __stack_regs_limit[0x5C-0x5F] undef,  r13-r14, spsr
 * __stack_regs_limit[0x6C-0x6F] resv
 * __stack_regs_limit[0x7C-0x7F] resv
 * TODO: cp15
 */

#define stack_regs_usr 0x200
#define stack_regs_sys 0x200
#define stack_regs_fiq (stack_regs_usr+0x18*4)
#define stack_regs_irq (stack_regs_usr+0x2D*4)
#define stack_regs_abt (stack_regs_usr+0x3D*4)
#define stack_regs_svc (stack_regs_usr+0x4D*4)
#define stack_regs_und (stack_regs_usr+0x5D*4)

/*
 * svc mode -> go
 * usr & other mode -> return
 */
	push	{lr}
	mrs	lr, cpsr

	and	lr, lr, #0x1F
	cmp	lr, #0x13		@ svc mode only.
	popne	{lr}
	bxne	lr
/* else we are in svc mode */
/* save sys and usr in svc mode, r0-r7 */
	ldr	lr, =stack_regs_usr
	stmia	lr, {r0-r7}		@ Now, we can work with r0-r7
/* svc mode */
	ldr	r7, =stack_regs_svc
	ldr	lr, [sp, #4]
	stmia	r7, {sp, lr}
/* fiq mode */
	mrs	r7, cpsr		@ r7 = cpsr
	bic	r7, #0x1F
	orr	r7, #0x11
	msr	cpsr, r7

	ldr	r6, =stack_regs_fiq
	stmia	r6, {r8-r14}
/* irq mode */
	bic	r7, #0x1F
	orr	r7, #0x12
	msr	cpsr, r7

	ldr	r6, =stack_regs_irq
	stmia	r6, {r13, r14}
/* abt mode */
	bic	r7, #0x1F
	orr	r7, #0x17
	msr	cpsr, r7

	ldr	r6, =stack_regs_abt
	stmia	r6, {r13, r14}
/* und mode */
	bic	r7, #0x1F
	orr	r7, #0x1C
	msr	cpsr, r7

	ldr	r6, =stack_regs_und
	stmia	r6, {r13, r14}
/* sys mode */
	orr	r7, #0x1F
	msr	cpsr, r7
	ldr	r6, =stack_regs_usr
	add	r6, #32
	stmia	r6, {r8-r14}
/* back to svc */
	bic	r7, #0x1F
	orr	r7, #0x13
	msr	cpsr, r7

	bl	entMonitor		@ don't switch modes in 'entMonitor'

	pop	{lr}
	bx	lr

/* ------------------------------------------------------------------------ */

/*
 * calling an external program
 * W callExtProg( FP entry )
 */
	.text
	.align	2
	.globl	callExtProg
	.type	callExtProg, %function
callExtProg:
	push	{r4-r10, fp, lr}	// save registers
	blx	r0			// call entry(void)
	pop	{r4-r10, fp, lr}	// restore registers
	bx	lr
