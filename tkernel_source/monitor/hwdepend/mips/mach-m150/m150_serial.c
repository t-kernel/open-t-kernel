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
 *	m150_serial.c	( T-Monitor for APP-M150 )
 *
 *	 serial port I/O
 */

#include <tmonitor.h>

#define	DBG_PORT	2		/* UART port# for Debug	*/

#define CLOCK		24000000	/* EXTAL freq: 48 MHz	*/

#define INB(x)		in_b(x)
#define OUTB(x, y)	out_b((x), (y))

/*
 * m150 UART registres - Byte access.
 */
#define	UART_BASE(n)	( 0xB0030000 + (n) * 0x1000 )

#define	UART_REG(ofs)	( UART_BASE(DBG_PORT) + (ofs) * 4 )
#define	UART_DR		UART_REG(0)	/* Data			(RW)	*/
#define	UART_DLL	UART_REG(0)	/* Divisor Latch Low	(RW)	*/
#define	UART_IER	UART_REG(1)	/* Interrupt Enable	(RW)	*/
#define	UART_DLH	UART_REG(1)	/* Divisor Latch High	(RW)	*/
#define	UART_IIR	UART_REG(2)	/* Interrupt Ident	(R )	*/
#define UART_FCR	UART_REG(2)	/* FIFO Control		( W)	*/
#define	UART_LCR	UART_REG(3)	/* Line Control		(RW)	*/
#define	UART_MCR	UART_REG(4)	/* Modem Control	(RW)	*/
#define	UART_LSR	UART_REG(5)	/* Line Status		(R )	*/
#define	UART_MSR	UART_REG(6)	/* Modem Status		(R )	*/
#define	UART_SCR	UART_REG(7)	/* Scratch Data		(RW)	*/
#define	UART_ISR	UART_REG(8)	/* Infrared Select	( W)	*/
#define	UART_UMR	UART_REG(9)	/* UART M		(RW)	*/
#define	UART_ACR	UART_REG(10)	/* Add Cycle (16bits)	(RW)	*/
#define	UART_RCR	UART_REG(16)	/* RXFIFO Counter	(R )	*/
#define	UART_TCR	UART_REG(17)	/* TXFIFO Counter	(R )	*/

/* IER */
#define IE_RIE		0x01		/* Receive Ready Int.		*/
#define IE_TIE		0x02		/* Transmit Ready Int.		*/
#define IE_RLIE		0x04		/* Receive Line Status Int.	*/
#define IE_MIE		0x08		/* Modem Status Int.		*/
#define IE_RTIE		0x10		/* Receive Timeout Int.		*/

#define	dtIM		( 0x00 )

/* IIR	*/
#define II_PEND 	0x01		/* Interrupt Pending		*/
#define II_ID		0x0e		/* Interrupt ID			*/
#define II_RTMO 	0x0c		/* ID=6 Receive Timeout		*/
#define II_LSTS 	0x06		/* ID=3 Receive Line Status	*/
#define II_RDR		0x04		/* ID=2 Receive Data Ready	*/
#define II_TDR		0x02		/* ID=1 Transmit Data Ready	*/
#define II_MSTS 	0x00		/* ID=0 Modem Satus		*/
#define II_FIFO 	0xC0		/* FIFO mode			*/

/* FCR */
#define FC_TL01 	0x00		/* Receive Int Threshold 1 byte	*/
#define FC_TL08 	0x40		/*			8 byte	*/
#define FC_TL16 	0x80		/*			16 byte	*/
#define FC_TL32 	0xc0		/*			32 byte	*/
#define	FC_UME		0x10		/* Enable UART			*/
#define	FC_DME		0x08		/* Enable DMA Mode		*/
#define FC_TXCLR	0x04		/* Clear Trasnmit FIFO		*/
#define FC_RXCLR	0x02		/* Clear Receive FIFO		*/
#define FC_FIFO 	0x01		/* Enable FIFO Mode		*/

#define	FIFO_SIZE	32		/* FIFO Size			*/

#define	dtFC		( FC_FIFO | FC_UME | FC_TL16 )
#define	dtFC_CLR	( FC_FIFO | FC_UME | FC_TXCLR | FC_RXCLR )

/* LCR */
#define	LC_DLAB		0x80		/* Divisor (DLL/DLH) Access	*/
#define	LC_SBRK		0x40		/* Send BREAK			*/
#define	LC_SNDP		0x20		/* Sticky Parity		*/
#define	LC_EVNP		0x10		/* Even Parity			*/
#define	LC_ENAP		0x08		/* Enable Parity		*/
#define	LC_STP1		0x00		/* Stop 1 bit			*/
#define	LC_STP2		0x04		/* Stop 2 bits			*/
#define	LC_LEN5		0x00		/* Data Length 5 bits		*/
#define	LC_LEN6		0x01		/* Data Length 6 bits		*/
#define	LC_LEN7		0x02		/* Data Length 7 bits		*/
#define	LC_LEN8		0x03		/* Data Length 8 bits		*/

#define	dtLC		( LC_LEN8 | LC_STP1 )

