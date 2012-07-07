#include <stdio.h>
#include <malloc.h>

#include "minisoc_hardware.h"
#include "ints.h"
#include "ps2.h"
#include "keyboard.h"
#include "textbuffer.h"

short *FrameBuffer;

void extern DrawIteration();

static short framecount=0;
short MouseX=0,MouseY=0;

void vblank_int()
{
	int yoff;
	framecount++;
	if(framecount==959)
		framecount=0;
	if(framecount>=480)
		yoff=959-framecount;
	else
		yoff=framecount;
	HW_VGA_L(FRAMEBUFFERPTR)=(unsigned long)(&FrameBuffer[yoff*640]);

	while(PS2MouseBytesReady()>=3)
	{
		short nx;
		short w1,w2,w3;
		w1=PS2MouseRead();
		w2=PS2MouseRead();
		w3=PS2MouseRead();
//		printf("%02x %02x %02x\n",w1,w2,w3);
		if(w1 & (1<<5))
			w3|=0xff00;
		if(w1 & (1<<4))
			w2|=0xff00;
//			HW_PER(PER_HEX)=(w2<<8)|(w3 & 255);

		nx=MouseX+w2;
		if(nx<0)
			nx=0;
		if(nx>639)
			nx=639;
		MouseX=nx;

		nx=MouseY-w3;
		if(nx<0)
			nx=0;
		if(nx>479)
			nx=479;
		MouseY=nx;
	}
	HW_VGA(SP0XPOS)=MouseX;
	HW_VGA(SP0YPOS)=MouseY;

	if(PS2KeyboardBytesReady())
		HandlePS2RawCodes();
}


int c_entry()
{
	short counter=0;
	void *ptr=0;

	ClearTextBuffer();
	printf("Heap_low: %lx, heap_top: %lx\n",&heap_low,&heap_top);
	malloc_add(&heap_low, &heap_top-&heap_low);

	PS2Init();
	SetSprite();

	FrameBuffer=malloc(sizeof(short)*640*960);

	HW_VGA_L(FRAMEBUFFERPTR)=FrameBuffer;

	EnableInterrupts();

	while(PS2MouseRead()>-1)
		; // Drain the buffer;
	PS2MouseWrite(0xf4);
	while(PS2MouseRead()!=0xfa)
		; // Read the acknowledge byte

	// Don't set the VBlank int handler until the mouse has been initialised.
	SetIntHandler(VGA_INT_VBLANK,&vblank_int);


	while((ptr=malloc(262144)))
	{
//		printf("Allocated %ld\n",(long)ptr);
		++counter;
	}
	printf("malloc() returned zero after %d iterations\n",counter);

	while(1)
	{
		DrawIteration();

//		++counter;
//		printf("Hello world! Iteration %d\n",counter);
	}
}

