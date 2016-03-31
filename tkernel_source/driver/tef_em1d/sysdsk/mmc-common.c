#include <tk/tkernel.h>
#include "sdisk.h"

ER	mmcDiskInit(DrvTab *drv) { return E_OK; }
ER	mmcFormat(DrvTab *drv, DiskFormat *fmt, W dcnt) { return E_OK; }
ER	mmcIdentify(DrvTab *drv, BOOL check) { return E_OK; }
ER	mmcMisc(DrvTab *drv, W cmd) { return E_OK; }
INT	mmcReadWrite(DrvTab *drv, W blk, W cnt, void *mptr, BOOL write) { return 0; }
