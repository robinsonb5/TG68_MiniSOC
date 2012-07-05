SECTIONS
{
	. = 0x100;
	CODE : {
	  BUILD/startup.o	/* VASM assembled */
	}
	.code : {
	  *(.text)
	  *(.rodata)
	  *(.rodata.*)
	  *(.data)
	}
	.extra : {
		__s_bss = . ;
	  *(.bss)
	  	__e_bss = . ;
	}
	.eh_frame : {
	  *(.eh_frame)
	}
	heap_low = .; /* for _sbrk */
	. = . + 0x1000; /* 64kB of heap memory */
	heap_top = .; /* for _sbrk */

	stack_top = 0x7ffffe; /* for startup.s */
	start = 0x100;
}

ENTRY(start)
