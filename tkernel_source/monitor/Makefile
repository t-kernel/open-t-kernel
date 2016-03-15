
ARCH := arm

# MACH := mach-em1d
# MACH := mach-asm9
# MACH := mach-acd2

MACH := mach-sam9

include Makefile.src
-include Makefile.obj

CROSS_COMPILE ?= arm-eabi-

GNUCC := $(CROSS_COMPILE)gcc
ARMCC := armcc
CC := $(GNUCC)

ifeq ($(MACH),mach-em1d)
LDS := "hwdepend/arm/lib/monitor.lnk"
else
LDS := "hwdepend/arm/lib/monitor.ld"
endif

INCLUDE = \
	-Ihwdepend/arm/$(MACH)/include \
	-Ihwdepend/arm/include \
	-Iinclude \
	-Ihwdepend/arm/$(MACH) \
	-I../include \
	-Icmdsvc

CFLAGS := -O2 -msoft-float -mthumb-interwork -mstructure-size-boundary=8 -ffreestanding -Wno-pointer-sign -D_TEF_EM1D_ -nostdlib

-include hwdepend/$(ARCH)/Makefile

ifeq ($(ARCH),arm)
CFLAGS += -D__ARM__
endif
ifeq ($(ARCH),mips)
CFLAGS += -D__MIPS__
endif
ifeq ($(MACH),mach-em1d)
CFLAGS += -mcpu=arm1176jzf-s
CFLAGS += -D__TRON_ARCH_ARM=6
CFLAGS += -DCONFIG_MACH_EM1D
endif

ifeq ($(MACH),mach-acd2)
CFLAGS += -mcpu=cortex-r4
CFLAGS += -D__TRON_ARCH_ARM=7
CFLAGS += -DCONFIG_MACH_ACD2
endif

ifeq ($(MACH),mach-asm9) 
CFLAGS += -mcpu=arm926ej-s
CFLAGS += -D__TRON_ARCH_ARM=5
CFLAGS += -DCONFIG_MACH_ASM9
CFLAGS += -DCONFIG_INIT_SP=0x40002000
endif

ifeq ($(MACH),mach-sam9) 
CFLAGS += -mcpu=arm926ej-s
CFLAGS += -D__TRON_ARCH_ARM=5
CFLAGS += -DCONFIG_MACH_SAM9
# t-monitor drivers
CFLAGS += -DCONFIG_TM_INIT_SP=0x00010000 # 64KiB
CFLAGS += -DCONFIG_TM_SIO
CFLAGS += -DCONFIG_TM_DISK
CFLAGS += -DCONFIG_TM_FLASHROM
CFLAGS += -D__TMONITOR__
CFLAGS += -DCONFIG_TM_BAUD_RATE=115200

# t-monitor
CFLAGS += -DCONFIG_TM_WRKBUF_SZ="(1<<10)"
endif

%.o: %.S
	@echo	"     AS\t"	$@
	@$(CC) $(INCLUDE) $(CFLAGS) -c $< -o $@ #-D_in_asm_source_

%.o: %.c
	@echo	"     CC\t"	$@
	@$(CC) $(INCLUDE) $(CFLAGS) -c $< -o $@

tmonitor: $(OBJ)
	@$(CROSS_COMPILE)gcc $^ -o $@ $(INCLUDE) -T$(LDS) -nostdlib -lgcc
	@echo	"     LD\t"	$@
	@$(CROSS_COMPILE)objdump -DS $@ >tm.S
	@echo	"    DIS\t"	tm.S
	@$(CROSS_COMPILE)objcopy -O binary $@ tm.bin
	@echo	"OBJDUMP\t"	tm.bin
	@cp tm.bin /var/lib/tftpboot/
	@$(CROSS_COMPILE)nm $@ >tm.map
	@echo   " SYSMAP\t"	tm.map
clean:
	@rm -f $(OBJ) tmonitor tm.S tm.bin
	@echo	"  CLEAN"

prepare:
	@sed 's/^SRC/OBJ/g' Makefile.src | sed 's/[cS]$$/o/g' >Makefile.obj
	@echo	"   GEN\tMakefile"
