	incdir	data:AmigaDev/sources/
	include "custom.i"
	include "Gouraud/defines.i"
*********************************************************************
	section	main,CODE_F
Init:
;	bsr	RenderLoop
;	rts
;	bra	mm

	move.l	4.w,a6		; execbase
	clr.l	d0
	move.l	#gfxname,a1
	jsr	-408(a6)	; eld open library
	move.l	d0,a1
	move.l	38(a1),d4	; original copperaddr
	move.l	d4,org_copper

	jsr	-414(a6)	; close library

	move.w	$dff01c,d0
	move.w	d0,org_intena
	move.w	$dff002,d0
	move.w	d0,org_dmacon

	move.w	#$0138,d0
	bsr.w	WaitRaster

	move.w	#$7fff,$dff09a	; disable all bits in INTENA
	move.w	#$7fff,$dff09c	; disable all bits in INTREQ
	move.w	#$7fff,$dff09c	; disable all bits in INTREQ
	move.w	#$7fff,$dff096	; disable all bits in DMACON
	move.w	#$87c0,$dff096

	move.l	$6c.w,org_int3
	move.l	#IntLevel3,$6c.w

	move.w	#$c060,$dff09a
;---------Bitplane init ----------

	lea	Bitplane1,a0
	move.l	#Screen1,d0
	move.l	#Planes-1,d1
.l1:
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	#ScreenWidth/8*ScreenHeight,d0
	add.l	#8,a0
	dbf	d1,.l1

	lea	Bitplane2,a0
	move.l	#Screen2,d0
	move.l	#Planes-1,d1
.l2:
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	#ScreenWidth/8*ScreenHeight,d0
	add.l	#8,a0
	dbf	d1,.l2

	lea	Bitplane3,a0
	move.l	#Screen3,d0
	move.l	#Planes-1,d1
.l3:
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	#ScreenWidth/8*ScreenHeight,d0
	add.l	#8,a0
	dbf	d1,.l3

	lea	Palette,a0
	lea	ColorCopper1+2,a1
	lea	ColorCopper2+2,a2
	lea	ColorCopper3+2,a3
	move.w	#32-1,d7
clo:	move.w	(a0)+,d0
	move.w	d0,(a1)
	move.w	d0,(a2)
	move.w	d0,(a3)
	add	#4,a1
	add	#4,a2
	add	#4,a3
	dbf	d7,clo

	bsr	InitMasks
	
;	d0 = x0, d1 = y0
;	d2 = x1, d3 = y1
;	d4 = ScreenWidth
;	a0 = ScreenPtr

;	move.l	#$ffffffff,Screen1
;	move.l	#$ffffffff,Screen1+ScreenWidth/8*128+24

	move.l	#Copper1,$dff080
mm:
;--------------------------------------------------------------------	
mainloop:
.wframe:
	btst	#0,$dff005
	bne.b	.wframe
	cmp.b	#$2e,$dff006
	bne.b	.wframe
.wframe2:
	cmp.b	#$30,$dff006
	bne.b	.wframe2
;	move.w	#$004,$dff180

	bsr	BlitWait
	move.w	BlitListEnd+2,BlitListEnd
	bsr	StartBlitList

	move.w	Frames,d0
	muls.w	#8,d0
	move.w	d0,sinpos
	;move.w	#0,Frames
	lea	Sinus,a0
	move.w	sinpos,d0
	add.w	d0,d0
	and.w	#SinusSize*2-1,d0
	move.w	(a0,d0.w),d0
	muls.w	#41,d0
	add.l	#128,d0
	asr.l	#8,d0
	add.w	#41,d0
	move.w	d0,XEnd
	
	bsr	RenderLoop

;	bsr BlitWait
;	move.w	#$000,$dff180

	lea	Screens,a0
	bsr	Switch
	lea	Copper,a0
	bsr	Switch

	move.l	Copper,$dff080

	btst	#6,$bfe001
	bne.w	mainloop
exit:
	move.w	#$7fff,$dff096
	move.w	org_dmacon,d0
	or.w	#$8200,d0
	move.w	d0,$dff096
	move.l	org_copper,d0
	move.l	d0,$dff080
	move.w	#$7fff,$dff09a
	move.l	org_int3,$6c.w
	move.w	org_intena,d0
	or.l	#$c000,d0
	move	d0,$dff09a

	rts

;--------------------------------------------------------------------	
WaitRaster:			; wait for rasterline d0.w. Modifies d0-d2/a0
	move.l	#$1ff00,d2
	lsl.l	#8,d0
	and.l	d2,d0
	lea	$dff004,a0
.wr:	move.l	(a0),d1
	and.l	d2,d1
	cmp.l	d1,d0
	bne.s	.wr
	rts
;--------------------------------------------------------------------	
IntLevel3:
	movem.l	d0-a6,-(sp)
	move.w	INTREQR+$dff000,d0
	btst	#6,d0			; Blitter IRG
	bne.b	.blit_handle
	btst	#5,d0
	beq.b	IntLevel3_end
	add.w	#1,Frames
	move.w	#$0020,$dff09c
	move.w	#$0020,$dff09c
	bra.w	IntLevel3_end
.blit_handle:
	move.w	BlitListBeg,d0
	move.w	BlitListEnd,d1
	cmp.w	d0,d1
	bne.b	.blit_next
	move.w	#0,BEnd
	move.w	#$0040,$dff09c
	move.w	#$0040,$dff09c
	bra.b	 IntLevel3_end
.blit_next:
	bsr	StartBlitList
IntLevel3_end:
	movem.l	(sp)+,d0-a6
	rte
;--------------------------------------------------------------------	
BlitWait:
	cmp.w	#0,BEnd
	bne.b	BlitWait
	rts
;--------------------------------------------------------------------	
Switch:
	move.l	(a0),d0
	move.l	4(a0),d1
	move.l	8(a0),d2
	move.l	d1,(a0)
	move.l	d2,4(a0)
	move.l	d0,8(a0)
	rts
