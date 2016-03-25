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
 *	eitent-start.S
 *	Startup Code (reset vector)
 */

#define	_in_asm_source_

#include <machine.h>
#include <tk/sysdef.h>
@#ifdef CONFIG_MACH_EM1D
#include <mach/em1d512.h>
@#endif
#include <sys/sysinfo.h>

#define	base(n)		( (n) & 0xfffff000 )
#define	offs(n)		( (n) & 0x00000fff )

// see <sys/sysdepend/tef_em1d/sysinfo_depend.h>
#define	N_INTVEC	256

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
	.global __svc_entry
	.global iabort_entry
	.global undef_entry
_start:
	b	__startup_entry		@ 00 : reset
	b	undef_entry		@ 04 : undefined instruction
	b	__svc_entry		@ 08 : software interrupt
	b	iabort_entry		@ 0C : prefetch abort
	b	dabort_entry		@ 10 : data abort
	nop				@ 14 : reserved
	b	irq_entry		@ 18 : IRQ
fiq_entry:				@ 1C : FIQ
/*
 * fast interrupt
 *       calls the handler defined at FIQ interrupt vector unconditionally.
 *       no saving of registers to stack is performed.
 *       the content of R12_fiq(ip) register is overwritten.
 */
	ldr	ip, =base(EIT_VECTBL)
	ldr	ip, [ip, #offs(EITVEC(EIT_FIQ))]
	bx	ip









__startup_entry:
	mov	r0, #0
	mov	r1, #'A'
	bl	putSIO_mx28
	bl	putSIO_mx28
	bl	putSIO_mx28
	bl	putSIO_mx28
	bl	putSIO_mx28
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

#define CONFIG_TM_DBG_VECTORS
#ifdef CONFIG_TM_DBG_VECTORS
__svc_entry:
	bx	lr
#endif







	.global svc
svc_r0: .word	0xEF0000EF
	bx	lr
svc:
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
	bx	lr

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
	bx	lr

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
 */
svc_entry:
#if __TRON_ARM_ARCH__ >= 6
	srsdb	sp!, #PSR_SVC		// save registers
	stmfd	sp!, {ip}
	
	mrs	ip, spsr
#else
	push	{ip}
	mrs	ip,spsr
	push	{ip}
#endif
	tst	ip, #PSR_T
	ldrneh	ip, [lr, #-2]		// Thumb instruction
	ldreq	ip, [lr, #-4]		// ARM instruction
	bicne	lr, ip, #0xff00
	biceq	lr, ip, #0xff000000
	cmp	lr, #N_INTVEC		// lr = software interrupt number
	movge	lr, #0

	ldr	ip, =EIT_VECTBL
	ldr	lr, [ip, lr, lsl #2]!
	cmp	lr, #0
	bxne	lr
	b	default_entry

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
	bx	lr

/*
 * default handler
 *       stack contains the details of the generated exception.
 *      registers upon handler invocation
 *       ip = address of the vector table for the raised exception
 *       lr = indeterminate
 */
default_entry:
	bx	lr


	.pool
