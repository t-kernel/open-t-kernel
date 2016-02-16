#include <tk/tkernel.h> 
#include "sdisk.h"

IMPORT	ER	mmcDiskInit(DrvTab *drv) { return E_OK; }
IMPORT	ER	mmcFormat(DrvTab *drv, DiskFormat *fmt, W dcnt) { return E_OK; }
IMPORT	ER	mmcIdentify(DrvTab *drv, BOOL check) { return E_OK; }
IMPORT	ER	mmcMisc(DrvTab *drv, W cmd) { return E_OK; }
IMPORT	INT	mmcReadWrite(DrvTab *drv, W blk, W cnt, void *mptr, BOOL write) { return 0; }