;--------------------------------------------------------------------	
InitMasks:
	lea	Mask0,a0
	move.l	#0,a6		; Last Mask
	move.w	#0,d4		; xoffs
	move.w	#0,d5	 	; yoffs
	bsr	.InitMask1

	move.l	a0,a6
	lea	Mask1,a0
	move.w	#1,d4		; xoffs
	move.l	#2,d5		; yoffs
	bsr	.InitMask1

	move.l	a0,a6
	lea	Mask2,a0
	move.w	#2,d4		; xoffs
	move.l	#1,d5		; yoffs
	bsr	.InitMask1

	move.l	a0,a6
	lea	Mask3,a0
	move.w	#2,d4		; xoffs
	move.l	#0,d5		; yoffs
	bsr	.InitMask1

	move.l	a0,a6
	lea	Mask4,a0
	move.w	#0,d4		; xoffs
	move.l	#1,d5		; yoffs
	bsr	.InitMask1

	move.l	a0,a6
	lea	Mask5,a0
	move.w	#0,d4		; xoffs
	move.l	#2,d5		; yoffs
	bsr	.InitMask1

	move.l	a0,a6
	lea	Mask6,a0
	move.w	#1,d4		; xoffs
	move.l	#0,d5		; yoffs
	bsr	.InitMask1

	move.l	a0,a6
	lea	Mask7,a0
	move.w	#1,d4		; xoffs
	move.l	#1,d5		; yoffs
	bsr	.InitMask1

	rts
.InitMask1:
	cmp.l	#0,a6
	beq	.iclm
	move.l	a0,a1
	eor.l	d0,d0
	move.w	#ScreenWidth/8*ScreenHeight/4-1,d7
.clet4:	move.l	(a6)+,(a1)+
	dbf	d7,.clet4
	bra	.clet3
.iclm:
	move.l	a0,a1
	eor.l	d0,d0
	move.w	#ScreenWidth/8*ScreenHeight/4-1,d7
.clet:	move.l	d0,(a1)+
	dbf	d7,.clet
.clet3:	
	move.w	#ScreenHeight/3-1,d7
;	sub.w	d5,d7
	mulu.w	#ScreenWidth/8,d5
	move.l	a0,a1
	add.l	d5,a1
.clet2:	move.w	d4,d1
	move.w	#ScreenWidth/3-1,d6
;	sub.w	d4,d6
.clet1:	move.w	d1,d2
	lsr.w	#3,d2
	move.b	d1,d3
	not.b	d3
	bset	d3,(a1,d2.w)
	add.w	#3,d1
	dbf	d6,.clet1
	add.l	#ScreenWidth/8*3,a1
	dbf	d7,.clet2


	rts
;--------------------------------------------------------------------	
RenderLoop:
	move.l	Screens+8,a1
	move.w	#(ScreenHeight*Planes)*64+((ScreenWidth/16)&63),d0
	bsr	ClrScr
	
	move.l	#LineScreen,a1
	move.w	#(ScreenHeight)*64+((ScreenWidth/16)&63),d0
	bsr	ClrScr

;	move.l	#32,d2	; xstart
;	move.l	#0,d3	; ystart
;	move.l	#32,d0	; xend
;	move.l	#64,d1	; yend
;	move.l	Screens+4,a5
;	bsr	DRAWLINE


SH0 = 0
SH1 = ScreenHeight/3
SH2 = ScreenHeight*2/3
SH3 = ScreenHeight
SH = ScreenHeight-1
ADDS = 2

;----- Render ShadeBackGround

	move.w	#0,d6
	swap	d6
	move.w	XEnd,d6
	swap	d6
	move.w	#4-1,d7
RL_l1:	move.w	d6,d2	; xstart
	move.w	#0,d3	; ystart
	swap	d6
	move.w	d6,d0	; xend
	swap	d6
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE
	add.w	#ADDS*9,d6
	swap	d6	
	add.w	#ADDS*9,d6
	swap	d6
	dbf	d7,RL_l1

	move.l	#LineScreen,d0
	move.l	#FillScreen,d1
	bsr	Fill

	move.l	#FillScreen,d0
	move.l	Screens+8,d1
	move.l	#0,a1
	move.w	#blith*64+blitw,d2
	bsr	Copy

	move.w	#0,d6
	swap	d6
	move.w	XEnd,d6
	swap	d6
	move.w	#4-1,d7
RL_l2:	move.w	d6,d2	; xstart
	move.w	#0,d3	; ystart
	swap	d6
	move.w	d6,d0	; xend
	swap	d6
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE
	add.w	#ADDS*9,d6
	swap	d6	
	add.w	#ADDS*9,d6
	swap	d6
	dbf	d7,RL_l2

	move.w	#ADDS*9,d6
	swap	d6
	move.w	#ADDS*9,d6
	add.w	XEnd,d6
	swap	d6
	move.w	#2-1,d7
RL_l3:	move.w	d6,d2	; xstart
	move.w	#0,d3	; ystart
	swap	d6
	move.w	d6,d0	; xend
	swap	d6
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE
	add.w	#ADDS*9*2,d6
	swap	d6
	add.w	#ADDS*9*2,d6
	swap	d6
	dbf	d7,RL_l3

	move.l	#LineScreen,d0
	move.l	#FillScreen,d1
	bsr	Fill

	move.l	#FillScreen,d0
	move.l	Screens+8,d1
	add.l	#ScreenWidth/8*ScreenHeight,d1
	move.l	#0,a1
	move.w	#blith*64+blitw,d2
	bsr	Copy

	move.w	#ADDS*9,d6
	swap	d6
	move.w	#ADDS*9,d6
	add.w	XEnd,d6
	swap	d6
	move.w	#2-1,d7
RL_l4:	move.w	d6,d2	; xstart
	move.w	#0,d3	; ystart
	swap	d6
	move.w	d6,d0	; xend
	swap	d6
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE
	add.w	#ADDS*9*2,d6
	swap	d6
	add.w	#ADDS*9*2,d6
	swap	d6
	dbf	d7,RL_l4
;--------------
;	rts
;--- Render Color

	move.w	#0,d2	; xstart
	move.w	#0,d3	; ystart
	move.w	XEnd,d0	; xend
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

	move.w	#ADDS*9*3,d2	; xstart
	move.w	#0,d3	; ystart
	move.w	#ADDS*9*3,d0	; xend
	add.w	XEnd,d0
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

	move.l	#LineScreen,d0
	move.l	#FillScreen,d1
	bsr	Fill

	move.l	#FillScreen+ScreenWidth/8*ScreenWidth/4,d0
	move.l	Screens+8,d1
	add.l	#ScreenWidth/8*ScreenHeight*2+ScreenWidth/8*ScreenHeight/4,d1
	move.l	#0,a1
	move.w	#(blith/4)*64+blitw,d2
	bsr	Copy

	move.l	#FillScreen+ScreenWidth/8*ScreenWidth*3/4,d0
	move.l	Screens+8,d1
	add.l	#ScreenWidth/8*ScreenHeight*2+ScreenWidth/8*ScreenHeight*3/4,d1
	move.l	#0,a1
	move.w	#(blith/4)*64+blitw,d2
	bsr	Copy

	move.l	#FillScreen+ScreenWidth/8*ScreenWidth*2/4,d0
	move.l	Screens+8,d1
	add.l	#ScreenWidth/8*ScreenHeight*3+ScreenWidth/8*ScreenHeight*2/4,d1
	move.l	#0,a1
	move.w	#(blith/2)*64+blitw,d2
	bsr	Copy

	move.w	#0,d2	; xstart
	move.w	#0,d3	; ystart
	move.w	XEnd,d0	; xend
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

	move.w	#ADDS*9*3,d2	; xstart
	move.w	#0,d3	; ystart
	move.w	#ADDS*9*3,d0	; xend
	add.w	XEnd,d0
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

