	include "custom.i"
	include "Wolfenstein3D/defines.i"
*********************************************************************
	section	main,CODE_F
Init:
;	move.l	#65536*8,d0
;	divs.w	#128,d0
;	rts

;	bra	noControl
;	bsr	InitBitZoom
;	bsr	RenderLoop
;	bsr	RenderLoop
;	rts

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
	move.l	#4-1,d1
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
	move.l	#4-1,d1
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
	move.l	#4-1,d1
.l3:
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	#ScreenWidth/8*ScreenHeight,d0
	add.l	#8,a0
	dbf	d1,.l3

	move.l	#Copper1,$dff080

	jsr	InitBitZoom
;----------------------------------
	lea	BufferMask16,a0
	move.l	#$ffff0000,d0
	move.w	#(ScreenHeight+16)*Planes/16-1,d6
IBM17:	move.w	#ScreenWidth/8*16/4-1,d7
IBM16:	move.l	d0,(a0)+
	dbf	d7,IBM16
	eor.l	#$0000ffff,d0
	dbf	d6,IBM17

	lea	BufferMask8,a0
	lea	BufferMask8_,a1
	move.l	#$ff00ff00,d0
	move.l	#$ffffffff,d1
	move.w	#ScreenHeight/8*Planes-1,d6
IBM9:	move.w	#ScreenWidth/8*8/4-1,d7
IBM8:	move.l	d0,(a0)+
	move.l	d1,(a1)+
	dbf	d7,IBM8
	eor.l	#$00ff00ff,d0
	eor.l	#$ff00ff00,d1
	dbf	d6,IBM9

	lea	BufferMask4,a0
	lea	BufferMask4_,a1
	move.l	#$f0f0f0f0,d0
	move.l	#$ffffffff,d1
	move.w	#ScreenHeight/4*Planes-1,d6
IBM5:	move.w	#ScreenWidth/8*4/4-1,d7
IBM4:	move.l	d0,(a0)+
	move.l	d1,(a1)+
	dbf	d7,IBM4
	eor.l	#$0f0f0f0f,d0
	eor.l	#$f0f0f0f0,d1
	dbf	d6,IBM5

	lea	BufferMask2,a0
	lea	BufferMask2_,a1
	move.l	#$cccccccc,d0
	move.l	#$ffffffff,d1
	move.w	#3*Planes-1,d6
IBM3:	move.w	#ScreenWidth/8*2/4-1,d7
IBM2:	move.l	d0,(a0)+
	move.l	d1,(a1)+
	dbf	d7,IBM2
	eor.l	#$33333333,d0
	eor.l	#$cccccccc,d1
	dbf	d6,IBM3

	lea	BufferMask1,a0
	lea	BufferMask1_,a1
	move.l	#$aaaaaaaa,d0
	move.l	#$ffffffff,d1
	move.w	#3*Planes-1,d6
IBM1:	move.w	#ScreenWidth/8*1/4-1,d7
IBM0:	move.l	d0,(a0)+
	move.l	d1,(a1)+
	dbf	d7,IBM0
	eor.l	#$55555555,d0
	eor.l	#$aaaaaaaa,d1
	dbf	d6,IBM1

	bsr	InitDoubleCopper

	
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

;	IF DoubleY
;	lea	CopperDouble,a0
;	move.l	#$0001+VSTART<<8,d0
;	swap	d0
;	move.w	#$fffe,d0
;	move.w	#ScreenHeight,d7
;frw:	move.l	#$01080000+((-ScreenWidth/8)&$ffff),(a0)+
;	move.l	#$010a0000+((-ScreenWidth/8)&$ffff),(a0)+
;	move.l	d0,(a0)+
;	add.l	#$01000000,d0
;	move.l	#$01080000,(a0)+
;	move.l	#$010a0000,(a0)+
;	move.l	d0,(a0)+
;	add.l	#$01000000,d0
;	dbf	d7,frw
;	ENDC

; 128 	S->B
; 64	B->S
; 32	S->B
; 16	B->S
; 8	S->B
; 4	B->S
; 2	S->B
; 1	B->S
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
	move.l	Copper,$dff080

;	move.w	#$888,$dff180

	bsr.w	Control

	move.w	#$0,$dff036
	move.l	Screens+4,a0
	add.l	#ScreenWidth/8*ScreenHeight*4,a0
	eor.l	d0,d0
	move.w	#ScreenWidth/8/4*2-1,d7
cler:	move.l	d0,(a0)+
	dbf	d7,cler

	move.l	Screens+4,a0
	add.l	#ScreenWidth/8*ScreenHeight*2,a0
	move.l	#$ffffffff,d0
	move.w	#ScreenWidth/32-1,d7
gfg:	move.l	d0,(a0)+
	dbf	d7,gfg

	move.l	Screens+4,a0
	add.l	#ScreenWidth/8*ScreenHeight*3,a0
	move.l	#$00000000,d0
	move.w	#ScreenWidth/32*160/2-1,d7
gfg1:	move.l	d0,(a0)+
	dbf	d7,gfg1

	bra	noControl
	lea	VectorsOrg,a1
	lea	Vectors,a0
	move.w	ZPos,d0
	move.w	XPos,d2
	move.w	#6-1,d7
loopd1:	move.w	2(a1),d1
;	add.w	d0,d1
	move.w	d1,2(a0)
	move.w	(a1),d1