/* LSR */
#define	LS_RERR		0x80		/* Receive Error in FIFO	*/
#define	LS_TEMP		0x40		/* Transmit Holding Reg. Empty	*/
#define	LS_TDRQ		0x20		/* Transmit Data Request	*/
#define	LS_BRK		0x10		/* BREAK Received		*/
#define	LS_FERR		0x08		/* Framing Error		*/
#define	LS_PERR		0x04		/* Parity Error			*/
#define	LS_OERR		0x02		/* Overrun Error		*/
#define	LS_DRDY		0x01		/* Receive Data Ready		*/

#define	LS_RxERR	( LS_BRK | LS_FERR | LS_PERR | LS_OERR )

/* MCR */
#define MC_MCE		0x80		/* Modem Control Enable		*/
#define MC_HFC		0x40		/* Hardware Flow Control	*/
#define	MC_LOOP		0x10		/* Loop Back			*/
#define	MC_RTS		0x02		/* Request To Send		*/

#define	dtMC		( MC_RTS | MC_MCE )

/* MSR */
#define	MS_CS		0x10		/* Clear To Send		*/
#define	MS_CCS		0x01		/* Change Status of CS		*/

/* ISR */
#define IS_XMTIR	0x01		/* Transmitter SIR Enable	*/
#define IS_RCVIR	0x02		/* Receiver SIR Enable		*/
#define IS_TPWS		0x04		/* Transmit Pulse Width		*/
#define IS_TXPL		0x08		/* Transmit Data Polarity	*/
#define IS_RXPL		0x10		/* Receive Data Polarity	*/

#define	dtISR		( 0x00 )	/* Not SIR			*/

/* Transmission speed -> Divided counter value. */
#define	LC_LINE_SPEED(bps)	( CLOCK / 16 / (bps) )

/* ------------------------------------------------------------------------ */

/*
 * serial port I/O
 */
LOCAL	void	putSIO_m150( SIOCB *scb, UB c )
{
	/* Wait until transmission is ready. */
	while ( (INB(UART_LSR) & LS_TEMP) == 0 );

	/* Write transmission data */
	OUTB(UART_DR, c);

	/* Wait until the completion of transmission */
	while ( (INB(UART_LSR) & LS_TEMP) == 0 );
}

/*
 * serial port input
 *	 tmo	 timeout (milliseconds)
 *		 You can not wait forever.
 *	 return value	>= 0 : character code
 *			  -1 : timeout
 *	 input data using buffer.
 *	 receive error is ignored.
 */
LOCAL	W	getSIO_m150( SIOCB *scb, W tmo )
{
	W	sts, c = 0;

	tmo *= 1000 / 20;		/* Convert tmo to 20 usec units */

	/* Receive as much data as possible in the receive buffer */
	while ( scb->iptr - scb->optr < SIO_RCVBUFSZ ) {

		/* Is there data in FIFO? */
		if ( ((sts = INB(UART_LSR)) & (LS_DRDY | LS_RxERR)) == 0 ) {
			if ( scb->iptr != scb->optr ) break;
							/* Already Received */
			if ( tmo-- <= 0 ) break;	/* Timeout */
			waitUsec(20);
			continue;
		}

		/* Receive data input */
		if ( sts & LS_DRDY ) c = INB(UART_DR);

		/* Error check */
		if ( sts & LS_RxERR ) continue;

		/* Set data to rcvbuf */
		scb->rcvbuf[scb->iptr++ & SIO_PTRMSK] = c;
	}

	/* Return the data in rcvbuf */
	return ( scb->iptr == scb->optr ) ?
			-1 : scb->rcvbuf[scb->optr++ & SIO_PTRMSK];
}

/* ------------------------------------------------------------------------ */

/*
 * initialize serial port
 *	 speed	 communication speed (bps)
 *	 initialize the serial port according to the specified parameters
 *	 and set SIOCB.
 *	 SIOCB is given in 0-cleared state initially.
 *	 Subsequent I/O operations uses the SIOCB.
 */
EXPORT	ER	initSIO_m150( SIOCB *scb, W speed )
{
	UH	div;

	/* Initialize serial controller */
	OUTB(UART_IER, 0);		/* disable interrupt */
	OUTB(UART_FCR, 0);		/* disable UART */
	OUTB(UART_ISR, dtISR);		/* set UART mode (not SIR) */

	INB(UART_LSR);			/* clear IS_LSTS */
	INB(UART_IIR);			/* clear IS_SND  */
	INB(UART_MSR);			/* clear IS_MSTS */

	/* Communicatin speed divisor value */
	div = LC_LINE_SPEED(speed);

	OUTB(UART_LCR, LC_DLAB);	/* set LC_DLAB */
	OUTB(UART_DLH, div >> 8);	/* communication speed */
	OUTB(UART_DLL, div & 0xff);

	OUTB(UART_LCR, dtLC);		/* line mode */
	OUTB(UART_FCR, dtFC_CLR);	/* clear FIFO */
	OUTB(UART_FCR, dtFC);		/* FIFO mode */
	OUTB(UART_MCR, dtMC);		/* modem mode */
	OUTB(UART_IER, dtIM);		/* interrupt mask */

	/* I/O function default */
	scb->put = putSIO_m150;
	scb->get = getSIO_m150;

	return E_OK;
}

