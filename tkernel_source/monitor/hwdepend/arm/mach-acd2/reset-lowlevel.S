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

#define	_in_asm_source_

#include <machine.h>
#include <tk/sysdef.h>
#include <sys/sysinfo.h>

#include <mach/em1d512.h>
#include <setup_em1d512.h>

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


/*----------------------------------------------------------------------
        T-Monitor boot processing
----------------------------------------------------------------------*/
	.section .startup
	.globl	startup_entry_lowlevel
startup_entry_lowlevel:
@ Machine/Board initial
// Setup clock divider
	mov	r0, #0
	ldr	r2, =CHG_L1_HOLD
	str	r0, [r2]		// release data hold when L1 is off
	mov	r0, #0x30000000
	ldr	r2, =AUTO_FRQ_CHANGE
	str	r0, [r2]		// automatic frequency change function is off

setup_clock_divider:
	adr	r0, param_table0
	setup_param

// Setup PLL1 (PLL3 is operating)
@setup_pll1:
        // We assume Power ON mode: In other mode setting, we simply take it for granted that PLL has been configured already
	ldr	r2, =CLK_MODE_SEL
	ldr	r0, [r2]
	ands	r0, r0, #0x00000f00
	bne	setup_power_mode

	mov	r0, #0x79		// (default) PLL1=499.712MHz
	ldr	r2, =PLL1CTRL0
	str	r0, [r2]
	mov	r0, #0
	ldr	r2, =PLL1CTRL1
	str	r0, [r2]		// PLL starts to operate
	ldr	r2, =PLL_STATUS
wait_pll1:
	ldr	r0, [r2]		// Wait for PLL1 operation completion
	ands	r0, r0, #0x00000001
	beq	wait_pll1

// Setup power mode
setup_power_mode:
        // Transition from Power ON to Normal Mode A
	mov	r0, #1
	ldr	r2, =CLK_MODE_SEL
	str	r0, [r2]
wait_power_mode_change:
	ldr	r0, [r2]
	and	r0, r0, #0x00000f00
	cmp	r0, #0x00000100
	bne	wait_power_mode_change

// Setup PLL2 (needs to be configured in Normal Mode)
setup_pll2:
	mov	r0, #0xff		// PLL2 ceases to operate
	ldr	r2, =PLL2CTRL1
	str	r0, [r2]
	ldr	r2, =PLL_STATUS
wait_pll2_0:	
	ldr	r0, [r2]		// Wait for PLL1 operation
	ands	r0, r0, #0x00000100
	bne	wait_pll2_0

	mov	r0, #0x61		// PLL2=401.408MHz
	ldr	r2, =PLL2CTRL0
	str	r0, [r2]
	mov	r0, #0			// PLL2 starts to operate
	ldr	r2, =PLL2CTRL1
	str	r0, [r2]
	ldr	r2, =PLL_STATUS
wait_pll2_1:	
	ldr	r0, [r2]		// wait for PLL2 to stop operation.
	ands	r0, r0, #0x00000100
	beq	wait_pll2_1

// Setup pin multiplexer
setup_pin_mux:
	mov	r1, #0xff000000		// since 'adr' cannot be used, we manually make sure
	ldr	r0, =Csym(GPIOConfig)	// that the code is relocatable at 16MB units boundary.
	bic	r0, r0, r1
	and	r1, pc, r1
	orr	r0, r0, r1
	setup_param
	
// release reset of the internal modules
setup_module:
	adr	r0, param_table1
	setup_param
	ldr	r0, =100000
	wait_nsec

// supplying clock to modules.
setup_clock_distribution:
	adr	r0, param_table2
	setup_param

// Setup Bus controller
setup_bcr:
	adr	r0, param_table3
	setup_param

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

	bx	lr

@ End of Machine/Board initial
	

// initialization of DDR memory
setup_ddr:
	ldr	r0, =MEMCCLK270_SEL
	ldr	r1, =0x00000001		// MEMCCLK270 no phase delay
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGT1
	ldr	r1, =0x00000006		// start auto-calibration
	str	r1, [r0]
