/*
 * Copyright (C) 2009-2010 Freescale Semiconductor, Inc. All Rights Reserved.
 * Copyright (C) 2016 Du Huanpeng<u74147@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

/*
 * based on linux/arch/arm/plat-mxs/icoll.c
 */
  

#include "regs-icoll.h"
#include <mach/mx28.h>
#include <mach/cpudepend.h>
#include <tmonitor.h>
#include <typedef.h>

#define w_out(data, port) out_w((INT)(port), (UW)(data))

volatile void  *g_icoll_base;

/*
 * IRQ handling
 */
static void icoll_ack_irq(unsigned int irq)
{
	w_out(0, g_icoll_base + HW_ICOLL_VECTOR);

	/* ACK current interrupt */
	w_out(BV_ICOLL_LEVELACK_IRQLEVELACK__LEVEL0,
		     g_icoll_base + HW_ICOLL_LEVELACK);

	/* Barrier */
	(void)in_w(g_icoll_base + HW_ICOLL_STAT);
}

static void icoll_mask_irq(unsigned int irq)
{
	w_out(BM_ICOLL_INTERRUPTn_ENABLE,
		     g_icoll_base + HW_ICOLL_INTERRUPTn_CLR(irq));
}

static void icoll_unmask_irq(unsigned int irq)
{
	w_out(BM_ICOLL_INTERRUPTn_ENABLE,
		     g_icoll_base + HW_ICOLL_INTERRUPTn_SET(irq));
}

static int icoll_set_wake_irq(unsigned int irq, unsigned int enabled)
{
	return 0;
}

void  avic_init_irq(void *base, int nr_irqs)
{
	int i;
	g_icoll_base = base;

	/* Reset icoll */
	w_out(BM_ICOLL_CTRL_SFTRST, g_icoll_base + HW_ICOLL_CTRL_CLR);

	for (i = 0; i < 100000; i++) {
		if (!(in_w(g_icoll_base + HW_ICOLL_CTRL) &
		      BM_ICOLL_CTRL_SFTRST))
			break;
		waitUsec(2);
	}
	if (i >= 100000) {
		printk("%s:%d timeout when enableing\n",
		       __func__, __LINE__);
		return;
	}
	w_out(BM_ICOLL_CTRL_CLKGATE, g_icoll_base + HW_ICOLL_CTRL_CLR);

	for (i = 0; i < nr_irqs; i++) {
		w_out(0, g_icoll_base + HW_ICOLL_INTERRUPTn(i));
	}

	w_out(BF_ICOLL_LEVELACK_IRQLEVELACK
		     (BV_ICOLL_LEVELACK_IRQLEVELACK__LEVEL0),
		     g_icoll_base + HW_ICOLL_LEVELACK);
	w_out(BF_ICOLL_LEVELACK_IRQLEVELACK
		     (BV_ICOLL_LEVELACK_IRQLEVELACK__LEVEL1),
		     g_icoll_base + HW_ICOLL_LEVELACK);
	w_out(BF_ICOLL_LEVELACK_IRQLEVELACK
		     (BV_ICOLL_LEVELACK_IRQLEVELACK__LEVEL2),
		     g_icoll_base + HW_ICOLL_LEVELACK);
	w_out(BF_ICOLL_LEVELACK_IRQLEVELACK
		     (BV_ICOLL_LEVELACK_IRQLEVELACK__LEVEL3),
		     g_icoll_base + HW_ICOLL_LEVELACK);

	w_out(0, g_icoll_base + HW_ICOLL_VECTOR);
	/* Barrier */
	(void)in_w(g_icoll_base + HW_ICOLL_STAT);
}

void mxs_set_irq_fiq(unsigned int irq, unsigned int type)
{
	if (type == 0)
		w_out(BM_ICOLL_INTERRUPTn_ENFIQ,
			g_icoll_base +
			HW_ICOLL_INTERRUPTn_CLR(irq));
	else
		w_out(BM_ICOLL_INTERRUPTn_ENFIQ,
			g_icoll_base +
			HW_ICOLL_INTERRUPTn_SET(irq));
}

void mxs_enable_fiq_functionality(int enable)
{
	if (enable)
		w_out(BM_ICOLL_CTRL_FIQ_FINAL_ENABLE,
			g_icoll_base + HW_ICOLL_CTRL_SET);
	else
		w_out(BM_ICOLL_CTRL_FIQ_FINAL_ENABLE,
			g_icoll_base + HW_ICOLL_CTRL_CLR);

}

