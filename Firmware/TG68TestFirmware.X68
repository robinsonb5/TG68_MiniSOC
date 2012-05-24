*-----------------------------------------------------------
* Program    : TG68TestFirmware
* Written by : Alastair M. Robinson
* Date       : 2012-05-22
* Description: Simple program to test the TG68 processor.
*-----------------------------------------------------------

PEN equ $ffffe
FRAMEBUFFER equ	$100000
FB_WIDTH equ 640
FB_HEIGHT equ 480

	ORG	$0
	dc.l	$7ffffe		; Initial stack pointer
	dc.l	START
	
START:				; first instruction of program
	move.w	#$3803,pen
	bsr	FillScreen

	move.l	#0,d0
	move.l	#1,d1
.mainloop
	add.w	#1,pen
	add.l	#17,d0
	add.l	#37,d1
	and.l	#511,d0
	and.l	#255,d1
	bsr	Plot
	bra	.mainloop

	MOVE.B	#9,D0
	TRAP	#15		; halt simulator


Plot				; X: d0, y: d1
	movem.l	a0/d0-d1,-(a7)
	lea	FRAMEBUFFER,a0
	mulu	#FB_WIDTH*2,d1
	asl.l	#1,d0
	add.l	d1,d0
	add.l	d0,a0
	move.w	pen,(a0)
	movem.l	(a7)+,a0/d0-d1
	rts

FillScreen
	movem.l	a0-a4/d1-d4,-(a7)
	lea	FRAMEBUFFER,a0
	move.l	#FB_HEIGHT,d0
	mulu	#FB_WIDTH,d0
	move.l	d0,FRAMEBUFFER
	add.l	d0,a0
	add.l	d0,a0		; Point to end of buffer
	lsr.l	#4,d0		; We're moving 16 bytes at a time
	move.w	pen,d1
	swap	d1
	move.w	pen,d1
	move.l	d1,d2
	move.l	d1,d3
	move.l	d1,d4
	move.l	d1,a1
	move.l	d1,a2
	move.l	d1,a3
	move.l	d1,a4
.fillloop
	movem.l	a1-a4/d1-d4,-(a0)
	sub.l	#1,d0
	bne	.fillloop
	movem.l	(a7)+,a0-a4/d1-d4
	rts
		
	END	START		; last line of source









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