;	add.w	d2,d1
	move.w	d1,(a0)
	add	#4,a0
	add	#4,a1
	dbf	d7,loopd1

noControl:

	lea	Sinus,a1
	lea	Vectors,a0
	lea	VectorsOrg,a2
	move.w	SinPos,d0
	move.w	(a1,d0),d0
	add.w	#128+8,d0
	move.w	#6-1,d7
weq:	move.l	(a2)+,d1
	add.w	d0,d1
	move.l	d1,(a0)+
	dbf	d7,weq

	bsr	RenderLoop

	sub.w	#4,movingX
	move.w	Frames,d0
	asl.w	#1,d0
	add.w	d0,d0
	sub.w	d0,SinPos
	and.w	#(SinusSize-1)*2,SinPos
	add.w	#10*2,SinPos+2
	and.w	#(SinusSize-1)*2,SinPos+2
	move.l	TexAnim,d0
	add.l	#1,d0
	cmp.l	#12,d0
	blt	noi
	move.l	#0,d0
noi:	move.l	d0,TexAnim

	bsr	BlitWait

	move.l	Screens+4,a0
	move.l	a0,BltDst
	move.l	#BufferTmp,a0
	move.l	a0,BltSrc
	move.l	Screens+8,a0
	move.l	a0,BltClr
	bsr	ScreenBlt

	move.w	BlitListEnd+2,BlitListEnd
	move.w	#$0,Frames
	bsr	StartBlitList
	
;	bsr	BlitWait

;	move.w	#$000,$dff180

	lea	Screens,a0
	bsr	Switch
	lea	Copper,a0
	bsr	Switch
	move.l	BufferTmp,d0
	move.l	BufferTmp+4,BufferTmp
	move.l	d0,BufferTmp+4


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
InitDoubleCopper:
	lea	PlaneDouble1,a0
	move.l	#Screen1,d6
	bsr	IDC
	lea	PlaneDouble2,a0
	move.l	#Screen2,d6
	bsr	IDC
	lea	PlaneDouble3,a0
	move.l	#Screen3,d6
	bsr	IDC
	rts
IDC:
	move.l	#$00e80000,d0
	move.l	#$00ea0000,d1
	move.l	#$00ec0000,d2
	move.l	#$00ee0000,d3
	move.l	#$00f00000,d4
	move.l	#$00f20000,d5
	move.l	d6,d7	
	add.l	#ScreenWidth/8*ScreenHeight*4,d7
	move.w	d7,d1
	move.l	d1,a2
	swap	d7
	move.w	d7,d0
	move.l	d0,a3
	swap	d7
	add.l	#ScreenWidth/8,d7
	move.w	d7,d3
	move.l	d3,a4
	swap	d7
	move.w	d7,d2
	move.l	d2,a5
	move.l	d6,d0
	move.l	#ScreenWidth/8,d2
	add.l	#ScreenWidth/8*ScreenHeight*2,d0
	sub.l	d2,d0
	move.l	#$0001+(VSTART-1)<<8,d1
	swap	d1
	move.w	#$fffe,d1
	add.l	#$01000000,d1
	move.w	#(ScreenHeight-CutLow)/2-1,d7
frw1:
	move.w	d0,d5
	swap	d0
	move.w	d0,d4
	swap	d0
	move.l	d4,(a0)+
	move.l	d5,(a0)+
	move.l	a3,(a0)+
	move.l	a2,(a0)+
	move.l	a5,(a0)+
	move.l	a4,(a0)+
	move.l	d1,(a0)+
	add.l	d2,d0
	add.l	#$01000000,d1
	dbf	d7,frw1
	add.l	d2,d0

	move.w	d0,d5
	swap	d0
	move.w	d0,d4
	swap	d0
	move.l	d4,(a0)+
	move.l	d5,(a0)+
	move.l	a3,(a0)+
	move.l	a2,(a0)+
	move.l	a5,(a0)+
	move.l	a4,(a0)+

	lea	ColorReflBottom,a6
	move.l	#$01a00000,d3
	move.w	#16-1,d7
frw3:	move.w	(a6)+,d3
	move.l	d3,(a0)+
	add.l	#$00020000,d3
	dbf	d7,frw3

	move.l	d1,(a0)+
	add.l	d2,d0
	add.l	#$01000000,d1

	move.w	#(ScreenHeight-CutLow)/2-1-0,d7
frw2:
	move.w	d0,d5
	swap	d0
	move.w	d0,d4
	swap	d0
	move.l	d4,(a0)+
	move.l	d5,(a0)+
	move.l	a3,(a0)+
	move.l	a2,(a0)+
	move.l	a5,(a0)+
	move.l	a4,(a0)+
	move.l	d1,(a0)+
	add.l	#$01000000,d1
	sub.l	d2,d0
	dbf	d7,frw2
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
BEnd:	dc.w	0
XPos:	dc.w	0
ZPos:	dc.w	128
;--------------------------------------------------------------------	
BlitWait:
	cmp.w	#0,BEnd
	bne.b	BlitWait
	rts
;--------------------------------------------------------------------	
Control:
	move.w	$dff00c,d0
	and.w	#$0303,d0
	move.w	d0,d1
	and.w	#$0202,d1
	lsr.w	#1,d1
	eor.w	d1,d0
	move.w	d0,d1
	lsr.w	#8,d1
	move.w	Frames,d2
	lsl.w	#2,d2
	btst	#0,d0
	beq.b	COnoup
	add.w	d2,ZPos
	bra.b	COnoupdown
