#ifndef BOARD_H
#define BOARD_H

#define PERIPHERALBASE 0x81000000
#define HW_PER(x) *(volatile unsigned short *)(PERIPHERALBASE+x)

/* Capability registers */

#define PER_CAP_RAMSIZE 0x28
#define PER_CAP_CLOCKSPEED 0x2A
#define PER_CAP_SPISPEED 0x2C

#endif

