MACH := mach-acd2
include Makefile.src
include Makefile.obj

CROSS_COMPILE ?= arm-none-eabi-

CC := $(CROSS_COMPILE)gcc
LDS := "hwdepend/arm/lib/monitor.ld"

INCLUDE = \
	-Ihwdepend/arm/$(MACH)/include \
	-Ihwdepend/arm/include \
	-Iinclude \
	-Ihwdepend/arm/$(MACH) \
	-I../include \
	-Icmdsvc

CFLAGS := -O2 -mcpu=cortex-a8 -msoft-float -mfpu=vfp -mthumb-interwork -mstructure-size-boundary=8 -ffreestanding -Wno-pointer-sign -D_TEF_EM1D_


%.o: %.S
	$(CC) $(INCLUDE) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(INCLUDE) $(CFLAGS) -c $< -o $@

tmonitor: $(OBJ)
	$(CROSS_COMPILE)gcc $^ -o $@ $(INCLUDE) -T$(LDS) -lgcc -nostdlib -static 
	$(CROSS_COMPILE)objdump -DS $@ >tm.S
	$(CROSS_COMPILE)objcopy -O binary $@ tm.bin
clean:
	rm -f $(OBJ) tmonitor tm.S tm.bin