COnoup:
	btst	#0,d1
	beq.b	COnodown
	sub.w	d2,ZPos
COnodown:
COnoupdown:
	btst	#1,d1
	beq.b	COnoleft
	add.w	d2,XPos
	bra.b	COnoleftright
COnoleft:
	btst	#1,d0
	beq.w	COnoright
	sub.w	d2,XPos
COnoright:
COnoleftright:

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
	EVEN
	EVEN
;--------------------------------------------------------------------	
RL_CheckInside:
	; in  = d0,d1 points
	; out = d4 draw or not

	move.w	d0,d3
	move.w	d3,d4
	and.w	#7,d3
	lsr.l	#3,d4
	btst	d3,(a4,d4.w)
	bne.b	RL_noCheck0
	move.w	d0,d4
	bsr	RL_CheckFrustumLeft
	move.w	d0,d4
	bsr	RL_CheckFrustumRight
RL_noCheck0:
	
	move.w	d1,d3
	move.w	d3,d4
	and.w	#7,d3
	lsr.l	#3,d4
	btst	d3,(a4,d4.w)
	bne.b	RL_noCheck1
	move.w	d1,d4
	bsr	RL_CheckFrustumLeft
	move.w	d1,d4
	bsr	RL_CheckFrustumRight
RL_noCheck1:

	rts
;--------------------------------------------------------------------	
RL_CheckFrustumLeft:
	; in  = d4 point
	; out = d3 in or out
	movem.l	d2/d3/d4,-(sp)	
	lsl.w	#2,d4
	move.l	(a5,d4),d2
	move.l	d2,d3
	swap	d3
	ext.l	d2
	ext.l	d3
	muls.w	#Deep,d3
	muls.w	#-ScreenWidth/2,d2
	sub.l	d2,d3
	blt.w	RL_noOnScrL
	lsr.w	#2,d4
	move.w	d4,d3
	and.w	#7,d3
	lsr.w	#3,d4
	bset	d3,(a2,d4)
RL_noOnScrL:	
	bset	d3,(a4,d4)
	movem.l	(sp)+,d2/d3/d4
	rts
;--------------------------------------------------------------------	
RL_CheckFrustumRight:
	; in  = d4 point
	; out = d3 in or out
	movem.l	d2/d3/d4,-(sp)	
	lsl.w	#2,d4
	move.l	(a5,d4),d2
	move.l	d2,d3
	swap	d3
	ext.l	d2
	ext.l	d3
	muls.w	#Deep,d3
	muls.w	#ScreenWidth/2,d2
	sub.l	d2,d3
	bpl	RL_noOnScrR
	lsr.w	#2,d4
	move.w	d4,d3
	and.w	#7,d3
	lsr.w	#3,d4
	bset	d3,(a3,d4)
RL_noOnScrR:	
	bset	d3,(a4,d4)
	movem.l	(sp)+,d2/d3/d4
	rts
;--------------------------------------------------------------------	
RenderLoop:
;	bra	mm
; --------------------
	lea	ScreenPreRender,a0
	move.w	#$ffff,d0
	move.w	#ScreenWidth-1,d7
RL0:	move.w	d0,(a0)+
	dbf	d7,RL0
; --------------------
	lea	InFrustumLeft,a0
	lea	InFrustumRight,a1
	lea	InFrustumToTest,a2
	move.w	#(128-4)/4-1,d7
	eor.l	d0,d0
RL_l3:	move.l	d0,(a0)+
	move.l	d0,(a1)+
	move.l	d0,(a2)+
	dbf	d7,RL_l3

	lea	Walls,a6
	lea	Vectors,a5
	lea	InFrustumLeft,a2
	lea	InFrustumRight,a3
	lea	InFrustumToTest,a4
	move.w	#$0,d6
	move.w	#5-1,d7
;	move.w	#1-1,d7
RL3:	move.w	d6,d5
	lsl.w	#4,d5
	move.w	(a6,d5.w),d0	; x1-vector
	move.w	2(a6,d5.w),d1	; x2-vector
; ------------------------- check if positions are in frustrum
	bsr	RL_CheckInside

	move.w	d0,d3
	move.w	d3,d4
	and.w	#7,d3
	lsr.l	#3,d4
	btst	d3,(a3,d4.w)
	beq.w	RL_n3

	move.w	d1,d3
	move.w	d3,d4
	and.w	#7,d3
	lsr.l	#3,d4
	btst	d3,(a2,d4.w)
	beq.b	RL_n3

; -------------------------
	lsl.w	#2,d0
	lsl.w	#2,d1
	move.l	(a5,d0),d0	; x1-vector
	move.l	(a5,d1),d1	; x2-vector
	move.w	d0,d2
	swap	d0
	ext.l	d0
	asl.l	#DeepShift,d0
	divs.w	d2,d0

	move.w	d1,d2
	swap	d1
	ext.l	d1
	asl.l	#DeepShift,d1
	divs.w	d2,d1

	move.w	d1,d2
	sub.w	d0,d2
	move.w	d2,6(a6,d5)

	cmp.w	#-ScreenWidth/2,d1
	ble.b	RL_n3

	cmp.w	#ScreenWidth/2,d1
	ble.b	RL_n2
	move.w	#ScreenWidth/2,d1
