#! /usr/bin/perl
#
# ----------------------------------------------------------------------
#     T-Kernel 2.0 Software Package
#
#     Copyright 2011 by Ken Sakamura.
#     This software is distributed under the latest version of T-License 2.x.
# ----------------------------------------------------------------------
#
#     Released by T-Engine Forum(http://www.t-engine.org/) at 2011/05/17.
#     Modified by T-Engine Forum at 2014/07/14.
#     Modified by TRON Forum(http://www.tron.org/) at 2015/06/01.
#
# ----------------------------------------------------------------------
#

#
#	makeifex.pl
#
#	generate extended SVC interface library for EM1-D512
#

sub makelibex
{
	print LIB <<EndOfExtIfLibBody;
#include <machine.h>
#include <tk/sysdef.h>
#include <sys/svc/$fn_h>

#if (defined __GNUC__) && !(defined __SES_ARM) && !(defined __CROSSWORKS_ARM)
	.text
	.balign	4
	.globl	Csym(${func})
	.type	Csym(${func}), %function
Csym(${func}):
	stmfd	sp!, {r0-r3}
	mov	r0, sp
	stmfd	sp!, {lr}
	ldr	ip, =${prefix}_${Func}_FN
	swi	SWI_SVC
	ldmfd	sp!, {lr}
	add	sp, sp, #4*4
	bx	lr
	.end
#endif

#ifdef __CC_ARM

; generated by Component: ARM Compiler 5.06 update 1 (build 61) Tool: armcc [4d35ad]
; commandline armcc [--arm -S svc.c]
;
; DO NOT MODIFY.
;
; This file was generated by Kbuild
;

;----------------------------------------------------------------------
;    Open T-Kernel Project
;    Copyright 2017 Du Huanpeng <u74147@gmail.com>
;----------------------------------------------------------------------

        ARM
        REQUIRE8
        PRESERVE8

        AREA ||.text||, CODE, READONLY, ALIGN=2

${func} PROC
        STMFD    sp!, {r0-r3}
        MOV      r0, sp
        STMFD    sp!, {lr}
        LDR      ip, =${prefix}_${Func}_FN
        SWI      SWI_SVC
        LDMFD    sp!, {lr}
        ADD      sp, sp, #4*4
        BX       lr
        ENDP


        EXPORT ${func} [CODE]



        END

#endif

EndOfExtIfLibBody
}

1;
