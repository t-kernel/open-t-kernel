
	.global	kstart
kstart:
1:	svc	0
	ldr	r0, 1b
	add	r0, #1
	bic	r0, #0xFF000000
	orr	r0, #0xEF000000
	str	r0, 1b
	b	1b

	b	.
	.end

