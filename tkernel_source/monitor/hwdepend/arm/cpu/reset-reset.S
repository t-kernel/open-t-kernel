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
#define __lr			r5

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
	.arm
startup_entry:
@ ARM926EJ-S NZCVQ--J -------- -------- IFTMMMMM
@ CORTEX-R4  NZCVQ[IT 1:0] J [DNM][GE 3:0][IT 7:2]EAIFTMMMMM page 3-9
@ ARM lowlevel initial
// SVC mode, FIQ/IRQ interrupt disabled
	mrs	r0, cpsr
	bic	r0, #0x1F
	orr	r0, #0xD3	@ disable FIQ IRQ Supervisor Mode
	msr	cpsr, r0

// use On-Chip SRAM as stack area
#ifdef CONFIG_TM_INIT_SP
	ldr	sp, =(CONFIG_TM_INIT_SP-16)
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
	.align	2
	.globl	reset_entry
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

#if CONFIG_MACH_EM1D
// Switch to T-Monitor stack
	ldr	sp, __stack_bottom

// not in effect: cache (D/I), program-flow prediction, High-Vector, VIC
// in effect: Force AP, TEX remap, Subpage AP
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


	ldr	sp, __stack_top
	mrs	r7, cpsr
#define __STACK_TOP		(CONFIG_TM_STACK_TOP)
#define __STACK_SIZE		(CONFIG_TM_STACK_SIZE)
#define __STACK_LIMIT		(__STACK_TOP   - __STACK_SIZE)
#define __STACK_FIQ		(__STACK_TOP   + 0x200 - __STACK_SIZE)
#define __STACK_IRQ		(__STACK_FIQ   + 0x200)
#define __STACK_SVC		(__STACK_IRQ   + 0x200)
#define __STACK_ABORT		(__STACK_SVC   + 0x200)
#define __STACK_UNDEFINED	(__STACK_ABORT + 0x200)
#define __STACK_SYSTEM		(__STACK_TOP)

@ +--------------------------
@ +
@ + main	64KiB-
@ +
@ +--------------------------
@ + fiq		512B
@ +--------------------------
@ + irq		512B
@ +--------------------------
@ + svc		512B
@ +--------------------------
@ + abort	512B
@ +--------------------------
@ + undefined	512B
@ +--------------------------

@ prepare stacks and registers
@ r7: cpsr
@ r6: scatch
@ r0: zero
	mrs	r7, cpsr
	bic	r7, #0x1F
	orr	r7, #(0<<5)		@ Thumb state bit
	orr	r7, #(1<<6)		@ FIQ disable
	orr	r7, #(1<<7)		@ IRQ disable
#if __TRON_ARM_ARCH__ > 7
	orr	r7, #(0<<8)		@ Imprecise abort disable bit
#endif
	orr	r7, #(0<<9)		@ Data endianness bit

@ FIQ: 10001
	bic	r7, #0x1F
	orr	r7, #0x13
	msr	cpsr, r7		@ switch to fiq mode
	msr	spsr, r0
	mov	r8,  r0
	mov	r9,  r0
	mov	r10, r0
	mov	r11, r0
	mov	r12, r0

	ldr	r13, __stack_fiq
	ldr	r14, __unknow

@ IRQ: 10010
	bic	r7, #0x1F
	orr	r7, #0x12
	msr	cpsr, r7		@ switch to irq mode
	msr	spsr, r0

	ldr	r13, __stack_irq
	ldr	r14, =__unknow

@ SVC: 10011
	bic	r7, #0x1F
	orr	r7, #0x13
	msr	cpsr, r7
	msr	spsr, r0

	ldr	r13, __stack_svc
	ldr	r14, =__unknow

@ abort: 10111
	bic	r7, #0x1F
	orr	r7, #0x17
	msr	cpsr, r7
	msr	spsr, r0

	ldr	r13, __stack_abort
	ldr	r14, =__unknow
	
@ undefined: 11011
	bic	r7, #0x1F
	orr	r7, #0x1B
	msr	cpsr, r7
	msr	spsr, r0

	ldr	r13, __stack_undefined
	ldr	r14, =__unknow

@ system: 11111
@   user: 10000
	bic	r7, #0x1F
	orr	r7, #0x1F
	msr	cpsr, r7

	ldr	r13, __stack_top
	ldr	r14, =__unknow

#ifdef CONFIG_ARM_VFP
	b	.			@ TODO
#endif

@ back to SVC mode
	bic	r7, #0x1F
	orr	r7, #0x13
	msr	cpsr, r7

	mov	r1, r0			@ r0 is zero
	mov	r2, r0
	mov	r3, r0
	mov	r4, r0
	mov	r5, r0
	mov	r6, r0
	mov	r7, r0
	
	mov	r8, r0
	mov	r9, r0
	mov	r10, r0
	mov	r11, r0
	mov	r12, r0

#ifdef CONFIG_ARM_VFP
	b	.			@ TODO
#endif

#define puts_ll putString
	ldr	r0, =banner
	bl	puts_ll
	ldr	r0, =Version
	bl	puts_ll
	ldr	r0, =patch
	bl	puts_ll

// enter monitor by means of SVC #0 instruction (SVC mode)
  resetLoop:
	svc	#0
	b	resetLoop		// return will cause another reset

	.global	__unknow
__unknow:
	mov	__lr, lr
	ldr	r0, =__unknow_msg
	bl	puts_ll
	b	.
__unknow_msg:
.asciz	"You should not return here."
banner:
.asciz "Open T-Monitor! "
patch:
.asciz " p0.9\r\n"

	.align	2
__magic:
	.word	0xdeadbeef
@ GCC will place const here, but not checking align,
@ without this magic, will cause a exception.
	.global	__stack_top
	.global	__stack_size
	.global	__stack_limit
	.global	__stack_bottom
__stack_top:
	.word	__STACK_TOP
__stack_size:
	.word	__STACK_SIZE
__stack_limit:
__stack_bottom:
	.word	__STACK_LIMIT
__stack_fiq:
	.word	__STACK_FIQ
__stack_irq:
	.word	__STACK_IRQ
__stack_svc:
	.word	__STACK_SVC
__stack_abort:
	.word	__STACK_ABORT
__stack_undefined:
	.word	__STACK_UNDEFINED
__stack_system:
	.word	__STACK_SYSTEM
	.pool
	.end

