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
#include <mach/em1d512.h>

LOCAL	UW	delay64us;		 /* wait for 64 microsec */

/*
 * wait for nanoseconds
 */
EXPORT	void	waitNsec(_UW nsec)
{
	for (nsec = nsec * delay64us / 64000; nsec > 0; nsec--);

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
	UW	t0, t1, t2;

#define	MAX_CNT		(ACPU_CLK * 64 / 10)	/* 1 Clock */
#define	MIN_CNT		(ACPU_CLK * 64 / 1280)	/* 128 Clock */

        /* use TI0 timer, and assume clock is PLL3 / 8 */
			/* Timer stop, count clear */
	

	/* maximum count */
			/* Timer start */

	delay64us = 64;
	/* wait for a while until things settle down */


				/* Timer stop, count clear */
	
	
		/* count for 3000 times */
		/* count for 1000 times */
		/* count for 2000 times */

	/*
         * calculate the count for 64 microsec
	 *
         *                    2000 loops x timer clock [MHz] x 64 [microsec]
	 *	delay64us = ------------------------------------------------
	 *	                                 t2
	 *
         * * considering the representation of PLL3_CLK (1/1000MHz unit), and setting of pre scaler,
         * it can be written down as follows.
	 *
         *                    2 loops x PLL3_CLK [1/1000MHz] x 8 [microsec]
	 *	delay64us = -------------------------------------------
	 *	                                 t2
	 *
	 */
	 

	return;
}

