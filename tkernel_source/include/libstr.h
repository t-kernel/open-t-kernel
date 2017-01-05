/*
 *----------------------------------------------------------------------
 *    T-Kernel 2.0 Software Package
 *
 *    Copyright 2011 by Ken Sakamura.
 *    This software is distributed under the latest version of T-License 2.x.
 *----------------------------------------------------------------------
 *
 *    Released by T-Engine Forum(http://www.t-engine.org/) at 2011/05/17.
 *    Modified by T-Engine Forum at 2014/09/10.
 *    Modified by TRON Forum(http://www.tron.org/) at 2015/06/01.
 *
 *----------------------------------------------------------------------
 */

/*
 *	@(#)libstr.h
 *
 *	Standard library for kernel link
 *
 */

#ifndef	__LIBSTR_H__
#define __LIBSTR_H__

#include <stdtype.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __CC_ARM
#ifdef	__size_t
typedef __size_t	size_t;
#undef	__size_t
#endif

#ifdef	__wchar_t
typedef __wchar_t	wchar_t;
#undef	__wchar_t
#endif
#endif

#ifndef NULL
#define NULL		0
#endif

extern void* tkl_memset( void *s, int c, size_t n );
extern int tkl_memcmp( const void *s1, const void *s2, size_t n );
extern void* tkl_memcpy( void *dst, const void *src, size_t n );
extern void* tkl_memmove( void *dst, const void *src, size_t n );

extern size_t tkl_strlen( const char *s );
extern int tkl_strcmp( const char *s1, const char *s2 );
extern char* tkl_strcpy( char *dst, const char *src );
extern char* tkl_strncpy( char *dst, const char *src, size_t n );
extern char* tkl_strcat( char *dst, const char *src );
extern char* tkl_strncat( char *dst, const char *src, size_t n );

extern unsigned long int tkl_strtoul( const char *nptr, char **endptr, int base );

#define	MEMSET	tkl_memset
#define	MEMCMP	tkl_memcmp
#define	MEMCPY	tkl_memcpy
#define	MEMMOVE	tkl_memmove
#define	STRLEN	tkl_strlen
#define	STRCMP	tkl_strcmp
#define	STRCPY	tkl_strcpy
#define	STRNCPY	tkl_strncpy
#define	STRCAT	tkl_strcat
#define	STRNCAT	tkl_strncat
#define	STRTOUL	tkl_strtoul

/* Use "memcpy" of the libstr for "implicit memcpy call"
	which is generated by the compiler when copying a structure. */
#define	use_libstr_memcpy_implicit	1

/* Use "memxxx" and "strxxx" of the libstr as standard C functions */
#define	use_libstr_func_as_std		0

#ifdef __cplusplus
}
#endif
#endif /* __LIBSTR_H__ */
