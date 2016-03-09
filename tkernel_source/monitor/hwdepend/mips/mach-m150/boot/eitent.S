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
 *    Modified for APP-M150(MIPS32) at 2015/10/19.
 *
 *----------------------------------------------------------------------
 */

/*
 *	eitentry.S	( T-Monitor for APP-M150 )
 *
 *	 M150(MIPS32) exception branch handling
 */

#define	_in_asm_source_

#include <machine.h>
#include <tk/asm.h>
#include <tk/sysdef.h>
#include <sys/sysinfo.h>

#include <tmonitor.h>

	.extern procReset
	.extern entMonitor
	.extern regStack

/*------------------------------------------------------------------------
	0x8000 0000	TLB Refile Exception Entry Point (HW)
	0x8000 0010	Start - Reset Entry (SW)
	0xA000 0100	Cache Error Exception Entry Point (HW)
	0x8000 0180	Other Exception Entry Point (HW)
	0x8000 0200	Interrupt Entry Point (HW)
	---------------------------------------------
	0x8000 7000	EIT Vector (SW)
	---------------------------------------------
	0xBFC0 0000	Reset/MMI Entry Point (HW) --> Boot-ROM Program
	---------------------------------------------
	0xF400 0000	Primary Boot Program called by Boot-ROM (HW)
------------------------------------------------------------------------*/

#define	RESET_VECTOR	0xBFC00000

	.section .eitent, "ax"
	.balign	4

/*----------------------------------------------------------------------
	0x8000 0000	TLB Refile Exception Entry
----------------------------------------------------------------------*/
	.org	0x0000
tlbmiss_entry:
	lw	$kt0, sadr(XEITVEC(EIT_TLBMISS))
	jr	$kt0

/*----------------------------------------------------------------------
	Reset Entry from UBOOT-SPL
----------------------------------------------------------------------*/
	.globl	Csym(_start)
	.type	Csym(_start), %function

	.org	0x0010
Csym(_start):
	/* Initialize Registers */
	/* Initialize Hardware */
	/* Initialize Cache */
	li	$kt0, 0xFFFFFFFF
	mtc0	$kt0, $CP0_CMP
	mtc0	$zero, $CP0_CNT
	li	$kt0, SR_IMMSK|SR_KNL|SR_ERL
	mtc0	$kt0, $CP0_PSR

	j	procReset

/*----------------------------------------------------------------------
	Default handler
----------------------------------------------------------------------*/
default_entry:
	lw	$kt0, sadr(EITVEC(EIT_DEFAULT))
	jr	$kt0

	.globl	Csym(_sysReset)
	.type	Csym(_sysReset), %function
Csym(_sysReset):
	la	$kt1, RESET_VECTOR
	jr	$kt1

/*----------------------------------------------------------------------
	0xA000 0100	Cache Error Exception Entry
----------------------------------------------------------------------*/
	.org	0x0100
cacheerr_entry:
	lw	$kt0, sadr(XEITVEC(EIT_CACHEERR))
	beqz	$kt0, Csym(_sysReset)
	jr	$kt0

/*----------------------------------------------------------------------
	0x8000 0180	Other Exception Entry

		+---------------+
	isp  ->	| t8		|
	   +1*4	| t9		|
	   +2*4	| EPC		|
	   +3*4	| taskmode	|
	   +4*4	| PSR		|
	   +5*4	| usp / dummy	| usp: RNG1-3, dummy: RNG0
		+---------------+
	* Stack Pointer should be aligned by 8 bytes.

	Jump to the EITVEC( EIT_EXC(0-31) ) entry
			according to exception code in the CP0_OCC

	At handler entry	t8: EIT vector address
				t9: CP0_OCC
				kt0: Undefined
				kt1: isp
----------------------------------------------------------------------*/
  o_jmphdr:
	li	$t8, ~SR_KSU
	and	$kt0, $kt0, $t8
	mtc0	$kt0, $CP0_PSR			// KSU = 0 to Kernel mode

	li	$kt0, EITVEC(EIT_EXC(0))
	mfc0	$t9, $CP0_OCC			// t9 = CP0_OCC
	and	$t8, $t9, OC_EXC
	addu	$t8, $t8, $kt0			// jump to EIT_EXC(0-31)
	lw	$kt0, 0($t8)
	beqz	$kt0, default_entry
	jr	$kt0

