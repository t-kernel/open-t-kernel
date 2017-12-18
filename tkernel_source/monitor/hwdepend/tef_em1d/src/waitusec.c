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
 *	waitusec.c
 *
 *       EM1-D512: micro wait
 */

#include "sysdepend.h"
#include <arm/em1d512.h>

LOCAL	UW	delay64us;		 // wait for 64 microsec

/*
 * wait for nanoseconds
 */
EXPORT	void	waitNsec(_UW nsec)
{


	return;
}

/*
 * wait for microseconds
 */
EXPORT	void	waitUsec(_UW usec)
{
	for (usec = usec * delay64us / 64; usec > 0; usec--);

	return;
}

/*
 * wait for milliseconds
 */
EXPORT	void	waitMsec(UW msec)
{
	while (msec-- > 0) waitUsec(1000);

	return;
}

/* ------------------------------------------------------------------------ */

/*
 * setting up the initial count for micro-wait()
 */
EXPORT	void	setupWaitUsec(void)
{
	delay64us = 740;

	return;
}

