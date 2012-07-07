ARCH=68000
VASM=vasmm68k_mot
OBJCOPY=m68k-elf-objcopy
SRECCAT=srec_cat

BOOTSTRAPSRC=bootstrap.s
BOOTSTRAP=bootstrap.elf
BOOTSTRAPSREC=bootstrap.srec
BOOTSTRAPMIF=bootstrap.mif

all:  $(BOOTSTRAPMIF)

clean:
	rm $(BOOTSTRAP) $(BOOTSTRAPSREC) $(BOOTSTRAPMIF)

$(BOOTSTRAP): $(BOOTSTRAPSRC)
	$(VASM) -Felf -o $@ $<

$(BOOTSTRAPSREC): $(BOOTSTRAP)
	$(OBJCOPY) -O srec $< $@

$(BOOTSTRAPMIF): $(BOOTSTRAPSREC)
	$(SRECCAT) $< -o $@ -mif 16
