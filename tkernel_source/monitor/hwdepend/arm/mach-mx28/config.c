/*
 *----------------------------------------------------------------------
 *    T-Kernel 2.0 Software Package
 *
 *    Copyright 2011 by Ken Sakamura.
 *    This software is distributed under the latest version of T-License 2.x.
 *----------------------------------------------------------------------
 *
 *    Released by T-Engine Forum(http://www.t-engine.org/) at 2011/05/17.
 *    Modified by T-Engine Forum at 2011/09/08.
 *    Modified by TRON Forum(http://www.tron.org/) at 2015/06/01.
 *
 *----------------------------------------------------------------------
 */

/*
 *	config.c
 *
 *       system-related processing / system configuration information
 *
 *	based on target: T-Engine/EM1D-512
 *	i.MX280 board setup
 *	monitor/hwdepend/arm/mach-mx28/config.c
 *	Copyright 2015, 2016 Du Huanepng<u74147@gmail.com>
 *
 */

#include "sysdepend.h"
#include <mach/em1d512.h>

/* used device driver */
IMPORT	ER	initSIO_mx28(SIOCB *, const CFGSIO *, W speed);
IMPORT	ER	initMemDisk(DISKCB *, const CFGDISK *);

/* memory region definition */
EXPORT	MEMSEG	MemSeg[] = {
	/* internal SRAM 128KiB */
	{0x00000000, 0x00020000, MSA_SRAM,	PGA_RW|PGA_NC},
	/* DDR2 SDRAM, 64MiB */
	{0x40000000, 0x44000000, MSA_RAM,	PGA_RW|PGA_C},
        /* EM1 internal device (1) */
	{0x40000000, 0x70000000, MSA_IO,	PGA_RW|PGA_D |PGA_S|PGA_XN},
	/* Bank0 */
	{0x70000000, 0x72000000, MSA_FROM,	PGA_RO|PGA_C |0x90000000},
        /* EM1 internal SRAM */
	{0xa0000000, 0xb0000000, MSA_SRAM,	PGA_RW|PGA_NC},
        /* EM1 internal device (2) */
	{0xb0000000, 0xd0000000, MSA_IO,	PGA_RW|PGA_D |PGA_S|PGA_XN},
        /* EM1 internal Boot ROM */
	{0xf0000000, 0xffffffff, MSA_ROM,	PGA_RO|PGA_NC},

	{0x70000000, 0x70020000, MSA_MON,	0},
	{0x70030000, 0x72000000, MSA_RDA,	0},
	{0x30006000, 0x34000000, MSA_OS,	0},
};

EXPORT	W	N_MemSeg = sizeof(MemSeg) / sizeof(MEMSEG);

/* unused memory region definition */
EXPORT	MEMSEG	NoMemSeg[] = {
	{0x00000000, 0x10000000, 0,		0},
	{0x72000000, 0xa0000000, 0,		0},
	{0xd0000000, 0xf0000000, 0,		0},
};

EXPORT	W	N_NoMemSeg = sizeof(NoMemSeg) / sizeof(MEMSEG);

/*
 * serial port configuration definition
 *       list in the order of port number
 */
EXPORT	const	CFGSIO	ConfigSIO[] = {
	{initSIO_mx28, 0},
};

EXPORT	const W	N_ConfigSIO = sizeof(ConfigSIO) / sizeof(CFGSIO);


/*
 * disk drive configuration definition
 *	list in the order of port number
 */
EXPORT	const CFGDISK	ConfigDisk[] = {
	{"rda",	DA_RONLY,	initMemDisk,	0},	/* FlashROM */
};

EXPORT	const W	N_ConfigDisk = sizeof(ConfigDisk) / sizeof(CFGDISK);

/* boot information */
EXPORT	const UH	BootSignature = 0xe382;		/* signature */
EXPORT	UB *	const PBootAddr = (UB *)0x30200000;	/* primary boot loader address */
 
/* ------------------------------------------------------------------------ */

#define	IICC_IICE	(1 << 7)
#define	IICC_WREL	(1 << 5)
#define	IICC_WTIM	(1 << 3)
#define	IICC_ACKE	(1 << 2)
#define	IICC_STT	(1 << 1)
#define	IICC_SPT	(1 << 0)

#define	IICCL_SMC	(1 << 3)
#define	IICCL_DFC	(1 << 2)

#define	IICSE_MSTS	(1 << 15)
#define	IICSE_ALD	(1 << 14)
#define	IICSE_ACKD	(1 << 10)
#define	IICSE_SPD	(1 << 8)

