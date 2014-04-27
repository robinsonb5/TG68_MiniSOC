#include <stdio.h>
#include <string.h>
#include <malloc.h>

#include "minisoc_hardware.h"
#include "ints.h"
#include "ps2.h"
#include "keyboard.h"
#include "textbuffer.h"
//#include "uart.h"
#include "vga.h"

short *FrameBuffer;

static short framecount=0;
short MouseX=0,MouseY=0,MouseZ=0,MouseButtons=0;
short mousetimeout=0;

void vblank_int()
{
	static short mousemode=0;
	char a=0;

	while(PS2MouseBytesReady()>=(3+mousemode))	// FIXME - institute some kind of timeout here to re-sync if sync lost.
	{
		short nx;
		short w1,w2,w3,w4;
		w1=PS2MouseRead();
		w2=PS2MouseRead();
		w3=PS2MouseRead();
		if(mousemode)	// We're in 4-byte packet mode...
		{
			w4=PS2MouseRead();
			if(w4&8)	// Negative
				MouseZ-=(w4^15)&15;
			else
				MouseZ+=w4&15;
		}
		MouseButtons=w1;
		if(w1 & (1<<5))
			w3|=0xff00;
		if(w1 & (1<<4))
			w2|=0xff00;

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

		mousetimeout=0;
	}
	HW_VGA(SP0XPOS)=MouseX;
	HW_VGA(SP0YPOS)=MouseY;

	// Clear any incomplete packets, to resync the mouse if comms break down.
	if(PS2MouseBytesReady())
	{
		++mousetimeout;
		if(mousetimeout==20)
		{
			while(PS2MouseBytesReady())
				PS2MouseRead();
			mousetimeout=0;
			mousemode^=1;	// Toggle 3/4 byte packets
		}
	}

	// Receive any keystrokes
	if(PS2KeyboardBytesReady())
	{
		while((a=HandlePS2RawCodes()))
		{
			char buf[2]={0,0};
			HW_PER(PER_UART)=a;
			buf[0]=a;
			puts(buf);
		}
	}
}


void timer_int()
{
	if(HW_PER(PER_TIMER_CONTROL) & (1<<PER_TIMER_TR5))
		mousetimeout=1;
//	puts("Timer int received\n");
}


void SetTimeout(int delay)
{
	HW_PER(PER_TIMER_CONTROL)=(1<<PER_TIMER_EN5);
	HW_PER(PER_TIMER_DIV5)=delay;
}


extern char heap_low;
void AddMemory()
{
	size_t low;
	size_t size;
	low=(size_t)&heap_low;
	low+=15;
	low&=0xfffffff0; // Align to SDRAM burst boundary
	size=1L<<HW_PER(PER_CAP_RAMSIZE);
	size-=low;
	size-=0x1000; // Leave room for the stack
	printf("Heap_low: %lx, heap_size: %lx\n",low,size);
	malloc_add((void*)low,size);
}


enum Screenmodes {
	MODE_640_480,
	MODE_320_480,
	MODE_800_600,
	MODE_768_576
};