/*--------------------------------------------------------------------*/
	.org	0x0180
other_entry:
	.set	noreorder
	lui	$kt0, %hi(SCINFO)
	lw	$kt1, %lo(ISTKPOS)($kt0)
	subu	$kt1, $kt1, 6*4			// kt1 = isp -= 6*4
	sw	$kt1, %lo(ISTKPOS)($kt0)

	lw	$kt0, %lo(TASKMODE)($kt0)
	and	$kt0, $kt0, TMF_CPL(3)
	beqz	$kt0, o_savereg			// Level 0
	lui	$kt0, %hi(SCINFO)

	sw	$sp, 5*4($kt1)			// save usp
	lw	$sp, %lo(SSTKTOP)($kt0)		// switch to ssp

  o_savereg:
	sw	$t8, 0*4($kt1)			// save t8
	sw	$t9, 1*4($kt1)			// save t9
	mfc0	$t8, $CP0_EPC
	sw	$t8, 2*4($kt1)			// save CP0_EPC
	lw	$t9, %lo(TASKMODE)($kt0)
	sw	$t9, 3*4($kt1)			// save taskmode
	sll	$t9, $t9, 16			// update taskmode
	sw	$t9, %lo(TASKMODE)($kt0)
	mfc0	$kt0, $CP0_PSR
	sw	$kt0, 4*4($kt1)			// save CP0_PSR
	.set	reorder

	b	o_jmphdr			// jump to handler

/*----------------------------------------------------------------------
	0x8000 0200	Interrupt Entry

		+---------------+
	isp  ->	| t8		|
	   +1*4	| t9		|
	   +2*4	| EPC		|
	   +3*4	| taskmode	|
	   +4*4	| PSR		|
	   +5*4	| usp / dummy	| usp: RNG1-3, dummy: RNG0
		+---------------+

	* Stack Pointer should be aligned by 8 bytes.

	Jump to the EITVEC( EIT_IP(0-7) ) entry
			according to IP bit in the CP0_OCC

	At handler entry	t8: EIT vector address
				t9: CP0_OCC
				kt0: Undefined
				kt1: isp
----------------------------------------------------------------------*/
	.org	0x0200
int_entry:
	.set	noreorder
	lui	$kt0, %hi(SCINFO)
	lw	$kt1, %lo(ISTKPOS)($kt0)
	subu	$kt1, $kt1, 6*4			// kt1 = isp -= 6*4
	sw	$kt1, %lo(ISTKPOS)($kt0)

	lw	$kt0, %lo(TASKMODE)($kt0)
	and	$kt0, $kt0, TMF_CPL(3)
	beqz	$kt0, i_savereg			// Level 0
	lui	$kt0, %hi(SCINFO)

	sw	$sp, 5*4($kt1)			// save usp
	lw	$sp, %lo(SSTKTOP)($kt0)		// switch to ssp

  i_savereg:
	sw	$t8, 0*4($kt1)			// save t8
	sw	$t9, 1*4($kt1)			// save t9
	mfc0	$t8, $CP0_EPC
	sw	$t8, 2*4($kt1)			// save CP0_EPC
	lw	$t9, %lo(TASKMODE)($kt0)
	sw	$t9, 3*4($kt1)			// save taskmode
	sll	$t9, $t9, 16			// update taskmode
	sw	$t9, %lo(TASKMODE)($kt0)
	mfc0	$kt0, $CP0_PSR
	sw	$kt0, 4*4($kt1)			// save CP0_PSR

	li	$t8, ~SR_KSU
	and	$kt0, $kt0, $t8
	mtc0	$kt0, $CP0_PSR			// KSU = 0 to Kernel mode

	mfc0	$t9, $CP0_OCC			// t9 = CP0_OCC
	.set	reorder

	// Fall through to _intHdr

