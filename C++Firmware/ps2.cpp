#include <stdio.h>
#include <stdlib.h>

#include "ps2.h"

PS2Device PS2_Keyboard(PER_PS2_KEYBOARD);
PS2Device PS2_Mouse(PER_PS2_MOUSE);

void PS2Device::IntHandler()
{
	int v1=HW_PER(PER_PS2_KEYBOARD);
	int v2=HW_PER(PER_PS2_MOUSE);

	if(PS2_Keyboard.outbuffer.ReadReady())
	{
		if (v1&PER_PS2_CTS)
		{
			HW_PER(PER_PS2_KEYBOARD)=PS2_Keyboard.outbuffer.GetC();
			PS2_Keyboard.intpending=true;
		}
	}
	else
		PS2_Keyboard.intpending=false;

	if(v1&(1<<PER_PS2_RECV))
	{
		if(PS2_Keyboard.inbuffer.WriteReady())
			PS2_Keyboard.inbuffer.PutC(v1&255);
	}

	if(PS2_Mouse.outbuffer.ReadReady())
	{
		if (v2&PER_PS2_CTS)
		{
			HW_PER(PER_PS2_MOUSE)=PS2_Mouse.outbuffer.GetC();
			PS2_Mouse.intpending=true;
		}
	}
	else
		PS2_Mouse.intpending=false;

	if(v2&(1<<PER_PS2_RECV))
	{
		if(PS2_Mouse.inbuffer.WriteReady())
			PS2_Mouse.inbuffer.PutC(v2&255);
	}
}

