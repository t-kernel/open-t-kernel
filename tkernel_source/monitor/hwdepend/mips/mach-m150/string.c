/*
 *----------------------------------------------------------------------
 *    T-Kernel 2.0 Software Package
 *
 *    Copyright 2011 by Ken Sakamura.
 *    This software is distributed under the latest version of T-License 2.x.
 *----------------------------------------------------------------------
 *
 *    Released by T-Engine Forum(http://www.t-engine.org/) at 2011/05/17.
 *    Modified by TRON Forum(http://www.tron.org/) at 2015/06/01.
 *
 *    Modified for APP-M150(MIPS32) at 2015/10/19.
 *
 *----------------------------------------------------------------------
 */

/*
 *	string.c	( T-Monitor for APP-M150 )
 *
 *	Standard string / memory operations used for t-monitor
 */

#include <tmonitor.h>

/* memory access size */
#define	MASZ	(sizeof(unsigned long))
#define	MAMSK	(MASZ - 1)

/* memory access pointer */
typedef	union {
	unsigned char	*cp;
	unsigned long	*lp;
	unsigned long	lv;
} MPTR;

/*
 * memset : fill memory area
 */
void* memset( void *s, int c, size_t n )
{
	MPTR		m;
	size_t		cnt;
	unsigned long	val;

	m.cp = (unsigned char *)s;
	val = (unsigned char)c;

	cnt = m.lv & MAMSK;
	if ( cnt > 0 ) {
		/* Not aligned in WASZ bytes */
		if ( n < MASZ * 2) {
			cnt = n;
		} else {
			cnt = MASZ - cnt;
		}
		/* Fill preceding bytes to align */
		n -= cnt;
		do {
			*m.cp++ = (unsigned char)val;
		} while ( --cnt > 0 );
	}

	/* Fill in WASZ bytes unit */
	if ( n >= MASZ ) {
		cnt = n / MASZ;
		n &= MAMSK;
		val |= val << 8;
		val |= val << 16;
		do {
			*m.lp++ = val;
		} while ( --cnt > 0 );
	}

	/* Fill trailing bytes */
	while ( n-- > 0 ) {
		*m.cp++ = (unsigned char)val;
	}
	return s;
}

/*
 * memcmp : perform memory comparison
 */
int memcmp( const void *s1, const void *s2, size_t n )
{
	int	result;
	const unsigned char	*p1 = s1;
	const unsigned char	*p2 = s2;

	while ( n-- > 0 ) {
		result = *p1++ - *p2++;
		if ( result != 0 ) return result;
	}
	return 0;
}

/*
 * memcpy : copy memory
 */
void* memcpy( void *dst, const void *src, size_t n )
{
	MPTR	s, d;
	size_t	cnt;

	d.cp = (unsigned char *)dst;
	s.cp = (unsigned char *)src;

	if ( ( (s.lv | d.lv) & MAMSK ) != 0 ) {
		/* Not aligned in WASZ bytes */
		if ( ( (s.lv ^ d.lv) & MAMSK ) != 0 || n < MASZ * 2) {
			/* Full copy in a byte unit */
			cnt = n;
		} else {
			/* Copy preceding bytes to align */
			cnt = MASZ - (s.lv & MAMSK);
		}
		/* Copy in a byte unit */
		n -= cnt;
		do {
			*d.cp++ = *s.cp++;
		} while ( --cnt > 0 );
	}

	/* Copy in WASZ bytes unit */
	if ( n >= MASZ ) {
		cnt = n / MASZ;
		n &= MAMSK;
		do {
			*d.lp++ = *s.lp++;
		} while ( --cnt > 0 );
	}

	/* Copy trailing bytes */
	while ( n-- > 0 ) {
		*d.cp++ = *s.cp++;
	}
	return dst;
}

/*
 * memmove : move memory
 */
