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
	mrs	r1, cpsr
	str	r1, [r0, #16]
	mrs	r1, spsr
	str	r1, [r0, #17]
	ldr	r1, [r0, #1]

	bx	lr

	stmfd	sp, {r0-r15}
	mrs	r0, cpsr
	str	r0, [sp, #-16]
	mrs	r0, spsr
	str	r0, [sp, #-17]


	.global set_cpsr
	.global get_cpsr
	.global mask_cpsr
get_cpsr:
	mrs	r0, cpsr
	bx	lr
set_cpsr:
	msr	cpsr, r0
	bx	lr

mask_cpsr:
	bl	printk
	bx	lr