;----- Render Gouraud

	lea	Masks,a6
	move.w	#0,d4
	move.w	#0,d6
	swap	d6
	move.w	XEnd,d6
	swap	d6	
	move.l	d6,d7
	add.l	#ADDS+(ADDS<<16),d7

	move.w	#9-1,d5

	move.w	d6,d2	; xstart
	move.w	#0,d3	; ystart
	swap	d6
	move.w	d6,d0	; xend
	swap	d6
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

	move.w	d6,d2	; xstart
	add.w	#ADDS*9,d2
	move.w	#0,d3	; ystart
	swap	d6
	move.w	d6,d0	; xend
	add.w	#ADDS*9,d0
	swap	d6
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

	move.w	d6,d2	; xstart
	add.w	#ADDS*9*2,d2
	move.w	#0,d3	; ystart
	swap	d6
	move.w	d6,d0	; xend
	add.w	#ADDS*9*2,d0
	swap	d6
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE
RL_l0:	
	move.w	d7,d2	; xstart
	move.w	#0,d3	; ystart
	swap	d7
	move.w	d7,d0	; xend
	swap	d7
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

	move.w	d7,d2	; xstart
	add.w	#ADDS*9,d2
	move.w	#0,d3	; ystart
	swap	d7
	move.w	d7,d0	; xend
	add.w	#ADDS*9,d0
	swap	d7
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

	move.w	d7,d2	; xstart
	add.w	#ADDS*9*2,d2
	move.w	#0,d3	; ystart
	swap	d7
	move.w	d7,d0	; xend
	add.w	#ADDS*9*2,d0
	swap	d7
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

	move.l	(a6,d4.w),d0
	beq.w	RL_n1

	move.l	#LineScreen,d0
	move.l	#FillScreen,d1
	bsr	Fill

	move.l	#FillScreen,d0
	move.l	Screens+8,d1
	add.l	#ScreenWidth/8*ScreenHeight*4,d1
	move.l	(a6,d4.w),a1
	move.w	#blith*64+blitw,d2
	bsr	Copy

RL_n1:
	cmp.l	#0,d5
	beq.w	RL_n0
	move.w	d6,d2	; xstart
	move.w	#0,d3	; ystart
	swap	d6
	move.w	d6,d0	; xend
	swap	d6
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

	move.w	d6,d2	; xstart
	add.w	#ADDS*9,d2
	move.w	#0,d3	; ystart
	swap	d6
	move.w	d6,d0	; xend
	add.w	#ADDS*9,d0
	swap	d6
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE

	move.w	d6,d2	; xstart
	add.w	#ADDS*9*2,d2
	move.w	#0,d3	; ystart
	swap	d6
	move.w	d6,d0	; xend
	add.w	#ADDS*9*2,d0
	swap	d6
	move.w	#SH,d1	; yend
	move.l	#LineScreen,a5
	bsr	DRAWLINE
RL_n0:
	add.l	#ADDS+(ADDS<<16),d6
	add.l	#ADDS+(ADDS<<16),d7
	add.w	#4,d4
	dbf	d5,RL_l0
;------------

	rts

;--------------------------------------------------------------------
RenderBack:
	rts
;--------------------------------------------------------------------
ClrScr:
	; a1 = dst
	; d0 = Size
	move.w	d0,-(sp)	; Size
	MOVE.W	#0,-(sp)
	MOVE.W	#0,-(sp)
	MOVE.L	#-1,-(sp)
	move.l	a1,-(sp)					; D-Dest
	move.l	#0,-(sp)				; C-Mask
	move.l	0,-(sp)					; B-Src1
	move.l	0,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#0,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$01000000,-(sp)				; BlitCon0/1
	bsr	SetBlit
	rts
;--------------------------------------------------------------------
blitw	=ScreenWidth/16			;sprite width in words
blith	=ScreenHeight			;sprite height in lines
Fill:
	add.l	#blitw*2-2,d0		; Screen(X)
	add.l	#blitw*2-2,d1		; Screen(X)
	move.w	#blith*64+blitw,-(sp)
	move.w	#-1,-(sp)
	move.w	#-1,-(sp)
	move.l	#-1,-(sp)
	move.l	d1,-(sp)
	move.l	#0,-(sp)
	move.l	#0,-(sp)
	move.l	d0,-(sp)
	move.w	#-(ScreenWidth/8+blitw*2),-(sp)
	move.w	#0,-(sp)
	move.w	#0,-(sp)
	move.w	#-(ScreenWidth/8+blitw*2),-(sp)
	move.l	#$09f00012,-(sp)
	bsr	SetBlit

	rts
;--------------------------------------------------------------------
Copy:
	move.w	d2,-(sp)
	move.w	#-1,-(sp)
	move.w	#-1,-(sp)
	move.l	#-1,-(sp)
	move.l	d1,-(sp)
	move.l	a1,-(sp)
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	move.w	#0,-(sp)
	move.w	#0,-(sp)
	move.w	#0,-(sp)
	move.w	#0,-(sp)
	move.l	#%11111100<<16,d2
	or.l	#$0d000000,d2
	cmp.l	#0,a1
	beq.b	.Copy0
	move.l	#%11101100<<16,d2
	or.l	#$0f000000,d2
.Copy0:
	move.l	d2,-(sp)
	bsr	SetBlit

	rts
