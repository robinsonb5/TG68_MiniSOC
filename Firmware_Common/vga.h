#ifndef MINISOC_VGA_H
#define MINISOC_VGA_H

#define VGABASE 0x80000000

#define FRAMEBUFFERPTR 0

#define SP0PTR 0x100
#define SP0XPOS 0x104
#define SP0YPOS 0x106

#define HW_VGA(x) *(volatile unsigned short *)(VGABASE+x)
#define HW_VGA_L(x) *(volatile unsigned long *)(VGABASE+x)
#define VGA_INT_VBLANK 1

/*
4	Word	Even row modulo (not yet implemented)

6	Word	Odd row modulo (not yet implemented)

8	Word	HTotal -  the total number of pixel clocks in a scanline (not yet implemented)

A	Word	HSize – number of horizontal pixels displayed (not yet implemented)

C	Word	HBStart – start of the horizontal blank (not yet implemented)

E	Word	HBStop – end of the horizontal blanking period. (Not yet implemented)

10	Word	Vtotal – the number of scanlines in a frame (not yet implemented)

12	Word	Vsize – the number of displayed scanlines  (not yet implemented)

14	Word	Vbstart – start of the vertical blanking period  (not yet implemented)

16	Word	Vbstop – end of the vertical blanking period  (not yet implemented)

18	Word	Control  (not yet implemented)
		bit 7	Character overlay on/off  (not yet implemented)
		bit 1	resolution – 1: high, 0: low   (not yet implemented)
		bit 0	visible.  (not yet implemented)
*/

#define VGACHARBUFFERBASE 0x80000800
extern char *VGACharBuffer;

void SetSprite();

#endif

