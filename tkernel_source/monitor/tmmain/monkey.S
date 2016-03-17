/*
 * ARM SVC call 
 * 2016/05/17 by Du Huanpeng<u74147@gmail.com>
 */


.global	svc_r0

__lr:	svc	0x00DEADEF
__svc:	svc	0x00BEEFEF
	ldr	pc, __lr

svc_r0:
	bic	r0, #0xFF000000
	orr	r0, #0xEF000000
	str	r0, __svc
	str	lr, __lr
	b	__svc

