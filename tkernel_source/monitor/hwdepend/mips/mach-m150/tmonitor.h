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
 *	tmonitor.h	( T-Monitor for APP-M150 )
 *
 *	 T-Monitor internal common definitions
 */

#ifndef __MONITOR_TMONITOR_H__
#define	__MONITOR_TMONITOR_H__

/*
 * Memory Addresses
 */
#define	RAM_TOP		0x80008000
#define	RAM_END		0x88000000
#define	MON_STACK_TOP	0x80005000
#define	MON_STACK	0x80006000
#define	EIT_STACK	0x80007000

#define	KSEG1_BASE	0xA0000000

/* ======================================================================== */

#ifndef	_in_asm_source_

#include <basic.h>
#include <tk/errno.h>
#include <sys/sysinfo.h>
#include <sys/rominfo.h>
#include <tk/sysdef.h>
#include "device.h"

/*
 * T-Monitor Service Call function code
 */
#define	TM_MONITOR	0
#define	TM_GETCHAR	1
#define	TM_PUTCHAR	2
#define	TM_GETLINE	3
#define	TM_PUTSTRING	4
#define	TM_COMMAND	5
#define	TM_READDISK	6
#define	TM_WRITEDISK	7
#define	TM_INFODISK	8
#define	TM_EXIT		9

#define	TM_EXTSVC	255

IMPORT	W	procSVC( W fno, W p1, W p2, W p3, W p4 );

/* ======================================================================== */

/*
 * System funcitons
 */

/*
 * System termination
 *	 reset	  0 : power off
 *		 -1 : reboot
 *		 other: machine-dependent
 */
IMPORT	void	sysExit( W reset );

/*
 * Control LED
 *	bit 16: Green Mask (1: No Change)  bit 0: Green value (1:ON)
 *	bit 17: Yellow Mask (1: No Change) bit 1: Yellow Value (1:ON)
 */
EXPORT	void	cpuLED( W v );

/*
 * Get DIPSW status
 *	bit4: PSW2, bit3-0: DIPSW4-1
 */
EXPORT	W	dipSW( void );

/*
 * micro wait for a small amount of time
 *	 wait time is not that accurate.
 */
#define CP0CNT_CLK	792000000	/* CPU 792 MHz */
IMPORT	void	setupWaitUsec( void );

IMPORT	void	waitMsec( UW msec );	/* milliseconds */
IMPORT	void	waitUsec( UW usec );	/* microseconds */
IMPORT	void	waitNsec( UW nsec );	/* nanoseconds */

/*
 * Cache operation
 */
IMPORT	void	FlushCacheAll( void );

/*
 * Register access
 */
IMPORT	UW	getRegister( W regno );
IMPORT	W	setRegister( W regno, UW val );
IMPORT	UW	getCurPC( void );
IMPORT	UW	adjCurPC( W adj );
IMPORT	UW	getBadAddr( void );
IMPORT	UW	getCurPSR( void );
IMPORT	void	setBoot( UW pc );

/*
 * Entry of system-defined handler
 */
IMPORT	void	_intHdr( void );
IMPORT	void	_ip2Hdr( void );
IMPORT	void	_ip3Hdr( void );
IMPORT	void	_ip4Hdr( void );
IMPORT	void	_ip5Hdr( void );
IMPORT	void	_ip6Hdr( void );
IMPORT	void	_svcHdr( void );
IMPORT	void	_defaultHdr( void );
IMPORT	void	_sysReset( void );

/*
 * Command processing
 */
IMPORT	void	procCommand( FP *entp );

/* ======================================================================== */

/*
 * Console I/O funcitons
 */

#define	L_LINE		256

/*
 * Console Output
 *	 XON/XOFF flow control
 *	 check for CTRL-C input
 *	 return value	    0 : normal
 *			   -1 : CTRL-C input exists
 */
IMPORT	W	putChar( W c );
IMPORT	W	putString( const UB *str );

/*
 * Console Input (one character)
 *	 if wait = TRUE, wait for input if FALSE, do not wait.
 *	 return value	    >= 0 : character
 *			      -1 : no input
 */
IMPORT	W	getChar( BOOL wait );

/*
 * Console Input (character string)
 *	 line input with editing
 *	 return value	   >= 0 : number of input characters
 *			     -1 : CTRL-C was detected
 */
IMPORT	W	getString( UB *str );


/* ======================================================================== */

/*
 * I/O port access functions
 */
Inline	void	out_w( INT port, UW data )
{
	*(_UW*)port = data;
}
Inline	void	out_h( INT port, UH data )
{
	*(_UH*)port = data;
}
Inline	void	out_b( INT port, UB data )
{
	*(_UB*)port = data;
}

Inline	UW	in_w( INT port )
{
	return *(_UW*)port;
}
Inline	UH	in_h( INT port )
{
	return *(_UH*)port;
}
Inline	UB	in_b( INT port )
{
	return *(_UB*)port;
}

/* ======================================================================== */

/*
 * Standard string / memory operations used for t-monitor
 */

IMPORT	void*	memset( void *s, int c, size_t n );
IMPORT	int	memcmp( const void *s1, const void *s2, size_t n );
IMPORT	void*	memcpy( void *dst, const void *src, size_t n );
IMPORT	void*	memmove( void *dst, const void *src, size_t n );
IMPORT	size_t	strlen( const char *s );
IMPORT	int	strcmp( const char *s1, const char *s2 );
IMPORT	int	strncmp( const char *s1, const char *s2, size_t n );
IMPORT	char*	strcpy( char *dst, const char *src );
IMPORT	char*	strncpy( char *dst, const char *src, size_t n );
IMPORT	unsigned long strtoul( const char *nptr, char **endptr, int base );

/*
 * Standard printf operations used for t-monitor
 */

IMPORT	int	printf(const char *format, ...);
IMPORT	int	sprintf(char *str, const char *format, ...);

#define	DSP(exp)	printf exp

/* ======================================================================== */
#endif	/* _in_asm_source_ */

#endif /* __MONITOR_TMONITOR_H__ */
