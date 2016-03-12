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
 *	sio.c
 *
 *       serial port I/O
 */

#include "hwdepend.h"

EXPORT	W	ConPort;	/* console port number */
EXPORT	UW	ConPortBps;	/* console port commnication speed (bps) */

LOCAL	SIOCB	SIO;		/* serial port control block */

/*
 * initialize serial port
 *       port    console port number (0 - )
 *              when it is -1, it means there is no console.
 *       speed   communication speed (bps)
 */
EXPORT ER initSIO( W port, W speed )
{
	const CFGSIO	*cp;
	ER	err;
serial_putchar('I');
	if ( port >= N_ConfigSIO ) port = 0; /* invalid value is turned into a default value. */

	memset(&SIO, 0, sizeof(SIO));
	ConPort    = port;
	ConPortBps = speed;
	serial_putchar('n');

	if ( port < 0 ) return E_OK; /* no console */

        /* initialize hardware */
	cp = &ConfigSIO[port];
	err = (*cp->initsio)(&SIO, cp, speed);
	serial_putchar('i');
	if ( err < E_OK ) goto err_ret;
	serial_putchar('t');

	return E_OK;
	serial_putchar('S');

err_ret:
        /* if there was an error, treat it as no console */
	serial_putchar('I');
	memset(&SIO, 0, sizeof(SIO));
	ConPort = -1;
	return err;
}

/*
 * serial port I/O
 */
EXPORT void putSIO( UB c )
{
	if ( SIO.put ) SIO.put(&SIO, c);
}

/*
 * serial port input (with buffering)
 *       tmo     timeout (milliseconds)
 *              You can not wait forever.
 *       return value       >= 0 : character code
 *                 -1 : timeout
 *       receive error is ignored
 */
EXPORT W getSIO( W tmo )
{
	if (SIO.get) return SIO.get (&SIO, tmo);
	else return -1;
}
