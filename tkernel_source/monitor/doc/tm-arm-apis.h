EXPORT	ER	clearBreak(UW addr)
EXPORT	ER	disAssemble(UW *saddr, UW *naddr, UB *str)
EXPORT	ER	doLoading(W proto, UW addr, UW *range)
EXPORT	ER	flashwr(UW addr, void *data, W nsec, BOOL reset)
EXPORT	ER	goTrace(W trace, UW pc, UW par)
EXPORT	ER	setBreak(UW addr, W atr, UB *cmd, W cmdlen)
EXPORT	ER	setRegister(W regno, UW val)
EXPORT	UB	lineBuf[L_LINE];	/* line buffer */
EXPORT	UB	wrkBuf[WRKBUF_SZ];
EXPORT	UB *	const PBootAddr = (UB *)0x30200000;	/* primary boot loader address */
EXPORT	UW	ConPortBps;	/* console port commnication speed (bps) */
EXPORT	UW	DipSw;		/* DipSw status */
EXPORT	UW	DipSwStatus(void)
EXPORT	UW	getCP15(W reg, W opcd)
EXPORT	UW	getCurCPSR(void)
EXPORT	UW	getCurPC(void)
EXPORT	UW	getCurPCX(void)
EXPORT	UW	getCurSPSR(void)
EXPORT	UW	getRegister(W regno)
EXPORT	UW	regStack[39 + 10 + 2];
EXPORT	W	ConPort;	/* console port number */
EXPORT	W	N_MemSeg = sizeof(MemSeg) / sizeof(MEMSEG);
EXPORT	W	N_NoMemSeg = sizeof(NoMemSeg) / sizeof(MEMSEG);
EXPORT	W	chkIOAddr(UW addr, UW *pa, W len)
EXPORT	W	chkMemAddr(UW addr, UW *pa, W len, W rw)
EXPORT	W	errinfo;		/* error information */
EXPORT	W	getBreakAtr(UB *name)
EXPORT	W	getStepAddr(UW pc, UW cpsr, W mode, UW* npc, UW *rep)
EXPORT	W	invalidPC(UW addr)
EXPORT	W	invalidPC2(UW addr)
EXPORT	W	isKillValid(void)
EXPORT	W	isTKDSValid(void)
EXPORT	W	killProcReq;		/* request to forcibly kill a process */
EXPORT	W	pmicRead(W reg)
EXPORT	W	procBreak(W bpflg, UB **cmd)
EXPORT	W	procHwInt(UW vec)
EXPORT	W	readIO(UW addr, UW *data, W unit)
EXPORT	W	readMem(UW addr, void *buf, W len, W unit)
EXPORT	W	readMemStr(UW addr, void *buf, W len)
EXPORT	W	resetBreak(UW vec)
EXPORT	W	searchRegister(UB *name, W grp)
EXPORT	W	writeIO(UW addr, UW data, W unit)
EXPORT	W	writeMem(UW addr, void *buf, W len, W unit)
EXPORT	const UH	BootSignature = 0xe382;		/* signature */
EXPORT	const UW	FROM_SECSZ = SECSZ;	/* sector size */
EXPORT	const W	N_ConfigDisk = sizeof(ConfigDisk) / sizeof(CFGDISK);
EXPORT	const W	N_ConfigSIO = sizeof(ConfigSIO) / sizeof(CFGSIO);
EXPORT	const W	N_JedecSpec = sizeof(JedecSpec) / sizeof(JEDEC_SPEC);
EXPORT	void	cpuLED(UW v)
EXPORT	void	dispRegister(W regno)
EXPORT	void	dspBreak(void)
EXPORT	void	initBreak(void)
EXPORT	void	initChkAddr(void)
EXPORT	void	initHardware(void)
EXPORT	void	pmicWrite(W reg, W dat)
EXPORT	void	powerOff(void)
EXPORT	void	procCommand(UB *cmd, W fin)
EXPORT	void	resetStart(void)
EXPORT	void	resetSystem(W boot)
EXPORT	void	setCurPC(UW val)
EXPORT	void	setCurPCX(UW val)
EXPORT	void	setUpBoot( void *start, BootInfo *bootinfo )
EXPORT	void	setupBreak(void)
EXPORT	void	setupWaitUsec(void)
EXPORT	void	stopTrace(void)
EXPORT	void	sysExit(W reset)
EXPORT	void	usbPower(BOOL power)
EXPORT	void	waitMsec(UW msec)
EXPORT	void	waitNsec(_UW nsec)
EXPORT	void	waitUsec(_UW usec)
EXPORT BOOL checkAbort( void )
EXPORT BOOL inMemArea( UW top, UW end, UW attr )
EXPORT BOOL isOverlapMemArea( UW top, UW end, UW attr )
EXPORT BOOL memDiskSVC( W fno, W p1, W p2, W p3, W *er_p )
EXPORT ER bootDisk( const UB *devnm )
EXPORT ER bootROM( void )
EXPORT ER flashwr_protect( UW addr, W nsec )
EXPORT ER infoDisk( const UB *devnm, W *blksz, W *tblks )
EXPORT ER initMemDisk( DISKCB *dcb, const CFGDISK *cfg )
EXPORT ER initSIO( W port, W speed )
EXPORT ER initSIO_ns16550(SIOCB *scb, const CFGSIO *csio, W speed)
EXPORT ER rwDisk( const UB *devnm, W blk, W nblk, void *buf, BOOL wrt )
EXPORT ER writeFrom( UW addr, UW data, W nsec, W msg )
EXPORT MEMSEG* AddrMatchMemArea( UW addr, UW attr )
EXPORT MEMSEG* MemArea( UW attr, W no )
EXPORT UW getDipSw( void )
EXPORT UW* const	TopPageTable = (UW*)PAGETBL_BASE;
EXPORT W	bootFlag;	/* boot flag */
EXPORT W PrintTaskRegister( int (*prfn)( const char *format, ... ),
EXPORT W bootSelect( void )
EXPORT W enterMonitor( UW info )
EXPORT W getChar( BOOL wait )
EXPORT W getConPort( void )
EXPORT W getSIO( W tmo )
EXPORT W getString( UB *str )
EXPORT W leaveMonitor( UW info )
EXPORT W openDisk( const UB *devnm, DISKCB **dcb_p )
EXPORT W procEIT( UW vec )
EXPORT W procSVC( W fno, W p1, W p2, W p3, W p4 )
EXPORT W putChar( W c )
EXPORT W putDec( UW val )
EXPORT W putHex2( UB val )
EXPORT W putHex4( UH val )
EXPORT W putHex8( UW val )
EXPORT W printk( const UB *str )
EXPORT const UB* bootDevice( W no )
EXPORT const UB* diskList( W no, UW *attr )
EXPORT void ChangeMemAttr( UW top, UW end, UW attr );
EXPORT void DisableCache( void )
EXPORT void EnableCache( void )
EXPORT void callUserResetInit( void )
EXPORT void dispTitle( void )
EXPORT void entMonitor( UW vec )
EXPORT void flashwr_done( void )
EXPORT void flashwr_reset( void )
EXPORT void flashwr_setup( BOOL reset )
EXPORT void printHelp( const HELP *help )
EXPORT void procReset( void )
EXPORT void putSIO( UB c )
EXPORT void setupFlashLoad( W mode, UW addr[3] )
