#ifndef __COMPILER_H__
#define __COMPILER_H__

#if defined(__CC_ARM) && defined(_in_asm_source_) 
#define __BITOR__ :OR: 
#else
/* default compiler is GCC */ 
#define __BITOR__ |
#endif

#endif /* __COMPILER_H__ */
