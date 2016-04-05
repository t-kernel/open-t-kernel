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


#include <machine.h>
#include <tk/sysdef.h>
#include <sys/sysinfo.h>

#include <mach/em1d512.h>
#include <setup_em1d512.h>



#define Mode_IRQ              0x12
#define Mode_SVC              0x13
#define GLOBAL_VARIABLE_AREA  0xFF000


/*----------------------------------------------------------------------
        T-Monitor boot processing
----------------------------------------------------------------------*/
	.section .startup
	.globl	startup_entry_lowlevel
startup_entry_lowlevel:
@ Machine/Board initial


@===================================================================
@ Configure region 0 for MPU
@===================================================================

	@ Region 0 - All
	MOV     r1, #0
	MCR     p15, 0, r1, c6, c2, 0       	@ Set memory region number register
	ISB                                 	@ Ensure subsequent insts execute wrt region 0 settings
	LDR     r2, =0x0
	MCR     p15, 0, r2, c6, c1, 0       	@ Set region base address register
	LDR     r2, =0x3F			            @ Region_Enable
	MCR     p15, 0, r2, c6, c1, 2       	@ Set region size & enable register 4GB
	LDR     r2, =0x300			            @ Non-Shared_Non-Bufferable_Non-Cachable_Full-Access, Strongly-ordered
	MCR     p15, 0, r2, c6, c1, 4       	@ Set region access control register

@===================================================================
@ Configure region 1 for MPU: embedded RAM
@===================================================================

	@ Region 1 - embedded RAM
	MOV     r1, #1
	MCR     p15, 0, r1, c6, c2, 0       	@ Set memory region number register
	ISB                                 	@ Ensure subsequent insts execute wrt region 1 settings
	LDR     r2, =0x0
	MCR     p15, 0, r2, c6, c1, 0       	@ Set region base address register
	LDR     r2, =0x27			@ Region_Enable
	MCR     p15, 0, r2, c6, c1, 2       	@ Set region size & enable register 1MB
	LDR     r2, =0x303			@ Non-Shared_Bufferable_Cachable_Full-Access, Outer and Inner write-back, no write-allocate
	MCR     p15, 0, r2, c6, c1, 4       	@ Set region access control register

@===================================================================
@ Configure region 2 for MPU: SDRAM (First 32 MB portion)
@===================================================================

	@ Region 2 - SDRAM
	MOV     r1, #2
	MCR     p15, 0, r1, c6, c2, 0       	@ Set memory region number register
	ISB                                 	@ Ensure subsequent insts execute wrt region 2 settings
	LDR     r2, =0x60000000
	MCR     p15, 0, r2, c6, c1, 0       	@ Set region base address register
	LDR     r2, =0x31			@ Region_Enable
	MCR     p15, 0, r2, c6, c1, 2       	@ Set region size & enable register 64MB
	LDR     r2, =0x323			@ Non-Shared_Bufferable_Cachable_Full-Access, Outer and Inner write-back, no write-allocate
	MCR     p15, 0, r2, c6, c1, 4       	@ Set region access control register

@===================================================================
@ Configure region 3 for MPU: SQI-NOR
@===================================================================

	@ Region 3 - NOR
	MOV     r1, #3
	MCR     p15, 0, r1, c6, c2, 0       	@ Set memory region number register
	ISB                                 	@ Ensure subsequent insts execute wrt region 2 settings
	LDR     r2, =0x90000000
	MCR     p15, 0, r2, c6, c1, 0       	@ Set region base address register
	LDR     r2, =0x2F			@ Region_Enable
	MCR     p15, 0, r2, c6, c1, 2       	@ Set region size & enable register 16MB
	LDR     r2, =0x303			@ Non-Shared_Bufferable_Cachable_Full-Access, Outer and Inner write-back, no write-allocate
	MCR     p15, 0, r2, c6, c1, 4

@===================================================================
@ Configure region 4 for MPU: TCM
@===================================================================

	@ Region 4 - TCM
	MOV     r1, #4
	MCR     p15, 0, r1, c6, c2, 0       	@ Set memory region number register
	ISB                                 	@ Ensure subsequent insts execute wrt region 2 settings
	LDR     r2, =0x68000000
	MCR     p15, 0, r2, c6, c1, 0       	@ Set region base address register
	LDR     r2, =0x1F			@ Region_Enable
	MCR     p15, 0, r2, c6, c1, 2       	@ Set region size & enable register 64 KB
	LDR     r2, =0x300			@ Non-Shared_Non_Bufferable_Cachable_Full-Access, Outer and Inner write-back, no write-allocate
	MCR     p15, 0, r2, c6, c1, 4

@===================================================================
@ Configure region 5 for MPU: M3 eSRAM (second 128 KB bank)
@===================================================================

	@ Region 5 - TCM
	MOV     r1, #5
	MCR     p15, 0, r1, c6, c2, 0       	@ Set memory region number register
	ISB                                 	@ Ensure subsequent insts execute wrt region 2 settings
	LDR     r2, =0x10020000
	MCR     p15, 0, r2, c6, c1, 0       	@ Set region base address register
	LDR     r2, =0x21			@ Region_Enable
	MCR     p15, 0, r2, c6, c1, 2       	@ Set region size & enable register 128 KB
	LDR     r2, =0x303			@ Non-Shared_Non_Bufferable_Cachable_Full-Access, Outer and Inner write-back, no write-allocate
	MCR     p15, 0, r2, c6, c1, 4

