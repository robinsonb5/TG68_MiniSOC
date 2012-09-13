#ifndef SERIAL_H
#define SERIAL_H

#include <hardware/minisoc_hardware.h>
#include <hardware/uart.h>
#include <hardware/ints.h>

#include "ringbuffer.h"

// TODO -
// Get system clock speed from hardware (needs hardware support)
// Use a ring buffer and interrupt routine for reading/writing

class RS232Serial
{
	public:
	RS232Serial(volatile unsigned short *base=(volatile unsigned short *)PERIPHERALBASE)
		: base(base), intpending(false), outgoing(8), incoming(8)
	{
		SetIntHandler(PER_INT_UART,IntHandler);
	}

	~RS232Serial()
	{
		SetIntHandler(PER_INT_UART,0);
	}

	void SetBaud(int baud=115200)
	{
		// FIXME - get system clock speed from hardware.
		int clk=256; // Master clock speed, in MHz, shifted left 8 bits
		// FIXME - if we add a second UART, we'll need to employ the base pointer.
		HW_PER(PER_UART_CLKDIV)=(clk*1000000)/(baud<<8);
		
	}

	// FIXME - make this a stream superclass
	void PutC(char c)
	{
		DisableInterrupts();
		if(intpending)
		{
			// If we know an interrupt is pending, we just tack in the incoming character onto the end of the ringbuffer
			outgoing.Write(c);
		}
		else
		{
			// If there's no interrupt pending, we write immediately
			while(!((HW_PER(PER_UART)&(1<<PER_UART_TXREADY))))
				;
			HW_PER(PER_UART)=c;
			intpending=true;
		}
		EnableInterrupts();
	}
	void PutS(const char *s)
	{
		char c;
		while((c=*s++))
			PutC(c);
	}
	static void IntHandler();
	protected:
	volatile unsigned short *base;
	bool intpending;
	RingBuffer outgoing;
	RingBuffer incoming;
};

extern RS232Serial RS232;

#endif

