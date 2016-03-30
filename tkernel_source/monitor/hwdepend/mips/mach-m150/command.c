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
 *	command.c	( T-Monitor for APP-M150 )
 *
 *	command processing
 */

#include <tmonitor.h>

/*
 *	Dump memory
 */
LOCAL	void	dump_mem( UW *adr, INT len )
{
	INT	i;

	for ( i = 0; i < len; ) {
		if ( i % 16 == 0 ) DSP(("%08x:", (UW)adr));
		DSP((" %08x", *adr));
		adr += 1;
		if ( (i += 4) % 16 == 0 ) DSP(("\n"));
	}
	if ( i % 16 != 0 ) DSP(("\n"));
}

/*
 *	Process command
 */
EXPORT	void	procCommand( FP *entp )
{
	B	buf[128], c1, c2;
	char	*cp;
	UW	p1, p2, p3;
	INT	i;
static	UW	brk_ad = 0, brk_dt = 0;

#define	BRK_CMD	(0x0000000C | (42 << 6))	// instruction "SYSCALL 42"

	for (;;) {
		DSP(("TM> "));
		getString((UB*)(cp = (char*)buf));

		c1 = *cp++;
		c2 = *cp;
		while ( *cp > ' ' ) cp++;
		while ( *cp <= ' ' && *cp != '\0' ) cp++;

		p1 = strtoul(cp, &cp, 16);
		p2 = strtoul(cp, &cp, 16);
		p3 = strtoul(cp, &cp, 16);

		switch( c1 ) {
		case 'd':
			p1 &= ~3;
			if ( p2 <= 0 ) p2 = 4;
			dump_mem((UW*)p1, p2);
			break;

		case 'm':
			if ( c2 == 'w' ) {
				*((UW*)p1) = p2;
			} else {
				*((UB*)p1) = p2;
			}
			break;

		case 'f':
			memset((void*)p1, p2, p3);
			break;

		case 'g':
			if ( p1 != 0 ) {
				if ( entp != NULL ) *entp = (FP)p1;
				setBoot(p1);
				DSP(("go %08x\n", p1));
			}
			FlushCacheAll();
			goto cmd_exit;
			break;

		case 'b':
			if ( c2 != 'c' && p1 == 0 ) {
				// Show break point
				if ( brk_ad != 0 ) {
					DSP(("BP: %08x\n", brk_ad));
				}
				break;
			}
			if ( brk_ad != 0 ) {
				// Clear break point
				if ( *((UW*)brk_ad) == BRK_CMD ) {;
					*((UW*)brk_ad) = brk_dt;
				}
				brk_ad = 0;
			}
			if ( c2 != 'c' && p1 != 0 ) {
				// Set break point
				brk_ad = p1;
				brk_dt = *((UW*)p1);
				*((UW*)p1) = BRK_CMD;
			}
			break;

		case 'r':
			for ( i = 0; i < 32; ) {
				if ( (i % 4) == 0 ) DSP(("R%02d:", i));
				DSP((" %08x", getRegister(i)));
				if ( (++i % 4) == 0 ) DSP(("\n"));
			}
			DSP(("PC: %08x PSR: %08x\n", getCurPC(), getCurPSR()));
			break;

		case 'h':
		case '?':
			DSP(("d addr len      dump memory (word)\n"));
			DSP(("m addr data     modify memory (byte)\n"));
			DSP(("mw addr data    modify memory (word)\n"));
			DSP(("f addr len data fill memory (byte)\n"));
			DSP(("g [addr]        goto program addr\n"));
			DSP(("b               show break point\n"));
			DSP(("b addr          set break point\n"));
			DSP(("bc              clear break point\n"));
			DSP(("r               show registers\n"));
			break;
		}
	}
cmd_exit:	;
}

