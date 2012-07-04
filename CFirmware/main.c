#include <stdio.h>

#include "minisoc_hardware.h"
#include "ints.h"

#define HEX 0x810006

short *myfb[648*480];


struct ps2_ringbuffer
{
	volatile int in_hw;
	volatile int in_cpu;
	volatile int out_hw;
	volatile int out_cpu;
	unsigned char buf[8];
};

void ps2_ringbuffer_init(struct ps2_ringbuffer *r)
{
	r->in_hw=0;
	r->in_cpu=0;
	r->out_hw=0;
	r->out_cpu=0;
}

void ps2_ringbuffer_write(struct ps2_ringbuffer *r,unsigned char in)
{
	while(r->out_hw==((r->out_cpu+1)&7))
		;
	r->buf[r->out_cpu]=in;
	r->out_cpu=(r->out_cpu+1) & 7;
}


short ps2_ringbuffer_read(struct ps2_ringbuffer *r)
{
	unsigned char result;
	if(r->in_hw==r->in_cpu)
		return(-1);	// No characters ready
	result=r->buf[r->in_cpu];
	r->in_cpu=(r->in_cpu+1) & 7;
	return(result);
}

short ps2_ringbuffer_count(struct ps2_ringbuffer *r)
{
	if(r->in_hw>=r->in_cpu)
		return(r->in_hw-r->in_cpu);
	return(r->in_hw+8-r->in_cpu);
}


void SetIntHandler(short interrupt, void(*handler)())
{
	if(interrupt>0 && interrupt<=7)
	{
		void (**h)()=&IntHandler1;
		h[interrupt-1]=handler;
	}
}

struct ps2_ringbuffer kbbuffer;
struct ps2_ringbuffer mousebuffer;

void PS2Handler()
{
	short kbd=HW_PER(PER_PS2_KEYBOARD);
	short mouse=HW_PER(PER_PS2_MOUSE);

	if(kbd & (1<<PER_PS2_RECV))
	{
		kbbuffer.buf[kbbuffer.in_hw]=(unsigned char)kbd;
		kbbuffer.in_hw=(kbbuffer.in_hw+1) & 7;
	}
	if((kbd & (1<<PER_PS2_CTS)) && kbbuffer.out_hw!=kbbuffer.out_cpu)
	{
		HW_PER(PER_PS2_KEYBOARD)=kbbuffer.buf[kbbuffer.out_hw];
		kbbuffer.out_hw=(kbbuffer.out_hw+1) & 7;
	}
	if(mouse & (1<<PER_PS2_RECV))
	{
		mousebuffer.buf[mousebuffer.in_hw]=(unsigned char)mouse;
		mousebuffer.in_hw=(mousebuffer.in_hw+1) & 7;
	}
	if((mouse & (1<<PER_PS2_CTS)) && mousebuffer.out_hw!=mousebuffer.out_cpu)
	{
		HW_PER(PER_PS2_MOUSE)=mousebuffer.buf[mousebuffer.out_hw];
		mousebuffer.out_hw=(mousebuffer.out_hw+1) & 7;
	}

}


static short framecount=0;
short MouseX=0,MouseY=0;

void vblank_int()
{
	framecount++;
	HW_VGA_L(FRAMEBUFFERPTR)=(unsigned long)(myfb+framecount);
	HW_VGA(SP0XPOS)=MouseX;
	HW_VGA(SP0YPOS)=MouseY;
}


int c_entry()
{
	short counter=0;

	SetSprite();

	HW_VGA_L(FRAMEBUFFERPTR)=(unsigned long)myfb;

	SetIntHandler(VGA_INT_VBLANK,&vblank_int);
	SetIntHandler(PER_INT_PS2,&PS2Handler);
	EnableInterrupts();

	while(ps2_ringbuffer_read(&mousebuffer)>-1)
		; // Drain the buffer;
	ps2_ringbuffer_write(&mousebuffer,0xf4);
	while(ps2_ringbuffer_read(&mousebuffer)>-1)
		; // Read the acknowledge byte

	while(1)
	{
		if(ps2_ringbuffer_count(&mousebuffer)>=3)
		{
			short nx;
			short w1,w2,w3;
			w1=ps2_ringbuffer_read(&mousebuffer);
			w2=ps2_ringbuffer_read(&mousebuffer);
			w3=ps2_ringbuffer_read(&mousebuffer);
			if(w1 & (1<<5))
				w3|=0xff00;
			if(w1 & (1<<4))
				w2|=0xff00;
			HW_PER(PER_HEX)=(w2<<8)|(w3 & 255);

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

		++counter;
		printf("Hello world! Iteration %d\n",counter);
	}
}