RL_n2:
	cmp.w	#ScreenWidth/2,d0
	bge.b	RL_n3


	move.w	#0,4(a6,d5)
	cmp.w	#-ScreenWidth/2,d0
	bge.b	RL_n0
	add.w	#ScreenWidth/2,d0
	neg.w	d0
	move.w	d0,4(a6,d5)
	move.w	#-ScreenWidth/2,d0
RL_n0:
	sub.w	d0,d1
	subq.w	#1,d1
	bmi.b	RL_n3
	ext.l	d0
	asl.l	#1,d0
	lea	ScreenPreRender+2*ScreenWidth/2,a0
RL_1:	cmp.w	#$ffff,(a0,d0)
	bne.b	RL_5
	move.w	d6,(a0,d0)
RL_5:	add.l	#2,d0
	dbf	d1,RL_1
RL_n3:
	add.w	#1,d6
	dbf	d7,RL3


;	lea	ScreenPreRender,a0
;	move.w	#ScreenWidth-1,d7
;RL_2:	move.w	(a0),d0
;	cmp.w	#$ffffffff,d0
;	beq.b	RL_3
;	move.w	d7,d6
;	and.l	#63,d6
;	or.l	#((121)<<6),d6
;	move.l	d6,(a0)
;RL_3:	addq	#4,a0
;	dbf	d7,RL_2

	bra	dd
	
; --------------------
; ScreenPreRender 00000000TTTTTTTT0CCZZZZZZZPPPPPP
; --------------------
mm:	lea	ScreenPreRender,a0
	lea	Sinus,a4
	move.w	SinPos,d4
	swap	d4
	move.w	SinPos+2,d4
	swap	d4
	move.w	movingX,d1
	move.w	#ScreenWidth-1,d7
RL1:	move.w	d1,d5
	lsr.w	#1,d5
	and.w	#63,d5
	move.w	(a4,d4.w),d2
	lsr.w	#4,d2
;	move.w	#0,YOffset
	sub.w	#19*(DoubleX+1)*2,d4
	and.w	#(SinusSize-1)*2,d4
	swap	d4
	move.w	(a4,d4.w),d0
	lsr.w	#2,d0
	add.w	d2,d0
	add.w	#32,d0
	add.w	#2*(DoubleX+1)*2,d4
	and.w	#(SinusSize-1)*2,d4
	swap	d4
	lsl.w	#6,d0
	or.w	d0,d5
; -------------------- testcolor
	move.w	d1,d0
	lsr.w	#7,d0
	and.w	#$3,d0
	ror.w	#16-6-7,d0
	or.w	d0,d5
; --------------------
	and.l	#$0000ffff,d5
	move.l	d5,(a0)+
	addq.l	#1*(DoubleX+1),d1
	dbf	d7,RL1

;----------------------------------------
dd:
	move.l	#$80000000,RLbit+2
	lea	Walls,a6
	lea	Vectors,a5
	lea	ScreenPreRender,a4
	move.w	#0,Statistics
	move.w	#0,Statistics+2
	move.w	movingX,d1
	move.l	Screens+4,a1
	add.l	#ScreenWidth/8*ScreenHeight*4,a1
	move.l	Screens+4,a3
	move.l	#0,d6			; last t/z
	move.l	#0,d3			; last 1/z
	move.w	#-1,d0			; last drawn wall
	move.w	#0,d4			; last drawn y
	move.w	#ScreenWidth/32-1,d7
_lh1:	swap	d7
	move.l	a3,a2
	move.w	#32/(DoubleX+1)-1,d7
_lh:	move.w	(a4)+,d1
	cmp.w	#$ffff,d1
	beq.w	RLnorender
;--------
;-- Render Span
;--------	
	cmp.w	d1,d0
	beq.w	RLnonewwall
	move.w	d1,d0

	move.w	d0,d5
	lsl.w	#4,d5

	move.w	#$4e71,RLbit+6		; nop ; 4e71
	move.w	#$4e71,RLbit+6+2
	move.w	#$4e71,RLbit+6+4
	move.w	8(a6,d5),d1	; color
	btst	#0,d1
	bne	eewl
	move.w	#$8791,RLbit+6		; or.l	d3,(a1)	; 8791
eewl:	btst	#1,d1
	bne	eewh
	move.w	#$87a9,RLbit+6+2	
	move.w #ScreenWidth/8,RLbit+6+4	; or.l	d3,ScreenWidth/8(a1) ; 87a9xxxx