@===================================================================
@ Configure region 6 for MPU: SDRAM 16 MB (Second 16 MB portion)
@===================================================================

	@ Region 6 - SDRAM
	MOV     r1, #6
	MCR     p15, 0, r1, c6, c2, 0       	@ Set memory region number register
	ISB                                 	@ Ensure subsequent insts execute wrt region 2 settings
	LDR     r2, =0x62000000
	MCR     p15, 0, r2, c6, c1, 0       	@ Set region base address register
	LDR     r2, =0x2F			@ Region_Enable
	MCR     p15, 0, r2, c6, c1, 2       	@ Set region size & enable register 16MB
	LDR     r2, =0x323			@ Non-Shared_Bufferable_Cachable_Full-Access, Outer and Inner write-back, no write-allocate
	MCR     p15, 0, r2, c6, c1, 4       	@ Set region access control register

@===================================================================
@ Configure region 7 for MPU: SDRAM 8 MB (Third 8 MB portion)
@===================================================================

	@ Region 7 - SDRAM
	MOV     r1, #7
	MCR     p15, 0, r1, c6, c2, 0       	@ Set memory region number register
	ISB                                 	@ Ensure subsequent insts execute wrt region 2 settings
	LDR     r2, =0x63000000
	MCR     p15, 0, r2, c6, c1, 0       	@ Set region base address register
	LDR     r2, =0x2D			@ Region_Enable
	MCR     p15, 0, r2, c6, c1, 2       	@ Set region size & enable register 8MB
	LDR     r2, =0x323			@ Non-Shared_Bufferable_Cachable_Full-Access, Outer and Inner write-back, no write-allocate
	MCR     p15, 0, r2, c6, c1, 4       	@ Set region access control register


@===================================================================
@ Configure region 8 (Optional NO cache)
@===================================================================

	@ Region 8 - Optional region 1 - no cache
	LDR     r0, =GLOBAL_VARIABLE_AREA
	LDR     r3, [r0, #0xDC]
	CMP     r3, #0x0
	BEQ     end_no_cac_regs

	MOV     r1, #8
	MCR     p15, 0, r1, c6, c2, 0       	@ Set memory region number register
	ISB                                 	@ Ensure subsequent insts execute wrt region 2 settings

	MOV     r2, r3
	MCR     p15, 0, r2, c6, c1, 0       	@ Set region base address register

	LDR     r0, =GLOBAL_VARIABLE_AREA
	LDRB    r2, [r0, #0xE0]			        @ Region_Enable
	ORR     r2, r2, #0x1
	MCR     p15, 0, r2, c6, c1, 2       	@ Set region size & enable register
	LDR     r2, =0x320			@ Non-Shared_Non_Bufferable_Cachable_Full-Access, Outer and Inner write-back, no write-allocate
	MCR     p15, 0, r2, c6, c1, 4

@===================================================================
@ Configure region 9 (Optional NO cache)
@===================================================================

	@ Region 9 - Optional region 1 - no cache
	LDR     r0, =GLOBAL_VARIABLE_AREA
	LDR     r3, [r0, #0xE4]
	CMP     r3, #0x0
	BEQ     end_no_cac_regs

	MOV     r1, #9
	MCR     p15, 0, r1, c6, c2, 0       	@ Set memory region number register
	ISB                                     @ Ensure subsequent insts execute wrt region 2 settings

	MOV     r2, r3
	MCR     p15, 0, r2, c6, c1, 0       	@ Set region base address register

	LDR     r0, =GLOBAL_VARIABLE_AREA
	LDRB    r2, [r0, #0xE8]			        @ Region_Enable
	ORR     r2, r2, #0x1
	MCR     p15, 0, r2, c6, c1, 2       	@ Set region size & enable register 64 KB
	LDR     r2, =0x320			@ Non-Shared_Non_Bufferable_Cachable_Full-Access, Outer and Inner write-back, no write-allocate
	MCR     p15, 0, r2, c6, c1, 4

end_no_cac_regs:

@===================================================================
@ Cache enable
@===================================================================
	mrc	p15, 0, r1, c15, c0, 0		@ Read SCTLR configuration data
	bic 	r1, r1, #0x1 <<22
	mcr 	p15, 0, r1, c15, c0, 0 		@ Enabled cache RAMs

	mrc 	p15, 0, r1, c1, c0, 0 		@ Read SCTLR configuration data
	orr 	r1, r1, #0x1 <<17 		@ Background region enable
	orr 	r1, r1, #0x1 <<12 					@ Instruction cache enable
	orr 	r1, r1, #0x1 <<2 					@ Data cache enable
	orr 	r1, r1, #0x1 						@ Enable MPU
	dsb

@===================================================================
@ Invalidate cache contents
@===================================================================
	mcr 	p15, 0, r0, c15, c5, 0 				@ Invalidate entire data cache
	mcr 	p15, 0, r0, c7, c5, 0 				@ Invalidate entire instruction cache
	mcr 	p15, 0, r1, c1, c0, 0 				@ Enabled cache RAMs
	isb
@ End of Machine/Board initial
@ --> setup stack.

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
