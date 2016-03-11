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
	RAM0 (rxw) : ORIGIN = 0x00000000, LENGTH = 0x02000000
	ROM0 (rx)  : ORIGIN = 0x80000000, LENGTH = 0x00080000
}

OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

SECTIONS {

	__stack_size = 0x100000;
	__heap_size  = 0x100000;

	EITBRA_START = 0x20000000;

	. = EITBRA_START;

	__loadaddr = .;

	.eitbra EITBRA_START : AT(__loadaddr) {
		__eitbra_start = .;
		*(EITBRA)
		. = ALIGN(0x10);
	}

	__startup_org = _start + SIZEOF(.eitbra);
	.startup __startup_org : {
		*(.startup)
		. = ALIGN(0x10);
	}
	
	__text_org = __loadaddr + SIZEOF(.startup) + SIZEOF(.eitbra);
	.text __text_org : {
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
	__data_org = . ;
	.data __data_org : AT(LOADADDR(.text) + SIZEOF(.text)) {
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
		PROVIDE (edata = .);
	}
	.bss (NOLOAD) : AT(LOADADDR(.data) + SIZEOF(.data)) {
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
		PROVIDE (end = .);
	}
	__flashwr_org = __data_org + SIZEOF(.data);
	OVERLAY : AT(LOADADDR(.bss)) {
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
	}
	.heap ALIGN(0x10) (NOLOAD) : {
		__heap_top    = .;
		. = ALIGN(__heap_top + __heap_size, 4); 
		__heap_bottom = .;
	}
	.stack ALIGN(0x10) (NOLOAD) : {
		__stack_top    = .;
		. = ALIGN(__stack_top + __stack_size, 4); 
		__stack_bottom = .;
	}
}