eewh:
	move.w	(a6,d5),d1		; x1-vector
	move.w	2(a6,d5),d2		; x2-vector
	lsl.w	#2,d1
	lsl.w	#2,d2
	move.w	2(a5,d1),d3
	swap	d3
	move.w	2(a5,d2),d3
	move.w	6(a6,d5),d2
	swap	d3

	move.l	#64,d4
	asl.l	#DeepShift,d4
	divs.w	d3,d4
	swap	d3		; z2
	ext.l	d4
	asl.l	#7,d4

	move.l	#64,d1
	asl.l	#DeepShift,d1
	divs.w	d3,d1
	swap	d3		; z1
	ext.l	d1
	asl.l	#7,d1
	sub.l	d4,d1
	divs.w	d2,d1
	ext.l	d1
	move.l	d1,RLaddY+2
	sub.l	#$400,d4
	muls.w	4(a6,d5),d1
	add.l	d1,d4

	swap	d3		; z2
	move.l	#64<<12,d1
	divs.w	d3,d1
	ext.l	d1
	asl.l	#8,d1
	divs.w	d2,d1
	ext.l	d1
	move.l	d1,RLaddT+2
	move.l	#$0,d6
	move.w	4(a6,d5),d2
	ext.l	d2
	muls	d2,d1
	add.l	d1,d6

	move.l	#1<<16,d2
	move.l	d2,d1
	divs.w	d3,d2
	swap	d3		; z1
	divs.w	d3,d1
	ext.l	d2
	ext.l	d1
	asl.l	#8,d2
	asl.l	#8,d1
	sub.l	d1,d2
	divs.w	6(a6,d5),d2
	ext.l	d2
	move.l	d2,RLaddZ+2
	move.w	4(a6,d5),d3
	ext.l	d3
	muls	d3,d2
	add.l	d2,d1
	move.l	d1,d3

RLnonewwall:
	movem.l	d0-d7/a0-a6,-(sp)

	move.l	d6,d5
	asr.l	#2,d5
	move.l	d3,d0
	asr.l	#6,d0
	divs.w	d0,d5
	and.l	#63,d5
	move.l	d4,d0
	eor.b	d0,d0
	lsr.l	#1,d0
	or.l	d0,d5
	and.l	#%1111111111111,d5
;	and.l	#%111111,d5

RLbit:	move.l	#$80000000,d3
	nop
	nop
	nop
	move.l	d4,d0
	asr.l	#7,d0
	add.w	#20,d0
	move.w	#ScreenHeight/2,d1
	sub.w	d0,d1
	bpl.b	RL5
	move.w	#0,d1
RL5
	muls.w	#ScreenWidth/8,d1
	add.w	#ScreenWidth/8*2*ScreenHeight,d1
	eor.l	d3,(a3,d1)

	bsr	RenderTexLine
	movem.l	(sp)+,d0-d7/a0-a6
RLnorender:
RLaddY:	add.l	#$00000000,d4
RLaddT:	add.l	#$00000000,d6
RLaddZ:	add.l	#$00000000,d3
	add.l	#ScreenWidth/8*(DoubleX+1),a2
	move.l	RLbit+2,d5
	ror.l	#1,d5
	move.l	d5,RLbit+2
	dbf	d7,_lh
	add.l	#4,a3
	add.l	#4,a1
	swap	d7
	dbf	d7,_lh1

;----------------------------------------

	rts

	lea	ScreenStats,a0
	move.l	#0,d0
	move.w	#320/8/4*8*2,d7
RLcl0:	move.l	d0,(a0)+
	dbf	d7,RLcl0

	lea	ScreenStats,a0
	move.l	#$ffffffff,(a0)
	move.w	Statistics+StatsNonCached,d0
	mulu.w	#31,d0
	divu.w	#192,d0
	cmp.w	#0,d0
	beq.b	RLdd
	move.l	#$ffffffff,d1
	eor.w	#31,d0
	lsl.l	d0,d1
	move.l	d1,320/8*8(a0)
RLdd:
	addq.l	#5,a0
	move.w	Frames,d0
ffe:	move.b	#$fe,(a0)+
	dbf	d0,ffe

	rts
StatsNonCached	= 0
StatsCached     = 2
Statistics:
	dc.w	0
	dc.w	0
TexAnim:
	dc.l	0
;--------------------------------------------------------------------	
	EVEN
Lines8	= ScreenHeight/16*2*Planes
ScreenBlt:	
;	IFNE	DoubleX
;	move.l	BltSrc,a1
;	move.l	a1,a2
;	add.l	#ScreenWidth/8,a2
;	move.w	#ScreenHeight/2*Planes*64+((ScreenWidth/16*1)&63),-(sp)
;	move.l	a2,-(sp)
;	move.l	#0,-(sp)
;	move.l	a1,-(sp)
;	move.l	a1,-(sp)
;	move.w	#ScreenWidth/8,-(sp)
;	move.w	#0,-(sp)
;	move.w	#0,-(sp)
;	move.w	#ScreenWidth/8,-(sp)
;	move.l	#$09f00000,-(sp)
;	bsr	SetBlit
;	ENDC

OFFSET16 = ScreenWidth/8*16
	move.l	BltDst,a1
	move.l	BltSrc,a2
;	add.l	#OFFSET16,a1
;	add.l	#OFFSET16,a2
	move.w	#(Planes*ScreenHeight)*64+((ScreenWidth/16)&63),-(sp); Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask16+2+ScreenWidth/8*16,-(sp)			; C-Mask
	move.l	BltDst,a3
	add.l	#-ScreenWidth/8*16+2,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#0,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0fe40000,-(sp)				; BlitCon0/1
	bsr	SetBlit

	move.l	BltSrc,a1
	move.l	BltDst,a2
	move.w	#(Planes*ScreenHeight-16)*64+((ScreenWidth/16)&63),-(sp) ; Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask16,-(sp)				; C-Mask
	move.l	BltDst,a3
	add.l	#ScreenWidth/8*16-2,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#0,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0fe40000,-(sp)				; BlitCon0/1
	bsr	SetBlit
	

