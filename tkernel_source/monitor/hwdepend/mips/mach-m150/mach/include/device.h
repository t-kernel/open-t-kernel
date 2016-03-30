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
 *	device.h	( T-Monitor for APP-M150 )
 *
 *	 T-Monitor device-related definitions
 *
 *	 since machines support different devices, functions defined here
 *	 may not be usable all the time.
 *	 Available functions differ from one system to the other.
 */

#ifndef __MONITOR_DEVICE_H__
#define __MONITOR_DEVICE_H__

/* ------------------------------------------------------------------------ */
/*
 *	 serial port
 */

/*
 * initialize serial port
 *	 port	 console port number (0 - )
 *		when it is -1, it means there is no console.
 *	 speed	 communication speed (bps)
 */
IMPORT ER initSIO( W port, W speed );

/*
 * serial port output (one character transmission)
 */
IMPORT void putSIO( UB c );

/*
 * serial port input (one character reception)
 *	 tmo	 timeout (milliseconds)
 *		You can not wait forever.
 *	 return value	    >= 0 : character code
 *		   -1 : timeout
 *	 input data using buffer.
 *	 receive error is ignored.
 */
IMPORT W getSIO( W tmo );

#define	SIO_RCVBUFSZ	64		/* receive buffer size */
#define	SIO_PTRMSK	(SIO_RCVBUFSZ - 1)

/*
 * control block for a serial port
 */
typedef struct siocb	SIOCB;
struct siocb {
	UW	info;			/* misc informaion */
	UB	rcvbuf[SIO_RCVBUFSZ];	/* receive buffer */
	UW	iptr;			/* input pointer */
	UW	optr;			/* output pointer */

	/*
	 * I/O functions
	 *	 same specification as putSIO(), and getSIO()
	 */
	void (*put)( SIOCB*, UB c );	/* send a character */
	W    (*get)( SIOCB*, W tmo );	/* receive a character */
};

IMPORT W	ConPort;	/* console port number */
IMPORT UW	ConPortBps;	/* console port communication speed (bps) */

#endif /* __MONITOR_DEVICE_H__ */
