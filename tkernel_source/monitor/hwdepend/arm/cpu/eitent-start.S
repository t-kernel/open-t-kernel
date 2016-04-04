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
 *	eitentry.S
 *
 *       EM1D512 (ARM1176JZF-S) exception branch handling
 *
 *	monitor/hwdepend/arm/cpu/eitent-start.S
 *	Startup Code (reset vector) for T-Monitor
 *	rewrite but keep the most of orignal global symbol names.
 *	
 */

/*
 * Copyright (C) 2016  Du Huanpeng<u74147@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */


#define	_in_asm_source_

#include <machine.h>
#include <tk/sysdef.h>
#include <mach/em1d512.h>
#include <sys/sysinfo.h>

// see <sys/sysdepend/tef_em1d/sysinfo_depend.h>

#define EIT_DEFAULT	0		/* default handler */
#define EIT_UNDEF	1		/* undefined instruction */
#define EIT_IABORT	2		/* prefetch abort */
#define EIT_DABORT	3		/* data abort */
#define EIT_IDEBUG	29		/* debug abort instruction */
#define EIT_DDEBUG	30		/* debug abort data */
#define EIT_FIQ		31		/* fast interrupt FIQ */
#define EIT_IRQ(n)	(  32 + (n) )	/* interrupt		IRQ  0-95 */
#define EIT_GPIO(n)	( 128 + (n) )	/* GPIO interrupt	port 0-127 */

#define EIT_ENTRY(n)	(EIT_VECTBL+4*(n))


/*
 *       EIT entry
 */


/*
 * r0-r7, r8-r12, r13(sp), r14(lr), r15(pc)
 */

	.section eitbra
	.global  _start
	.global fiq_entry
	.global dabort_entry
	.global svc_entry
	.global iabort_entry
	.global undef_entry
	.global irq_entry
_start:
	b	__startup_entry		@ 00 : reset
	b	undef_entry		@ 04 : undefined instruction
	b	svc_entry		@ 08 : software interrupt
	b	iabort_entry		@ 0C : prefetch abort
	b	dabort_entry		@ 10 : data abort
	b	.			@ 14 : reserved
	b	irq_entry		@ 18 : IRQ
fiq_entry:				@ 1C : FIQ
/*
 * fast interrupt
 *       calls the handler defined at FIQ interrupt vector unconditionally.
 *       no saving of registers to stack is performed.
 *       the content of R12_fiq(ip) register is overwritten.
 */
	push	{r0-r7, lr}

	mrs	lr, cpsr
	orr	lr, #(1<<6)	@ disable fiq
 	msr	cpsr, lr


	ldr	lr, =EIT_ENTRY(EIT_FIQ)
	ldr	lr, [lr]
	blx	lr

	pop	{r0-r7, lr}
	subs	pc, lr, #4
@ end of fiq

__startup_entry:
	mov	r0, #0
	mov	r1, #'A'
	bl	putSIO_mx28

#if 0

@	mov	r8-r12
@ if we called from u-boot or...
@	mov	r11, sp
@	mov	r12, lr

@ calc run-time offset
	mov	r2, pc
	ldr	r1, =1f
	sub	r0, r2, r1
1:	ldr	r2, =__vectors_start
	add	r2, r2, r0		@ run-time address of 1
	mov	r1, #0			@ assume V bit is zero

	mov	r8, r0			@ ok, r0 = offset

copy:	ldr	r0, [r2]
	str	r0, [r1]		@ abort?
verify:
	ldr	r3, [r1]
	cmp	r0, r3
	movne	r0, #0xE1		@ Error #1, dest is not writeable?
	bne	.			@ Error #1, hang

	add	r1, #4
	add	r2, #4
	ldr	r0, =__vectors_end
	cmp	r0, r2
	bne	copy
#endif
	b	startup_entry

	.weak syscall
svc_r0: .word	0xEFEFEFEF
	bx	lr
syscall:
	bic	r0, #0xFF000000
	orr	r0, #0xEF000000
	str	r0, svc_r0
	b	svc_r0
	bx	lr
/*
 * interrupt
 *       ACPU interrupt mask status register of Interrupt controller (AINT)
 *      Judge the priority of interrupts using (IT0_MST0,1,2),
 *       the highest interrupt's handler is called by jumping into it.
 *       Interrupt priority is descending order of interrupt factor (INT 0-95) , and INT 95 (IRQ 95) is highest.
 *       INT 0 (IRQ 0) has the lowest priority.
 *       If there is no cause of the interrupt, the handler of INT 95 (IRQ95) is called.
 *		+---------------+
 *	sp  ->	|R3		|
 *		|R12=ip		|
 *              |R14=lr         | <- return address from interrupt
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       ip = vector table address
 *       lr = indeterminate
 */
