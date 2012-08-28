ARCH=68000
VASM=vasmm68k_mot
LD=m68k-elf-ld
OBJCOPY=m68k-elf-objcopy
SRECCAT=srec_cat

BOOTSTRAPSRC=bootstrap.s
BOOTSTRAP=bootstrap.elf
BOOTSTRAPSREC=bootstrap.srec
BOOTSTRAPMIF=bootstrap.mif

SDBOOTSTRAPSRC=sdbootstrap.s
SDBOOTSTRAPOBJ=sdbootstrap.o
SDBOOTSTRAP=sdbootstrap.elf
SDBOOTSTRAPSREC=sdbootstrap.srec
SDBOOTSTRAPMIF=sdbootstrap.mif

all:  $(BOOTSTRAPMIF) $(SDBOOTSTRAPMIF)

clean:
	rm $(BOOTSTRAP) $(BOOTSTRAPSREC) $(BOOTSTRAPMIF) $(SDBOOTSTRAPMIF)

$(BOOTSTRAP): $(BOOTSTRAPSRC)
	$(VASM) -showopt -m68000 -Felf -o $@ $<

$(SDBOOTSTRAPOBJ): $(SDBOOTSTRAPSRC)
	$(VASM) -showopt -m68000 -Felf -o $@ $<

$(SDBOOTSTRAP): $(SDBOOTSTRAPOBJ)
	$(LD) -T ldscript.ld -o $@ $<

$(BOOTSTRAPSREC): $(BOOTSTRAP)
	$(OBJCOPY) -O srec $< $@

$(SDBOOTSTRAPSREC): $(SDBOOTSTRAP)
	$(OBJCOPY) -O srec $< $@

$(BOOTSTRAPMIF): $(BOOTSTRAPSREC)
	$(SRECCAT) $< -o $@ -mif 16

$(SDBOOTSTRAPMIF): $(SDBOOTSTRAPSREC)
	$(SRECCAT) $< -o $@ -mif 16
