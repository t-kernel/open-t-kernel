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
 */

/*
 *	base on monitor/driver/sio/src/ns16550.c
 *	monitor/driver/sio/sio-mx28.c
 *	i.MX280 debug uart driver for T-Monitor
 *	Copyright (C) 2014, 2015, 2016 Du Huanpeng<u74147@gmail.com>
 */

#include <tmonitor.h>
#include <mach/em1d512.h>


#define HW_UARTDBG	0x80074000

#define HW_UARTDBG_DR	(HW_UARTDBG + 0x000)
#define HW_UARTDBG_FR	(HW_UARTDBG + 0X018)
#define TXFF		(1<<5)
#define RXFE		(1<<4)

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
#define	N_DEFSIO	( sizeof(DefSIO) / sizeof(DEFSIO) )

/*
 * serial port I/O
 */
void putSIO_mx28( SIOCB *scb, UB c )
{

	unsigned val;

	do {
		val = in_w(HW_UARTDBG_FR);
		val &= TXFF;
	} while(val);

	out_b(HW_UARTDBG_DR, c);

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
LOCAL W getSIO_mx28(SIOCB *scb, W tmo )
{

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
EXPORT ER initSIO_mx28(SIOCB *scb, const CFGSIO *csio, W baudrate)
{

	if ( (UW)csio->info >= N_DEFSIO ) return E_PAR;

        /* select the target port */
	scb->info = DefSIO[csio->info].iob;
	strncpy(scb->name, "mx28-sio", sizeof(scb->name));

	/* I/O function default */
	scb->put = putSIO_mx28;
	scb->get = getSIO_mx28;


	return E_OK;
}
