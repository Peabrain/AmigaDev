COMPATIBILITY	=	1
FASTMEM	=	0
RMBPAUSE	=	0
FPUINT	=	0
COPPER	=	0
BLITTER	=	0
SPRITE	=	0
TOPAZ	=	0
SECTIONHACK	=	0

	include	cinter/DemoStartup.S
	include	Cinter/Cinter3.S

_Exit:
	rts

_Precalc:
	move.l	ChipPtr(pc),a4
	add.l	#InstrumentSpace-Chip,a4
	lea	MusicData(pc),a2
	move.l	a2,a6
	add.l	#CinterSpace-MusicData,a6
	; A2 = Music data
	; A4 = Instrument space
	; A6 = Cinter working memory
	bsr.w	CinterInit
	rts

_Main:

MainLoop:
	bra.w	MainLoop

_Interrupt:
	lea	MusicData(pc),a2
	move.l	a2,a6
	add.l	#CinterSpace-MusicData,a6
	; A6 = Cinter working memory
	bsr.w	CinterPlay1

	; Put your other interrupt code here

	lea	MusicData(pc),a2
	move.l	a2,a6
	add.l	#CinterSpace-MusicData,a6
	; A6 = Cinter working memory
	bsr.w	CinterPlay2
	rts

MusicData:
	incbin	Cinter/test.cinter

CinterSpace:
	ds.b	c_SIZE

	section	inst,bss_c
Chip:

InstrumentSpace:
	ds.b	200000


	section	music,data

