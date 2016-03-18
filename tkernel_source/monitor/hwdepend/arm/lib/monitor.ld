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
	RAM0 (rxw) : ORIGIN = 0x00000000, LENGTH =  64K
	RAM1 (rxw) : ORIGIN = 0x72200000, LENGTH =  64M
	ROM0 (rx)  : ORIGIN = 0x80000000, LENGTH =  64K
	ROM1 (r)   : ORIGIN = 0x00000000, LENGTH = 256M
}

OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

SECTIONS {
	.eitbra : {
		__loadaddr = .;
		__eitbra_start = .;

		hwdepend/arm/cpu/eitent-start.o (*)
		KEEP(*(.eitbra))

		. = ALIGN(0x10);
		__eitbra_end = .;
		__eitbra_size = SIZEOF(.eitbra);
	} > RAM1
 
	.startup : {
		__startup_org = .;
		__startup_start = .;
		KEEP(*(.startup))
		. = ALIGN(0x10);
		__startup_end = .;
		__startup_size = .;
	} > RAM1
	
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
	} > RAM1
	.ARM.extab : 
	{
		*(.ARM.extab* .gnu.linkonce.armextab.*)
	} > RAM1
	__exidx_start = .;
	.ARM.exidx :
	{
		*(.ARM.exidx* .gnu.linkonce.armexidx.*)
	} > RAM1
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
	} > RAM1
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
	} > RAM1
	__flashwr_org = .;
	OVERLAY : {
		.flashwr {
			__flashwr_start = .;
			*(flashwr.text)
			__flashwr_end = .;
			. = ALIGN(0x10);
		}
		.wrkbuf {
			*/wrkbuf.o(COMMON)
			. = ALIGN(0x10);
		}
	} > RAM1

	/* Set stack top to end of RAM, and stack limit move down by
	 * size of stack_dummy section */
	__tm_stack_top = ORIGIN(RAM1) + LENGTH(RAM1);

}