;--------------------------------------------------------------------
SetBlit:
	move.l	(sp)+,SetBlitBack+2
	lea	BlitList,a0
	eor.l	d0,d0
	move.w	BlitListEnd+2,d0
	muls.w	#38,d0
	move.l	(sp)+,(a0,d0)	; BLTCON0
	move.w	(sp)+,4(a0,d0)	; BLTAMOD
	move.w	(sp)+,6(a0,d0)	; BLTBMOD
	move.w	(sp)+,8(a0,d0)	; BLTCMOD
	move.w	(sp)+,10(a0,d0)	; BLTDMOD
	move.l	(sp)+,12(a0,d0)	; BLTAPTH
	move.l	(sp)+,16(a0,d0)	; BLTBPTH
	move.l	(sp)+,20(a0,d0)	; BLTCPTH
	move.l	(sp)+,24(a0,d0)	; BLTDPTH
	move.l	(sp)+,28(a0,d0)	; BLTAFWM
	move.w	(sp)+,32(a0,d0)	; BLTADAT
	move.w	(sp)+,34(a0,d0)	; BLTBDAT
	move.w	(sp)+,36(a0,d0)	; BLTSIZE
	move.w	BlitListEnd+2,d0
	addq.w	#1,d0
	and.w	#BlitListLen-1,d0
	move.w	d0,BlitListEnd+2
SetBlitBack:
	move.l	#$00000000,-(sp)
	rts
;--------------------------------------------------------------------
StartBlitList:
	lea	BlitList,a0
	eor.l	d0,d0
	move.w	BlitListBeg,d0
	move.w	BlitListEnd,d1
	cmp.w	d0,d1
	beq.w	NoBlitList
	move.w	#1,BEnd
	muls.w	#38,d0


	lea	$dff000,a6
.WAIT:
	BTST	#$6,$2(A6)	; Wait on the blitter
	BNE.S	.WAIT

	add.l	d0,a0
	move.l	(a0),BLTCON0(a6)
	move.l	#$ffffffff,BLTAFWM(a6)
	move.w	4(a0),BLTAMOD(a6)
	move.w	6(a0),BLTBMOD(a6)
	move.w	8(a0),BLTCMOD(a6)
	move.w	10(a0),BLTDMOD(a6)
	move.l	12(a0),BLTAPTH(a6)
	move.l	16(a0),BLTBPTH(a6)
	move.l	20(a0),BLTCPTH(a6)
	move.l	24(a0),BLTDPTH(a6)
	move.l	28(a0),BLTAFWM(A6)	; FirstLastMask
	move.w	32(a0),BLTADAT(A6)	; BLT data A
	move.w	34(a0),BLTBDAT(A6)
	move.w	BlitListBeg,d0
	addq.w	#1,d0
	and.w	#BlitListLen-1,d0
	move.w	d0,BlitListBeg
	move.w	36(a0),BLTSIZE(a6)
NoBlitList:
	rts
;--------------------------------------------------------------------
SINGLE = 0	; 2 = SINGLE BIT WIDTH
;*****************
;* DRAW LINE *
;*****************

; USES D0/D1/D2/D3/D4/D7/A5/A6

DRAWLINE:
	movem.l	d0-a6,-(sp)
	lea	$dff000,a6
	SUB.W	D3,D1
	MULU	#ScreenWidth/8,D3	; ScreenWidth * D3

	MOVEQ	#$F,D4
	AND.W	D2,D4	; Get lowest bits from D2

;--------- SELECT OCTANT ---------

	SUB.W	D2,D0
	BLT.S	DRAW_DONT0146
	TST.W	D1
	BLT.S	DRAW_DONT04

	CMP.W	D0,D1
	BGE.S	DRAW_SELECT0
	MOVEQ	#$11+SINGLE,D7	; Select Oct 4
	BRA.S	DRAW_OCTSELECTED
	DRAW_SELECT0:
	MOVEQ	#1+SINGLE,D7	; Select Oct 0
	EXG	D0,D1
	BRA.S	DRAW_OCTSELECTED

DRAW_DONT04:
	NEG.W	D1
	CMP.W	D0,D1
	BGE.S	DRAW_SELECT1
	MOVEQ	#$19+SINGLE,D7	; Select Oct 6
	BRA.S	DRAW_OCTSELECTED
	DRAW_SELECT1:
	MOVEQ	#5+SINGLE,D7	; Select Oct 1
	EXG	D0,D1
	BRA.S	DRAW_OCTSELECTED


DRAW_DONT0146:
	NEG.W	D0
	TST.W	D1
	BLT.S	DRAW_DONT25
	CMP.W	D0,D1
	BGE.S	DRAW_SELECT2
	MOVEQ	#$15+SINGLE,D7	; Select Oct 5
	BRA.S	DRAW_OCTSELECTED
DRAW_SELECT2:
	MOVEQ	#9+SINGLE,D7	; Select Oct 2
	EXG	D0,D1
	BRA.S	DRAW_OCTSELECTED
DRAW_DONT25:
	NEG.W	D1
	CMP.W	D0,D1
	BGE.S	DRAW_SELECT3
	MOVEQ	#$1D+SINGLE,D7	; Select Oct 7
	BRA.S	DRAW_OCTSELECTED
DRAW_SELECT3:
	MOVEQ	#$D+SINGLE,D7	; Select Oct 3
	EXG	D0,D1

;--------- CALCULATE START ---------

DRAW_OCTSELECTED:
	ADD.W	D1,D1	; 2*dy
	ASR.W	#3,D2	; x=x/8
	EXT.L	D2
	ADD.L	D2,D3	; d3 = x+y*40 = screen pos
	MOVE.W	D1,D2	; d2 = 2*dy
	SUB.W	D0,D2	; d2 = 2*dy-dx
	BGE.S	DRAW_DONTSETSIGN
	ORI.W	#$40,D7	; dx < 2*dy
DRAW_DONTSETSIGN:

;--------- SET BLITTER ---------

;	bsr BlitWait

	move.l	d2,d5
	SUB.W	D0,D2	; d2 = 2*dy-dx-dx

;--------- MAKE LENGTH ---------

	ASL.W	#6,D0	; d0 = 64*dx
;	ADD.W	#$0001,D0	; d0 = 64*(dx+1)+2

;--------- MAKE CONTROL 0+1 ---------

	ROR.W	#4,D4
	ORI.W	#$B5a,D4	; $B4A - DMA + Minterm
	SWAP	D7
	MOVE.W	D4,D7
	SWAP	D7
	ADD.L	A5,D3	; SCREEN PTR

	or.l	#$2,d7

	move.w	d0,-(sp)
	MOVE.W	#$FFFF,-(sp)
	MOVE.W	#$8000,-(sp)
	MOVE.L	#-1,-(sp)
	move.l	d3,-(sp)
	move.l	d3,-(sp)
	move.l	#0,-(sp)
	move.l	d5,-(sp)
	move.w	#0,-(sp)
	move.w	#ScreenWidth/8,-(sp)
	move.w	d1,-(sp)
	move.w	d2,-(sp)
	move.l	d7,-(sp)

	bsr	SetBlit

	movem.l	(sp)+,d0-a6
	rts