/*----------------------------------------------------------------------
	Interrupt handler EIT_EXC(0)

	IP7: Highest -- IP0: Lowest priority
----------------------------------------------------------------------*/
	.globl	Csym(_intHdr)
	.type	Csym(_intHdr), %function
Csym(_intHdr):
	// t9 = CP0_OCC
	mfc0	$kt0, $CP0_PSR
	and	$t8, $t9, $kt0
	or	$t8, $t8, OC_IP(0)
	sll	$t8, $t8, 16
	clz	$t8, $t8		// t8 = 7 - IPx(0-7)

	lui	$kt1, 0xffff
	sra	$kt1, $kt1, $t8
	or	$kt1, $kt1, 0x00ff
	and	$kt0, $kt0, $kt1
	mtc0	$kt0, $CP0_PSR		// Disable low priority interrupts

	sll	$t8, $t8, 2
	li	$kt0, EITVEC(EIT_IP(7))
	addu	$t8, $t8, $kt0
	lw	$kt0, 0($t8)
	beqz	$kt0, default_entry
	jr	$kt0

/*----------------------------------------------------------------------
	Interrupt handler for Interrupt Controller EIT_IP(6-2)

	IRQ63: Highest -- IRQ0: Lowest priority

	Jump to the EITVEC( EIT_IRQ(63-0) ) entry
			according to the INT_ICPR1/0

	At handler entry	t8: EIT vector address
				t9, kt0, kt1: Undefined
----------------------------------------------------------------------*/
	.globl	Csym(_ip2Hdr)
	.type	Csym(_ip2Hdr), %function
	.globl	Csym(_ip3Hdr)
	.type	Csym(_ip3Hdr), %function
	.globl	Csym(_ip4Hdr)
	.type	Csym(_ip4Hdr), %function
	.globl	Csym(_ip5Hdr)
	.type	Csym(_ip5Hdr), %function
	.globl	Csym(_ip6Hdr)
	.type	Csym(_ip6Hdr), %function
Csym(_ip2Hdr):
Csym(_ip3Hdr):
Csym(_ip4Hdr):
Csym(_ip5Hdr):
Csym(_ip6Hdr):
	lui	$t9, %hi(INTC_ICPR1)		// IRQ63 - 32
	lw	$t8, %lo(INTC_ICSR1)($t9)
	li	$kt0, EITVEC(EIT_IRQ(63))	// Vector Base
	bnez	$t8, ip_ckbit

	lw	$t8, %lo(INTC_ICPR0)($t9)	// IRQ31 - 0
	or	$t8, $t8, 1			// Stopper IRQ0
	li	$kt0, EITVEC(EIT_IRQ(31))	// Vector Base
  ip_ckbit:
	clz	$t8, $t8
	sll	$t8, $t8, 2			// x 4

	addu	$t8, $t8, $kt0
	lw	$kt0, 0($t8)
	beqz	$kt0, default_entry
	jr	$kt0

/*----------------------------------------------------------------------
	EIT_EXC(8) : SYSCALL Exception Handler

	Jump to the EITVEC( SYSCALL number 0 - 127 ) entry

	At handler entry	t8: EIT vector address
				t9, kt0, kt1: Undefined
----------------------------------------------------------------------*/
	.globl	Csym(_svcHdr)
	.type	Csym(_svcHdr), %function

Csym(_svcHdr):
	// t9: CP0_OCC, kt1: isp
	bltz	$t9, default_entry	// SYSCALL in delayed slot

	mfc0	$kt0, $CP0_EPC
	lw	$t8, 0($kt0)		// Fetch SYSCALL instruction
	addu	$kt0, $kt0, 4
	sw	$kt0, 2*4($kt1)		// Adjust return address: EPC += 4

	srl	$t8, $t8, 6		// Get SYSCALL number
	sltiu	$kt0, $t8, MAX_INTVEC
	movz	$t8, $zero, $kt0	// Use 0 when the number is invalid
	sll	$t8, $t8, 2
	li	$kt0, EIT_VECTBL
	addu	$t8, $t8, $kt0
	lw	$kt0, 0($t8)
	beqz	$kt0, default_entry
	jr	$kt0

