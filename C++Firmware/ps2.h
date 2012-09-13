#ifndef PS2_H
#define PS2_H

#include <hardware/minisoc_hardware.h>
#include <hardware/ps2regs.h>
#include <hardware/ints.h>

#include "chardevice.h"

class PS2Device : public CharDevice
{
	public:
	PS2Device(int device=PER_PS2_KEYBOARD) : CharDevice(8), device(device), intpending(false)
	{
		while(!((HW_PER(device)&(1<<PER_PS2_CTS))))
			;
		SetIntHandler(PER_INT_PS2,IntHandler);
	}
	virtual ~PS2Device()
	{
		SetIntHandler(PER_INT_UART,0);
	}
	virtual int Write(const char *buf,int len)
	{
		int result=0;
		DisableInterrupts();
		if(!intpending)
		{
			HW_PER(device)=*buf++;
			--len;
			result=1;
			intpending=true;
		}			
		result+=CharDevice::Write(buf,len);
		EnableInterrupts();
		return(result);
	}

	virtual int Read(char *buf,int len)
	{
		int result;
		DisableInterrupts();
		result=CharDevice::Read(buf,len);
		EnableInterrupts();
		return(result);
	}

	static void IntHandler();
	protected:
	int device;
	bool intpending;
};

extern PS2Device PS2_Keyboard;
extern PS2Device PS2_Mouse;

#endif