;--------------------------------------------------------------------	
	SECTION	chip,DATA_C
;-----------
; display dimensions
DISPW           equ     ScreenWidth
DISPH           equ     ScreenHeight

; display window in raster coordinates (HSTART must be odd)
HSTART          equ     129+(256-ScreenWidth)/2
VSTART          equ     36
VEND            equ     VSTART+DISPH

; normal display data fetch start/stop (without scrolling)
DFETCHSTART     equ     HSTART/2
DFETCHSTOP      equ     DFETCHSTART+8*((DISPW/16)-1)
;-----------
Copper1:
	dc.w	$01fc,$000c
	dc.w	$0100,$0200
	dc.w	$008e,$2c00+HSTART
	dc.w	$0090,$2c00+HSTART+ScreenWidth+16-$100
	dc.w	$0092,DFETCHSTART
	dc.w	$0094,DFETCHSTOP
	dc.w	$0108,0 ; ScreenWidth/8*(Planes-1)
	dc.w	$010a,0 ; ScreenWidth/8*(Planes-1)
	dc.w	$0102,$0000
	dc.w	$0104,$0000
Bitplane1:
	dc.w	$00e0,$0000
	dc.w	$00e2,$0000
	dc.w	$00e4,$0000
	dc.w	$00e6,$0000
	dc.w	$00e8,$0000
	dc.w	$00ea,$0000
	dc.w	$00ec,$0000
	dc.w	$00ee,$0000
	dc.w	$00f0,$0000
	dc.w	$00f2,$0000
	dc.w	$00f4,$0000
	dc.w	$00f6,$0000
ColorCopper1:
	dc.w	$0180,$0008
	dc.w	$0182,$0533
	dc.w	$0184,$0966
	dc.w	$0186,$0ddd
	dc.w	$0188,$0888
	dc.w	$018a,$0aaa
	dc.w	$018c,$0ccc
	dc.w	$018e,$0eee
	dc.w	$0190,$0866
	dc.w	$0192,$0a64
	dc.w	$0194,$0976
	dc.w	$0196,$0b76
	dc.w	$0198,$0a86
	dc.w	$019a,$0998
	dc.w	$019c,$0e44
	dc.w	$019e,$0e55
	dc.w	$01a0,$0d86
	dc.w	$01a2,$099a
	dc.w	$01a4,$0e56
	dc.w	$01a6,$0e85
	dc.w	$01a8,$0ca8
	dc.w	$01aa,$0f78
	dc.w	$01ac,$0e97
	dc.w	$01ae,$0abc
	dc.w	$01b0,$0caa
	dc.w	$01b2,$0fb5
	dc.w	$01b4,$0f9a
	dc.w	$01b6,$0ccc
	dc.w	$01b8,$0fc7
	dc.w	$01ba,$0fbb
	dc.w	$01bc,$0fdb
	dc.w	$01be,$0fff

	dc.w	$0106,$0000
	dc.w	$0007+(VSTART<<8),$fffe
	dc.w	$0100,(Planes<<12)
;	dc.w	$0180,$0000
	dc.w	$0007+((VEND)<<8),$fffe
	dc.w	$0100,0
	dc.w	$ffff,$fffe

;-----------
Copper2:
	dc.w	$01fc,$000c
	dc.w	$0100,$0200
	dc.w	$008e,$2c00+HSTART
	dc.w	$0090,$2c00+HSTART+ScreenWidth+16-$100
	dc.w	$0092,DFETCHSTART
	dc.w	$0094,DFETCHSTOP
	dc.w	$0108,0 ; ScreenWidth/8*(Planes-1)
	dc.w	$010a,0 ; ScreenWidth/8*(Planes-1)
	dc.w	$0102,$0000
	dc.w	$0104,$0000
Bitplane2:
	dc.w	$00e0,$0000
	dc.w	$00e2,$0000
	dc.w	$00e4,$0000
	dc.w	$00e6,$0000
	dc.w	$00e8,$0000
	dc.w	$00ea,$0000
	dc.w	$00ec,$0000
	dc.w	$00ee,$0000
	dc.w	$00f0,$0000
	dc.w	$00f2,$0000
	dc.w	$00f4,$0000
	dc.w	$00f6,$0000
ColorCopper2:
	dc.w	$0180,$0008
	dc.w	$0182,$0533
	dc.w	$0184,$0966
	dc.w	$0186,$0ddd
	dc.w	$0188,$0888
	dc.w	$018a,$0aaa
	dc.w	$018c,$0ccc
	dc.w	$018e,$0eee
	dc.w	$0190,$0866
	dc.w	$0192,$0a64
	dc.w	$0194,$0976
	dc.w	$0196,$0b76
	dc.w	$0198,$0a86
	dc.w	$019a,$0998
	dc.w	$019c,$0e44
	dc.w	$019e,$0e55
	dc.w	$01a0,$0d86
	dc.w	$01a2,$099a
	dc.w	$01a4,$0e56
	dc.w	$01a6,$0e85
	dc.w	$01a8,$0ca8
	dc.w	$01aa,$0f78
	dc.w	$01ac,$0e97
	dc.w	$01ae,$0abc
	dc.w	$01b0,$0caa
	dc.w	$01b2,$0fb5
	dc.w	$01b4,$0f9a
	dc.w	$01b6,$0ccc
	dc.w	$01b8,$0fc7
	dc.w	$01ba,$0fbb
	dc.w	$01bc,$0fdb
	dc.w	$01be,$0fff

	dc.w	$0106,$0000
	dc.w	$0007+(VSTART<<8),$fffe
	dc.w	$0100,(Planes<<12)
;	dc.w	$0180,$0000
	dc.w	$0007+((VEND)<<8),$fffe
	dc.w	$0100,0
	dc.w	$ffff,$fffe

;-----------
Copper3:
	dc.w	$01fc,$000c
	dc.w	$0100,$0200
	dc.w	$008e,$2c00+HSTART
	dc.w	$0090,$2c00+HSTART+ScreenWidth+16-$100
	dc.w	$0092,DFETCHSTART
	dc.w	$0094,DFETCHSTOP
	dc.w	$0108,0 ; ScreenWidth/8*(Planes-1)
	dc.w	$010a,0 ; ScreenWidth/8*(Planes-1)
	dc.w	$0102,$0000
	dc.w	$0104,$0000
