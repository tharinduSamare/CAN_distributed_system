ISA = rv32i

LAB=1

ifeq ($(LAB), 1)
	PREFIX = /import/public/Linux/riscv/riscv-rv32imc/bin/riscv32-unknown-elf-
else
	PREFIX = /opt/riscv/bin/riscv32-unknown-elf-
endif

LD = $(PREFIX)ld
CC = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump

CFLAGS = -O1 -Wall -march=$(ISA) -mabi=ilp32 -Wa,-adghlmns=$(@:.o=.s) -std=c99 -mpreferred-stack-boundary=4 -nostartfiles -ffreestanding -fverbose-asm
LDFLAGS = -Wl,-Bstatic,-A,$(ISA),-Map,$(TARGET).map,--gc-sections,-lgcc,-static,--print-memory-usage

SDIR = .
SRC = $(wildcard $(SDIR)/*.c)
DEP = $(SRC:.c=.d)
OBJ = $(SRC:.c=.o)
BOOTSRCS= $(wildcard boot/*.s)
BOOTOBJS= $(BOOTSRCS:.s=.o)
TARGET = main
LINKER_SCR = platform.ld
FORMROM=python3 format_rom.py

all: $(TARGET).rom

$(TARGET).rom: $(TARGET).out
	$(FORMROM) $< $@

$(TARGET).out: $(TARGET).elf
	$(OBJCOPY) -O verilog $< $@
	$(OBJDUMP) --disassemble-all -Mno-aliases $(TARGET).elf	> $(TARGET).dasm
-include $(DEP)

$(TARGET).elf: $(DEP) $(OBJ) $(BOOTOBJS) $(LINKER_SCR)
	$(CC) $(CFLAGS) $(OBJ) $(BOOTOBJS) -o $@ -T $(LINKER_SCR) $(LDFLAGS)

%.d: %.c
	$(CC) $(CFLAGS) -c -MF"$@" -MG -MM $<

ifeq ($(LAB), 1)
%.o: %.s
	$(CC) -c -march=rv32i -mabi=ilp32 $< -o $@
else
%.o: %.s
	$(CC) -c -march=rv32izicsr -mabi=ilp32 $< -o $@
endif


# %.elf: %.o $(BOOTOBJS)
# 	$(LD) -o $@ -T $(LINKER_SCR) $^

%.txt: %.elf
	$(OBJCOPY) -O verilog $< $@

# %.rom: %.txt
# 	$(FORMROM) $< $@

.PHONY: clean
clean:
	@rm -f $(OBJ) $(BOOTOBJS) $(DEP) $(SRC:.c=.s) $(TARGET).elf $(TARGET).map $(TARGET).out $(TARGET).rom $(TARGET).dasm
