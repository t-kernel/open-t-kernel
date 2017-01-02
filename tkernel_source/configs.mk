#!/bin/bash

# Copyright (c) 2014-2017 Du Huanpeng<u74147@gmail.com>
# 1. place this file to tkernel_source/
# 2. . configs.mk /path/to/gcc

if [ -n "$1" ]
then
GCC_DIR="$1"
else
GCC_DIR="/home/opt/gcc-arm/"
fi


export BD=${PWD}
export GNU_BD=${GCC_DIR}
export GNUarm_2=${GCC_DIR}
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