void* memmove( void *dst, const void *src, size_t n )
{
	MPTR	s, d;
	size_t	cnt;

	d.cp = (unsigned char *)dst;
	s.cp = (unsigned char *)src;

	if ( d.cp < s.cp ) {	/* Copy forward */
		if ( ( (s.lv | d.lv) & MAMSK ) != 0 ) {
			if ( ( (s.lv ^ d.lv) & MAMSK ) != 0 || n < MASZ * 2 ) {
				cnt = n;
			} else {
				cnt = MASZ - (s.lv & MAMSK);
			}
			n -= cnt;
			do {
				*d.cp++ = *s.cp++;
			} while ( --cnt > 0 );
		}
		if ( n >= MASZ ) {
			cnt = n / MASZ;
			n &= MAMSK;
			do {
				*d.lp++ = *s.lp++;
			} while ( --cnt > 0 );
		}
		while ( n-- > 0 ) {
			*d.cp++ = *s.cp++;
		}
	} else {		/* Copy backward */
		s.cp += n;
		d.cp += n;
		if ( ( (s.lv | d.lv) & MAMSK ) != 0 ) {
			if ( ( (s.lv ^ d.lv) & MAMSK ) != 0 || n < MASZ * 2 ) {
				cnt = n;
			} else {
				cnt = s.lv & MAMSK;
			}
			n -= cnt;
			do {
				*--d.cp = *--s.cp;
			} while ( --cnt > 0 );
		}
		if ( n >= MASZ ) {
			cnt = n / MASZ;
			n &= MAMSK;
			do {
				*--d.lp = *--s.lp;
			} while ( --cnt > 0 );
		}
		while ( n-- > 0 ) {
			*--d.cp = *--s.cp;
		}
	}
	return dst;
}

/*
 * strlen : get text string length
 */
size_t strlen( const char *s )
{
	char	*cp = (char *)s;

	while ( *cp != '\0' ) cp++;
	return (size_t)(cp - s);
}

/*
 * strcmp : perform text string comparison
 */
int strcmp( const char *s1, const char *s2 )
{
	for ( ; *s1 == *s2; s1++, s2++ ) {
		if ( *s1 == '\0' ) return 0;
	}
	return (unsigned char)*s1 - (unsigned char)*s2;
}

/*
 * strncmp : perform text string comparison of specified length
 */
int strncmp( const char *s1, const char *s2, size_t n )
{
	int	result;

	while ( n-- > 0 ) {
		result = (unsigned char)*s1 - (unsigned char)*s2++;
		if ( result != 0 ) return result;
		if ( *s1++ == '\0' ) break;
	}
	return 0;
}

/*
 * strcpy : copy text string
 */
char* strcpy( char *dst, const char *src )
{
	char	*dp = dst;

	while ( (*dp++ = *src++) != '\0' );
	return dst;
}

/*
 * strncpy : copy text string of specified length
 */
char* strncpy( char *dst, const char *src, size_t n )
{
	char	*dp = dst;

	while ( n-- > 0 ) {
		if ( (*dp++ = *src++) == '\0' ) {
			while ( n-- > 0 ) *dp++ = '\0';
			break;
		}
	}
	return dst;
}

/*
 * strtoul : convert text string to integer value (unsigned long int)
 */
unsigned long strtoul( const char *nptr, char **endptr, int base )
{
	unsigned long int	value = 0;
	int		sign = 1;
	int		i;

	while ( (*nptr == ' ' || *nptr == '\t') ) {
		++nptr;
	}

	switch ( *nptr ) {
	  case '-':
		sign = -1;
		/* no break */
	  case '+':
		++nptr;
		/* no break */
	  default:
		break;
	}

	if ( base == 16 ) {
		if ( *nptr == '0' ) {
			++nptr;
			if ( *nptr == 'X' || *nptr == 'x' ) {
				++nptr;
			}
		}
	} else if ( base == 0 ) {
		if ( *nptr == '0' ) {
			++nptr;
			if ( *nptr == 'X' || *nptr == 'x' ) {
				++nptr;
				base = 16;
			} else {
				base = 8;
			}
		} else {
			base = 10;
		}
	} else if ( base < 2 || base > 36 ) {
		base = 10;
	}

	while ( *nptr != '\0' ) {
		if ( *nptr >= '0' && *nptr <= '9' ) {
			i = *nptr - '0';
		} else if ( *nptr >= 'A' && *nptr <= 'Z' ) {
			i = *nptr - 'A' + 10;
		} else if ( *nptr >= 'a' && *nptr <= 'z' ) {
			i = *nptr - 'a' + 10;
		} else {
			break;
		}
		if ( i >= base ) {
			break;
		}
		value = value * base + i;
		++nptr;
	}
	if ( endptr != NULL ) {
		*endptr = (char *)nptr;
	}
	return value * sign;
}

