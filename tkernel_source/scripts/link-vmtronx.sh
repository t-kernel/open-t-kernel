#!/bin/sh
#
# link vmtronx
#
# vmtronx is linked from the objects selected by $(KBUILD_VMLINUX_INIT) and
# $(KBUILD_VMLINUX_MAIN). Most are built-in.o files from top-level directories
# in the kernel tree, others are specified in arch/$(ARCH)/Makefile.
# Ordering when linking is important, and $(KBUILD_VMLINUX_INIT) must be first.
#
# vmtronx
#   ^
#   |
#   +-< $(KBUILD_VMLINUX_INIT)
#   |   +--< init/version.o + more
#   |
#   +--< $(KBUILD_VMLINUX_MAIN)
#   |    +--< drivers/built-in.o mm/built-in.o + more
#   |
#   +-< ${kallsymso} (see description in KALLSYMS section)
#
# vmtronx version (uname -v) cannot be updated during normal
# descending-into-subdirs phase since we do not yet know if we need to
# update vmtronx.
# Therefore this step is delayed until just before final link of vmtronx.
#
# System.map is generated to document addresses of all kernel symbols

# Error out on error
set -e

# Nice output in kbuild format
# Will be supressed by "make -s"
info()
{
	if [ "${quiet}" != "silent_" ]; then
		printf "  %-7s %s\n" ${1} ${2}
	fi
}

# Link of vmtronx.o used for section mismatch analysis
# ${1} output file
modpost_link()
{
	${LD} ${LDFLAGS} -r -o ${1} ${KBUILD_VMLINUX_INIT}                   \
		--start-group ${KBUILD_VMLINUX_MAIN} --end-group
}

# Link of vmtronx
# ${1} - optional extra .o files
# ${2} - output file
vmtronx_link()
{
	local lds="${objtree}/${KBUILD_LDS}"

	if [ "${SRCARCH}" != "um" ]; then
		${LD} ${LDFLAGS} ${LDFLAGS_vmtronx} -o ${2}                  \
			-T ${lds} ${KBUILD_VMLINUX_INIT}                     \
			--start-group ${KBUILD_VMLINUX_MAIN} --end-group ${1}
	else
		${CC} ${CFLAGS_vmtronx} -o ${2}                              \
			-Wl,-T,${lds} ${KBUILD_VMLINUX_INIT}                 \
			-Wl,--start-group                                    \
				 ${KBUILD_VMLINUX_MAIN}                      \
			-Wl,--end-group                                      \
			-lutil ${1}
		rm -f linux
	fi
}


# Create ${2} .o file with all symbols from the ${1} object file
kallsyms()
{
	info KSYM ${2}
	local kallsymopt;

	if [ -n "${CONFIG_HAVE_UNDERSCORE_SYMBOL_PREFIX}" ]; then
		kallsymopt="${kallsymopt} --symbol-prefix=_"
	fi

	if [ -n "${CONFIG_KALLSYMS_ALL}" ]; then
		kallsymopt="${kallsymopt} --all-symbols"
	fi

	if [ -n "${CONFIG_ARM}" ] && [ -n "${CONFIG_PAGE_OFFSET}" ]; then
		kallsymopt="${kallsymopt} --page-offset=$CONFIG_PAGE_OFFSET"
	fi

	if [ -n "${CONFIG_X86_64}" ]; then
		kallsymopt="${kallsymopt} --absolute-percpu"
	fi

	local aflags="${KBUILD_AFLAGS} ${KBUILD_AFLAGS_KERNEL}               \
		      ${NOSTDINC_FLAGS} ${TRONXINCLUDE} ${KBUILD_CPPFLAGS}"

	${NM} -n ${1} | \
		scripts/kallsyms ${kallsymopt} | \
		${CC} ${aflags} -c -o ${2} -x assembler-with-cpp -
}

# Create map file with all symbols from ${1}
# See mksymap for additional details
mksysmap()
{
	${CONFIG_SHELL} "${srctree}/scripts/mksysmap" ${1} ${2}
}

sortextable()
{
	${objtree}/scripts/sortextable ${1}
}