/*----------------------------------------------------------------------
	Default Hadler ( Monitor common entry )
----------------------------------------------------------------------*/
	.globl	Csym(_defaultHdr)
	.type	Csym(_defaultHdr), %function
Csym(_defaultHdr):

//	t8 : Vector table address
//	t9, kt0, kt1 : Undefined
//	sp : System Stack
//	ISP[0*4]	t8
//	   [1*4]	t9
//	   [2*4]	EPC
//	   [3*4]	taskmode
//	   [4*4]	PSR
//	   [5*4]	usp/dummy ( usp: RNG1-3, dummy: RNG0 )

// Save registers
//	regStack[1-31]	r1 .. r31
//		[32-33]	hi,lo
//		[34-44]	IDX,RND,ELO0,ELO1,CTX,PMSK,WIR,BVA,EHI,PSR,OCC
//		[45-51] EPC,PRID,CFG,LLA,TLO,THI,EEPC
//		[52,53]	fcr0,fcr31
//		[54-85]	f0 .. f31

	la	$t9, regStack
	.set	noat
	sw	$at, 1*4($t9)		// R1 - R31
	.set	at
	sw	$v0, 2*4($t9)
	sw	$v1, 3*4($t9)
	sw	$a0, 4*4($t9)
	sw	$a1, 5*4($t9)
	sw	$a2, 6*4($t9)
	sw	$a3, 7*4($t9)
	sw	$t0, 8*4($t9)
	sw	$t1, 9*4($t9)
	sw	$t2, 10*4($t9)
	sw	$t3, 11*4($t9)
	sw	$t4, 12*4($t9)
	sw	$t5, 13*4($t9)
	sw	$t6, 14*4($t9)
	sw	$t7, 15*4($t9)
	sw	$s0, 16*4($t9)
	sw	$s1, 17*4($t9)
	sw	$s2, 18*4($t9)
	sw	$s3, 19*4($t9)
	sw	$s4, 20*4($t9)
	sw	$s5, 21*4($t9)
	sw	$s6, 22*4($t9)
	sw	$s7, 23*4($t9)

	// Set CP0_PSR : 1:CU1,FR, 0:KSU,ERL,EXL,IE
	mfc0	$t0, $CP0_PSR
	li	$t1, SR_CU1|SR_FR|SR_KSU|SR_ERL|SR_EXL|SR_IE
	or	$t0, $t1
	xori	$t0, $t0, SR_KSU|SR_ERL|SR_EXL|SR_IE
	mtc0	$t0, $CP0_PSR

	lui	$t0, %hi(SCINFO)
	lw	$s7, %lo(ISTKPOS)($t0)	// s7 : ISP

	lw	$t0, 0*4($s7)		// t8
	lw	$t1, 1*4($s7)		// t9
	lw	$t2, 2*4($s7)		// EPC
	lw	$s6, 3*4($s7)		// taskmode
	lw	$t3, 4*4($s7)		// PSR

	ori	$t3, $t3, SR_EXL
	xori	$t3, $t3, SR_EXL	// Clear EXL

	sw	$t0, 24*4($t9)		// t8
	sw	$t1, 25*4($t9)		// t9
	sw	$t2, 45*4($t9)		// EPC
	sw	$t3, 43*4($t9)		// PSR

	or	$t4, $sp, $sp		// SP
	and	$s6, $s6, TMF_CPL(3)
	beqz	$s6, no_usp0		// s6: usp mode

	lw	$t4, 5*4($s7)		// USP

  no_usp0:
	sw	$t4, 29*4($t9)		// SP

	sw	$kt0,26*4($t9)
	sw	$kt1,27*4($t9)
	sw	$gp, 28*4($t9)
	sw	$fp, 30*4($t9)
	sw	$ra, 31*4($t9)
	mfhi	$t0			// HI, LO
	mflo	$t1
	sw	$t0, 32*4($t9)
	sw	$t1, 33*4($t9)

	mfc0	$v0, $CP0_IDX		// CP0_XXX
	mfc0	$v1, $CP0_RND
	mfc0	$a1, $CP0_ELO0
	mfc0	$a2, $CP0_ELO1
	mfc0	$a3, $CP0_CTX
	mfc0	$t0, $CP0_PMSK
	mfc0	$t1, $CP0_WIR
	mfc0	$t2, $CP0_BVA
	mfc0	$t3, $CP0_EHI
	mfc0	$t4, $CP0_OCC
	mfc0	$t5, $CP0_PRID
	mfc0	$t6, $CP0_CFG
	mfc0	$t7, $CP0_LLA

	sw	$v0, 34*4($t9)		// IDX
	sw	$v1, 35*4($t9)		// RND
	sw	$a1, 36*4($t9)		// ELO0
	sw	$a2, 37*4($t9)		// ELO1
	sw	$a3, 38*4($t9)		// CTX
	sw	$t0, 39*4($t9)		// PMSK
	sw	$t1, 40*4($t9)		// WIR
	sw	$t2, 41*4($t9)		// BVA
	sw	$t3, 42*4($t9)		// EHI
					// 43: PSR
	sw	$t4, 44*4($t9)		// OCC
					// 45: EPC
	sw	$t5, 46*4($t9)		// PRID
	sw	$t6, 47*4($t9)		// CFG
	sw	$t7, 48*4($t9)		// LLA
	sw	$s0, 49*4($t9)		// TLO
	sw	$s1, 50*4($t9)		// THI
	sw	$s2, 51*4($t9)		// EEPC

	cfc1	$t0, $0			// FCR0
	cfc1	$t1, $31		// FCR31
	sw	$t0, 52*4($t9)
	sw	$t1, 53*4($t9)

	// $t9 should be aligned by 8 bytes.
	sdc1	$f0, 54*4($t9)		// FGR0 - 31
	sdc1	$f2, 56*4($t9)
	sdc1	$f4, 58*4($t9)
	sdc1	$f6, 60*4($t9)
	sdc1	$f8, 62*4($t9)
	sdc1	$f10, 64*4($t9)
	sdc1	$f12, 66*4($t9)
	sdc1	$f14, 68*4($t9)
	sdc1	$f16, 70*4($t9)
	sdc1	$f18, 72*4($t9)
	sdc1	$f20, 74*4($t9)
	sdc1	$f22, 76*4($t9)
	sdc1	$f24, 78*4($t9)
	sdc1	$f26, 80*4($t9)
	sdc1	$f28, 82*4($t9)
	sdc1	$f30, 84*4($t9)

	// Switch to MON_STACK
	or	$s0, $sp, $sp		// Save current SSP
	la	$t1, MON_STACK
	la	$t0, MON_STACK_TOP
	subu	$t0, $sp, $t0
	blez	$t0, chg_monstk		// sp <= MON_STACK_TOP : Switch
	subu	$t0, $sp, $t1
	blez	$t0, nochg_monstk	// sp <= MON_STACK : No Switch
  chg_monstk:
	move	$sp, $t1		// Switch to MON_STACK
  nochg_monstk:

	// Monitor Entry (s0: SSP saved)
	la	$t0, EIT_VECTBL
	subu	$a0, $t8, $t0		// arg0 = Vector offset

