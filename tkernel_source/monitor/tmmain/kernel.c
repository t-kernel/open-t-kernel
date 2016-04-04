#include <tmonitor.h>

extern int getcpsr(void);
int set_cpsr(int cpsr);
int get_cpsr(void);

extern int getr(int *);

extern int syscall(int);

int flag = 0;

void start_timer();

void icoll_unmask_irq(unsigned int irq);

/* ICOLL */
#define HW_ICOLL_VECTOR   0x80000000
#define HW_ICOLL_LEVELACK 0x80000010
#define HW_ICOLL_CTRL     0x80000020
#define HW_ICOLL_VBASE    0x80000040
#define HW_ICOLL_STAT     0x80000070
#define HW_ICOLL_RAW0     0x800000A0
#define HW_ICOLL_RAW1     0x800000B0
#define HW_ICOLL_RAW2     0x800000C0
#define HW_ICOLL_RAW3     0x800000D0


#define HW_TIMROT_TIMCTRL1       0x80068060
#define HW_TIMROT_TIMCTRL1_CLR   0x80068068

int do_irq(unsigned r0, unsigned r1, unsigned r2, unsigned r3)
{
	int vec;
	int intno;
	int timerctrl;

	vec = in_w(HW_ICOLL_VECTOR);
	out_w(HW_ICOLL_VECTOR, 0);
	intno = in_w(HW_ICOLL_STAT);

	

	putchar('\n');
	printk("CPSR(irq): %X\n", r0);
	printk("CPSR(blx): %X\n", r1);

	printk("irq no: %d\n", intno);
	printk("vecisr: %x\n", vec);

	timerctrl = in_w(HW_TIMROT_TIMCTRL1);
	printk("timer-ctrl: %016b\n", timerctrl);
	out_w(HW_TIMROT_TIMCTRL1, timerctrl);

	out_w(HW_TIMROT_TIMCTRL1_CLR, 1<<15);

	out_w(HW_ICOLL_LEVELACK, 0x1);
//	out_w(HW_ICOLL_LEVELACK, 0x2);
//	out_w(HW_ICOLL_LEVELACK, 0x4);
//	out_w(HW_ICOLL_LEVELACK, 0x8);

}


int start_kernel(int argc, char *argv[])
{
	int i;
	int rc;
	int reg[16];
	int cpsr;
	const int timer_irq = 49;

	cpsr = get_cpsr();
	cpsr &= ~(1<<6 | 1<<7); /* enable irq & fiq */
	cpsr = set_cpsr(cpsr);

	printk("starting kernel...\n");

	printk("starting timer1...\n");
	avic_init_irq((void *)0x80000000, 128);
	mxs_enable_fiq_functionality(1);

	icoll_unmask_irq(timer_irq);



	start_timer(0, 0, 0, 0);


	waitMsec(1000);

	printk("CPSR: [%08X]\n", getcpsr());
	getr(reg);

	for(i=0; i<16; i++){
		printk("register [%d]: [%X]\n", i, reg[i]);
	}
	printk("Hello World!\n");

	while(1) {
		printk("E");
		waitMsec(1000);
	}
	return 0;
}


/* Test stuff for i.MX280 only */

/* ICOLL */
#define HW_ICOLL_VECTOR   0x80000000
#define HW_ICOLL_LEVELACK 0x80000010
#define HW_ICOLL_CTRL     0x80000020
#define HW_ICOLL_VBASE    0x80000040
#define HW_ICOLL_STAT     0x80000070
#define HW_ICOLL_RAW0     0x800000A0
#define HW_ICOLL_RAW1     0x800000B0
#define HW_ICOLL_RAW2     0x800000C0
#define HW_ICOLL_RAW3     0x800000D0

struct HW_TIMROT_T {
	unsigned long HW_TIMROT_ROTCTRL[4];
	unsigned long HW_TIMROT_TIMCTRL[4];
	unsigned long HW_TIMROT_RUNNING_COUNT[4];
	unsigned long HW_TIMROT_FIXED_COUNT[4];
	unsigned long HW_TIMROT_MATCH_COUNT[4];
};