; 8 bit
	move.l	BltDst,a1
	move.l	BltSrc,a2
	move.w	#(Planes*ScreenHeight-8)*64+((ScreenWidth/16)&63),-(sp)	; Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask8,-(sp)				; C-Mask
	move.l	a1,a3
	add.l	#ScreenWidth/8*8,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#0,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0fe48000,-(sp)				; BlitCon0/1
	bsr	SetBlit

OFFSET8 = ScreenWidth/8*Planes*ScreenHeight-2
	move.l	BltSrc,a1
	move.l	BltSrc,a2
	add.l	#OFFSET8,a1
	add.l	#OFFSET8,a2
	move.w	#(Planes*ScreenHeight-8)*64+((ScreenWidth/16)&63),-(sp); Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask8_+OFFSET8,-(sp); C-Mask
	move.l	BltDst,a3
	add.l	#OFFSET8,a3	
	sub.l	#ScreenWidth/8*8,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#0,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0fe48002,-(sp)				; BlitCon0/1
	bsr	SetBlit
; 4 bit
	move.l	BltSrc,a1
	move.l	BltDst,a2
	move.w	#(Planes*ScreenHeight-4)*64+((ScreenWidth/16)&63),-(sp)	; Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask4,-(sp)				; C-Mask
	move.l	a1,a3
	add.l	#ScreenWidth/8*4,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#0,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0fe44000,-(sp)				; BlitCon0/1
	bsr	SetBlit

OFFSET4 = ScreenWidth/8*Planes*ScreenHeight-2
	move.l	BltDst,a1
	move.l	BltDst,a2
	add.l	#OFFSET4,a1
	add.l	#OFFSET4,a2
	move.w	#(Planes*ScreenHeight-4)*64+((ScreenWidth/16)&63),-(sp); Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask4_+OFFSET4,-(sp); C-Mask
	move.l	BltSrc,a3
	add.l	#OFFSET4,a3	
	sub.l	#ScreenWidth/8*4,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#0,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0fe44002,-(sp)				; BlitCon0/1
	bsr	SetBlit
; 2 bit
	move.l	BltDst,a1
	move.l	BltSrc,a2
	move.w	#(Planes*ScreenHeight/4)*64+((ScreenWidth/16*4)&63),-(sp)	; Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask2,-(sp)				; C-Mask
	move.l	a1,a3
	add.l	#ScreenWidth/8*2,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#-ScreenWidth/8*4,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0fe42000,-(sp)				; BlitCon0/1
	bsr	SetBlit

OFFSET2 = ScreenWidth/8*(Planes*ScreenHeight)-2
	move.l	BltSrc,a1
	move.l	BltSrc,a2
	add.l	#OFFSET2,a1
	add.l	#OFFSET2,a2
	move.w	#(Planes*ScreenHeight/4)*64+((ScreenWidth/16*4)&63),-(sp); Size
;	move.w	#(4-2)*64+((ScreenWidth/16*4)&63),-(sp); Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask2_+ScreenWidth/8*4-2,-(sp); C-Mask
	move.l	BltDst,a3
	add.l	#OFFSET2,a3	
	sub.l	#ScreenWidth/8*2,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#-ScreenWidth/8*4,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0fe42002,-(sp)				; BlitCon0/1
	bsr	SetBlit
; 1 bit
	move.l	BltSrc,a1
	move.l	BltDst,a2
	move.w	#(Planes*ScreenHeight)/2*64+((ScreenWidth/16*2)&63),-(sp)	; Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask1,-(sp)				; C-Mask
	move.l	a1,a3
	add.l	#ScreenWidth/8*1,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#-ScreenWidth/8*2,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0fe41000,-(sp)				; BlitCon0/1
	bsr	SetBlit

OFFSET1 = ScreenWidth/8*(Planes*ScreenHeight)-2
	move.l	BltDst,a1
	move.l	BltDst,a2
	add.l	#OFFSET1,a1
	add.l	#OFFSET1,a2
	move.w	#(Planes*ScreenHeight/2)*64+((ScreenWidth/16*2)&63),-(sp); Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask1_+ScreenWidth/8*2-2,-(sp); C-Mask
	move.l	BltSrc,a3
	add.l	#OFFSET1,a3	
	sub.l	#ScreenWidth/8*1,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#-ScreenWidth/8*2,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0fe41002,-(sp)				; BlitCon0/1
	bsr	SetBlit

	move.l	BltDst,a1
	add.l	#ScreenWidth/8*ScreenHeight*2,a1
	move.l	a1,a2
	add.l	#ScreenWidth/8,a2
	move.w	#(ScreenHeight)/2*64+((ScreenWidth/16)&63),-(sp)	; Size
	move.l	a2,-(sp)					; D-Dest
	move.l	0,-(sp)				; C-Mask
	move.l	a1,a3
	add.l	#ScreenWidth/8*1,a3
	move.l	a2,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#0,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$0d3c0000,-(sp)				; BlitCon0/1
	bsr	SetBlit


	move.l	BltSrc,a1
	move.l	BltClr,a2
	add.l	#ScreenWidth/8*ScreenHeight*Planes,a2
	move.w	#(ScreenHeight/4*2)*64+((ScreenWidth/16*4)&63),-(sp)	; Size
	move.l	a2,-(sp)					; D-Dest
	move.l	#BufferMask1,-(sp)				; C-Mask
	move.l	a1,a3
	add.l	#ScreenWidth/8*1,a3
	move.l	a3,-(sp)					; B-Src1
	move.l	a1,-(sp)					; A-Src0
	move.w	#0,-(sp)		; D-Mod
	move.w	#0,-(sp)		; C-Mod
	move.w	#0,-(sp)		; B-Mod
	move.w	#0,-(sp)		; A-Mod
	move.l	#$01000000,-(sp)				; BlitCon0/1
	bsr	SetBlit

	rts
