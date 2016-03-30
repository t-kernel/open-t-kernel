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
 *	helpmsg.c
 *
 *       command help message
 */

#include <cmdsvc.h>
#include "help.h"

/*
 * display help message
 */
EXPORT void printHelp( const HELP *help )
{
	(*help->prfn)(help);
}

/*
 * display simple help message
 */
LOCAL void prSimpleHelp( const HELP *help )
{
	printk(help->msg);
}

/*
 * display help message for dump command
 */
LOCAL void prDumpHelp( const HELP *help )
{
	const UB *p1 = help->msg;
	const UB *p2;

	for (; *p1; p1++);
	p2 = ++p1;
	for (; *p2; p2++);
	p2++;
	printk("Dump%s(D%s)) [start_addr][,{end_addr|#data_cnt}] ", help->msg, p1);
	printk(": Dump Memory in %s\n",p2);
}

/*
 * display help message for modify command
 */
LOCAL void prModifyHelp( const HELP *help )
{
	const UB *p1 = help->msg;
	const UB *p2;

	for (; *p1; p1++);
	p2 = ++p1;
	for (; *p2; p2++);
	p2++;
	printk("Modify%s(M%s) [start_addr][,data].. ", help->msg, p1);
	printk(": Modify Memory in %s\n", p2);
}

/*
 * display help message for fill command
 */
LOCAL void prFillHelp( const HELP *help )
{
	const UB *p1 = help->msg;
	const UB *p2;

	for (; *p1; p1++);
	p2 = ++p1;
	for (; *p2; p2++);
	p2++;
	printk("Fill(F%s) start_addr,{end_addr|#data_cnt}[,data].. ", help->msg, p1);
	printk(": Fill Memory in %s\n", p2);
}

/*
 * display help message for search command
 */
LOCAL void prSearchHelp( const HELP *help )
{
	const UB *p1 = help->msg;
	const UB *p2;

	for (; *p1; p1++);
	p2 = ++p1;
	for (; *p2; p2++);
	p2++;
	printk("Search%s(SC%s) start_addr,{end_addr|#data_cnt},data[,data].. ", help->msg, p1);
	printk(": Search Memory in %s\n", p2);
}

/*
 * display help message for input command
 */
LOCAL void prInputHelp( const HELP *help )
{
	const UB *p = help->msg;

	for (; *p; p++);
	p++;
	printk("Input%s(I%s) port ", help->msg, p);
	printk(": Input %s from I/O port\n", help->msg);
}

/*
 * display help message for output command
 */
LOCAL void prOutputHelp( const HELP *help )
{
	const UB *p = help->msg;

	for (; *p; p++);
	p++;
	printk("Output%s(O%s) port,data ", help->msg, p);
	printk(": Output %s to I/O port\n", help->msg);
}

/*
 * display help message with disk name listing
 */
LOCAL void prDiskHelp( const HELP *help )
{
	const UB *devnm;
	UW	attr;
	W	i;

	printk(help->msg);
	printk("  device :");
	for ( i = 0;; ++i ) {
		devnm = ( help == &helpBD )? bootDevice(i): diskList(i, &attr);
		if ( devnm == NULL ) break;

                /* exclude devices that can not be specified */
		if ( help == &helpWD && (attr & DA_RONLY) != 0 ) continue;
		printk(" %s", devnm);
	}
	printk("\n");
}

/*
 * display help message for WROM command
 */
LOCAL void prWRomHelp( const HELP *help )
{
	const MEMSEG	*rom, *ram;
	UW	ram_top, sz;

	rom = MemArea(MSA_FROM, 1);
	ram = MemArea(MSA_OS, 1);
	if ( rom == NULL || ram == NULL ) {
		printk("Not Supported\n");
		return;
	}

	ram_top = (ram->top + FROM_SECSZ - 1) & ~(FROM_SECSZ - 1);
	sz = rom->end - rom->top;
	if ( sz > ram->end - ram_top ) sz = ram->end - ram_top;

	printk(help->msg);
	printk("  rom_addr      : 0x%08X - 0x%08X\n", rom->top, rom->end-FROM_SECSZ);
	printk("  data_ram_addr : 0x%08X - 0x%08X\n", ram_top, ram->end-FROM_SECSZ);
	printk("  block_count   : 1 - %d (1 block = %dKB)\n", sz / FROM_SECSZ, FROM_SECSZ / 1024);
}

/* ------------------------------------------------------------------------ */

EXPORT const HELP helpALL	= { prSimpleHelp,
 "--- Command List :   \"? command\" for details ---\n"
 "DumpByte/Half/Word(D/DB/DH/DW)  ModifyByte/Half/Word(M/MB/MH/MW)\n"
 "FillByte/Half/Word(F/FB/FH/FW)  SearchByte/Half/Word(SC/SCB/SCH/SCW)\n"
 "InputByte/Half/Word(IB/IH/IW)   OutputByte/Half/Word(OB/OH/OW)\n"
 "Compare(CMP)    Move(MOV)       Disassemble(DA) Register(R)\n"
 "Go(G)  Step(S)  Next(N)         BreakPoint(B)   BreakClear(BC)\n"
 "BackTrace(BTR)  Kill(KILL)      Load(LO)"
 "\n"
 "BootDisk(BD)    ReadDisk(RD)    WriteDisk(WD)   InfoDisk(ID)\n"
 "WriteROM(WROM)  FlashLoad(FLLO) Exit(EX)        Help(H/?)\n"
};

EXPORT const HELP helpD		= { prDumpHelp,
 "\0\0Byte"
};

EXPORT const HELP helpDB	= { prDumpHelp,
 "Byte\0B\0Byte"
};

EXPORT const HELP helpDH	= { prDumpHelp,
 "Half\0H\0Half"
};

