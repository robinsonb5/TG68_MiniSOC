#include <stdio.h>

#include "minisoc_hardware.h"
#include "ints.h"
#include "ps2.h"
#include "textbuffer.h"

short *myfb[648*480];


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

	PS2Init();
	ClearTextBuffer();
	SetSprite();

	HW_VGA_L(FRAMEBUFFERPTR)=(unsigned long)myfb;


	SetIntHandler(VGA_INT_VBLANK,&vblank_int);
	EnableInterrupts();

	while(PS2MouseRead()>-1)
		; // Drain the buffer;
	PS2MouseWrite(0xf4);
	while(PS2MouseRead()!=0xfa)
		; // Read the acknowledge byte

	while(1)
	{
		if(PS2KeyboardBytesReady())
		{
			static short keyup=0;
			static short leds=0;
			short kc=PS2KeyboardRead();
			if(kc==0xf0)
				keyup=1;
			else
			{
				if(kc==0x58 && keyup==0)
				{
					leds^=0x04;
					PS2KeyboardWrite(0xed);
					PS2KeyboardWrite(leds);
				}
				keyup=0;
			}
		}
		if(PS2MouseBytesReady()>=3)
		{
			short nx;
			short w1,w2,w3;
			w1=PS2MouseRead();
			w2=PS2MouseRead();
			w3=PS2MouseRead();
			printf("%02x %02x %02x\n",w1,w2,w3);
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

//		++counter;
//		printf("Hello world! Iteration %d\n",counter);
	}
}

