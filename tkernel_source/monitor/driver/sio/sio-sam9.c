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


#define AT91C_BASE_DBGU		0xFFFFEE00 // (DBGU) Base Address
#define DBGU_CR          	0x00000000 // (DBGU_CR) Control Register
#define DBGU_MR          	0x00000004 // (DBGU_MR) Mode Register
#define DBGU_IER         	0x00000008 // (DBGU_IER) Interrupt Enable Register
#define DBGU_IDR         	0x0000000C // (DBGU_IDR) Interrupt Disable Register
#define DBGU_IMR         	0x00000010 // (DBGU_IMR) Interrupt Mask Register
#define DBGU_CSR         	0x00000014 // (DBGU_CSR) Channel Status Register
#define DBGU_RHR         	0x00000018 // (DBGU_RHR) Receiver Holding Register
#define DBGU_THR         	0x0000001C // (DBGU_THR) Transmitter Holding Register
#define DBGU_BRGR        	0x00000020 // (DBGU_BRGR) Baud Rate Generator Register
#define DBGU_CIDR        	0x00000040 // (DBGU_CIDR) Chip ID Register
#define DBGU_EXID        	0x00000044 // (DBGU_EXID) Chip ID Extension Register
#define DBGU_FNTR        	0x00000048 // (DBGU_FNTR) Force NTRST Register

#define DBGU_PTCR		0x00000120


#define AT91C_US_PAR          (0x7 <<  9) // (DBGU) Parity type
#define 	AT91C_US_PAR_EVEN                 (0x0 <<  9) // (DBGU) Even Parity
#define 	AT91C_US_PAR_ODD                  (0x1 <<  9) // (DBGU) Odd Parity
#define 	AT91C_US_PAR_SPACE                (0x2 <<  9) // (DBGU) Parity forced to 0 (Space)
#define 	AT91C_US_PAR_MARK                 (0x3 <<  9) // (DBGU) Parity forced to 1 (Mark)
#define 	AT91C_US_PAR_NONE                 (0x4 <<  9) // (DBGU) No Parity
#define 	AT91C_US_PAR_MULTI_DROP           (0x6 <<  9) // (DBGU) Multi-drop mode

// -------- DBGU_CR : (DBGU Offset: 0x0) Debug Unit Control Register -------- 
#define AT91C_US_RSTRX        (0x1 <<  2) // (DBGU) Reset Receiver
#define AT91C_US_RSTTX        (0x1 <<  3) // (DBGU) Reset Transmitter
#define AT91C_US_RXEN         (0x1 <<  4) // (DBGU) Receiver Enable
#define AT91C_US_RXDIS        (0x1 <<  5) // (DBGU) Receiver Disable
#define AT91C_US_TXEN         (0x1 <<  6) // (DBGU) Transmitter Enable
#define AT91C_US_TXDIS        (0x1 <<  7) // (DBGU) Transmitter Disable
#define AT91C_US_RSTSTA       (0x1 <<  8) // (DBGU) Reset Status Bits

// -------- PDC_PTCR : (PDC Offset: 0x20) PDC Transfer Control Register -------- 
#define AT91C_PDC_RXTEN       (0x1 <<  0) // (PDC) Receiver Transfer Enable
#define AT91C_PDC_RXTDIS      (0x1 <<  1) // (PDC) Receiver Transfer Disable
#define AT91C_PDC_TXTEN       (0x1 <<  8) // (PDC) Transmitter Transfer Enable
#define AT91C_PDC_TXTDIS      (0x1 <<  9) // (PDC) Transmitter Transfer Disable
// -------- PDC_PTSR : (PDC Offset: 0x24) PDC Transfer Status Register -------- 


/// Frequency of the board main oscillator.
#define BOARD_MAINOSC           12000000

/// Master clock frequency (when using board_lowlevel.c).
// ((12MHz / DIVA / PLLADIV2 / MDIV) * (MULA+1)
#define BOARD_MCK               ((unsigned long)((BOARD_MAINOSC / 3 / 2 / 3) * 200 )) // 133MHz
//#define BOARD_MCK               ((unsigned long)((BOARD_MAINOSC / 3 / 2 / 4) * 200 )) // 100MHz


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
void putSIO_sam9( SIOCB *scb, UB c )
{
#ifdef __GNUC__
	unsigned val;
wait:
	val = in_w(AT91C_BASE_DBGU+0x14);
	val &= (1<<9);
	if(val == 0) goto wait;
#else
	while (in_w(AT91C_BASE_DBGU+0x14) & (1<<9) == 0);
#endif
	out_b(AT91C_BASE_DBGU+0x1C, c);
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
	W	sts, c = 0;

	tmo *= 1000/20; 	/* convert tmo to 20 usec units */

	/* receive as much data as possible in the receive buffer */
	while (scb->iptr - scb->optr < SIO_RCVBUFSZ) {

		sts = in_w(AT91C_BASE_DBGU + 0x14);


		/* is there data in FIFO? */
		if ( sts & 1 == 0) {
			if (scb->iptr != scb->optr) break;  /* already received */
			if (tmo-- <= 0) break;		    /* timeout */
			waitUsec(20);
			continue;
		}

		/* receive data input */
		if (sts & 1) c = in_b(AT91C_BASE_DBGU + 0x18);


		/* set data to rcvbuf */
		scb->rcvbuf[scb->iptr++ & SIO_PTRMSK] = c;
	}

	/* return the data in rcvbuf */
	return (scb->iptr == scb->optr)?
			-1 : scb->rcvbuf[scb->optr++ & SIO_PTRMSK];
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
EXPORT ER initSIO_sam9(SIOCB *scb, const CFGSIO *csio, W baudrate)
{
	W mode = AT91C_US_PAR_NONE;
	W mck  = BOARD_MCK;

	if ( (UW)csio->info >= N_DEFSIO ) return E_PAR;

        /* select the target port */
	scb->info = DefSIO[csio->info].iob;

        /* initialize serial controller */
	// Reset & disable receiver and transmitter, disable interrupts
	out_w(AT91C_BASE_DBGU + DBGU_CR, AT91C_US_RSTRX | AT91C_US_RSTTX);
	out_w(AT91C_BASE_DBGU + DBGU_IDR, 0xFFFFFFFF);

	// Configure baud rate
	out_w(AT91C_BASE_DBGU + DBGU_BRGR,  mck / (baudrate * 16));

	// Configure mode register
	out_w(AT91C_BASE_DBGU + DBGU_MR,  mode);

	// Disable DMA channel
	out_w(AT91C_BASE_DBGU + DBGU_PTCR, AT91C_PDC_RXTDIS | AT91C_PDC_TXTDIS);

	// Enable receiver and transmitter
	out_w(AT91C_BASE_DBGU + DBGU_CR, AT91C_US_RXEN | AT91C_US_TXEN);


	/* I/O function default */
	scb->put = putSIO_sam9;
	scb->get = getSIO_sam9;

	return E_OK;
}
