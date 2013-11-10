ARCH=68000
CC=m68k-elf-gcc
VASM=vasmm68k_mot
LD=m68k-elf-ld
OBJCOPY=m68k-elf-objcopy
SRECCAT=srec_cat

BOOTSTRAPSRC=bootstrap.s 
BOOTSTRAP=bootstrap.elf
BOOTSTRAPSREC=bootstrap.srec
BOOTSTRAPMIF=bootstrap.mif

RAMTESTSRC=ramtest.s 
RAMTEST=ramtest.elf
RAMTESTSREC=ramtest.srec
RAMTESTMIF=ramtest.mif

SDBOOTSTRAP_CSRC=spi.c
SDBOOTSTRAP_ASRC=sdbootstrap.s
C_OBJ=$(patsubst %.c,%.o,$(SDBOOTSTRAP_CSRC))
A_OBJ=$(patsubst %.s,%.o,$(SDBOOTSTRAP_ASRC))
SDBOOTSTRAPOBJ=$(A_OBJ)
SDBOOTSTRAP=sdbootstrap.elf
SDBOOTSTRAPSREC=sdbootstrap.srec
SDBOOTSTRAPMIF=sdbootstrap.mif

all:  $(BOOTSTRAPMIF) $(SDBOOTSTRAPMIF) $(RAMTESTMIF)

clean:
	rm $(BOOTSTRAP) $(BOOTSTRAPSREC) $(SDBOOTSTRAPSREC) $(SDBOOTSTRAPOBJ) $(SDBOOTSTRAP) $(BOOTSTRAPMIF) $(SDBOOTSTRAPMIF)


%.elf: %.s
	$(VASM) -m68000 -Felf -o $@ $<

%.o: %.s
	$(VASM) -m68000 -Felf -o $@ $<

%.o: %.c
	$(CC) -O1 -c -o $@ $<

%.srec: %.elf
	$(OBJCOPY) -O srec $< $@

%.mif: %.srec
	$(SRECCAT) $< -o $@ -mif 16

$(SDBOOTSTRAP): $(SDBOOTSTRAPOBJ)
	$(LD) -T ldscript.ld -o $@ $(SDBOOTSTRAPOBJ)


