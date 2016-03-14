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
 *	reset-reset.S
 *	 main of reset.S, ARM, stack, etc.
 *	TODO:
 *	 Remove machine/board related things.
 */

#define	_in_asm_source_

#include <machine.h>
#include <tk/sysdef.h>
#include <sys/sysinfo.h>

#include <mach/em1d512.h>
#include <setup_em1d512.h>

/*----------------------------------------------------------------------
        T-Monitor boot processing
----------------------------------------------------------------------*/
	.section .startup
	.globl	startup_entry
	.type	startup_entry, %function
startup_entry:
@ ARM926EJ-S NZCVQ--J -------- -------- IFTMMMMM
@ CORTEX-R4  NZCVQ[IT 1:0] J [DNM][GE 3:0][IT 7:2]EAIFTMMMMM page 3-9
@ ARM lowlevel initial
// SVC mode, FIQ/IRQ interrupt disabled
#if __TRON_ARM_ARCH__ >= 6
	mov	r0, #(PSR_SVC | PSR_I | PSR_F)
	msr	cpsr_fsxc, r0
#else
	mrs	r0, cpsr
	bic	r0, #0x1F
	orr	r0, #0xD3	@ disable FIQ IRQ Supervisor Mode
	msr	cpsr, r0
#endif

// use On-Chip SRAM as stack area
#if CONFIG_MACH_EM1D
	ldr	sp, =0xa0020000
#endif
#ifdef CONFIG_INIT_SP
	ldr	sp, =(DCONFIG_TM_INIT_SP-16)
#endif

// not in effect: MMU, cache (D/I), program-flow prediction, High-Vector, VIC
// in effect: Force AP, TEX remap, Subpage AP

#if __TRON_ARM_ARCH__ >= 6
	dsb
	mcr	p15, 0, r0, cr7, c10, 4
	mrc	p15, 0, r0, cr1, cr0, 0
	ldr	r1, =~0x01003f85
	and	r0, r0, r1
	ldr	r1, =0x30800000
	orr	r0, r0, r1
	mcr	p15, 0, r0, cr1, cr0, 0
#else
tc_loop:
        mrc     p15, 0, r15, c7, c10, 3		@ test and clean
        bne     tc_loop
/*
 * Register c1 is the Control Register for the ARM926EJ-S processor. This
 * register specifies the configuration used to enable and disable the caches
 * and MMU. It is recommended that you access this register using a
 * read-modify-write sequence.
 *
 * For both reading and writing, the CRm and Opcode_2 fields Should Be Zero.
 * To read and write this register, use the instructions:
 * MRC p15, 0, <Rd>, c1, c0, 0 ; read control register
 * MCR p15, 0, <Rd>, c1, c0, 0 ; write control register
 *
 * ARM DDI 0198E 2-14
 */
	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, #(1<<9)		@ ROM protection
	bic	r0, #(1<<8)		@ System protection
	bic	r0, #(1<<7)		@ Little-endian operation
	bic	r0, #(1<<2)		@ DCache disabled
	orr	r0, #(1<<1)		@ Alignment fault enable
	bic	r0, #(1<<0)		@ MMU disabled
        mcr     p15, 0, r0, c1, c0, 0
#endif
@ Machine/Board initial
// Setup clock divider
	bl	startup_entry_lowlevel

@ ARM initial cp15 and enable mmu.
#ifdef CONFIG_MACH_EM1D
// initialization of CP15
	ldr	r0, =0x00000004
	mcr	p15, 0, r0, cr2, cr0, 2		// TTBCR
	ldr	r0, =(PAGETBL_BASE + 0x09)	// WB/WA, no-shared, cachable
	mcr	p15, 0, r0, cr2, cr0, 1		// TTBR1
	mcr	p15, 0, r0, cr2, cr0, 0		// TTBR0
	ldr	r0, =EITENT_BASE
	mcr	p15, 0, r0, cr12, cr0, 0	// VBAR

@	DDI0198E_arm926ejs_r0p5_trm.pdf
@	2.3.12 Register c11 and c12
@	Accessing, reading or writing, these registers causes Unpredicatable behavior.

	ldr	r0, =0x000a8aa4
	mcr	p15, 0, r0, cr10, cr2, 0 	// PRRR
	ldr	r0, =0x44e048e0
	mcr	p15, 0, r0, cr10, cr2, 1	// NMRR
	ldr	r0, =0x55555555			// All client
	mcr	p15, 0, r0, cr3, cr0, 0		// Domain access
#else
	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, #(1<<9)		@ ROM protection
	bic	r0, #(1<<8)		@ System protection
	bic	r0, #(1<<7)		@ Little-endian operation
	bic	r0, #(1<<2)		@ DCache disabled
	orr	r0, #(1<<1)		@ Alignment fault enable
	bic	r0, #(1<<0)		@ MMU disabled
        mcr     p15, 0, r0, c1, c0, 0
#endif