irq_entry:
	push	{r0-r12, lr}

	mrs	lr, spsr
	orr	lr, #(1<<7)
	msr	spsr, lr

	ldr	r0, =irqmsg
	bl	printk

	pop	{r0-r12, lr}
	subs	pc, lr, #4
irqmsg:
.asciz "IRQ" 

#ifdef CONFIG_MACH_EM1D
#endif

/*
 * undefined instruction
 *		+---------------+
 *	sp  ->	|R12=ip		|
 *              |R14=lr         | <- the return address, i.e., the next address that follows the undefined instruction
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       ip = vector table address
 *       lr = indeterminate
 */
 	
undef_entry:
	push	{r0}
	mrs	r0, spsr
@ TODO: check if sp < __stack_system
	push	{r0-r12, r14}

	ldr	lr, =EIT_ENTRY(EIT_UNDEF)
	ldr	lr, [lr]
	blx	lr

	mov	r0, lr
	bl	printh

	pop	{r0-r12, r14}
	msr	spsr, r0
	pop	{r0}

	movs	pc, lr

/*
 * supervisor call(SVC)
 *      the valid range of supervisor call number is 0-255 (N_INTVEC - 1).
 *       if an out of range value is given, treat it as SVC 0, and invokes the default handler.
 *		+---------------+
 *	sp  ->	|R12=ip		|
 *              |R14=lr         | <- return address: the address that follows the SVC instruction
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       ip = vector table address
 *       lr = indeterminate
 *
 *	just care about the lowest byte of svc instruction, other bytes are ignored.
 *	hope it works with thumb mode.
 *	simply save all registers.
 *	  r0 = the vector number.
 *	+---------------+
 *	| r0		|
 *	| spsr		|
 *	| r1-r12	|
 *	| lr		|
 *	+---------------+
 */

svc_entry:
	push	{r0}
	mrs	r0, spsr
	push	{r0-r12, lr}

	ldrb	r0, [lr]
	ldr	lr, =EIT_VECTBL

	ldr	lr, [lr, r0, lsl #2]
	blx	lr

	pop	{r0-r12, lr}
	msr	spsr, r0
	pop	{r0}

	movs	pc, lr

/*
 * prefetch abort
 *       in the case of debug event, debug abort (instruction) handler is called.
 *       Otherwise, prefetch abort handler is called.
 *		+---------------+
 *	sp  ->	|R12=ip		|
 *              |R14=lr         | <- return address: the address of aborted instruction
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       ip = vector table address
 *       lr = indeterminate
 */
iabort_entry:
	push	{r0}
	mrs	r0, spsr
	push	{r0-r12, r14}

	mov	r1, #'I'
	bl	putSIO_mx28

	mov	r0, lr
	bl	printh

	pop	{r0-r12, r14}
	msr	spsr, r0
	pop	{r0}

	bx	lr


/*
 * data abort
 *       in the case of debug event, debug abort (data) handler is called.
 *       Otherwise, data abort handler is called.
 *		+---------------+
 *	sp  ->	|R12=ip		|
 *              |R14=lr         | <- return address: the address of aborted instruction
 *		|SPSR		|
 *		+---------------+
 *      registers upon handler invocation
 *       ip = vector table address
 *       lr = indeterminate
 */
dabort_entry:
	push	{r0-r12}
	mrs	r7, spsr
	tst	r7, #(1<<5)
	subeq	lr, #4
	subne	lr, #6
	push	{lr}

	ldr	r7, =EIT_ENTRY(EIT_DABORT)
	ldr	r7, [r7]
	blx	r7

	pop	{lr}
	pop	{r0-r12}
	movs	pc, lr
	
	
#if 0
	push	{r7}
	mrs	r7, spsr
	tst	r7, #(1<<5)
	subeq	lr, #4		@ arm
	subne	lr, #6		@ thumb
	push	{r0-r12, r14}

	ldr	r7, =EIT_ENTRY(EIT_DABORT)
	ldr	r7, [r7]
	blx	r7

	pop	{r0-r12, r14}
	msr	spsr, r7
	pop	{r7}

	movs	pc, lr
#endif
/*
 * default handler
 *       stack contains the details of the generated exception.
 *      registers upon handler invocation
 *       ip = address of the vector table for the raised exception
 *       lr = indeterminate
 *
 *	Not used, waster some bytes to repeat similar code for every mode.
 */
default_entry:
	bx	lr


	.pool
