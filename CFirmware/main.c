#include <stdio.h>
#include <string.h>
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
short mousetimeout=0;

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

void timer_int()
{
	if(HW_PER(PER_TIMER_CONTROL) & (1<<PER_TIMER_TR5))
		mousetimeout=1;
	printf("Timer int received\n");
}


void SetTimeout(int delay)
{
	HW_PER(PER_TIMER_CONTROL)=(1<<PER_TIMER_EN5);
	HW_PER(PER_TIMER_DIV5)=delay;
}


void AddMemory()
{
	size_t low;
	size_t size;
	low=(size_t)&heap_low;
	low+=15;
	low&=0xfffffff8; // Align to SDRAM burst boundary
	size=((char*)&heap_top)-low;
	printf("Heap_low: %lx, heap_size: %lx\n",low,size);
	malloc_add((void*)low,size);
}


int c_entry()
{
	short counter=0;
	void *ptr=0;
	ClearTextBuffer();

	AddMemory();

	PS2Init();
	SetSprite();

	FrameBuffer=(short *)malloc(sizeof(short)*640*960);
	HW_VGA_L(FRAMEBUFFERPTR)=FrameBuffer;

	memset(FrameBuffer,0,sizeof(short)*640*960);

	EnableInterrupts();

	while(PS2MouseRead()>-1)
		; // Drain the buffer;
	PS2MouseWrite(0xf4);

	SetIntHandler(PER_INT_TIMER,&timer_int);
	SetTimeout(10000);
	while(PS2MouseRead()!=0xfa && mousetimeout==0)
		; // Read the acknowledge byte

	if(mousetimeout)
		printf("Mouse timed out\n");

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