EXPORT const HELP helpDW	= { prDumpHelp,
 "Word\0W\0Word"
};

EXPORT const HELP helpM		= { prModifyHelp,
 "\0\0Byte"
};

EXPORT const HELP helpMB	= { prModifyHelp,
 "Byte\0B\0Byte"
};

EXPORT const HELP helpMH	= { prModifyHelp,
 "Half\0H\0Half"
};

EXPORT const HELP helpMW	= { prModifyHelp,
 "Word\0W\0Word"
};

EXPORT const HELP helpF		= { prFillHelp,
 "\0\0Byte"
};

EXPORT const HELP helpFB	= { prFillHelp,
 "Byte\0B\0Byte"
};

EXPORT const HELP helpFH	= { prFillHelp,
 "Half\0H\0Half"
};

EXPORT const HELP helpFW	= { prFillHelp,
 "Word\0W\0Word"
};

EXPORT const HELP helpSC	= { prSearchHelp,
 "\0\0Byte"
};

EXPORT const HELP helpSCB	= { prSearchHelp,
 "Byte\0B\0Byte"
};

EXPORT const HELP helpSCH	= { prSearchHelp,
 "Half\0H\0Half"
};

EXPORT const HELP helpSCW	= { prSearchHelp,
 "Word\0W\0Word"
};

EXPORT const HELP helpCMP	= { prSimpleHelp,
 "Compare(CMP) start_addr,{end_addr|#byte_cnt},compare_addr : "
	"Compare Memory\n"
};

EXPORT const HELP helpMOV	= { prSimpleHelp,
 "Move(MOV) start_addr,{end_addr|#byte_cnt},dest_addr : Move Memory\n"
};

EXPORT const HELP helpIB	= { prInputHelp,
 "Byte\0B"
};

EXPORT const HELP helpIH	= { prInputHelp,
 "Half\0H"
};

EXPORT const HELP helpIW	= { prInputHelp,
 "Word\0W"
};

EXPORT const HELP helpOB	= { prOutputHelp,
 "Byte\0B"
};

EXPORT const HELP helpOH	= { prOutputHelp,
 "Half\0H"
};

EXPORT const HELP helpOW	= { prOutputHelp,
 "Word\0W"
};

EXPORT const HELP helpDA	= { prSimpleHelp,
 "Disassemble(DA) [start_addr][,step_cnt] : Disassemble\n"
 "  Not Supported\n"
};

EXPORT const HELP helpR		= { prSimpleHelp,
 "Register(R) [register_name[,data]] : Register Dump / Modify\n"
};

EXPORT const HELP helpG		= { prSimpleHelp,
 "Go(G) [start_addr][,break_addr] : Go Program\n"
};

EXPORT const HELP helpB		= { prSimpleHelp,
 "BreakPoint(B) [break_addr[,break_attr][,\"command\"]] : Set Break Point\n"
 "  break_attr : S\n"
};

EXPORT const HELP helpBC	= { prSimpleHelp,
 "BreakClear(BC) [break_addr][,break_addr].. : Clear Break Point\n"
};

EXPORT const HELP helpS		= { prSimpleHelp,
 "Step(S) [start_addr][,step_cnt] : Step Trace Program\n"
};

EXPORT const HELP helpN		= { prSimpleHelp,
 "Next(N) [start_addr][,step_cnt] : Next Trace Program\n"
};

EXPORT const HELP helpBTR	= { prSimpleHelp,
 "BackTrace(BTR) [frame_pointer] : Display Backtrace\n"
 "  Not Supported\n"
};

EXPORT const HELP helpLO	= { prSimpleHelp,
 "Load(LO) {S|XS|XM} [,load addr] : Load Program / Data\n"
 "  S  : Load s-format data (no protocol)\n"
 "  XM : Load memory image  (XMODEM protocol)\n"
 "  XS : Load s-format data (XMODEM protocol)\n"
};

EXPORT const HELP helpRD	= { prDiskHelp,
 "ReadDisk(RD) device, start_block, nblocks, mem_addr : Read Disk Blocks\n"
};

EXPORT const HELP helpWD	= { prDiskHelp,
 "WriteDisk(WD) device, start_block, nblocks, mem_addr : Write Disk Blocks\n"
};

EXPORT const HELP helpID	= { prDiskHelp,
 "InfoDisk(ID) device : Display Disk Information\n"
};

EXPORT const HELP helpBD	= { prDiskHelp,
 "BootDisk(BD) [device] : Boot from Disk\n"
};

EXPORT const HELP helpKILL	= { prSimpleHelp,
 "Kill : Kill Process and Continue\n"
};

EXPORT const HELP helpH		= { prSimpleHelp,
 "Help(H/?) [command_name] : Help Message\n"
};

EXPORT const HELP helpEX	= { prSimpleHelp,
 "Exit(EX) [0] : System Power Off\n"
 "Exit(EX) -1  : System Reset (Restart)\n"
};

EXPORT const HELP helpWROM	= { prWRomHelp,
 "WriteROM(WROM) rom_addr, data_ram_addr, block_count : "
	"Write Flash ROM blocks\n"
};

EXPORT const HELP helpFLLO	= { prSimpleHelp,
 "FlashLoad(FLLO) [attr] : Load S-Format Data & Write Flash ROM\n"
 "  attr: X  Use XMODEM protocol\n"
 "        E  Fill write blocks with 0xFF\n"
 "           Default : Overwrite original Flash ROM Image\n"
};

/* ======================================================================== */

/*
 * display boot message
 */
EXPORT void dispTitle( void )
{
	int i;

	printk("\n\n");
	for ( i = 0; Title[i] != NULL; i++ ) printk(Title[i]);
	printk("\n\n");
}
