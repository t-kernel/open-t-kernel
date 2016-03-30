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
 *	monitor.ld
 *
 *       link specification for monitor
 */

MEMORY
{
	RAM2 (rxw) : ORIGIN = 0x43F00000, LENGTH =   1M
	RAM0 (rxw) : ORIGIN = 0x00000000, LENGTH = 128K
	RAM1 (rxw) : ORIGIN = 0x40000000, LENGTH =  63M
	ROM0 (rx)  : ORIGIN = 0x80000000, LENGTH =  64K
	ROM1 (r)   : ORIGIN = 0x90000000, LENGTH = 256M
}

OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

SECTIONS {

	.eitbra : {
		__loadaddr = .;
		hwdepend/arm/cpu/eitent-start.o (*)
		KEEP(*(.eitbra))
		. = ALIGN(0x10);
	}


	.startup : {
		__startup_org = .;
		__startup_start = .;
		KEEP(*(.startup))
		. = ALIGN(0x10);
		__startup_end = .;
		__startup_size = .;
	}
	
	.text : {
		__text_org = . ;
		_stext = .;
		KEEP (*(.init))
		*(.text)
		*(.text.*)
		*(.stub)
		*(.glue_7t)
		*(.glue_7)
		KEEP (*(.fini))
		PROVIDE (__etext = .);
		PROVIDE (_etext = .);
		PROVIDE (etext = .);
		*(.rodata)
		*(.rodata.*)
		*(.rodata1)
		. = ALIGN(0x10);
	}
	.ARM.extab : 
	{
		*(.ARM.extab* .gnu.linkonce.armextab.*)
	}
	__exidx_start = .;
	.ARM.exidx :
	{
		*(.ARM.exidx* .gnu.linkonce.armexidx.*)
	}
	__exidx_end = .;
	__etext = .;

	.data : {
	__data_org = . ;
		__data_start = . ;
		*(flashwr.rodata)
		*(.data)
		*(.data.*)
		SORT(CONSTRUCTORS)
		*(.data1)
		KEEP (*(.eh_frame))
		*(.gcc_except_table)
		KEEP (*crtbegin.o(.ctors))
		KEEP (*(EXCLUDE_FILE (*crtend.o ) .ctors))
		KEEP (*(SORT(.ctors.*)))
		KEEP (*(.ctors))
		KEEP (*crtbegin.o(.dtors))
		KEEP (*(EXCLUDE_FILE (*crtend.o ) .dtors))
		KEEP (*(SORT(.dtors.*)))
		KEEP (*(.dtors))
		*(.got.plt)
		*(.got)
		*(.sdata)
		*(.sdata.*)
		. = ALIGN(0x10);
		_edata = .;
		__data_end = .;
		PROVIDE (edata = .);
	}
	.bss (NOLOAD) : {
		__bss_start = .;
		PROVIDE (__sbss_start = .);
		PROVIDE (___sbss_start = .);
		*(.sbss)
		*(.sbss.*)
		*(.scommon)
		PROVIDE (__sbss_end = .);
		PROVIDE (___sbss_end = .);
		*(.bss)
		*(.bss.*)
		*(EXCLUDE_FILE(*/wrkbuf.o) COMMON)
		. = ALIGN(0x10);
		_end = .;
		__bss_end = .;
		__bss_size = SIZEOF(.bss);
		PROVIDE (end = .);
	}
	__flashwr_org = .;
	__flashwr_start = .;
	__flashwr_end = .;

}