;--------------------------------------------------------------------
SetBlit:
	move.l	(sp)+,SetBlitBack+2
	lea	BlitList,a0
	eor.l	d0,d0
	move.w	BlitListEnd+2,d0
	lsl.l	#5,d0
	move.l	(sp)+,(a0,d0)	; BLTCON0
	move.w	(sp)+,4(a0,d0)	; BLTAMOD
	move.w	(sp)+,6(a0,d0)	; BLTBMOD
	move.w	(sp)+,8(a0,d0)	; BLTCMOD
	move.w	(sp)+,10(a0,d0)	; BLTDMOD
	move.l	(sp)+,12(a0,d0)	; BLTAPTH
	move.l	(sp)+,16(a0,d0)	; BLTBPTH
	move.l	(sp)+,20(a0,d0)	; BLTCPTH
	move.l	(sp)+,24(a0,d0)	; BLTDPTH
	move.w	(sp)+,28(a0,d0)	; BLTSIZE
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
	lsl.l	#5,d0

	lea	$dff000,a6
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
	move.w	BlitListBeg,d0
	addq.w	#1,d0
	and.w	#BlitListLen-1,d0
	move.w	d0,BlitListBeg
	move.w	28(a0),BLTSIZE(a6)
NoBlitList:
	rts
;--------------------------------------------------------------------
	EVEN
BltSrc:	dc.l	0
BltDst:	dc.l	0
BltClr:	dc.l	0
movingX:dc.w	0
BlitListBeg:
	dc.w	0
BlitListEnd:
	dc.w	0,0
Frames:
	dc.w	0
;--------------------------------------------------------------------
ID	= 0
Tex	= 2
Next	= 6
Pre	= 4
RenderTexLine:
	; d5 - TexLine
	; a6 - TexCacheMap
	; a2 - Screen

RTLgo1:	lea	Texture,a3
	move.l	TexAnim,d0
	lsl.l	#8,d0
	lsl.l	#2,d0
	add.l	d0,a3
	move.w	d5,d0
	and.w	#63,d0
	mulu.w	#128/8,d0
	add.l	d0,a3
	move.l	a2,a4
	jsr	Zoom

	add.w	#1,Statistics+StatsNonCached
RTLend:
	rts
;--------------------------------------------------------------------
	include "Wolfenstein3D/zoom.i"
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
;--------------------------------------------------------------------
;	section	tex1,DATA_F
SinPos:
	dc.w	0,0
	EVEN
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

	EVEN
VectorsOrg:		; x, z
	dc.w	-64-128,128-128
	dc.w	-64,128
	dc.w	-64,256
	dc.w	64,256
	dc.w	64,128
	dc.w	64+128,128-128
	EVEN
Vectors:		; x, z
	dc.w	-64-128-64,128
	dc.w	-64-64,128
	dc.w	-64-64,256
	dc.w	64-64,256
	dc.w	64-64,128
	dc.w	64+128-64,128
	EVEN
Walls:			; p1, p2, tex, tmp
	dc.w	0,1,0,0,3,0,0,0
	dc.w	1,2,0,0,0,0,0,0
	dc.w	2,3,0,0,1,0,0,0
	dc.w	3,4,0,0,2,0,0,0
	dc.w	4,5,0,0,3,0,0,0
	EVEN
Palette:
	dc.w	$0008
	dc.w	$0533
	dc.w	$0966
	dc.w	$0fdd
	
	dc.w	$0111
	dc.w	$0666
	dc.w	$0aaa
	dc.w	$0fff
	
	dc.w	$0111
	dc.w	$0353
	dc.w	$0696
	dc.w	$0dfd
	
	dc.w	$0111
	dc.w	$0335
	dc.w	$0669
	dc.w	$0ddf

	dc.w	$068a
	dc.w	$08ab
	dc.w	$0abb
	dc.w	$0dcc

	dc.w	$068a
	dc.w	$089b
	dc.w	$0abc
	dc.w	$0cce

	dc.w	$068a
	dc.w	$07ac
	dc.w	$09bd
	dc.w	$0bde

	dc.w	$068a
	dc.w	$079c
	dc.w	$09ad
	dc.w	$0bbe


ColorReflBottom:
	dc.w	$0a86
	dc.w	$0b97
	dc.w	$0ca9
	dc.w	$0ecc	
	
	dc.w	$0a86
	dc.w	$0ba9
	dc.w	$0dcb
	dc.w	$0edd
	
	dc.w	$0a86
	dc.w	$0ba8
	dc.w	$0cca
	dc.w	$0cec

	dc.w	$0a86
	dc.w	$0b98
	dc.w	$0bab
	dc.w	$0cce

Texture:
	incbin	Wolfenstein3D/texanim1.bin
