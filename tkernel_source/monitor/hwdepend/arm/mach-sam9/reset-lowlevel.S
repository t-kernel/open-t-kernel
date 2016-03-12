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
	mov	r0, #1
	ldr	r1, =0x80040000
	str	r0, [r1, #0x500]	@ power control

serial:
@ set_pin_mux(3,0,2);		//UART4-TXD
@ set_pin_mux(3,1,2);		//UART4-RXD
	ldr	r1, =0x80044000
	mov	r0, #0x12
	str	r0, [r1, #0x60]
	str	r0, [r1, #0x64]

	ldr	r1, =0x80040000
@    outl(1<<15,HW_AHBCLKCTRL0+4);			//UART4 ENABLE bit15---UART4
	mov	r0, #(1<<15)
	str	r0, [r1, #0x24]

@    outl(1,HW_UART4CLKDIV);					//UART4 devided by x from PLL
	mov	r0, #1
	str	r0, [r1, #0x1A8]

	mov	r0, #(1<<15)
@	outl(0x1<<15,HW_AHBCLKCTRL0+8);			//UART4 clk gate  //eye check
@	outl(0x1<<15,HW_AHBCLKCTRL0+4);			//UART4 clk gate  //eye check
@	outl(0x1<<15,HW_PRESETCTRL0+8);			//UART4 reset    //eye check
@	outl(0x1<<15,HW_PRESETCTRL0+4);			//UART4 reset    //eye check    	mov	r0, #(1<<15)
	str	r0, [r1, #0x28]
	str	r0, [r1, #0x24]
	str	r0, [r1, #8]
	str	r0, [r1, #4]

	ldr	r1, =0x80010000
@    outl(0xC0000000,HW_UART4_CTRL0+8);		//CLEAR UART4 SFTRST AND CLKGATE
	ldr	r0, =0xC0000000
	str	r0, [r1, #8]

@    outl(0x00062070,HW_UART4_LINECTRL);	// set bandrate 115200 12M
	ldr	r0, =0x00062070
	str	r0, [r1, #0x30]

@    outl(0x301,HW_UART4_CTRL2+4);  			// enable Rx&Tx
	ldr	r0, =0x301
	str	r0, [r1, #0x24]

@    outl(0xc000,HW_UART4_CTRL2+8); 			// clear hw control
	ldr	r0, =0xC000
	str	r0, [r1, #0x28]
@ serial done

	mov	r0, #'a'
	bl	serial_putchar
	mov	r0, #'s'
	bl	serial_putchar
	mov	r0, #'m'
	bl	serial_putchar
	mov	r0, #'9'
	bl	serial_putchar
	
	ldr	r1, =0x80040000

	mov	r0, #(1<<2)
	str	r0, [r1,  #0x24]

	mov	r0, #(1<<8)
	str	r0, [r1,  #0x34]

	mov	r0, #(3<<9)
	str	r0, [r1,  #0x24]

	ldr	r0, [r1, #0x238]
	bic	r0, #0x00000004
	str	r0, [r1, #0x238]

	mov	r0, #2
	str	r0, [r1, #0x17C]
	str	r0, [r1, #0x180]

	mov	r0, #480
	str	r0, [r1, #0x100]

	ldr	r1, =0x00100000		@ wait syspll lock
1:
	sub	r1, #1
	cmp	r1, #0
	beq	2f

	ldr	r0, =0x80040104
	ldr	r0, [r0]
	and	r0, r0, #1
	cmp	r0, #0
	beq	1b
2:
	ldr	r1, =2000		@ wait 100us or more
1:	sub	r1, #1
	cmp	r1, #0
	bne	1b

	ldr	r1, =0x80040000

	mov	r0, #1
	str	r0, [r1, #0x120]

	mov	r0, #0
	str	r0, [r1, #0x124]

	mov	r0, #1
	str	r0, [r1, #0x124]

	mov	r0, #(1<<6)	@ enable emi clock
	str	r0, [r1,  #0x24]

#ifdef CONFIG_MACH_ASM9

//SDRAM32M ASM9260T SIP
@	outl((1 << 3) | (12 << 5) | (8 << 9) | (0 << 13),0x80700000 );
@	  outl: 0x00001188 -> 0x80700000
	ldr	r0, =0x00001188
	ldr	r1, =0x80700000
	str	r0, [r1]

	ldr	r1, =0x80040000
@	outl((inl(0x8004034C) & 0xFFF1E0FF) | (5 << 8) | (1 << 17) | (2 << 18),0x8004034C);

	ldr	r0, [r1, #0x34C]
	bic	r0, #0x000E0000
	bic	r0, #0x00001F00
	orr	r0, #0x000A0000
	orr	r0, #0x00000500
	str	r0, [r1, #0x34C]

	ldr	r1, =0x80070000
@	outl(0x20000000,0x80700014 + 4*2);
	mov	r0, #0x20000000
	str	r0, [r1, #0x1C]

@	outl(0xc,0x80700054 + 4*2);
	mov	r0, #0xC
	str	r0, [r1, #0x5C]

@	outl(0x024996d9,0x80700004);
	ldr	r1, =0x024996D9
	str	r0, [r1, #4]

@	outl((inl(0x80700004) & 0xFFFFFFFC) | (1 << 0),0x80700004);
	ldr	r0, [r1, #4]
	bic	r0, #0x03
	orr	r0, #0x01
	str	r0, [r1, #4]

@	outl(0x00542b4f,0x80700094);
	ldr	r0, =0x00542b4F
	str	r0, [r1, #0x94]

@	outl(inl(0x8070000C) | (1 << 9) ,0x8070000C);
	ldr	r0, [r1, #0xC]
	orr	r0, #(1<<9)
	str	r0, [r1, #0xC]
#endif



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
	mov	lr, r6
	bx	lr

serial_putchar:
1:	ldr	r7, =0x80010000
	ldr	r7, [r7, #0x60]

	and	r7, #0x08000000
	cmp	r7, #0
	beq	1b

	ldr	r7, =0x80010000
	strb	r0, [r7, #0x50]
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
