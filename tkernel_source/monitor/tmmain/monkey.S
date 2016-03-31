/*
 * ARM SVC call 
 * 2016/03/17 by Du Huanpeng<u74147@gmail.com>
 */


	.global	syscall
	.code 32

__syscall:
	svc	0
	bx	lr

syscall:
	bic	r0, #0xFF000000
	orr	r0, #0xEF000000
	str	r0, __syscall
	b	__syscall


	.global getcpsr
getcpsr:
	mrs	r0, cpsr
	bx	lr


	.global getpc
getpc:
	mov	r0, lr
	bx	lr

	.global getr
getr:
	stmia	r0, {r0-r15}
	bx	lr