*********************************************************************

	SECTION	chip,DATA_C
	EVEN
; display dimensions
DISPW           equ     ScreenWidth
DISPH           equ     ScreenHeight-CutLow

; display window in raster coordinates (HSTART must be odd)
HSTART          equ     129+(256-ScreenWidth)/2
VSTART          equ     36+16
VEND            equ     VSTART+DISPH

; normal display data fetch start/stop (without scrolling)
DFETCHSTART     equ     HSTART/2
DFETCHSTOP      equ     DFETCHSTART+8*((DISPW/16)-1)

	EVEN
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
	dc.w	$00f0,$0000
	dc.w	$00f2,$0000
	dc.w	$00f4,$0000
	dc.w	$00f6,$0000
	dc.w	$00e8,$0000
	dc.w	$00ea,$0000
	dc.w	$00ec,$0000
	dc.w	$00ee,$0000
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
	dc.w	$0100,$6200;+(Planes<<12)
	dc.w	$0180,$0000
PlaneDouble1:
	ds.l	(ScreenHeight-CutLow)*7+16

;	dc.w	$0007+((VSTART+(ScreenHeight-CutLow))<<8),$fffe
	dc.w	$0100,$0200
	dc.w	$0180,$0008

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
	dc.w	$00f0,$0000
	dc.w	$00f2,$0000
	dc.w	$00f4,$0000
	dc.w	$00f6,$0000
	dc.w	$00e8,$0000
	dc.w	$00ea,$0000
	dc.w	$00ec,$0000
	dc.w	$00ee,$0000
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
	dc.w	$0100,$6200;+(Planes<<12)
	dc.w	$0180,$0000
PlaneDouble2:
	ds.l	(ScreenHeight-CutLow)*7+16

;	dc.w	$0007+((VSTART+ScreenHeight-CutLow)<<8),$fffe
	dc.w	$0100,$0200
	dc.w	$0180,$0008

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
	dc.w	$00f0,$0000
	dc.w	$00f2,$0000
	dc.w	$00f4,$0000
	dc.w	$00f6,$0000
	dc.w	$00e8,$0000
	dc.w	$00ea,$0000
	dc.w	$00ec,$0000
	dc.w	$00ee,$0000
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
	dc.w	$0100,$6200;+(Planes<<12)
	dc.w	$0180,$0000
PlaneDouble3:
	ds.l	(ScreenHeight-CutLow)*7+16


;	dc.w	$0007+((VSTART+ScreenHeight)<<8),$fffe
	dc.w	$0100,$0200
	dc.w	$0180,$0008

	dc.w	$ffff,$fffe





;	dc.w	$0100,$0200

;	dc.w	$008e,$2c81
;	dc.w	$0090,$2cc1
;	dc.w	$0092,$0038
;	dc.w	$0094,$00d0
;	dc.w	$0108,$0000
;	dc.w	$010a,$0000
;	dc.w	$0102,$0000
;	dc.w	$0182,$0fff
;	dc.w	$0184,$0f0f
;	dc.w	$0186,$00ff
;StatB0:	dc.w	$00e0,$0000
;	dc.w	$00e2,$0000
;	dc.w	$00e4,$0000
;	dc.w	$00e6,$0000
;	dc.w	$0007+((ScreenHeight*2+VSTART+1)&255)<<8,$fffe
;	dc.w	$0100,$2200
;	dc.w	$0007+((ScreenHeight*2+VSTART+1+8)&255)<<8,$fffe
;	dc.w	$0100,$0200

;	dc.w	$0180,$0000

;	dc.w	$ffff,$fffe

BufferMaskDoubleX:
	dc.w	$aaaa

*********************************************************************

	SECTION mem,BSS_C
Screen1:
	ds.b	ScreenWidth/8*ScreenHeight*4+ScreenWidth/8*2
Screen2:
	ds.b	ScreenWidth/8*ScreenHeight*4+ScreenWidth/8*2
Screen3:
	ds.b	ScreenWidth/8*ScreenHeight*4+ScreenWidth/8*2
BufferTmp:
	ds.b	ScreenWidth/8*ScreenHeight*Planes
BufferMask16:
	ds.b	ScreenWidth/8*Planes*(ScreenHeight+16)
BufferMask8:
	ds.b	ScreenWidth/8*Planes*ScreenHeight
BufferMask8_:
	ds.b	ScreenWidth/8*Planes*ScreenHeight
BufferMask4:
	ds.b	ScreenWidth/8*Planes*ScreenHeight
BufferMask4_:
	ds.b	ScreenWidth/8*Planes*ScreenHeight
BufferMask2:
	ds.b	ScreenWidth/8*Planes*6
BufferMask2_:
	ds.b	ScreenWidth/8*Planes*6
BufferMask1:
	ds.b	ScreenWidth/8*Planes*3
BufferMask1_:
	ds.b	ScreenWidth/8*Planes*3
ScreenStats:
	ds.b	320/8*8*2
;--------------------------------------------------------------------
;--------------------------------------------------------------------
	section	tex,BSS_F
BlitList:
	ds.b	32*BlitListLen
ScreenPreRender:
	ds.w	ScreenWidth
BitZoom:
	ds.l	65536
InFrustumLeft:
	ds.b	128-4
InFrustumRight:
	ds.b	128-4
InFrustumToTest:
	ds.b	128-4
