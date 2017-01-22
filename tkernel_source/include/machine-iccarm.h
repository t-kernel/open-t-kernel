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
 *    Open T-Kernel Project
 *    Copyright 2017 Du Huanpeng <u74147@gmail.com>
 *----------------------------------------------------------------------
 */

/*
 *	@(#)machine.h
 *
 *	Machine type definition
 *
 *	Describes differences between platforms, such as hardware
 *	and OS. Where the source code must be differentiated
 *	according to platform, macros and other definitions given
 *	here should be used.
 *
 *	Where possible, classifications should be based on general
 *	attributes rather than the machine type. Thus, the endian,
 *	for instance, should be described as BIGENDIAN rather than
 *	using a classification based on the machine type.
 *
 *	* Machine type definition is not used solely by the machine
 *	C language source file, so non-macro definitions are not
 *	permitted.
 */

#ifndef __MACHINE_H__
#error "Please don't include <machine-iccarm.h> directly, include <machine.h> instead."
#endif


/* ===== System dependencies definitions ================================ */


/* ===== Common definitions ============================================= */

#ifdef __ICCARM__

#ifndef Inline
#ifdef __cplusplus
#define Inline      inline
#else
#define Inline
/*
 * #pragma inline[=forced|=never]
 */
#endif
#endif


#ifndef Asm
#ifdef __ICCARM__
#define Asm(...)		do { } while(0)
#else
#define Asm			asm
#endif
#endif

/*
 * C symbol format
 *	_Csym = 0	do not append _
 *	_Csym = 1	append _
 *
 *	* In the UNIX System V Release 4 C compiler,
 *	   _ is not appended to symbols.
 */
#if _Csym == 0
#define Csym(sym)	sym
#else
#define Csym(sym)	_##sym
#endif

#endif /* __ICCARM__ */
