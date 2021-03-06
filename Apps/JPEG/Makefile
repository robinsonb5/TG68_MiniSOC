ARCH	= 68000
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
LIB_DIR = ../../Firmware_Common/klibc
KLIBC_HEADERS_DIR = ../../Firmware_Common/include/

BUILD_DIR=m68k_obj

STARTUP_SRC = $(STARTUP_DIR)/startup_app.s
STARTUP_OBJ = $(patsubst $(STARTUP_DIR)/%.s,$(BUILD_DIR)/%.o,$(STARTUP_SRC))

LIB_SRC = memcpy.c strcpy.c strcmp.c strncmp.c strncpy.c vsnprintf.c sprintf.c memset.c \
	 strlen.c malloc.c printf.c vsscanf.c sscanf.c strntoumax.c ctypes.c
LIB_OBJ = $(patsubst %.c,$(BUILD_DIR)/%.o,$(LIB_SRC))

COMMON_SRC = vga.c uart.c swap.c spi.c small_printf.c fat.c rafile.c syscalls.c textbuffer.c 
COMMON_OBJ = $(patsubst %.c,$(BUILD_DIR)/%.o,$(COMMON_SRC))
COMMON_S_SRC= $(COMMON_DIR)/spi_readsector.s
COMMON_S_OBJ = $(patsubst $(COMMON_DIR)/%.s,$(BUILD_DIR)/%.o,$(COMMON_S_SRC))

MAIN_PRJ = JPEGTest
MAIN_C_SRC=main.c junixio.c stubs.c
MAIN_C_OBJ = $(patsubst %.c,$(BUILD_DIR)/%.o,$(MAIN_C_SRC))

MAIN_S_SRC=
MAIN_S_OBJ = $(patsubst %.s,$(BUILD_DIR)/%.o,$(MAIN_S_SRC))

JPEG_DIR = jpeg-6b
JPEG_OBJ = $(JPEG_DIR)/libjpeg.a

MAIN_OBJ = $(COMMON_OBJ) $(COMMON_S_OBJ) $(MAIN_C_OBJ) $(MAIN_S_OBJ) $(LIB_OBJ) $(JPEG_OBJ)

LINKMAP  = $(STARTUP_DIR)/ldscript_app.ld

# Weirdly, -O2 gives a better Dhrystone score than -O3
CFLAGS  = -m$(ARCH) -fomit-frame-pointer -fno-common -I. -Ijpeg-6b/ \
	-c -O2 $(LIBOVERRIDES) -I$(COMMON_DIR) -I$(KLIBC_HEADERS_DIR)

LFLAGS  = -m$(ARCH) -nostartfiles -nostdlib -Wl,--relax -O2

LIBS = -lgcc

# Our target.
all: $(BUILD_DIR) $(MAIN_PRJ).sre $(MAIN_PRJ).rpt

clean:
	rm -f $(BUILD_DIR)/*.o *.elf *.sre *.rpt *.map *.lst *.srec *~ */*.o *.bin
	make -C $(JPEG_DIR) clean


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

# Build libjpeg if necessary
$(JPEG_DIR)/libjpeg.a:
	make -C $(JPEG_DIR) libjpeg.a

# Link - this produces an ELF binary.

$(MAIN_PRJ).elf: $(STARTUP_OBJ) $(MAIN_OBJ)
	$(LD) $(LFLAGS) -T $(LINKMAP) -o $@ $+ $(LIBS)

$(BUILD_DIR)/%.o: %.c Makefile
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: $(COMMON_DIR)/%.c Makefile
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: $(LIB_DIR)/%.c Makefile
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: %.s
	$(VASM) -Felf -o $@ $<

$(BUILD_DIR)/%.o: $(COMMON_DIR)/%.s
	$(VASM) -Felf -o $@ $<

$(BUILD_DIR)/%.o: $(STARTUP_DIR)/%.s
	$(VASM) -Felf -o $@ $<

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