////	la	$gp, _gp
	jal	entMonitor

	// Set CP0_PSR CU1
	mfc0	$t0, $CP0_PSR
	li	$t1, SR_CU1
	or	$t0, $t1
	mtc0	$t0, $CP0_PSR

	lui	$t0, %hi(SCINFO)
	lw	$s7, %lo(ISTKPOS)($t0)	// s7 : ISP

	// Update contents in ISP
	la	$t9, regStack

	lw	$t0, 24*4($t9)		// t8
	lw	$t1, 25*4($t9)		// t9
	lw	$t2, 45*4($t9)		// EPC
	lw	$t4, 43*4($t9)		// PSR

	// Set EXL
	ori	$t4, $t4, SR_EXL	// Set EXL
	sw	$t0, 0*4($s7)		// t8
	sw	$t1, 1*4($s7)		// t9
	sw	$t2, 2*4($s7)		// EPC
	lw	$s6, 3*4($s7)		// s6 : taskmode
	sw	$t4, 4*4($s7)		// PSR

	lw	$sp, 29*4($t9)		// SP
	and	$s6, $s6, TMF_CPL(3)
	beqz	$s6, no_usp1

	sw	$sp, 5*4($s7)		// USP
	move	$sp, $s0		// SSP

  no_usp1:

	// Recover Registers ( R0 : Read Only )