Bitplane3:
	dc.w	$00e0,$0000
	dc.w	$00e2,$0000
	dc.w	$00e4,$0000
	dc.w	$00e6,$0000
	dc.w	$00e8,$0000
	dc.w	$00ea,$0000
	dc.w	$00ec,$0000
	dc.w	$00ee,$0000
	dc.w	$00f0,$0000
	dc.w	$00f2,$0000
	dc.w	$00f4,$0000
	dc.w	$00f6,$0000
ColorCopper3:
	dc.w	$0180,$0008
	dc.w	$0182,$0533
	dc.w	$0184,$0966
	dc.w	$0186,$0ddd
	dc.w	$0188,$0888
	dc.w	$018a,$0aaa
	dc.w	$018c,$0ccc
	dc.w	$018e,$0eee
	dc.w	$0190,$0866
	dc.w	$0192,$0a64
	dc.w	$0194,$0976
	dc.w	$0196,$0b76
	dc.w	$0198,$0a86
	dc.w	$019a,$0998
	dc.w	$019c,$0e44
	dc.w	$019e,$0e55
	dc.w	$01a0,$0d86
	dc.w	$01a2,$099a
	dc.w	$01a4,$0e56
	dc.w	$01a6,$0e85
	dc.w	$01a8,$0ca8
	dc.w	$01aa,$0f78
	dc.w	$01ac,$0e97
	dc.w	$01ae,$0abc
	dc.w	$01b0,$0caa
	dc.w	$01b2,$0fb5
	dc.w	$01b4,$0f9a
	dc.w	$01b6,$0ccc
	dc.w	$01b8,$0fc7
	dc.w	$01ba,$0fbb
	dc.w	$01bc,$0fdb
	dc.w	$01be,$0fff

	dc.w	$0106,$0000
	dc.w	$0007+(VSTART<<8),$fffe
	dc.w	$0100,(Planes<<12)
;	dc.w	$0180,$0000
	dc.w	$0007+((VEND)<<8),$fffe
	dc.w	$0100,0
	dc.w	$ffff,$fffe


*********************************************************************
	SECTION mem,BSS_C
Screen1:
	ds.b	ScreenWidth/8*ScreenHeight*Planes
Screen2:
	ds.b	ScreenWidth/8*ScreenHeight*Planes
Screen3:
	ds.b	ScreenWidth/8*ScreenHeight*Planes
LineScreen:
	ds.b	ScreenWidth/8*ScreenHeight
FillScreen:
	ds.b	ScreenWidth/8*ScreenHeight
Mask0:
	ds.b	ScreenWidth/8*ScreenHeight
Mask1:
	ds.b	ScreenWidth/8*ScreenHeight
Mask2:
	ds.b	ScreenWidth/8*ScreenHeight
Mask3:
	ds.b	ScreenWidth/8*ScreenHeight
Mask4:
	ds.b	ScreenWidth/8*ScreenHeight
Mask5:
	ds.b	ScreenWidth/8*ScreenHeight
Mask6:
	ds.b	ScreenWidth/8*ScreenHeight
Mask7:
	ds.b	ScreenWidth/8*ScreenHeight
;--------------------------------------------------------------------
	section	data,DATA_F
gfxname:
	dc.b	"graphics.library",0

	EVEN
org_copper:
	dc.l	0
org_intena:
	dc.w	0
org_dmacon:
	dc.w	0
org_int3:
	dc.l	0
Copper:
	dc.l	Copper1,Copper2,Copper3
Screens:
	dc.l	Screen1,Screen2,Screen3
BltSrc:	dc.l	0
BltDst:	dc.l	0
BltClr:	dc.l	0
BlitListBeg:
	dc.w	0
BlitListEnd:
	dc.w	0,0
Frames:	dc.w	0
BEnd:	dc.w	0