#define IRQ         (1<<15)
#define IRQ_EN      (1<<14)
#define MATCH_MODE  (1<<11)
#define POLARITY    (1<<8)
#define UPDATA      (1<<7)
#define RELOAD      (1<<6)
#define PRESCALE(n) ((n)<<4)
  #define IDV_BY_8     (0x3)
#define SELECT(n)   ((n)<<0)
  #define TICK_ALWAYS  (0XF)



volatile struct HW_TIMROT_T *hw_timer_rotary[3];

int hw_icoll_raw(int irq)
{
	int irq_raw[4];
	
	irq_raw[0] = in_w(HW_ICOLL_RAW0);
	irq_raw[1] = in_w(HW_ICOLL_RAW1);
	irq_raw[2] = in_w(HW_ICOLL_RAW2);
	irq_raw[3] = in_w(HW_ICOLL_RAW3);

	return irq_raw[irq/32] & (1 << (irq%32));
	
}

void do_irq_timer(unsigned r0, unsigned r1, unsigned r2, unsigned r3)
{
}

void start_timer(unsigned r0, unsigned r1, unsigned r2, unsigned r3)
{
	int val;
	int i;

#define BIT(n) (1<<n)
#define BITTST(val, n) ((val) & BIT(n))

	hw_timer_rotary[0] = (void *)(0x80068000); /* have ROTCTRL */
	hw_timer_rotary[1] = (void *)(0x80068050);
	hw_timer_rotary[2] = (void *)(0x80068080);
	hw_timer_rotary[3] = (void *)(0x800680C0);

	val = hw_timer_rotary[0]->HW_TIMROT_ROTCTRL[0];
	printk("This SoC has:\n");
	if(BITTST(val,25)) printk("timer 0\n");
	if(BITTST(val,26)) printk("timer 1\n");
	if(BITTST(val,27)) printk("timer 2\n");
	if(BITTST(val,28)) printk("timer 3\n");

#define IRQ         (1<<15)
#define IRQ_EN      (1<<14)
#define MATCH_MODE  (1<<11)
#define POLARITY    (1<<8)
#define UPDATE      (1<<7)
#define RELOAD      (1<<6)
#define PRESCALE(n) ((n)<<4)
  #define DIV_BY_8     (0x3)
#define SELECT(n)   ((n)<<0)
  #define TICK_ALWAYS  (0XF)


#define SET 1
#define CLR 2
#define TOG 3

	hw_timer_rotary[1]->HW_TIMROT_FIXED_COUNT[0] = 0x00011000;
	val = IRQ_EN | UPDATE | RELOAD | PRESCALE(TICK_ALWAYS) | SELECT(0xB);
	out_w(HW_TIMROT_TIMCTRL1, val);

	while(1){
		static int random = 0;

		random++;
		printk("[%04d]wait timer1 irq\n", random);
		waitMsec(300);
		val = hw_timer_rotary[1]->HW_TIMROT_TIMCTRL[0];
		printk("%016b\n", val);
	}

	for(i=0; i<300; i++) {
		val = (unsigned long)(hw_timer_rotary[1]->HW_TIMROT_RUNNING_COUNT[0]);
		printk("Reading register [%016x]:\n", val);
		printk("Reading register [% 16x]:\n", val);
		printk("Reading register [%-16x]:\n", val);
		printk("Reading register [%116x]:\n", val);

		val = (hw_timer_rotary[1]->HW_TIMROT_RUNNING_COUNT[0]);

		printk("%08X\n", val);

		printk("ICOLL RAW:\n"
			"%033b %033b\n"
			"%033b %033b\n",
			in_w(HW_ICOLL_RAW0),
			in_w(HW_ICOLL_RAW1),
			in_w(HW_ICOLL_RAW2),
			in_w(HW_ICOLL_RAW3));

		printk("hw_icoll_raw[%d][%d]\n", 49, !!hw_icoll_raw(49));
		if(hw_icoll_raw(49)) {
			icoll_ack_irq(49);
			//hw_timer_rotary[1]->HW_TIMROT_ROTCTRL[CLR] = 1<<15;
			out_w((0x80068060+CLR), (1<<15));
		}

		waitMsec(300);



	}

	printk("Goodbye TIMER!\n");
		
	
}