//RO	lw	$t0,  52*4($t9)
//RO	ctc1	$t0,  $0		// FCR0
	lw	$t1,  53*4($t9)
	ctc1	$t1,  $31		// FCR31

	// $t9 should be aligned by 8 bytes.
	ldc1	$f0,  54*4($t9)		// FGR0 - 31
	ldc1	$f2,  56*4($t9)
	ldc1	$f4,  58*4($t9)
	ldc1	$f6,  60*4($t9)
	ldc1	$f8,  62*4($t9)
	ldc1	$f10, 64*4($t9)
	ldc1	$f12, 66*4($t9)
	ldc1	$f14, 68*4($t9)
	ldc1	$f16, 70*4($t9)
	ldc1	$f18, 72*4($t9)
	ldc1	$f20, 74*4($t9)
	ldc1	$f22, 76*4($t9)
	ldc1	$f24, 78*4($t9)
	ldc1	$f26, 80*4($t9)
	ldc1	$f28, 82*4($t9)
	ldc1	$f30, 84*4($t9)

	lw	$v0, 34*4($t9)		// IDX
//RO	lw	$v1, 35*4($t9)		// RND
	lw	$a1, 36*4($t9)		// ELO0
	lw	$a2, 37*4($t9)		// ELO1
	lw	$a3, 38*4($t9)		// CTX
	lw	$t0, 39*4($t9)		// PMSK
	lw	$t1, 40*4($t9)		// WIR
//RO	lw	$t2, 41*4($t9)		// BVA
	lw	$t3, 42*4($t9)		// EHI
					// 43: PSR
	lw	$t4, 44*4($t9)		// OCC
					// 45: EPC
//RO	lw	$t5, 46*4($t9)		// PRID
	lw	$t6, 47*4($t9)		// CFG
//RO	lw	$t7, 48*4($t9)		// LLA
	lw	$s0, 49*4($t9)		// TLO
	lw	$s1, 50*4($t9)		// THI
	lw	$s2, 51*4($t9)		// EEPC

	mtc0	$v0, $CP0_IDX		// CP0_XXX
//RO	mtc0	$v1, $CP0_RND
	mtc0	$a1, $CP0_ELO0
	mtc0	$a2, $CP0_ELO1
	mtc0	$a3, $CP0_CTX
	mtc0	$t0, $CP0_PMSK
	mtc0	$t1, $CP0_WIR
//RO	mtc0	$t2, $CP0_BVA
	mtc0	$t3, $CP0_EHI
	mtc0	$t4, $CP0_OCC
//RO	mtc0	$t5, $CP0_PRID
	mtc0	$t6, $CP0_CFG
