#include "board.h"

int main(int argc, char **argv)
{
	int i=0;

	do
	{
		HW_BOARD(REG_HEX)=i++;
	} while(1);
	
	return(0);
}

