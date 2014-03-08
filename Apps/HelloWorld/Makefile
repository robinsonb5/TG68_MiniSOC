BASE	= m68k-elf
CC      = $(BASE)-gcc
LD      = $(BASE)-gcc
AS      = $(BASE)-as
CP      = $(BASE)-objcopy
DUMP    = $(BASE)-objdump
VASM	= vasmm68k_mot

# we use crt0.s from here
STARTUP_DIR = ../../Firmware_Common
COMMON_DIR = ../../Firmware_Common

BUILD_DIR=m68k_obj

STARTUP_SRC = $(STARTUP_DIR)/startup_bootrom.s
STARTUP_OBJ = $(patsubst $(STARTUP_DIR)/%.s,$(BUILD_DIR)/%.o,$(STARTUP_SRC))

COMMON_SRC = uart.c
COMMON_OBJ = $(patsubst %.c,$(BUILD_DIR)/%.o,$(COMMON_SRC))

MAIN_PRJ = HelloWorld
MAIN_SRC = main.c
MAIN_OBJ = $(COMMON_OBJ) $(patsubst %.c,$(BUILD_DIR)/%.o,$(MAIN_SRC))

LINKMAP  = $(STARTUP_DIR)/ldscript_bootrom.ld


# Commandline options for each tool.

CFLAGS  = -I. -c -Os -DDISABLE_UART_RX -I$(COMMON_DIR)

LFLAGS  = -nostartfiles -Wl,--relax -Os


# Our target.
all: $(BUILD_DIR) $(MAIN_PRJ).sre $(MAIN_PRJ).rpt

clean:
	rm -f $(BUILD_DIR)/*.o *.elf *.sre *.rpt *.map *.lst *.srec *~ */*.o *.bin


# Convert ELF binary to bin file.
%.sre: %.elf
	$(CP) -O srec $< $@

%.rpt: %.elf
	echo >$@ -n "End of code:\t"
	$(DUMP) -x $< | grep >>$@ _romend
	echo >>$@ -n "Start of BSS:\t"
	$(DUMP) -x $< | grep  >>$@ __bss_start__
	echo >>$@ -n "End of BSS:\t"
	$(DUMP) -x $< | grep >>$@ __bss_end__
	cat $@

# Link - this produces an ELF binary.

$(MAIN_PRJ).elf: $(STARTUP_OBJ) $(MAIN_OBJ)
	$(LD) $(LFLAGS) -T $(LINKMAP) -o $@ $+ $(LIBS)

$(BUILD_DIR)/%.o: %.c Makefile
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: $(COMMON_DIR)/%.c Makefile
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: %.s
	$(VASM) -Felf -o $@ $<

$(BUILD_DIR)/%.o: $(STARTUP_DIR)/%.s
	$(VASM) -Felf -o $@ $<

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