//RO	mtc0	$t7, $CP0_LLA
	mtc0	$s0, $CP0_TLO
	mtc0	$s1, $CP0_THI
	mtc0	$s2, $CP0_EEPC

	lw	$t0, 32*4($t9)
	lw	$t1, 33*4($t9)
	mthi	$t0			// HI, LO
	mtlo	$t1

	.set	noat
	lw	$at, 1*4($t9)		// R1 - R31
	lw	$v0, 2*4($t9)
	lw	$v1, 3*4($t9)
	lw	$a0, 4*4($t9)
	lw	$a1, 5*4($t9)
	lw	$a2, 6*4($t9)
	lw	$a3, 7*4($t9)
	lw	$t0, 8*4($t9)
	lw	$t1, 9*4($t9)
	lw	$t2, 10*4($t9)
	lw	$t3, 11*4($t9)
	lw	$t4, 12*4($t9)
	lw	$t5, 13*4($t9)
	lw	$t6, 14*4($t9)
	lw	$t7, 15*4($t9)
	lw	$s0, 16*4($t9)
	lw	$s1, 17*4($t9)
	lw	$s2, 18*4($t9)
	lw	$s3, 19*4($t9)
	lw	$s4, 20*4($t9)
	lw	$s5, 21*4($t9)
	lw	$s6, 22*4($t9)
	lw	$s7, 23*4($t9)

	lw	$kt0,26*4($t9)
	lw	$kt1,27*4($t9)
	lw	$gp, 28*4($t9)
	lw	$fp, 30*4($t9)
	lw	$ra, 31*4($t9)
	.set	at

	// Here, all registers are recovered at at entry

	// Return form exception
	lui	$t8, %hi(SCINFO)
	lw	$t9, %lo(ISTKPOS)($t8)

	lw	$t9, 4*4($t9)		// PSR
	mtc0	$t9, $CP0_PSR		// Recover PSR: EXL = 1 Dis interrupt

	lw	$t9, %lo(ISTKPOS)($t8)
	lw	$t9, 3*4($t9)		// taskmode
	sw	$t9, %lo(TASKMODE)($t8)	// Recover taskmode

	lw	$kt1, %lo(ISTKPOS)($t8)	// kt1 = isp
	and	$kt0, $t9, TMF_CPL(3)
	beqz	$kt0, no_usp2

	lw	$sp, 5*4($kt1)		// Recover User Stack

  no_usp2:
	lw	$t9, 2*4($kt1)
	mtc0	$t9, $CP0_EPC		// Recover EPC
	lw	$t9, 1*4($kt1)		// Recover t9
	lw	$t8, 0*4($kt1)		// Recover t8

	addu	$kt1, $kt1, 6*4		// Update ISP
	lui	$kt0, %hi(ISTKPOS)
	sw	$kt1, %lo(ISTKPOS)($kt0)	// Save ISP
	eret

/*----------------------------------------------------------------------
	CP0 Access functions
----------------------------------------------------------------------*/
//
//	UW	readCP0cnt( void )
//	void	writeCP0cnt( UW cnt )
//
	.globl	Csym(readCP0cnt)
	.type	Csym(readCP0cnt), @function
	.globl	Csym(writeCP0cnt)
	.type	Csym(writeCP0cnt), @function
Csym(readCP0cnt):
	mfc0	$v0, $CP0_CNT
	jr	$ra
Csym(writeCP0cnt):
	mtc0	$v0, $CP0_CNT
	jr	$ra
//
//	UW	readCP0psr( void )
//	void	writeCP0psr( UW cnt )
//
	.globl	Csym(readCP0psr)
	.type	Csym(readCP0psr), @function
	.globl	Csym(writeCP0psr)
	.type	Csym(writeCP0psr), @function
Csym(readCP0psr):
	mfc0	$v0, $CP0_PSR
	jr	$ra
Csym(writeCP0psr):
	mtc0	$v0, $CP0_PSR
	jr	$ra
//
//	UW	readCP0cfg( void )
//	void	writeCP0cfg( UW cnt )
//
	.globl	Csym(readCP0cfg)
	.type	Csym(readCP0cfg), @function
	.globl	Csym(writeCP0cfg)
	.type	Csym(writeCP0cfg), @function
Csym(readCP0cfg):
	mfc0	$v0, $CP0_CFG
	jr	$ra
Csym(writeCP0cfg):
	mtc0	$v0, $CP0_CFG
	jr	$ra

//
//	void	setWatchPt( UW hi, UW lo )
//
	.globl	Csym(setWatchPt)
	.type	Csym(setWatchPt), @function
Csym(setWatchPt):
	mtc0	$a0, $CP0_WHI
	mtc0	$a1, $CP0_WLO
	jr	$ra

