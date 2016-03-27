/*
 * ARM SVC call 
 * 2016/03/17 by Du Huanpeng<u74147@gmail.com>
 */


	.global	syscall

__syscall:
	svc	0
	bx	lr

syscall:
	bic	r0, #0xFF000000
	orr	r0, #0xEF000000
	str	r0, __syscall
	b	__syscall