# Delete output files in case of error
trap cleanup SIGHUP SIGINT SIGQUIT SIGTERM ERR
cleanup()
{
	rm -f .old_version
	rm -f .tmp_System.map
	rm -f .tmp_kallsyms*
	rm -f .tmp_version
	rm -f .tmp_vmtronx*
	rm -f System.map
	rm -f vmtronx
	rm -f vmtronx.o
}

#
#
# Use "make V=1" to debug this script
case "${KBUILD_VERBOSE}" in
*1*)
	set -x
	;;
esac

if [ "$1" = "clean" ]; then
	cleanup
	exit 0
fi

# We need access to CONFIG_ symbols
case "${KCONFIG_CONFIG}" in
*/*)
	. "${KCONFIG_CONFIG}"
	;;
*)
	# Force using a file from the current directory
	. "./${KCONFIG_CONFIG}"
esac

#link vmtronx.o
info LD vmtronx.o
modpost_link vmtronx.o

# modpost vmtronx.o to check for section mismatches
${MAKE} -f "${srctree}/scripts/Makefile.modpost" vmtronx.o

# Update version
info GEN .version
if [ ! -r .version ]; then
	rm -f .version;
	echo 1 >.version;
else
	mv .version .old_version;
	expr 0$(cat .old_version) + 1 >.version;
fi;

# final build of init/
${MAKE} -f "${srctree}/scripts/Makefile.build" obj=kernel/sysinit

kallsymso=""
kallsyms_vmtronx=""
if [ -n "${CONFIG_KALLSYMS}" ]; then

	# kallsyms support
	# Generate section listing all symbols and add it into vmtronx
	# It's a three step process:
	# 1)  Link .tmp_vmtronx1 so it has all symbols and sections,
	#     but __kallsyms is empty.
	#     Running kallsyms on that gives us .tmp_kallsyms1.o with
	#     the right size
	# 2)  Link .tmp_vmtronx2 so it now has a __kallsyms section of
	#     the right size, but due to the added section, some
	#     addresses have shifted.
	#     From here, we generate a correct .tmp_kallsyms2.o
	# 2a) We may use an extra pass as this has been necessary to
	#     woraround some alignment related bugs.
	#     KALLSYMS_EXTRA_PASS=1 is used to trigger this.
	# 3)  The correct ${kallsymso} is linked into the final vmtronx.
	#
	# a)  Verify that the System.map from vmtronx matches the map from
	#     ${kallsymso}.

	kallsymso=.tmp_kallsyms2.o
	kallsyms_vmtronx=.tmp_vmtronx2

	# step 1
	vmtronx_link "" .tmp_vmtronx1
	kallsyms .tmp_vmtronx1 .tmp_kallsyms1.o

	# step 2
	vmtronx_link .tmp_kallsyms1.o .tmp_vmtronx2
	kallsyms .tmp_vmtronx2 .tmp_kallsyms2.o

	# step 2a
	if [ -n "${KALLSYMS_EXTRA_PASS}" ]; then
		kallsymso=.tmp_kallsyms3.o
		kallsyms_vmtronx=.tmp_vmtronx3

		vmtronx_link .tmp_kallsyms2.o .tmp_vmtronx3

		kallsyms .tmp_vmtronx3 .tmp_kallsyms3.o
	fi
fi

info LD vmtronx
vmtronx_link "${kallsymso}" vmtronx

if [ -n "${CONFIG_BUILDTIME_EXTABLE_SORT}" ]; then
	info SORTEX vmtronx
	sortextable vmtronx
fi

info SYSMAP System.map
mksysmap vmtronx System.map

# step a (see comment above)
if [ -n "${CONFIG_KALLSYMS}" ]; then
	mksysmap ${kallsyms_vmtronx} .tmp_System.map

	if ! cmp -s System.map .tmp_System.map; then
		echo >&2 Inconsistent kallsyms data
		echo >&2 Try "make KALLSYMS_EXTRA_PASS=1" as a workaround
		cleanup
		exit 1
	fi
fi

# We made a new kernel - delete old version file
rm -f .old_version