calibrate_loop:
	ldr	r1, [r0]
	ands	r1, r1, #0x00000002	// wait for complete
	beq	calibrate_loop

	ldr	r0, =MEMC_DDR_CONFIGT3
	ldr	r1, [r0]		// get calibration result
	ldr	r0, =MEMC_DDR_CONFIGT2
	str	r1, [r0]		// apply calibrated value

	ldr	r0, =MEMCCLK270_SEL
	ldr	r1, =0x00000000		// MEMCCLK270 270degree delay
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGT1
	ldr	r1, =0x000d0803
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGF
	ldr	r1, =0x00000015
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGA1
	ldr	r1, =0x53443203
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGA2
	ldr	r1, =0x28da1042
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGC2
	ldr	r1, =0x0000001d
	str	r1, [r0]

	ldr	r0, =200000
	wait_nsec

	ldr	r0, =MEMC_DDR_CONFIGC1
	ldr	r1, =0x80200033
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGC2
	ldr	r1, =0x00000018		// CS0: memory initialize sequence
	str	r1, [r0]
ddr_init_loop:
	ldr	r1, [r0]
	ands	r1, r1, #0x00000100
	beq	ddr_init_loop

	ldr	r0, =MEMC_REQSCH
	ldr	r1, =0x0000001f		// memory request schedule
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGC2
	ldr	r1, =0x00000090		// CS0: CMD_REQ release
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGR1
	ldr	r1, =0x00690069		// refresh counter
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGR2
	ldr	r1, =0x3777011f
	str	r1, [r0]

	ldr	r0, =MEMC_DDR_CONFIGR3
	ldr	r1, =0x00001415
	str	r1, [r0]

	bx	lr

	.pool

param_table0:
	.long	NORMALA_DIV		// ACPU =PLL1/1 (499.712MHz)
	.long	0x00244200		// ADSP =PLL1/1 (499.712MHz)
					// HBUS =PLL1/3 (166.571MHz)
					// LBUS =PLL1/6 ( 83.285MHz)
					// FLASH=PLL1/6 ( 83.285MHz)
					// MEMC =PLL1/3 (166.571MHz)
	.long	DIVU70SCLK
	.long	0x00000000		// U70_SCLK=PLL3/1 (229.376MHz)
	.long	DIVU71SCLK
	.long	0x00000000		// U71_SCLK=PLL3/1 (229.376MHz)
	.long	DIVU72SCLK
	.long	0x00000000		// U72_SCLK=PLL3/1 (229.376MHz)
	.long	DIVLCDLCLK
	.long	0x00000004		// LCD_LCLK=PLL2/16 (25.088MHz)
	.long	DIVIICSCLK
	.long	0x00530053		// IIC_SCLK=PLL3/48 (4.779MHz)
	.long	DIVTIMTIN
	.long	0x00000003		// Txx_TIN=PLL3/8 (28.672MHz)
	.long	DIVSP0SCLK
	.long	0x00000074		// SP0_SCLK=PLL3/128 (1.792MHz)
	.long	TI0TIN_SEL
	.long	0x00000000
	.long	TI1TIN_SEL
	.long	0x00000000
	.long	TI2TIN_SEL
	.long	0x00000000
	.long	TI3TIN_SEL
	.long	0x00000000
	.long	TIGnTIN_SEL
	.long	0x00000000

	.long	0x00000000		// (terminate)
	.long	0x00000000

param_table1:
	.long	RESETREQ0ENA
	.long	0xffffffff
	.long	RESETREQ0
	.long	0xffffffe7		// Reset everything, but DSP
	.long	RESETREQ0ENA
	.long	0x00000000
	.long	RESETREQ1ENA
	.long	0xffffffff
	.long	RESETREQ1
	.long	0xffffffff		// Reset everything
	.long	RESETREQ1ENA
	.long	0x00000000
	.long	RESETREQ2ENA
	.long	0xffffffff
	.long	RESETREQ2
	.long	0xffffffff		// Reset everything
	.long	RESETREQ2ENA
	.long	0x00000000
	.long	RESETREQ3ENA
	.long	0xffffffff
	.long	RESETREQ3
	.long	0xffffffff		// Reset everything
	.long	RESETREQ3ENA
	.long	0x00000000

	.long	0x00000000		// (terminate)
	.long	0x00000000

