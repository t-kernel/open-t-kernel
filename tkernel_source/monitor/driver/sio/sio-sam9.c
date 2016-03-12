/*
 *----------------------------------------------------------------------
 *    T-Kernel 2.0 Software Package
 *
 *    Copyright 2011 by Ken Sakamura.
 *    This software is distributed under the latest version of T-License 2.x.
 *----------------------------------------------------------------------
 *
 *    Released by T-Engine Forum(http://www.t-engine.org/) at 2011/05/17.
 *    Modified by T-Engine Forum at 2013/02/28.
 *    Modified by TRON Forum(http://www.tron.org/) at 2015/06/01.
 *
 *----------------------------------------------------------------------
 *	Copyright (C) 2014, 2015, 2016 Du Huanpeng<u74147@gmail.com>
 */

/*
 *	base on monitor/driver/sio/src/ns16550.c
 *	sio-sam9.c
 *
 *       serial port I/O
 */

#include <tmonitor.h>
#include <mach/em1d512.h>

/*
 * serial port hardware configuration definition
 */
typedef struct {
	UW	iob;		/* I/O base address */
} DEFSIO;

LOCAL const DEFSIO	DefSIO[] = {
	{ 0 },
};

/* ------------------------------------------------------------------------ */

/*
 * serial port I/O
 */
LOCAL void putSIO_sam9( SIOCB *scb, UB c )
{
	return;
}

/*
 * serial port input
 *       tmo     timeout (milliseconds)
 *              You can not wait forever.
 *       return value       >= 0 : character code
 *                 -1 : timeout
 *       input data using buffer.
 *       receive error is ignored.
 */
LOCAL W getSIO_sam9(SIOCB *scb, W tmo )
{
	if(tmo) return -1;
	else return 'S';
}

/* ------------------------------------------------------------------------ */

/*
 * initialize serial port
 *       serial port that is supported by the initialization of CFGSIO
 *       speed   communication speed (bps)
 *       initialize the serial port according to the specified parameters and set SIOCB
 *       SIOCB is given in 0-cleared state initially.
 *       Subsequent I/O operations uses the SIOCB.
 *
 *       Only for PC/AT version
 *      if speed = 0, we use the value in biosp->siomode.
 *       But we use only the transmission speed and other settings are ignored.
 *       Efforts were made to be compatible B-right/V, but because of the ignorance of no-speed settings such as data length and stop bit length,
 *       we have reduced functionality.
 */
EXPORT ER initSIO_sam9(SIOCB *scb, const CFGSIO *csio, W speed)
{

	if ( csio->info>1 ) return E_PAR;

        /* select the target port */
	scb->info = DefSIO[csio->info].iob;


        /* I/O function default */
	scb->put = putSIO_sam9;
	scb->get = getSIO_sam9;

	return E_OK;
}
