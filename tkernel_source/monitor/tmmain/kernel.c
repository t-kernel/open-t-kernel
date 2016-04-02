#include <tmonitor.h>

extern int getcpsr(void);
int set_cpsr(int cpsr);
int get_cpsr(void);

extern int getr(int *);

extern int syscall(int);

int start_kernel(int argc, char *argv[])
{
	int i;
	int rc;
	int reg[16];
	int cpsr;

	cpsr = get_cpsr();
	cpsr &= ~(1<<6 | 1<<7); /* enable irq & fiq */
	cpsr = set_cpsr(cpsr);

	printk("starting kernel...");

	avic_init_irq((void *)0x80000000, 128);


	printk("CPSR: [%08X]\n", getcpsr());
	getr(reg);

	for(i=0; i<16; i++){
		printk("register [%d]: [%X]\n", i, reg[i]);
	}
	printk("Hello World!\n");
	return 0;
}

