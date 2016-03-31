#include <tmonitor.h>

extern int syscall(int);

int start_kernel(int argc, char *argv[])
{
	int i;
	int rc;

	for(i=0; i<256; i++){
		rc = syscall(i);
	}
	printk("Hello World!\n");
	return 0;
}

