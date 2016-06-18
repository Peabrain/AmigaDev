/*; ys = Position im Langwort
; ye = Position im Langwort+Zoombits

; für obere freie Stellen in der Spalte
{
	move.l	#$0,d5
	move.l	d5,X(a2)
	....
}
; ersten 32 Bit der Textur
{
	move.l (a0)+,d0
	rol.l	#8,d0
}
; x4 wiederholen
{
	; bereite d2 (offset für bitzoom) vor
	{
		rol.l	#8,d0
		move.w	d0,d2
		eor.b	d2,d2
	}
	; hole gezoomtes Langwort
	{
		; wenn ys == 0
		move.l	ZOOMx*4(a1,d2.l),d5
		; ansonsten
		{
			move.l	ZOOMx*4(a1,d2.l),d4
			; wenn ye neues Langwort
			{
				; d4 temporär in d3 speichern
				move.l	d4,d3
				; schiebe d4 an Position ys
				{
					; wenn ys < 16
					{
						lsl.l	#ys,d4
					}
					; oder
					{
						eor.w	d4,d4
						swap	d4
						lsl.l	#ys-16,d4
					}
				}
				; setze d4 an Position ys in D5 und schreibe d5
				or.l	d4,d5
				move.l	d5,Y(a2)
				; zurückholen von d4
				move.l	d3,d5
				; schiebe d4 an Position 31-ys
				{
					; wenn (31-ys) < 16
					{
						lsl.l	#(31-ys),d4
					}
					; oder
					{
						swap	d4
						eor.w	d4,d4
						lsl.l	#(31-ys)-16,d4
					}
					ys = 0
				}
			}
			; ansonsten
			{
				; schiebe d4 an Position ys
				{
					; wenn ys < 16
					{
						lsl.r	#ys,d4
					}
					; oder
					{
						eor.w	d4,d4
						swap	d4
						lsl.r	#ys-16,d4
					}
				}
				; setze d4 an Position ys in D5 und schreibe d5
				or.l	d4,d5
			}
		}
	}
}
*/
#include	<stdio.h>
void rot(int ys,FILE *f)
{
	if(ys < 8)
	{
		if(ys > 0) fprintf(f,"\tlsr.l #%i,d4\n",ys);
	}
	else
	if(ys < 16)
	{
		fprintf(f,"\tswap d4\n");
		if(-(ys-16) > 0) fprintf(f,"\trol.l #%i,d4\n",-(ys-16));
	}
	else
	if(ys < 24)
	{
		fprintf(f,"\tswap d4\n");
		if(ys-16 > 0) fprintf(f,"\tlsr.l #%i,d4\n",ys-16);
	}
	else
	{
		if(-(ys-32) > 0) fprintf(f,"\trol.l #%i,d4\n",-(ys-32));
	}						
}
int	main()
{
	if(FILE *f = fopen("ZoomTmp.i","w"))
	{
		#define	Zoomstufen 128
		#define	ScreenHeight 160
		int j;
		fprintf(f,"ZoomAddr:\n");
		for(j= 16;j < Zoomstufen+5;j++)
		{
			if(!(j % 8))
				fprintf(f,"\tdc.l ");
			fprintf(f,"Zoom%i",j);
			if(!((j+1) % 8))
				fprintf(f,"\n");
			else
				fprintf(f,",");
		}


		int ZSize = 8;
		for(j = 16;j < Zoomstufen+5;j++,ZSize +=2)
		{
			int	count = 0;
			int	Zoom = 22;
			int	i,ScrPos = 0,k;
			int	yr = (ScreenHeight - ZSize*2) / 2; //176 / 2 - 64 / 2;
			int	ys = yr%32,yn = 0;
			int stop = 0;

			fprintf(f,"Zoom%i:\n",j);

			if(yr < 0) yr = 0;

			int	startYbyte = 0;
			if(yr / 32 > 0)
			{
				int i = 0;
				fprintf(f,"\teor.l d5,d5\n");
				for(i = 0;i < yr / 32; i++)
				{
					fprintf(f,"\tmove.l d5,ScreenWidth/8*32*%i(a2)\n",ScrPos++);
	//				yr += 32;
	//				yr %= 32;
				}
			}
			fprintf(f,"\teor.l d5,d5\n");
			yr = ZSize * count / 8 + (ScreenHeight - ZSize*2) / 2;
			for(k = 0;k < 4 && stop == 0;k++)
			{
				fprintf(f,"\tmove.l (a0)+,d0\n");
				fprintf(f,"\trol.l #8,d0\n");

				for(i = 0;i < 4 && stop == 0;i++)
				{
					yn = ZSize * (count + 1) / 8 + (ScreenHeight - ZSize*2) / 2;
					Zoom = yn - yr;
					fprintf(f,"; yn=%i,yr=%i\n",yn,yr);
					fprintf(f,"\trol.l #8,d0\n");
					if(yn> 0)
					{
						fprintf(f,"\tmove.w d0,d2\n");
						fprintf(f,"\teor.b d2,d2\n");
						fprintf(f,"\tmove.l %i*4(a1,d2.l),d4\n",(Zoom-1));
						if(yr < 0)
						{
							int z = -yr,u;
							for(u = 0;u < z / 8;u++)
								fprintf(f,"\tlsl.l #8,d4\n");
							if(z & 7) fprintf(f,"\tlsl.l #%i,d4\n",z & 7);
	//						Zoom += yr;
	//						yr = 0;
							ys = 0;
						}
						if((ys&31) + Zoom == 32)
						{
							rot(ys,f);
							fprintf(f,"\tor.l d4,d5\n");
							fprintf(f,"\tmove.l d5,ScreenWidth/8*32*%i(a2)\n",ScrPos++);
							if(ScrPos >= ScreenHeight/32)
							{
								stop = 1;
								break;
							}
							fprintf(f,"\teor.l d5,d5\n");
						}
						else
						if((ys&31) + Zoom > 32)
						{
							fprintf(f,"\tmove.l d4,d3\n");
							rot(ys,f);
							fprintf(f,"\tand.l #$%x,d4\n",(unsigned int)(2<<(31-ys))-1);
							fprintf(f,"\tor.l d4,d5\n");					
							fprintf(f,"\tmove.l d5,ScreenWidth/8*32*%i(a2)\n",ScrPos++);
							if(ScrPos >= ScreenHeight/32)
							{
								stop = 1;
								break;
							}
							fprintf(f,"\tmove.l d3,d5\n");
							int l = ((32-ys) % 32);

							if(l < 8)
							{
								if(l > 0) fprintf(f,"\tlsl.l #%i,d5\n",l);
							}
							else
							if(l < 16)
							{
		//						printf("\tswap d5\n");
		//						if(-(l-16) > 0) printf("\tror.l #%i,d5\n",-(l-16));
								fprintf(f,"\tlsl.l #8,d5\n");
								if(l-8 > 0) fprintf(f,"\tlsl.l #%i,d5\n",l-8);
							}
							else
							if(l < 24)
							{
		//						printf("\tswap d4\n");
		//						if(l-16 > 0) printf("\tlsl.l #%i,d5\n",l-16);
								fprintf(f,"\tlsl.l #8,d5\n");
								fprintf(f,"\tlsl.l #8,d5\n");
								if(l-16 > 0) fprintf(f,"\tlsl.l #%i,d5\n",l-16);
							}
							else
							{
		//						if(-(l-32) > 0) printf("\tror.l #%i,d5\n",-(l-32));
								fprintf(f,"\tlsl.l #8,d5\n");
								fprintf(f,"\tlsl.l #8,d5\n");
								fprintf(f,"\tlsl.l #8,d5\n");
								if(l-24 > 0) fprintf(f,"\tlsl.l #%i,d5\n",l-24);
							}						
		//					printf("\tand.l #$%x,d5\n",(unsigned int)(0xffffffff^(0xffffffff<<l)));
						}
						else
						{
							rot(ys,f);
							fprintf(f,"\tor.l d4,d5\n");
						}
					}
					yr = yn;
					if(yr >= ScreenHeight) stop = 1;
					ys = yr % 32;
					count++;
				}
			}
			if(ScrPos<ScreenHeight/32)
				fprintf(f,"\tmove.l d5,ScreenWidth/8*32*%i(a2)\n",ScrPos++);
			if(ScrPos<ScreenHeight/32)
			{
				fprintf(f,"\teor.l d5,d5\n");
				while(ScrPos<ScreenHeight/32)
					fprintf(f,"\tmove.l d5,ScreenWidth/8*32*%i(a2)\n",ScrPos++);
			}
		
			fprintf(f,"\trts\n");
		}
		fclose(f);
	}
	return 0;
}
