C_SRC=main.c minisoc_hardware.c textbuffer.c textbuffer.h ints.c ints.h ps2.c ps2.h keyboard.c keyboard.h
KLIBC_SRC=vsnprintf.c sprintf.c memcpy.c memcmp.c strcpy.c strcat.c strncat.c strncmp.c strlen.c memset.c strncpy.c strchr.c
A_SRC=startup.s draw.s

BUILD_DIR=BUILD
C_OBJ=$(patsubst %.c,$(BUILD_DIR)/%.o,$(C_SRC))
LIBC_OBJ=$(patsubst %.c,$(BUILD_DIR)/%.o,$(KLIBC_SRC))
A_OBJ=$(patsubst %.s,$(BUILD_DIR)/%.o,$(A_SRC))
OBJ= $(A_OBJ) $(C_OBJ)

ARCH=68000
CC=m68k-elf-gcc
AR=m68k-elf-ar
VASM=vasmm68k_mot
OBJCOPY=m68k-elf-objcopy
CFLAGS+=-m$(ARCH) -Wall -Wno-char-subscripts -Os -fno-common -fomit-frame-pointer -I./include
LDFLAGS+=-m$(ARCH) -Xlinker -Map=menu.map -nostartfiles -L.

ELF=out.elf
OUTPUT=out.srec
LINK_SCRIPT=ldscript.ld
LIBC_TARGET=libc.a

BOOTSTRAP=bootstrap/bootstrap.mif

all: $(BUILD_DIR) $(LIBC_TARGET) $(OUTPUT) $(BOOTSTRAP)

clean:
	rm -rf $(BUILD_DIR) $(LIBC_TARGET) $(ELF) $(OUTPUT)
	cd bootstrap; $(MAKE) clean

$(LIBC_TARGET): $(LIBC_OBJ)
	$(AR) -r $(LIBC_TARGET) $(LIBC_OBJ)

$(OUTPUT): $(ELF)
	$(OBJCOPY) -O srec $(ELF) out.srec

$(ELF): $(OBJ) $(LINK_SCRIPT)
	$(CC) $(LDFLAGS) -o $@ -T $(LINK_SCRIPT) $(OBJ)

$(BOOTSTRAP):
	cd bootstrap; $(MAKE)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)
	
$(BUILD_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: klibc/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: %.s
	$(VASM) -Felf -o $@ $<