param_table2:
	.long	GCLKCTRL0ENA
	.long	0xffffffff
	.long	GCLKCTRL0
	.long	0xffffffff		// (default) module clock on
	.long	GCLKCTRL0ENA
	.long	0x00000000
	.long	GCLKCTRL1ENA
	.long	0xffffffff
	.long	GCLKCTRL1
	.long	0xffffffff		// (default) module clock on
	.long	GCLKCTRL1ENA
	.long	0x00000000
	.long	GCLKCTRL2ENA
	.long	0xffffffff
	.long	GCLKCTRL2
	.long	0xffffffff		// (default) module clock on
	.long	GCLKCTRL2ENA
	.long	0x00000000
	.long	GCLKCTRL3ENA
	.long	0xffffffff
	.long	GCLKCTRL3
	.long	0xffffffff		// (default) module clock on
	.long	GCLKCTRL3ENA
	.long	0x00000000
	.long	GCLKCTRL4ENA
	.long	0xffffffff
	.long	GCLKCTRL4
	.long	0xffffffff		// (default) module clock on
	.long	GCLKCTRL4ENA
	.long	0x00000000
	.long	AHBCLKCTRL0
	.long	0x00000000		// (default) prohibit automatic control
	.long	AHBCLKCTRL1
	.long	0x00000000		// (default) prohibit automatic control
	.long	APBCLKCTRL0
	.long	0x00000000		// (default) prohibit automatic control
	.long	APBCLKCTRL1
	.long	0x00000000		// (default) prohibit automatic control
	.long	CLKCTRL
	.long	0x00000000		// (default) prohibit automatic control
	.long	CLKCTRL1
	.long	0x00000000

	.long	0x00000000		// (terminate)
	.long	0x00000000

param_table3:
	.long	AB1_U70WAITCTRL
	.long	0x00010200		// recommended value for 83MHz operation
	.long	AB1_U71WAITCTRL
	.long	0x00010200		// recommended value for 83MHz operation
	.long	AB1_U72WAITCTRL
	.long	0x00010200		// recommended value for 83MHz operation
	.long	AB1_IIC2WAITCTRL
	.long	0x00010300		// recommended value for 83MHz operation
	.long	AB1_IICWAITCTRL
	.long	0x00010300		// recommended value for 83MHz operation
	.long	AB1_SDIAWAITCTRL
	.long	0x00010300
	.long	AB1_SDIBWAITCTRL
	.long	0x00010300
	.long	AB1_SDICWAITCTRL
	.long	0x00010300
	.long	AB1_U70READCTRL
	.long	0x00000000		// (default)
	.long	AB1_U71READCTRL
	.long	0x00000000		// (default)
	.long	AB1_U72READCTRL
	.long	0x00000000		// (default)
	.long	AB1_IIC2READCTRL
	.long	0x00000000		// (default)
	.long	AB1_IICREADCTRL
	.long	0x00000000		// (default)
	.long	AB1_SDIAREADCTRL
	.long	0x00000000		// (default)
	.long	AB1_SDIBREADCTRL
	.long	0x00000000		// (default)
	.long	AB1_SDICREADCTRL
	.long	0x00000000		// (default)

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
	.long	AB0_CSnBASEADD(0)
	.long	0x00000000
	.long	AB0_CSnBITCOMP(0)
	.long	0xf0000000
	.long	AB0_CSnBASEADD(1)
	.long	0x10000000
	.long	AB0_CSnBITCOMP(1)
	.long	0xf0000000
	.long	AB0_CSnBASEADD(2)
	.long	0x20000000
	.long	AB0_CSnBITCOMP(2)
	.long	0xf8000000
	.long	AB0_CSnBASEADD(3)
	.long	0x28000000
	.long	AB0_CSnBITCOMP(3)
	.long	0xf8000000
	.long	AB0_FLASHCLKCTRL
	.long	0x00000001		// AB0:Flash=1:2

        // set up LAN controller
        // Assuming the use of 83.333 MHz (12ns/1clk), we set the following values.
	//	CSint=1clk (Read+1clk=24ns, Write+2clk=36ns)
	//	T0=0clk (0ns), T1=3clk(36ns), T2=2clk(24ns)
	.long	AB0_CSnWAITCTRL(3)
	.long	0x01020300
	.long	AB0_CSnWAITCTRL_W(3)
	.long	0x00020300
	.long	AB0_CSnREADCTRL(3)
	.long	0x00000000		// (default)
	.long	AB0_CSnWAIT_MASK(3)
	.long	0x00000000		// (default)
	.long	AB0_CSnCONTROL(3)
	.long	0x00010100		// (default)
	.long	AB0_FLASHCOMSET
	.long	0x00000008		// CS3 value above is reflected.
	
	.long	0x00000000		// (terminate)
	.long	0x00000000

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
