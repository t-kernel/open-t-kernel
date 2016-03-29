/*
 * Copyright (c) 2016 Du Huanpeng<u74147@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:

 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.

 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifdef DEBUG

#include <stdio.h>
#define printch(c) putchar(c)

#else

int printch(int ch)
{
	if (ch == '\n') putSIO_mx28(0, '\r');
	putSIO_mx28(0, ch);
}

#endif

#include <stdarg.h>

int prints(const char *str)
{
	int ch;
	int i = 0;

	while(ch=str[i]) {
		i++;
		printch(ch);
		if(i>80) break;
	}

	return i;
}

int printi(char buf[], unsigned int i, int base, int cap)
{
	int j;
	unsigned int mod;

	if(cap) cap = 'A' - 10;
	else cap = 'a' - 10;

	buf[0] = 0;
	j = 0;

	do {
		mod = i % base;
		i /= base;
		if(mod < 10) {
			buf[--j] = '0' + mod;
		} else {
			buf[--j] = cap + mod;
		}
	} while(i);

	return j;
}

/*
 * second version of vprintk.
 */

int vprintks(const char *fmt, va_list args)
{
	int c;
	int i, j, pi;
	char printbuf[32 + 1];
	#define printbufend (printbuf + sizeof(printbuf) - 1)

	int flag, pad;
	#define PAD_RIGHT	1
	#define PAD_LEFT	2


	j = 0;
	i = 0;
	pi = 0;

	while(c = fmt[i]) {
		if(j != i++) {	/* formating */
			if (c == 'c') {
				printbufend[pi--] = 0;
				printbufend[pi] = va_arg(args, int);
			} else if (c == '%') {
				j++;
				while(j<i) printch(fmt[j++]);
			} else if (c == 'd' || c == 'u') {
				pi = printi(printbufend, va_arg(args, int), 10, 0);
			} else if (c == 'x' || c == 'X' || c == 'p') {
				pi = printi(printbufend, va_arg(args, int), 16, c!='x');
			} else if (c == 'b') {
				pi = printi(printbufend, va_arg(args, int), 2, 0);
			} else if (c == 's') {
				prints(va_arg(args, const char *));
				j=i;
			} else if (i-j>8) {
				while(j<i) printch(fmt[j++]);
			}

			if(pi) {
				int w;
				/* 12345..n
				 * %0??f..f
				 * ^   ^   ^
				 * j   i   i
				 */
				w = 0;
				while(w+pi>0) {
					w--;
					printch('$');
				}
				prints(printbufend+pi);
				pi = 0;
				j  = i;
			}
		} else if (c != '%') {
			printch(c);
			j++;
		}
	}

	while(j<i) printch(fmt[j++]);	/* error format at the end. */

	va_end(args);
}

int printk(const char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	return vprintks(fmt, args);
}

int printf(const char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	return vprintks(fmt, args);
}

int printks(const char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	return vprintks(fmt, args);
}
int printh(unsigned h, int cap)
{
	printks("%x", h);
}

#ifdef DEBUG
int main(int argc, char *argv[])
{
	char format[] = "%099x" "%-99x" "%99lu" "%??c";
	printks("char: [%c]\n", 'C');
	printks("hex: [%x]\n", 0xABCD1234);
	printks("hex: [%X]\n", 0xABCDEF);
	printks("dec: [%d]\n", 1234567890);
	printks("bin: [%b]\n", 0x8421);
	printks("string: [%s]\n", "Hello World");
	printks("100: [%%]\n", 100);
	printks("error in the middle of format: [%1234567890c]\n", 100);
	printks("error format at the end: [%ASDF]\n", 100);
	printks("Left pad zero: [%08X]\n", 0xABCDEF00);
	printks("Right pad zero:[%-8X]\n", 0xABCDEF11);
	printks("percent 75 [75%]\n", 75);
	return 0;

}
#endif