XEnd:	dc.w	83
sinpos	dc.w	0
Masks:	dc.l	0,Mask0,Mask1,Mask2,Mask3,Mask4,Mask5,Mask6,Mask7
Sinus:
	DC.W	$0001,$0002,$0004,$0005,$0007,$0009,$000A,$000C,$000D,$000F
	DC.W	$0010,$0012,$0014,$0015,$0017,$0018,$001A,$001B,$001D,$001F
	DC.W	$0020,$0022,$0023,$0025,$0026,$0028,$0029,$002B,$002D,$002E
	DC.W	$0030,$0031,$0033,$0034,$0036,$0037,$0039,$003A,$003C,$003D
	DC.W	$003F,$0040,$0042,$0044,$0045,$0047,$0048,$004A,$004B,$004D
	DC.W	$004E,$0050,$0051,$0053,$0054,$0056,$0057,$0058,$005A,$005B
	DC.W	$005D,$005E,$0060,$0061,$0063,$0064,$0066,$0067,$0068,$006A
	DC.W	$006B,$006D,$006E,$0070,$0071,$0072,$0074,$0075,$0077,$0078
	DC.W	$0079,$007B,$007C,$007D,$007F,$0080,$0082,$0083,$0084,$0086
	DC.W	$0087,$0088,$008A,$008B,$008C,$008E,$008F,$0090,$0091,$0093
	DC.W	$0094,$0095,$0097,$0098,$0099,$009A,$009C,$009D,$009E,$009F
	DC.W	$00A1,$00A2,$00A3,$00A4,$00A5,$00A7,$00A8,$00A9,$00AA,$00AB
	DC.W	$00AD,$00AE,$00AF,$00B0,$00B1,$00B2,$00B3,$00B4,$00B6,$00B7
	DC.W	$00B8,$00B9,$00BA,$00BB,$00BC,$00BD,$00BE,$00BF,$00C0,$00C1
	DC.W	$00C2,$00C3,$00C4,$00C5,$00C6,$00C7,$00C8,$00C9,$00CA,$00CB
	DC.W	$00CC,$00CD,$00CE,$00CF,$00D0,$00D1,$00D2,$00D3,$00D4,$00D4
	DC.W	$00D5,$00D6,$00D7,$00D8,$00D9,$00DA,$00DA,$00DB,$00DC,$00DD
	DC.W	$00DE,$00DE,$00DF,$00E0,$00E1,$00E1,$00E2,$00E3,$00E4,$00E4
	DC.W	$00E5,$00E6,$00E6,$00E7,$00E8,$00E8,$00E9,$00EA,$00EA,$00EB
	DC.W	$00EC,$00EC,$00ED,$00ED,$00EE,$00EF,$00EF,$00F0,$00F0,$00F1
	DC.W	$00F1,$00F2,$00F2,$00F3,$00F3,$00F4,$00F4,$00F5,$00F5,$00F6
	DC.W	$00F6,$00F7,$00F7,$00F7,$00F8,$00F8,$00F9,$00F9,$00F9,$00FA
	DC.W	$00FA,$00FA,$00FB,$00FB,$00FB,$00FC,$00FC,$00FC,$00FC,$00FD
	DC.W	$00FD,$00FD,$00FD,$00FE,$00FE,$00FE,$00FE,$00FE,$00FF,$00FF
	DC.W	$00FF,$00FF,$00FF,$00FF,$00FF,$00FF,$0100,$0100,$0100,$0100
	DC.W	$0100,$0100,$0100,$0100,$0100,$0100,$0100,$0100,$0100,$0100
	DC.W	$0100,$0100,$0100,$0100,$0100,$0100,$00FF,$00FF,$00FF,$00FF
	DC.W	$00FF,$00FF,$00FF,$00FF,$00FE,$00FE,$00FE,$00FE,$00FE,$00FD
	DC.W	$00FD,$00FD,$00FD,$00FC,$00FC,$00FC,$00FC,$00FB,$00FB,$00FB
	DC.W	$00FA,$00FA,$00FA,$00F9,$00F9,$00F9,$00F8,$00F8,$00F7,$00F7
	DC.W	$00F7,$00F6,$00F6,$00F5,$00F5,$00F4,$00F4,$00F3,$00F3,$00F2
	DC.W	$00F2,$00F1,$00F1,$00F0,$00F0,$00EF,$00EF,$00EE,$00ED,$00ED
	DC.W	$00EC,$00EC,$00EB,$00EA,$00EA,$00E9,$00E8,$00E8,$00E7,$00E6
	DC.W	$00E6,$00E5,$00E4,$00E4,$00E3,$00E2,$00E1,$00E1,$00E0,$00DF
	DC.W	$00DE,$00DE,$00DD,$00DC,$00DB,$00DA,$00DA,$00D9,$00D8,$00D7
	DC.W	$00D6,$00D5,$00D4,$00D4,$00D3,$00D2,$00D1,$00D0,$00CF,$00CE
	DC.W	$00CD,$00CC,$00CB,$00CA,$00C9,$00C8,$00C7,$00C6,$00C5,$00C4
	DC.W	$00C3,$00C2,$00C1,$00C0,$00BF,$00BE,$00BD,$00BC,$00BB,$00BA
	DC.W	$00B9,$00B8,$00B7,$00B6,$00B4,$00B3,$00B2,$00B1,$00B0,$00AF
	DC.W	$00AE,$00AC,$00AB,$00AA,$00A9,$00A8,$00A7,$00A5,$00A4,$00A3
	DC.W	$00A2,$00A1,$009F,$009E,$009D,$009C,$009A,$0099,$0098,$0097
	DC.W	$0095,$0094,$0093,$0091,$0090,$008F,$008E,$008C,$008B,$008A
	DC.W	$0088,$0087,$0086,$0084,$0083,$0082,$0080,$007F,$007D,$007C
	DC.W	$007B,$0079,$0078,$0077,$0075,$0074,$0072,$0071,$0070,$006E
	DC.W	$006D,$006B,$006A,$0068,$0067,$0066,$0064,$0063,$0061,$0060
	DC.W	$005E,$005D,$005B,$005A,$0058,$0057,$0056,$0054,$0053,$0051
	DC.W	$0050,$004E,$004D,$004B,$004A,$0048,$0047,$0045,$0044,$0042
	DC.W	$0040,$003F,$003D,$003C,$003A,$0039,$0037,$0036,$0034,$0033
	DC.W	$0031,$0030,$002E,$002D,$002B,$0029,$0028,$0026,$0025,$0023
	DC.W	$0022,$0020,$001F,$001D,$001B,$001A,$0018,$0017,$0015,$0014
	DC.W	$0012,$0010,$000F,$000D,$000C,$000A,$0009,$0007,$0005,$0004
	DC.W	$0002,$0001,$FFFF,$FFFE,$FFFC,$FFFB,$FFF9,$FFF7,$FFF6,$FFF4
	DC.W	$FFF3,$FFF1,$FFF0,$FFEE,$FFEC,$FFEB,$FFE9,$FFE8,$FFE6,$FFE5
	DC.W	$FFE3,$FFE1,$FFE0,$FFDE,$FFDD,$FFDB,$FFDA,$FFD8,$FFD7,$FFD5
	DC.W	$FFD3,$FFD2,$FFD0,$FFCF,$FFCD,$FFCC,$FFCA,$FFC9,$FFC7,$FFC6
	DC.W	$FFC4,$FFC3,$FFC1,$FFC0,$FFBE,$FFBC,$FFBB,$FFB9,$FFB8,$FFB6
	DC.W	$FFB5,$FFB3,$FFB2,$FFB0,$FFAF,$FFAD,$FFAC,$FFAA,$FFA9,$FFA8
	DC.W	$FFA6,$FFA5,$FFA3,$FFA2,$FFA0,$FF9F,$FF9D,$FF9C,$FF9A,$FF99
	DC.W	$FF98,$FF96,$FF95,$FF93,$FF92,$FF90,$FF8F,$FF8E,$FF8C,$FF8B
	DC.W	$FF89,$FF88,$FF87,$FF85,$FF84,$FF83,$FF81,$FF80,$FF7E,$FF7D
	DC.W	$FF7C,$FF7A,$FF79,$FF78,$FF76,$FF75,$FF74,$FF72,$FF71,$FF70
	DC.W	$FF6F,$FF6D,$FF6C,$FF6B,$FF69,$FF68,$FF67,$FF66,$FF64,$FF63
	DC.W	$FF62,$FF61,$FF5F,$FF5E,$FF5D,$FF5C,$FF5B,$FF59,$FF58,$FF57
	DC.W	$FF56,$FF55,$FF53,$FF52,$FF51,$FF50,$FF4F,$FF4E,$FF4D,$FF4C
	DC.W	$FF4A,$FF49,$FF48,$FF47,$FF46,$FF45,$FF44,$FF43,$FF42,$FF41
	DC.W	$FF40,$FF3F,$FF3E,$FF3D,$FF3C,$FF3B,$FF3A,$FF39,$FF38,$FF37
	DC.W	$FF36,$FF35,$FF34,$FF33,$FF32,$FF31,$FF30,$FF2F,$FF2E,$FF2D
	DC.W	$FF2C,$FF2C,$FF2B,$FF2A,$FF29,$FF28,$FF27,$FF26,$FF26,$FF25
	DC.W	$FF24,$FF23,$FF22,$FF22,$FF21,$FF20,$FF1F,$FF1F,$FF1E,$FF1D
	DC.W	$FF1C,$FF1C,$FF1B,$FF1A,$FF1A,$FF19,$FF18,$FF18,$FF17,$FF16
	DC.W	$FF16,$FF15,$FF14,$FF14,$FF13,$FF13,$FF12,$FF11,$FF11,$FF10
	DC.W	$FF10,$FF0F,$FF0F,$FF0E,$FF0E,$FF0D,$FF0D,$FF0C,$FF0C,$FF0B
	DC.W	$FF0B,$FF0A,$FF0A,$FF09,$FF09,$FF09,$FF08,$FF08,$FF07,$FF07
	DC.W	$FF07,$FF06,$FF06,$FF06,$FF05,$FF05,$FF05,$FF04,$FF04,$FF04
	DC.W	$FF04,$FF03,$FF03,$FF03,$FF03,$FF02,$FF02,$FF02,$FF02,$FF02
	DC.W	$FF01,$FF01,$FF01,$FF01,$FF01,$FF01,$FF01,$FF01,$FF00,$FF00
	DC.W	$FF00,$FF00,$FF00,$FF00,$FF00,$FF00,$FF00,$FF00,$FF00,$FF00
	DC.W	$FF00,$FF00,$FF00,$FF00,$FF00,$FF00,$FF00,$FF00,$FF01,$FF01
	DC.W	$FF01,$FF01,$FF01,$FF01,$FF01,$FF01,$FF02,$FF02,$FF02,$FF02
	DC.W	$FF02,$FF03,$FF03,$FF03,$FF03,$FF04,$FF04,$FF04,$FF04,$FF05
	DC.W	$FF05,$FF05,$FF06,$FF06,$FF06,$FF07,$FF07,$FF07,$FF08,$FF08
	DC.W	$FF09,$FF09,$FF09,$FF0A,$FF0A,$FF0B,$FF0B,$FF0C,$FF0C,$FF0D
	DC.W	$FF0D,$FF0E,$FF0E,$FF0F,$FF0F,$FF10,$FF10,$FF11,$FF11,$FF12
	DC.W	$FF13,$FF13,$FF14,$FF14,$FF15,$FF16,$FF16,$FF17,$FF18,$FF18
	DC.W	$FF19,$FF1A,$FF1A,$FF1B,$FF1C,$FF1C,$FF1D,$FF1E,$FF1F,$FF1F
	DC.W	$FF20,$FF21,$FF22,$FF22,$FF23,$FF24,$FF25,$FF26,$FF26,$FF27
	DC.W	$FF28,$FF29,$FF2A,$FF2B,$FF2C,$FF2C,$FF2D,$FF2E,$FF2F,$FF30
	DC.W	$FF31,$FF32,$FF33,$FF34,$FF35,$FF36,$FF37,$FF38,$FF39,$FF3A
	DC.W	$FF3B,$FF3C,$FF3D,$FF3E,$FF3F,$FF40,$FF41,$FF42,$FF43,$FF44
	DC.W	$FF45,$FF46,$FF47,$FF48,$FF49,$FF4A,$FF4C,$FF4D,$FF4E,$FF4F
	DC.W	$FF50,$FF51,$FF52,$FF54,$FF55,$FF56,$FF57,$FF58,$FF59,$FF5B
	DC.W	$FF5C,$FF5D,$FF5E,$FF5F,$FF61,$FF62,$FF63,$FF64,$FF66,$FF67
	DC.W	$FF68,$FF69,$FF6B,$FF6C,$FF6D,$FF6F,$FF70,$FF71,$FF72,$FF74
	DC.W	$FF75,$FF76,$FF78,$FF79,$FF7A,$FF7C,$FF7D,$FF7E,$FF80,$FF81
	DC.W	$FF83,$FF84,$FF85,$FF87,$FF88,$FF89,$FF8B,$FF8C,$FF8E,$FF8F
	DC.W	$FF90,$FF92,$FF93,$FF95,$FF96,$FF98,$FF99,$FF9A,$FF9C,$FF9D
	DC.W	$FF9F,$FFA0,$FFA2,$FFA3,$FFA5,$FFA6,$FFA8,$FFA9,$FFAA,$FFAC
	DC.W	$FFAD,$FFAF,$FFB0,$FFB2,$FFB3,$FFB5,$FFB6,$FFB8,$FFB9,$FFBB
	DC.W	$FFBC,$FFBE,$FFC0,$FFC1,$FFC3,$FFC4,$FFC6,$FFC7,$FFC9,$FFCA
	DC.W	$FFCC,$FFCD,$FFCF,$FFD0,$FFD2,$FFD3,$FFD5,$FFD7,$FFD8,$FFDA
	DC.W	$FFDB,$FFDD,$FFDE,$FFE0,$FFE1,$FFE3,$FFE5,$FFE6,$FFE8,$FFE9
	DC.W	$FFEB,$FFEC,$FFEE,$FFF0,$FFF1,$FFF3,$FFF4,$FFF6,$FFF7,$FFF9
	DC.W	$FFFB,$FFFC,$FFFE,$FFFF

Palette:
	dc.w	$0546
	dc.w	$0222
	dc.w	$0555
	dc.w	$0aaa
	dc.w	$0000
	dc.w	$0112
	dc.w	$0225
	dc.w	$055a
	
	dc.w	$0000
	dc.w	$0121
	dc.w	$0252
	dc.w	$05a5
	dc.w	$0000
	dc.w	$0211
	dc.w	$0522
	dc.w	$0a55

	dc.w	$0222
	dc.w	$0555
	dc.w	$0aaa
	dc.w	$0eee
	dc.w	$0112
	dc.w	$0225
	dc.w	$055a
	dc.w	$0aae

	dc.w	$0121
	dc.w	$0252
	dc.w	$05a5
	dc.w	$0aea
	dc.w	$0211
	dc.w	$0522
	dc.w	$0a55
	dc.w	$0eaa

*********************************************************************
	section	tex,BSS_F
BlitList:
	ds.b	38*BlitListLen