// MMU enable
#if CONFIG_MMU
	dsb
	mcr	p15, 0, r0, cr8, cr7, 0		// I/D TLB invalidate
	mcr	p15, 0, r0, cr7, cr5, 6		// invalidate BTC
	dsb
	isb

	mrc	p15, 0, r0, cr1, cr0, 0
	orr	r0, r0, #0x00000001
	mcr	p15, 0, r0, cr1, cr0, 0
	isb
#endif

// perform reset processing
@ no return jump?
@	ldr	pc, =reset_entry
	b	reset_entry
@ End of startup_entry
	.pool


/*----------------------------------------------------------------------
        Reset processing
----------------------------------------------------------------------*/
	.text
	.balign	4
	.globl	reset_entry
	.type	reset_entry, %function
reset_entry:
// SVC mode, FIQ/IRQ interrupt disabled
#if CONFIG_MACH_EM1D
	mov	r0, #(PSR_SVC | PSR_I | PSR_F)
	msr	cpsr_fsxc, r0
#else
	mrs	r0, cpsr
	bic	r0, #0x1f
	orr	r0, #0xd3
	msr	cpsr, r0
#endif

// Switch to T-Monitor stack
	ldr	sp, =__stack_bottom

// not in effect: cache (D/I), program-flow prediction, High-Vector, VIC
// in effect: Force AP, TEX remap, Subpage AP
#if CONFIG_MACH_EM1D
	dsb
	mrc	p15, 0, r0, cr1, cr0, 0
	ldr	r1, =~0x01003f84
	and	r0, r0, r1
	ldr	r1, =0x30800000
	orr	r0, r0, r1
	mcr	p15, 0, r0, cr1, cr0, 0	
	isb
	mcr	p15, 0, r0, cr8, cr7, 0		// I/D TLB invalidate
	dsb
#else
	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, #(1<<9)		@ ROM protection
	bic	r0, #(1<<8)		@ System protection
	bic	r0, #(1<<7)		@ Little-endian operation
	bic	r0, #(1<<2)		@ DCache disabled
	orr	r0, #(1<<1)		@ Alignment fault enable
	bic	r0, #(1<<0)		@ MMU disabled
        mcr     p15, 0, r0, c1, c0, 0

#endif
	bl	Csym(FlushCache)		// Clean/invalidate I/D cache
#if	__TRON_ARM_ARCH__ >= 6
// Turn on VFP
	mrc	p15, 0, r0, cr1, cr0, 2
	orr	r0, r0, #0x00f00000	// VFP(CP11,CP10) enable
	bic	r0, r0, #0xc0000000	// Should be Zero
	mcr	p15, 0, r0, cr1, cr0, 2
	isb				// Flush Prefetch buffer
#endif

@ go setup C
// initialize data area
// clear bss and stack area
// clear in units of 16 bytes
	bl	reset_entry_setupc
@ End of setup C
// reset processing
	bl	procReset

// clear registers & initialize stack pointer
	ldr	r7, =__stack_top	// since it is 0-cleared, why not use it.

	ldmia	r7, {r8-r12,sp,lr}^	// usr: r8-r12, sp, lr

	mov	r0, #(PSR_FIQ | PSR_I | PSR_F)
	msr	cpsr_fsxc, r0
	ldmia	r7, {r8-r12,sp,lr}	// fiq: r8-r12, sp, lr, spsr
	msr	spsr_fsxc, lr
	ldr	sp, =__stack_top + 32

	mov	r0, #(PSR_IRQ | PSR_I | PSR_F)
	msr	cpsr_fsxc, r0
	ldr	sp, =__stack_top + 16	// irq: sp, lr, spsr
	mov	lr, #0
	msr	spsr_fsxc, lr

	mov	r0, #(PSR_ABT | PSR_I | PSR_F)
	msr	cpsr_fsxc, r0
	ldr	sp, =__stack_top + 64	// abt: sp, lr, spsr
	mov	lr, #0
	msr	spsr_fsxc, lr

	mov	r0, #(PSR_UND | PSR_I | PSR_F)
	msr	cpsr_fsxc, R0
	ldr	sp, =__stack_top + 48	// und: sp, lr, spsr
	mov	lr, #0
	msr	spsr_fsxc, lr



#if __TRON_ARM_ARCH__ >= 6
        // clear VFP
	mov	r0, #0x40000000		// EX=0,EN=1,SBZ/other flags = 0
	fmxr	fpexc, r0

	mov	r1, #0x00000000		// SBZ/other flags = 0
	fmxr	fpscr, r1

	fldmiad	r7, {d0-d15}		// zero clear
#endif

        // return to SVC mode
	mov	r0, #(PSR_SVC | PSR_I | PSR_F)
	msr	cpsr_fsxc, r0

	ldmia	r7, {r0-r7}		// r0-r7

	ldr	r0, =hello
	bl	putString

// enter monitor by means of SVC #0 instruction (SVC mode)
  resetLoop:
	svc	#0
	b	resetLoop		// return will cause another reset
hello:
.asciz "Hello World!\n"

	.pool
