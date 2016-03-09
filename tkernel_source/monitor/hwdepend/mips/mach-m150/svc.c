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
 *	svc.c	( T-Monitor for APP-M150 )
 *
 *	T-monitor service call
 */

#include <tmonitor.h>
#include <tm/tmonitor.h>

/*
 * T-Monitor Extended Service Call
 */
EXPORT	W	procExtSVC( W fno, W p1, W p2, W p3 )
{
	W	er = E_OK;

	switch ( fno ) {
	  case 0x00:	// Console Port Speed
		er = ConPortBps;
		break;

	  case 0x10:	// Read DIP-SW status
		er = dipSW();
		break;

	  case 0x11:	// Write LED
		cpuLED(p1);
		break;

	  default:
		er = E_PAR;
	}
	return er;
}

/*
 * T-Monitor Service Call
 */
EXPORT	W	procSVC( W fno, W p1, W p2, W p3, W p4 )
{
	W	er = E_OK;

	switch ( fno ) {
	  case TM_MONITOR:	/* void tm_monitor( void ) */
		procCommand(NULL);
		break;

	  case TM_GETCHAR:	/* INT	tm_getchar( INT wait ) */
		er = getChar(p1);
		break;

	  case TM_PUTCHAR:	/* INT	tm_putchar( INT c ) */
		er = putChar(p1);
		break;

	  case TM_GETLINE:	/* INT	tm_getline( UB *buff ) */
		er = getString((UB*)p1);
		break;

	  case TM_PUTSTRING:	/* INT	tm_putstring( const UB *buff ) */
		er = putString((UB*)p1);
		break;

	  case TM_COMMAND:	/* INT	tm_command( const UB *buff ) */
		er = E_NOSPT;
		break;

	  case TM_READDISK:
	  case TM_WRITEDISK:
	  case TM_INFODISK:
		/* INT tm_readdisk( const UB *dev, INT sec, INT nsec, void *addr )
		 * INT tm_writedisk( const UB *dev, INT sec, INT nsec, void *addr )
		 * INT tm_infodisk( const UB *dev, INT *blksz, INT *nblks )
		 */
		er = E_NOSPT;
		break;

	  case TM_EXIT:		/* void tm_exit( INT mode ) */
		sysExit(p1);		/* do not return */
		break;

	  case TM_EXTSVC:
		/* INT	tm_extsvc( INT fno, INT par1, INT par2, INT par3 ) */
		er = procExtSVC(p1, p2, p3, p4);
		break;

	  default:
		er = E_PAR;
	}

	return er;
}
