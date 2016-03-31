#include <tmonitor.h>

extern int syscall(int);

int start_kernel(int argc, char *argv[])
{
	int i;
	int rc;
	int reg[16];

	printk("starting kernel...");

	printk("CPSR: [%08X]\n", getcpsr());
	getr(reg);

	for(i=0; i<16; i++){
		printk("register [%d]: [%X]\n", i, reg[i]);
	}
	printk("Hello World!\n");
	return 0;
}