#define	IICF_IICBSY	(1 << 6)
#define	IICF_STCEN	(1 << 1)
#define	IICF_IICRSV	(1 << 0)

#define	IIC_TOPDATA	(1 << 11)
#define	IIC_LASTDATA	(1 << 10)

#define	TIMEOUT		1000000	/* microsec */

#define	IIC2_IRQ	39
#define	IRQbit(x)	(1 << ((x) % 32))

/* wait for register state information */
LOCAL	ER	wait_state(UW addr, UW mask, UW value)
{
	W	i;

	for (i = TIMEOUT; i > 0; i--) ;

	return i ? E_OK : E_TMOUT;
}

/* interrupt Raw status / clear */
LOCAL	void	clear_int(void)
{
	return;
}

/* interrupt Raw status / useable */
LOCAL	void	setup_int(void)
{
	return;
}

/* wait for interrupt Raw status */
LOCAL	ER	wait_int(void)
{
	ER	er = E_OK;
	return er;
}

/* start / restart */
LOCAL	ER	send_start(UB addr)
{
	ER	er;
	er = E_OK;
	return er;
}

/* stop */
LOCAL	ER	send_stop(void)
{
	ER	er;

        /* generate stop condition */
        /* wait for sending STOP bit(s) */
	return er;
}

/* data transmission */
LOCAL	ER	send_data(UB data)
{
	ER	er;
fin0:
	return er;
}

/* data receive */
LOCAL	W	recv_data(W attr)
{
	W	er = 0;

        /* when the first data is received, switch to receive mode */
        /* instruct the reception of data */
        /* read data */
        /* when an error occurs, or the last byte is seen, then perform the post processing */
	return er;
}

/* start IIC send/receive */
LOCAL	ER	iic_start(void)
{
	ER	er;
	putString(__func__);putString("\n");
	return er;
}

/* stop IIC send/receive */
LOCAL	void	iic_finish(void)
{
	printk("%s\n", __func__);
	return;
}

/* read IIC-GPIO */
LOCAL	W	IICGPIORead(W addr)
{
	W	dat;
	printk("%s\n", __func__);
	return dat;
}

/* IIC-GPIO write */
LOCAL	void	IICGPIOWrite(W addr, W dat)
{
	setup_int();

	iic_start();
	send_start(addr);
	send_data(dat);
	send_stop();
	iic_finish();

	clear_int();

	return;
}

/* ------------------------------------------------------------------------ */

IMPORT	W	pmicRead(W reg);
IMPORT	W	pmicWrite(W reg, W dat);
#define	pmicDelay(x)	waitUsec(4)	/* about 16msec */
#define	USBPowerOn	0xe0		/* GPIO13(OD), High * power is supplied to A connector only */
#define	USBPowerOff	0xe0		/* GPIO13(OD), High */

/* obtain DipSw status */
EXPORT	UW	DipSwStatus(void)
{
	UW	d;
        /* read data from read port */
        /* unnecessary bits are masked and then invert logic. */
        /* check abort switch */
	d = 1;
	return d;
}

/* USB power control */
EXPORT	void	usbPower(BOOL power)
{
	printk("[info] usb power %s\n", power ? "ON" : "OFF");
	return ;

}

/* power off */
EXPORT	void	powerOff(void)
{
	printk("[info] Power off\n");
	return ;
}

/* reset start*/
EXPORT	void	resetStart(void)
{
	printk("[info] reset board!\n");
	return ;
}

/* initialize hardware peripherals (executed only during reset) */
EXPORT	void	initHardware(void)
{
	printk("[info]:\tinit Hardware\n");
	return;
}

/* LED on/off */
EXPORT	void	cpuLED(UW v)
{
	if(v == LED_POWERUP) {
		printk("[info]:\tLED power up\n");
	}
	else if (v == LED_MEMCLR) {
		printk("[info]:\tLED mem clear\n");
	}
}

/*
 * machine-dependent interrupt processing
 *       vec     interrupt vector number
 *       return value    0: unsupported target
 *               1: for the supported target, processing was performed. (monitor still continues)
 *               2: for the supported target, proceesing was performed (interrupt handler is exited)
 */
EXPORT	W	procHwInt(UW vec)
{
        /* only abort switch (GPIO(P8)) is supported */

        /* clear interrupt */

	printk("Abort Switch (SW1) Pressed\n");
	return 1;
}

/* ------------------------------------------------------------------------ */

/*
 *        configure GPIO pin multiplexer
 */
    
EXPORT	const UW	GPIOConfig[] = {0, 0};