void SetMode(enum Screenmodes mode)
{
	switch(mode)
	{
		case MODE_640_480:
			HW_VGA(VGA_HTOTAL)=800;
			HW_VGA(VGA_HSIZE)=640;
			HW_VGA(VGA_HBSTART)=656;
			HW_VGA(VGA_HBSTOP)=752;
			HW_VGA(VGA_VTOTAL)=525;
			HW_VGA(VGA_VSIZE)=480;
			HW_VGA(VGA_VBSTART)=500;
			HW_VGA(VGA_VBSTOP)=502;
			HW_VGA(VGA_CONTROL)=0x87;
			break;	

		case MODE_320_480:
			HW_VGA(VGA_HTOTAL)=400;
			HW_VGA(VGA_HSIZE)=320;
			HW_VGA(VGA_HBSTART)=328;
			HW_VGA(VGA_HBSTOP)=376;
			HW_VGA(VGA_VTOTAL)=525;
			HW_VGA(VGA_VSIZE)=480;
			HW_VGA(VGA_VBSTART)=490;
			HW_VGA(VGA_VBSTOP)=492;
			HW_VGA(VGA_CONTROL)=0x8d;
			break;

		case MODE_800_600:
			HW_VGA(VGA_HTOTAL)=1024;
			HW_VGA(VGA_HSIZE)=800;
			HW_VGA(VGA_HBSTART)=824;
			HW_VGA(VGA_HBSTOP)=896;
			HW_VGA(VGA_VTOTAL)=625;
			HW_VGA(VGA_VSIZE)=600;
			HW_VGA(VGA_VBSTART)=601;
			HW_VGA(VGA_VBSTOP)=602;
			HW_VGA(VGA_CONTROL)=0x85;
		break;

		case MODE_768_576:
			HW_VGA(VGA_HTOTAL)=976;
			HW_VGA(VGA_HSIZE)=768;
			HW_VGA(VGA_HBSTART)=792;
			HW_VGA(VGA_HBSTOP)=872;
			HW_VGA(VGA_VTOTAL)=597;
			HW_VGA(VGA_VSIZE)=576;
			HW_VGA(VGA_VBSTART)=577;
			HW_VGA(VGA_VBSTOP)=580;
			HW_VGA(VGA_CONTROL)=0x85;
			break;
	}
}


void DrawTestcard(short *fbptr,int w, int h)
{
	int x,y;

	for(y=0;y<(h/4);++y)
	{
		for(x=0;x<(w/2);++x)
			*fbptr++=0xffff;
		for(;x<w;++x)
			*fbptr++=0x0;
	}
	for(;y<(3*h/4);++y)
	{
		int g=y-h/4;
		for(x=0;x<w;++x)
		{
			*fbptr++=((x&31)<<11)|(g&63)<<5|((x+y)&31);
		}
	}
	for(;y<h;++y)
	{
		for(x=0;x<(w/2);++x)
			*fbptr++=0xffff;
		for(;x<w;++x)
			*fbptr++=0x0;
	}
}


int main(int argc,char *argv)
{
	unsigned char *fbptr;
	ClearTextBuffer();

	HW_PER(PER_UART_CLKDIV)=(1000*HW_PER(PER_CAP_CLOCKSPEED))/1152;

	AddMemory();

	PS2Init();
	SetSprite();

	FrameBuffer=(short *)malloc(sizeof(short)*800*600+15);
	FrameBuffer=(short *)(((int)FrameBuffer+15)&~15); // Align to nearest 16 byte boundary.
	HW_VGA_L(FRAMEBUFFERPTR)=FrameBuffer;

	SetMode(MODE_800_600);
	DrawTestcard(FrameBuffer,800,600);

	EnableInterrupts();

	while(PS2MouseRead()>-1)
		; // Drain the buffer;
	PS2MouseWrite(0xf4);

	SetIntHandler(PER_INT_TIMER,&timer_int);
	SetTimeout(10000);
	while(PS2MouseRead()!=0xfa && mousetimeout==0)
		; // Read the acknowledge byte

	if(mousetimeout)
		puts("Mouse timed out\n");

	// Don't set the VBlank int handler until the mouse has been initialised.
	SetIntHandler(VGA_INT_VBLANK,&vblank_int);

	while(1)
	{
		if(TestKey(KEY_F1))
		{
			puts("640 x 480\n");
			SetMode(MODE_640_480);
			DrawTestcard(FrameBuffer,640,480);
			while(TestKey(KEY_F1))
				;
		}
		if(TestKey(KEY_F2))
		{
			puts("320 x 480\n");
			SetMode(MODE_320_480);
			DrawTestcard(FrameBuffer,320,480);

			while(TestKey(KEY_F2))
				;
		}
		if(TestKey(KEY_F3))
		{
			puts("800 x 600\n");
			SetMode(MODE_800_600);
			DrawTestcard(FrameBuffer,800,600);
			while(TestKey(KEY_F3))
				;
		}
		if(TestKey(KEY_F4))
		{
			puts("768 x 576\n");
			SetMode(MODE_768_576);
			DrawTestcard(FrameBuffer,768,576);
			while(TestKey(KEY_F4))
				;
		}

	}
}
