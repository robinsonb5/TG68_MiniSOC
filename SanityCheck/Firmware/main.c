#include "uart.h"

int main(int argc, char **argv)
{
	HW_UART(REG_UART_CLKDIV)=(HW_UART(REG_CAP_FREQ)*1000)/1152;
	puts("Hello, world!\n");
	return(0);
}

