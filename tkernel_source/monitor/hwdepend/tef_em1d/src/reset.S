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
 */

#define	_in_asm_source_

#include <machine.h>
#include <tk/sysdef.h>
#include <arm/em1d512.h>
#include <sys/sysinfo.h>

#include "setup_em1d512.h"

/*
 * macro for setting up registers
 */
.macro out_w reg, val
  .ifnes "\val", ""	// when val is empty, do nothing.
	ldr	r0, =\reg
	ldr	r1, =\val
	str	r1, [r0]
  .endif
.endm

.macro setup_param	// r0: address of parameter string.
0:			// * r0, r2, and r3 are going to be clobbered.
	ldmia	r0!, {r2, r3}
	cmp	r2, #0
	strne	r3, [r2]
	bne	0b
.endm

.macro	wait_nsec	// r0: wait time (nsec)
			// * Assume one step is 4 ns @ (500MHz)
	lsr	r0, r0, #2
0:
	subs	r0, r0, #1
	bne	0b
.endm

/*
 * memory barrier macros
 */
.macro _mov reg, val
  .ifnes "\reg", "\val"
	mov	\reg, \val
  .endif
.endm
.macro .ISB reg, val=#0
	_mov	\reg, \val
	mcr	p15, 0, \reg, c7, c5, 4
.endm
.macro .DSB reg, val=#0
	_mov	\reg, \val
	mcr	p15, 0, \reg, c7, c10, 4
.endm
.macro .DMB reg, val=#0
	_mov	\reg, \val
	mcr	p15, 0, \reg, c7, c10, 5
.endm

/*----------------------------------------------------------------------
        T-Monitor boot processing
----------------------------------------------------------------------*/
	.section .startup, "ax"
	.balign	4
	.globl	startup_entry
	.type	startup_entry, %function
	.org	0x00000000
startup_entry:
// SVC mode, FIQ/IRQ interrupt disabled
	mov	r0, #(PSR_SVC | PSR_I | PSR_F)
	msr	cpsr_fsxc, r0

// use On-Chip SRAM as stack area
	ldr	sp, =CONFIG_INIT_SP

// not in effect: MMU, cache (D/I), program-flow prediction, High-Vector, VIC
// in effect: Force AP, TEX remap, Subpage AP
	.DSB	r0
	mrc	p15, 0, r0, c1, c0, 0
	ldr	r1, =~0x00003005
	and	r0, r0, r1
	ldr	r1, =0x00000000
	orr	r0, r0, r1
	mcr	p15, 0, r0, c1, c0, 0

// Setup clock divider

setup_clock_divider:

// Setup PLL1 (PLL3 is operating)
setup_pll1:
        // We assume Power ON mode: In other mode setting, we simply take it for granted that PLL has been configured already
wait_pll1:

// Setup power mode
setup_power_mode:
        // Transition from Power ON to Normal Mode A
wait_power_mode_change:

// Setup PLL2 (needs to be configured in Normal Mode)
setup_pll2:
wait_pll2_0:	
wait_pll2_1:	

// Setup pin multiplexer
setup_pin_mux:
	
// release reset of the internal modules
setup_module:

// supplying clock to modules.
setup_clock_distribution:

// Setup Bus controller
setup_bcr:

// initialization of DDR memory
	bl	setup_ddr

// creation of temporary page table
	ldr	r0, =PAGETBL_BASE
	ldr	r1, =0x00000000
	ldr	r2, =0x00000402	// Kernel/RW, Strongly-order
tmptable_loop:
	orr	r3, r1, r2
	str	r3, [r0], #4
	adds	r1, r1, #0x00100000
	bne	tmptable_loop

// Mapping of FlashROM area (0x70000000 - 0x72000000 --> 0x00000000 -)
	ldr	r0, =(PAGETBL_BASE + (0x700 << 2))
	ldr	r1, =0x00000000
	ldr	r2, =0x0000940e	// Kernel/RO, Normal WB/WA
flashtable_loop:
	orr	r3, r1, r2
	str	r3, [r0], #4
	adds	r1, r1, #0x00100000
	cmp	r1, #0x02000000
	bne	flashtable_loop
	
// initialization of CP15
	ldr	r0, =0x00000004
	mcr	p15, 0, r0, c2, c0, 2		// TTBCR
	ldr	r0, =(PAGETBL_BASE + 0x09)	// WB/WA, no-shared, cachable
	mcr	p15, 0, r0, c2, c0, 1		// TTBR1
	mcr	p15, 0, r0, c2, c0, 0		// TTBR0
	ldr	r0, =EITENT_BASE
	mcr	p15, 0, r0, c2, c0, 0		// VBAR
	ldr	r0, =0x000a8aa4
	mcr	p15, 0, r0, c10, c2, 0 		// PRRR
	ldr	r0, =0x44e048e0
	mcr	p15, 0, r0, c10, c2, 1		// NMRR
	ldr	r0, =0x55555555			// All client
	mcr	p15, 0, r0, c3, c0, 0		// Domain access

// MMU enable
	.DSB	r0
	mcr	p15, 0, r0, c8, c7, 0		// I/D TLB invalidate
	mcr	p15, 0, r0, c7, c5, 6		// invalidate BTC
	.DSB	r0
	.ISB	r0
	mrc	p15, 0, r0, c1, c0, 0
	orr	r0, r0, #0x00000001
	mcr	p15, 0, r0, c1, c0, 0
	.ISB	r0

// perform reset processing
	ldr	pc, =reset_entry

// initialization of DDR memory
setup_ddr:
calibrate_loop:
ddr_init_loop:

	bx	lr

	.pool

param_table0:

param_table1:

param_table2:

param_table3:

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
	.globl	reset_entry
	.type	reset_entry, %function
reset_entry:

// SVC mode, FIQ/IRQ interrupt disabled
	mov	r0, #(PSR_SVC | PSR_I | PSR_F)
	msr	cpsr_fsxc, r0

// Switch to T-Monitor stack
	ldr	sp, =__stack_bottom

// not in effect: cache (D/I), program-flow prediction, High-Vector, VIC
// in effect: Force AP, TEX remap, Subpage AP
	.DSB	r0
	mrc	p15, 0, r0, c1, c0, 0
	ldr	r1, =~0x00003004
	and	r0, r0, r1
	ldr	r1, =0x00000000
	orr	r0, r0, r1
	mcr	p15, 0, r0, c1, c0, 0

	.ISB	r0
	mcr	p15, 0, r0, c8, c7, 0		// I/D TLB invalidate
	.DSB	r0
	bl	Csym(FlushCache)		// Clean/invalidate I/D cache

// Turn on VFP
	mrc	p15, 0, r0, c1, c0, 2
	orr	r0, r0, #0x00f00000	// VFP(CP11,CP10) enable
	bic	r0, r0, #0xc0000000	// Should be Zero
	mcr	p15, 0, r0, c1, c0, 2
	.ISB	r0			// Flush Prefetch buffer

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

        // clear VFP
	mov	r0, #0x40000000		// EX=0,EN=1,SBZ/other flags = 0
	fmxr	fpexc, r0

	mov	r1, #0x00000000		// SBZ/other flags = 0
	fmxr	fpscr, r1

	fldmiad	r7, {d0-d15}		// zero clear

        // return to SVC mode
	mov	r0, #(PSR_SVC | PSR_I | PSR_F)
	msr	cpsr_fsxc, r0

	ldmia	r7, {r0-r7}		// r0-r7

// enter monitor by means of SVC #0 instruction (SVC mode)
  resetLoop:
	svc	#0
	b	resetLoop		// return will cause another reset

	.pool
