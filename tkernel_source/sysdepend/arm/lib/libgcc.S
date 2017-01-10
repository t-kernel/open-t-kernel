.weak __aeabi_idiv
.weak __aeabi_uidiv
.weak __divsi3
.weak __modsi3
.weak __udivsi3
.weak __umodsi3
.weak __aeabi_idivmod
.weak __aeabi_ldivmod
.weak __aeabi_uidivmod
.weak __aeabi_uldivmod 
.weak __div0

__aeabi_idiv:
__aeabi_uidiv:
__divsi3:
__modsi3:
__udivsi3:
__umodsi3:
__aeabi_idivmod:
__aeabi_ldivmod:
__aeabi_uidivmod:
__aeabi_uldivmod:
	bx	lr

__div0:
	b	.

	.end
