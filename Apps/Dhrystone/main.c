#include "vga.h"
#include "ints.h"
#include "uart.h"
#include "dhry.h"
#include "board.h"

int microseconds=0;
static int msinc;
void vblank_int()
{
//	microseconds+=(16667*1250)/HW_PER(PER_CAP_CLOCKSPEED);	// Assumes 60Hz video mode.
	microseconds+=msinc;
}


int main(int argc,char **argv)
{
	unsigned char *fbptr;

	msinc=(16667*1250)/HW_BOARD(REG_CAP_CLOCKSPEED);	// Assumes 60Hz video mode.

	SetIntHandler(VGA_INT_VBLANK,&vblank_int);
	EnableInterrupts();

	Dhrystone();
}

