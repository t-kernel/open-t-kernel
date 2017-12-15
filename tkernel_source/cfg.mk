#!/bin/bash

# Copyright (c) 2014-2016 Du Huanpeng<u74147@gmail.com>
# place this file to tkernel_source/


export BD=${PWD}
export GNU_BD="/opt/gcc-arm"
export GNUarm_2="/opt/gcc-arm/."
export BUILD_TARGET="tef_em1d"

alias bd='cd ${BD}'
alias tk='cd ${BD}"/kernel/sysmain/build/tef_em1d/"'
alias tm='cd ${BD}"/monitor/tmmain/build/tef_em1d/"'
alias ro='cd ${BD}"/config/build/tef_em1d/"'

tk-link ()
{
	CROSS=${1}
	ln -s ${CROSS}ar ar
	ln -s ${CROSS}objcopy arm_2-unknown-tkernel-objcopy
	ln -s ${CROSS}gcc gcc4arm
	ln -s ${CROSS}nm  nm
	ln -s ${CROSS}ranlib  ranlib
}

tk-build ()
{
	cd ${BD}

	make -C kernel/sysmain/build/tef_em1d/
	make -C config/build/tef_em1d/
	make -C monitor/tmmain/build/tef_em1d/
}

