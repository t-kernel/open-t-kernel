
ARCH := arm

# MACH := mach-em1d
# MACH := mach-asm9
# MACH := mach-acd2

MACH := mach-sam9

include Makefile.src
-include Makefile.obj

CROSS_COMPILE ?= arm-none-eabi-

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

CFLAGS := -O2 -msoft-float -mfpu=vfp -mthumb-interwork -mstructure-size-boundary=8 -ffreestanding -Wno-pointer-sign -D_TEF_EM1D_

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
endif

ifeq ($(MACH),mach-asm9) 
CFLAGS += -mcpu=arm926ej-s
CFLAGS += -D__TRON_ARCH_ARM=5
CFLAGS += -DCONFIG_MACH_SAM9
endif

%.o: %.S
	@echo	"     AS\t"	$@
	@$(CC) $(INCLUDE) $(CFLAGS) -c $< -o $@

%.o: %.c
	@echo	"     CC\t"	$@
	@$(CC) $(INCLUDE) $(CFLAGS) -c $< -o $@

tmonitor: $(OBJ)
	@$(CROSS_COMPILE)gcc $^ -o $@ $(INCLUDE) -T$(LDS) -lgcc -nostdlib -static 
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
