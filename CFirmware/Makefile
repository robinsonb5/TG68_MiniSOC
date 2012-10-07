COMMON_C_SRC= minisoc_hardware.c textbuffer.c textbuffer.h ints.c ints.h ps2.c ps2.h keyboard.c keyboard.h \
	spi.c fat.c swap.c klibc/libc.a
COMMON_A_SRC=startup.s spi_readsector.s

MAIN_C_SRC=main.c
MAIN_A_SRC=draw.s

MEMCHECK_C_SRC=memcheck.c

BUILD_DIR=BUILD
COMMON_C_OBJ=$(patsubst %.c,$(BUILD_DIR)/%.o,$(COMMON_C_SRC))
COMMON_A_OBJ=$(patsubst %.s,$(BUILD_DIR)/%.o,$(COMMON_A_SRC))
COMMON_OBJ= $(COMMON_A_OBJ) $(COMMON_C_OBJ)
MAIN_C_OBJ=$(patsubst %.c,$(BUILD_DIR)/%.o,$(MAIN_C_SRC))
MAIN_A_OBJ=$(patsubst %.s,$(BUILD_DIR)/%.o,$(MAIN_A_SRC))
MAIN_OBJ= $(COMMON_OBJ) $(MAIN_A_OBJ) $(MAIN_C_OBJ)

MEMCHECK_C_OBJ=$(patsubst %.c,$(BUILD_DIR)/%.o,$(MEMCHECK_C_SRC))
MEMCHECK_OBJ= $(COMMON_OBJ) $(MEMCHECK_A_OBJ) $(MEMCHECK_C_OBJ)

ARCH=68000
CC=m68k-elf-gcc
AR=m68k-elf-ar
VASM=vasmm68k_mot
OBJCOPY=m68k-elf-objcopy
CFLAGS+=-m$(ARCH) -Wall -Wno-char-subscripts -O2 -fno-common -fomit-frame-pointer -I./include
LDFLAGS+=-m$(ARCH) -Xlinker -Map=menu.map -nostartfiles -Lklibc

MAIN_ELF=main.elf
MEMCHECK_ELF=memcheck.elf
OUTPUT=main.srec memcheck.srec

LINK_SCRIPT=ldscript.ld
LIBC_TARGET=klibc/libc.a

BOOTSTRAP=bootstrap/bootstrap.mif

all: $(BUILD_DIR) $(LIBC_TARGET) $(OUTPUT) $(BOOTSTRAP)

cleanall:
	rm -rf $(BUILD_DIR) $(LIBC_TARGET) $(ELF) $(OUTPUT)
	cd bootstrap; $(MAKE) clean
	cd klibc; $(MAKE) clean

clean:
	rm -rf $(BUILD_DIR) $(LIBC_TARGET) $(ELF) $(OUTPUT)

$(LIBC_TARGET):
	cd klibc; $(MAKE)

%.srec: %.elf
	$(OBJCOPY) -O srec $< $@

$(MAIN_ELF): $(MAIN_OBJ) $(LINK_SCRIPT)
	$(CC) $(LDFLAGS) -o $@ -T $(LINK_SCRIPT) $(MAIN_OBJ)

$(MEMCHECK_ELF): $(MEMCHECK_OBJ) $(LINK_SCRIPT)
	$(CC) $(LDFLAGS) -o $@ -T $(LINK_SCRIPT) $(MEMCHECK_OBJ)

$(BOOTSTRAP):
	cd bootstrap; $(MAKE)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)
	
$(BUILD_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: %.s
	$(VASM) -Felf -o $@ $<
