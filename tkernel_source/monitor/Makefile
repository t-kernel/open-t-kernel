include Makefile.src
include Makefile.obj

CC := arm-none-eabi-gcc
LDS := "hwdepend/arm/lib/monitor.lnk"

INCLUDE = \
	-Ihwdepend/arm/mach-em1d/include \
	-Ihwdepend/arm/include \
	-Iinclude \
	-Ihwdepend/arm/mach-em1d \
	-I../include

CFLAGS := -O2 -mcpu=arm1176jzf-s -msoft-float -mfpu=vfp -mthumb-interwork -mstructure-size-boundary=8 -ffreestanding -Wno-pointer-sign -D_TEF_EM1D_


%.o: %.S
	$(CC) $(INCLUDE) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(INCLUDE) $(CFLAGS) -c $< -o $@

tmonitor: $(OBJ)
	arm-none-eabi-gcc $^ -o $@ $(INCLUDE) -T$(LDS) -lgcc -nostdlib -static 
	arm-none-eabi-objdump -DS $@ >tm.S
	arm-none-eabi-objcopy -O binary $@ tm.bin
clean:
	rm -f $(OBJ) tmonitor tm.S tm.bin
	cp cmdsvc/cmdsvc.h cmdsvc.h
