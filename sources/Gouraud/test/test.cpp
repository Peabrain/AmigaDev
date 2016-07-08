#include	<stdio.h>
#include	<math.h>
//////////////////////////////////////////////////////
#define	PI 3.141592653589793
#define	SINCOS 1024
//////////////////////////////////////////////////////
typedef struct VEC3
{
	int	x,y,z;	
}VEC3;
typedef struct VEC2
{
	int	x,y;	
}VEC2;
typedef struct EDGE
{
	int a,b;	
}EDGE;
typedef	struct POLYGON
{
	int	vertices[4];	// -1 = means no vector
	int edges[4];		// -1 = means no edge
	VEC3 normal;
	VEC3 normalCalced;
	int visible;
}POLYGON;
typedef struct VEC2COL
{
	VEC2 v;
	int c;
}VEC2COL;
//////////////////////////////////////////////////////
VEC3	VectorsOrg[8] = 
{
	{-256,-256,-256},	// 0
	{ 256,-256,-256},	// 1
	{ 256, 256,-256},	// 2
	{-256, 256,-256},	// 3
	{-256, 256, 256},	// 4
	{ 256, 256, 256},	// 5
	{ 256,-256, 256},	// 6
	{-256,-256, 256},	// 7
};
VEC3	NormalsOrg[8] = 
{
	{-148,-148,-148},	// 0
	{ 148,-148,-148},	// 1
	{ 148, 148,-148},	// 2
	{-148, 148,-148},	// 3
	{-148, 148, 148},	// 4
	{ 148, 148, 148},	// 5
	{ 148,-148, 148},	// 6
	{-148,-148, 148},	// 7
};
EDGE Edges[] =
{
	{0,1},	// 0
	{1,2},	// 1
	{2,3},	// 2
	{3,0},	// 3
	{4,5},	// 4
	{5,6},	// 5
	{6,7},	// 6
	{7,4},	// 7
	{0,7},	// 8
	{1,6},	// 9
	{2,5},	// 10
	{3,4},	// 11
};
POLYGON	Polygons[] = 
{
	{{0,1,2,3},{0,1,2,3},{0,0,-256},0},
	{{1,6,5,2},{9,5,10,1},{256,0,0},0},
	{{6,7,4,5},{6,7,4,5},{0,0,256},0},
	{{7,0,3,4},{8,3,11,7},{-256,0,0},0},
	{{7,6,1,0},{6,9,0,8},{0,-256,0},0},
	{{3,2,5,4},{2,10,4,11},{0,256,0},0}
};
VEC3 Vectors[8];
VEC3 Normals[8];
int Dots[8];
VEC2 Vectors2D[8];
int RotationMatrix[] = 
{
	0,0,0,0,
	0,0,0,0,
	0,0,0,0,
};
//int WinkelX = (-128) & (SINCOS - 1),WinkelY = (0) & (SINCOS - 1),WinkelZ = (128) & (SINCOS - 1);
int WinkelX = (-128) & (SINCOS - 1),WinkelY = (32) & (SINCOS - 1),WinkelZ = (-144) & (SINCOS - 1);
// Problemfall !!!
//int WinkelX = (-0) & (SINCOS - 1),WinkelY = (0) & (SINCOS - 1),WinkelZ = (-0) & (SINCOS - 1);
#define SHADEFACTOR 10
//////////////////////////////////////////////////////
int	Sin[SINCOS];
int	Cos[SINCOS];
int ACos[256*2];
int EdgeVisible[12];
char	Screen[80*80];
char	Screen2[80*80];
//VEC2COL vTop;
int Top = 40;
int Bottom = -40;
int Left = 40;
int Right = -40;
int RightY = 0;
int EdgesCalced[12];
int EdgesCalcedLast[12];
VEC2COL Vec2Col[1024];
int Vec2ColCount = 0; 
//////////////////////////////////////////////////////
void	Init();
void	CalculateVectors();
void	CalculateNormals();
void	PrintVectors();
int	Dot(VEC3 v0,VEC3 v1);
VEC3 	Cross(VEC3 v0,VEC3 v1);
int		IsPolygonVisible(int p,VEC3 source);
void	CheckPolygonsVisible(VEC3 source);
void	CalculateRotationMatrix();
VEC3 	CalculateVector(VEC3 v);
VEC3 	CalculateNormal(VEC3 v);
void 	CalculateEdgeSplit();
void	ClearScreen();
void	PrintScreen();
void	GetBound(VEC2 &v0,VEC2 &v1,int Bound_v0,int Bound_v1);
VEC2 	Cut(VEC2 v0,VEC2 v1,int check,int check_first);
VEC2 	GetBoundVec(VEC2 v0,VEC2 v1);
void	DrawLine(char * Screen,int x0,int y0,int x1,int y1,char m);
void	DrawLineEor(char * Screen,int x0,int y0,int x1,int y1,char m);
void	DrawLineC(char * Screen,int x0,int y0,int x1,int y1,int aNorm,int bNorm);
//////////////////////////////////////////////////////
int	main()
{
	int MostTop = -1;
	VEC3 source = {0,0,0};
	int RightSideEdgeBits = 0;
	Init();

//	while(1)
//	{

	for(int i = 0;i < 80 * 80;i ++)
	{
		Screen[i] = 0;
		Screen2[i] = 0;
	}
	for(int i = 0;i < 12;i++) 
	{
		EdgeVisible[i] = 0;
	}

	Top = 40;
	Bottom = -40;
	Left = 40;
	Right = -40;
	RightY = 0;
	Vec2ColCount = 0;

	CalculateRotationMatrix();
	CalculateVectors();	
	CalculateNormals();	
	PrintVectors();
	CheckPolygonsVisible(source);
	CalculateEdgeSplit();
	ClearScreen();

	for(int i = 0;i < sizeof(Vectors2D)/sizeof(VEC2);i++)
	{
		if(Vectors2D[i].x < Left)
			Left = Vectors2D[i].x;
		else
		if(Vectors2D[i].x > Right)
		{
			Right = Vectors2D[i].x;
			RightY = Vectors2D[i].y;
		}
		if(Vectors2D[i].y < Top)
		{
			Top = Vectors2D[i].y;
			MostTop = i;
		}
		else
		if(Vectors2D[i].y > Bottom)
			Bottom = Vectors2D[i].y;
	}

	printf("Top: %i, Bottom: %i, Left: %i, Right: %i\n",Top,Bottom,Left,Right);

/*	for(int i = Left + 40;i < Right + 40;i++)
	{
		Screen[(Top + 40) * 80 + i] = 'A'-'a';
		Screen[(Bottom + 40) * 80 + i] = 'B'-'a';
	}
	for(int i = Top + 40;i < Bottom + 40;i++)
	{
		Screen[i * 80 + Left + 40] = 'L'-'a';
		Screen[i * 80 + Right + 40] = 'R'-'a';
	}
/**/
/*	for(int i = 0;i < 6;i++)
	{
		if(Polygons[i].visible)
		{
			int pTop = 100000000;
			int iTop = -1;
			for(int j = 0;j < 4;j++)
			{
				if(Vectors2D[Polygons[i].vertices[j]].y < pTop)
				{
					pTop = Vectors2D[Polygons[i].vertices[j]].y;
					iTop = j;
				}
			}
			int pt[4] = {Polygons[i].vertices[iTop],Polygons[i].vertices[(iTop + 1) & 3],Polygons[i].vertices[(iTop - 1) & 3],Polygons[i].vertices[(iTop + 2) & 3]};
			DrawLine(Vectors2D[pt[0]].x,Vectors2D[pt[0]].y,Vectors2D[pt[1]].x,Vectors2D[pt[1]].y,1);
			DrawLine(Vectors2D[pt[0]].x,Vectors2D[pt[0]].y,Vectors2D[pt[2]].x,Vectors2D[pt[2]].y,1);
			DrawLine(Vectors2D[pt[1]].x,Vectors2D[pt[1]].y,Vectors2D[pt[3]].x,Vectors2D[pt[3]].y,1);
			DrawLine(Vectors2D[pt[2]].x,Vectors2D[pt[2]].y,Vectors2D[pt[3]].x,Vectors2D[pt[3]].y,1);
//			break;
		} 
	}
*/
	for(int i = 0;i < 12;i++)
	{
		if(EdgeVisible[i] == 1)
		{
			if(Edges[i].a == MostTop || Edges[i].b == MostTop)
			{
				EDGE e1;
				EDGE e0 = Edges[i];
				if(e0.b == MostTop)
				{
					int a = e0.a;
					e0.a = e0.b;
					e0.b = a;
				}
				int j = 0;
				for(j = i + 1;j < 12;j++)
				{
					if(EdgeVisible[j] == 1)
					{
						if(Edges[j].a == MostTop || Edges[j].b == MostTop)
						{
							e1 = Edges[j];
							if(e1.b == MostTop)
							{
								int a = e1.a;
								e1.a = e1.b;
								e1.b = a;
							}
							break;
						}
					}
				}
				int iedge = i;
				if(Vectors2D[e1.b].x > Vectors2D[e0.b].x) 
				{
					e0 = e1;
					iedge = j;
				}

				RightSideEdgeBits |= 1 << iedge;
				int k = 0;
				for(int l = 0;l < 4;l++)
				{
					for(k = 0;k < 12;k++)
					{
						if((RightSideEdgeBits & (1 << k)) == 0 && EdgeVisible[k] == 1)
						{
							if(Edges[k].a == e0.b || Edges[k].b == e0.b)
							{
								e1 = Edges[k];
								if(e1.b == e0.b)
								{
									int z = e1.a;
									e1.a = e1.b;
									e1.b = z;
								}
								break;
							}
						}
					}
					if(k < 12)
					{
						if(Vectors[e1.b].y > Vectors[e1.a].y)
						{
							e0 = e1;
							RightSideEdgeBits |= 1 << k;
						}
					}
					else
						break;
				}
				break;
			}
		}
	}

	CalculateEdgeSplit();

	printf("Split: %i\n",Vec2ColCount);

	int PolSort[3];
	int PolySortCount = 0;
	for(int j = 0;j < 6;j++)
	{
		if(!Polygons[j].visible) continue;
		PolSort[PolySortCount++] = j;
	}
	for(int i = 0;i < PolySortCount - 1;i++)
		for(int j = i;j < PolySortCount;j++)
			if(Polygons[PolSort[i]].normalCalced.x < Polygons[PolSort[j]].normalCalced.x)
			{
				int k = PolSort[i];
				PolSort[i] = PolSort[j];
				PolSort[j] = k;
			}

	for(int k = 0;k < PolySortCount;k++)
	{
		int j = PolSort[k];
		// sorting
		int sorted[256];
		int sortedCount = 0;
		int t = 0;
		char coloradd = 0;
		if(Polygons[j].normalCalced.x < 0)
			coloradd = -1;
		for(int e = 0;e < 4;e++)
		{
			int i = Polygons[j].edges[e];
			int myVec2Col = EdgesCalced[i]; 
			int myVec2ColLast = EdgesCalcedLast[i];
			if(RightSideEdgeBits & (1 << i))
			{
				for(int m = myVec2Col;m < myVec2ColLast;m++)
					Screen[(Vec2Col[m].v.y + 40) * 80 + 40 + Right + 3] = Vec2Col[m].c;// + coloradd;
			}
			for(int m = myVec2Col;m < myVec2ColLast;m++) sorted[sortedCount++] = m;
		}
		for(int m = 0;m < sortedCount - 1;m++)
			for(int n = m;n < sortedCount;n++)
				if(Vec2Col[sorted[n]].c < Vec2Col[sorted[m]].c)
				{
					int l = sorted[n];
					sorted[n] = sorted[m];
					sorted[m] = l;
				}
		//////////

		for(int e = 0;e < sortedCount - 1;e += 2)
		{
			VEC2COL v0 = Vec2Col[sorted[e]];
			VEC2COL v1 = Vec2Col[sorted[e + 1]];
			if(v0.c == v1.c)
				DrawLine(Screen,v0.v.x,v0.v.y,v1.v.x,v1.v.y,v0.c + coloradd);//^(v0.c-1));
		}
	}
	char a = 0;
	int last = -1;
	int lastchar = 0;
	printf("TopRight %i,%i\n", Top,RightY);
	for(int i = Top + 40;i < RightY + 40;i++)
	{
		char b = Screen[i * 80 + 40 + Right + 3];
		if(b != 0) 
		{
			if(last == -1)
			{
				last = i;
				lastchar = b;
			}
			a = b;
		}
		Screen[i * 80 + 40 + Right + 3] = a;
	}
	lastchar--;
	for(int i = Top + 40;i < last;i++)
	{
		Screen[i * 80 + 40 + Right + 3] = lastchar;
	}
	printf("BottomRight %i,%i\n", Bottom,RightY);
	a = 0;
	last = -1;
	lastchar = 0;
	for(int i = Bottom + 40;i >= RightY + 40;i--)
	{
		char b = Screen[i * 80 + 40 + Right + 3];
		if(b != 0) 
		{
			if(last == -1)
			{
				last = i;
				lastchar = b;
			}
			a = b;
		}
		Screen[i * 80 + 40 + Right + 3] = a;
	}
	lastchar--;
	for(int i = last;i < Bottom + 40;i++)
	{
		Screen[i * 80 + 40 + Right + 3] = lastchar;
	}
/**/
	for(int y = Top + 40;y < Bottom + 40;y++)
	{
		char a = 0;
		for(int x = Right + 40 + 3;x >= Left + 40;x--)
		{
			char b = Screen[y * 80 + x];
			if(b != 0) a = b;
			Screen[y * 80 + x] = a;
		}
	}
/**/
	for(int i = 0;i < 12;i++)
	{
		if(EdgeVisible[i] == 1)
		{
			int a = Edges[i].a;
			int b = Edges[i].b;
			if(Vectors2D[b].y < Vectors2D[a].y)
			{
				int z = b;
				b = a;
				a = z;
			}
			DrawLineEor(Screen2,Vectors2D[a].x,Vectors2D[a].y,Vectors2D[b].x,Vectors2D[b].y,1);
		}
	}

	for(int y = Top + 40;y < Bottom + 40;y++)
	{
		char a = 0;
		for(int x = Right + 40 + 3;x >= Left + 40;x--)
		{
			char a = a ^ Screen2[y * 80 + x];
			if(a == 0)
				Screen[y * 80 + x] = 0;
		}
	}

/**/
	PrintScreen();
//	}
}
//////////////////////////////////////////////////////
void	Init()
{
	for(int i = 0;i < SINCOS;i++)
	{
		Sin[i] = (int)(sin(PI * 2.0 * (double)i / SINCOS) * 256.0);
		Cos[i] = (int)(cos(PI * 2.0 * (double)i / SINCOS) * 256.0);
	}
	for(int i = 0;i < 12;i++) EdgeVisible[i] = 0;
	for(int i = 0;i < 256*2;i++)
	{
		ACos[i] = (int)(sin((double)(i - 256) / 256.0) * 255.0 + 190);
	}
}
//////////////////////////////////////////////////////
void	CalculateVectors()
{
	for(int i = 0;i < sizeof(VectorsOrg)/sizeof(VEC3);i++)
	{
		Vectors[i] = CalculateVector(VectorsOrg[i]);
//		Vectors2D[i].x = Vectors[i].x * 30 / 512;
//		Vectors2D[i].y = Vectors[i].y * 30 / 512;
		Vectors2D[i].x = (Vectors[i].x * 1024 / Vectors[i].z) / 13;
		Vectors2D[i].y = (Vectors[i].y * 1024 / Vectors[i].z) / 13;
	}
}
//////////////////////////////////////////////////////
void	CalculateNormals()
{
	for(int i = 0;i < sizeof(NormalsOrg)/sizeof(VEC3);i++)
	{
		Normals[i] = CalculateNormal(NormalsOrg[i]);
	}
}
//////////////////////////////////////////////////////
void	PrintVectors()
{
	printf("--------\n");
	printf("Vectors:\n");
	printf("--------\n");
	for(int i = 0;i < sizeof(VectorsOrg)/sizeof(VEC3);i++)
		printf("x: %i, y: %i, z: %i, 2D(%i,%i)\n",Vectors[i].x,Vectors[i].y,Vectors[i].z,Vectors2D[i].x,Vectors2D[i].y);
	printf("--------\n");
	printf("Normals:\n");
	printf("--------\n");
	for(int i = 0;i < sizeof(NormalsOrg)/sizeof(VEC3);i++)
		printf("x: %i, y: %i, z: %i\n",Normals[i].x,Normals[i].y,Normals[i].z);
}
//////////////////////////////////////////////////////
int	Dot(VEC3 v0,VEC3 v1)
{
	return (v0.x * v1.x + v0.y * v1.y + v0.z * v1.z) >> 9;
}
//////////////////////////////////////////////////////
VEC3 	Cross(VEC3 v0,VEC3 v1)
{
	VEC3 v;
	v.x = (v0.y * v1.z - v0.z * v1.y) >> 9;
	v.y = (v0.z * v1.x - v0.x * v1.z) >> 9;
	v.z = (v0.x * v1.y - v0.y * v1.x) >> 9;
	return v;
}
//////////////////////////////////////////////////////
int	IsPolygonVisible(int p,VEC3 source)
{
	VEC3 v0,v1,v,s;
	Polygons[p].normalCalced = CalculateNormal(Polygons[p].normal);
/*	v0.x = Vectors[Polygons[p].vertices[0]].x - Vectors[Polygons[p].vertices[1]].x;
	v0.y = Vectors[Polygons[p].vertices[0]].y - Vectors[Polygons[p].vertices[1]].y;
	v0.z = Vectors[Polygons[p].vertices[0]].z - Vectors[Polygons[p].vertices[1]].z;
	v1.x = Vectors[Polygons[p].vertices[2]].x - Vectors[Polygons[p].vertices[1]].x;
	v1.y = Vectors[Polygons[p].vertices[2]].y - Vectors[Polygons[p].vertices[1]].y;
	v1.z = Vectors[Polygons[p].vertices[2]].z - Vectors[Polygons[p].vertices[1]].z;
	v = Cross(v0,v1);
*/
	v = Polygons[p].normalCalced;
	s.x = source.x - Vectors[Polygons[p].vertices[1]].x;
	s.y = source.y - Vectors[Polygons[p].vertices[1]].y;
	s.z = source.z - Vectors[Polygons[p].vertices[1]].z;
	int	dot = Dot(v,s);
//	Polygons[p].dot = dot;
	if(dot > 1) return 1;
	return 0;
}
//////////////////////////////////////////////////////
void	CheckPolygonsVisible(VEC3 source)
{

	for(int i = 0;i < sizeof(Polygons)/sizeof(POLYGON);i++)
	{
		if(Polygons[i].visible = IsPolygonVisible(i,source))
		{
			printf("Polygon: %i visible\n",i);
			for(int j = 0;j < 4;j++)
				if(Polygons[i].edges[j] != -1)
					EdgeVisible[Polygons[i].edges[j]]++;

		}
	}
	printf("EdgeVisibility:\n");
	for(int i = 0;i < 12;i++)
		printf("Edge %i: %i\n",i,EdgeVisible[i]);
}
//////////////////////////////////////////////////////
// cos(Y) * cos(Z) 			cos(X) * sin(Z) + sin(X) * sin(Y) * cos(Z) 		sin(X) * sin(Z) − cos(X) * sin(Y) * cos(Z)
// −cos(Y) * sin(Z) 		cos(X) * cos(Z) − sin(X) * sin(Y) * sin(Z) 		sin(X) * cos(Z) + cos(X) * sin(Y) * sin(Z)
// sin(Y) 					−sin(X) * cos(Y) 								cos(X) * cos(Y)

// cAcB 					cCsB + sCsAcB 				sCsB − cCsAcB
// −cAsB			 		cCcB − sCsAsB 				sCcB + cCsAsB
// sin(a) 					−sCcA			 			cCcA
void	CalculateRotationMatrix()
{
	int c1 = Cos[WinkelY];
	int c2 = Cos[WinkelX];
	int c3 = Cos[WinkelZ];
	int s1 = Sin[WinkelY];
	int s2 = Sin[WinkelX];
	int s3 = Sin[WinkelZ];

	printf("CosY: %i\n",c1);
	printf("CosX: %i\n",c2);
	printf("CosZ: %i\n",c3);
	printf("SinY: %i\n",s1);
	printf("SinX: %i\n",s2);
	printf("SinZ: %i\n",s3);

	int *m = RotationMatrix;

	m[4 * 0 + 0] = ((c1*c3)>>8) + ((((s1*s2)>>8)*s3)>>8);
	m[4 * 0 + 1] = -((c1*s3)>>8) + ((((c3*s1)>>8)*s2)>>8);
	m[4 * 0 + 2] = (c2*s1)>>8;

	m[4 * 1 + 0] = (c2*s3)>>8;
	m[4 * 1 + 1] = (c2*c3)>>8;
	m[4 * 1 + 2] = -s2;
	
	m[4 * 2 + 0] = -((c3*s1)>>8) + ((((c1*s2)>>8)*s3)>>8);
	m[4 * 2 + 1] = ((s1*s3)>>8) + ((((c1*c3)>>8)*s2)>>8);
	m[4 * 2 + 2] = (c1*c2)>>8;

	RotationMatrix[4 * 0 + 3] = 0;
	RotationMatrix[4 * 1 + 3] = 0;
	RotationMatrix[4 * 2 + 3] = 1024;
}
//////////////////////////////////////////////////////
VEC3 	CalculateVector(VEC3 v)
{
	VEC3 r;
	r.x = ((v.x * RotationMatrix[4 * 0 + 0] + v.y * RotationMatrix[4 * 0 + 1] + v.z * RotationMatrix[4 * 0 + 2]) >> 8) + RotationMatrix[4 * 0 + 3];
	r.y = ((v.x * RotationMatrix[4 * 1 + 0] + v.y * RotationMatrix[4 * 1 + 1] + v.z * RotationMatrix[4 * 1 + 2]) >> 8) + RotationMatrix[4 * 1 + 3];
	r.z = ((v.x * RotationMatrix[4 * 2 + 0] + v.y * RotationMatrix[4 * 2 + 1] + v.z * RotationMatrix[4 * 2 + 2]) >> 8) + RotationMatrix[4 * 2 + 3];
	return r;
}
//////////////////////////////////////////////////////
VEC3 	CalculateNormal(VEC3 v)
{
	VEC3 r;
	r.x = ((v.x * RotationMatrix[4 * 0 + 0] + v.y * RotationMatrix[4 * 0 + 1] + v.z * RotationMatrix[4 * 0 + 2]) >> 8);
	r.y = ((v.x * RotationMatrix[4 * 1 + 0] + v.y * RotationMatrix[4 * 1 + 1] + v.z * RotationMatrix[4 * 1 + 2]) >> 8);
	r.z = ((v.x * RotationMatrix[4 * 2 + 0] + v.y * RotationMatrix[4 * 2 + 1] + v.z * RotationMatrix[4 * 2 + 2]) >> 8);
	return r;
}
//////////////////////////////////////////////////////
void	ClearScreen()
{
	for(int y = 0;y < 80;y++)
	{
		for(int x = 0;x < 80;x++)
			Screen[y*80+x] = 0;
	}
}
//////////////////////////////////////////////////////
void	PrintScreen()
{
//	printf("\033[2J");
	for(int y = 0;y < 80;y++)
	{
		for(int x = 0;x < 80;x++)
			if(Screen[y*80+x])
				printf("%c",Screen[y*80+x]+'a');
			else
				printf(" ",Screen[y*80+x]);
		printf("\n");
	}
}
//////////////////////////////////////////////////////
void	DrawLine(char * Screen,int x0,int y0,int x1,int y1,char m)
{
	if(y1 < y0)
	{
		int a = y1;
		y1 = y0;
		y0 = a;
		a = x1;
		x1 = x0;
		x0 = a;
	}
	printf("Draw (%i,%i) to (%i,%i), %i\n",x0,y0,x1,y1,m);

	if(!(y1 - y0))
	{
		Screen[(y0 + 40) * 80 + 40 + x0] = m;//Screen[y0 * 80 + (x0 >> 8)] = m;
		Screen[(y1 + 40) * 80 + 40 + x1] = m;//Screen[y0 * 80 + (x0 >> 8)] = m;
	}
	else
	{
		int xadd = (x1 - x0) * 256 / (y1 - y0);
		int x = ((x0 + 40) << 8) + 127;
		for(int i = y0 + 40;i <= y1 + 40;i++,x += xadd)
		{
			Screen[i * 80 + (x >> 8)] = m;
		}
	}
}
//////////////////////////////////////////////////////
void	DrawLineEor(char * Screen,int x0,int y0,int x1,int y1,char m)
{
	if(y1 < y0)
	{
		int a = y1;
		y1 = y0;
		y0 = a;
		a = x1;
		x1 = x0;
		x0 = a;
	}
	printf("Draw (%i,%i) to (%i,%i), %i\n",x0,y0,x1,y1,m);

	if(!(y1 - y0))
	{
		Screen[(y0 + 40) * 80 + 40 + x0] ^= m;
		Screen[(y1 + 40) * 80 + 40 + x1] ^= m;
	}
	else
	{
		int xadd = (x1 - x0) * 256 / (y1 - y0);
		int x = ((x0 + 40) << 8) + 127;
		for(int i = y0 + 40;i < y1 + 40;i++,x += xadd)
		{
			Screen[i * 80 + (x >> 8)] ^= m;
		}
	}
}
//////////////////////////////////////////////////////
void	DrawLineC(char * Screen,int x0,int y0,int x1,int y1,int aNorm,int bNorm)
{
	if(y1 < y0)
	{
		int a = y1;
		y1 = y0;
		y0 = a;
		a = x1;
		x1 = x0;
		x0 = a;
		a = aNorm;
		aNorm = bNorm;
		bNorm = a;
	}
	aNorm = (aNorm * SHADEFACTOR) + 127;
	bNorm = (bNorm * SHADEFACTOR) + 127;

	printf("Draw (%i,%i) to (%i,%i), Norm (%i,%i)\n",x0,y0,x1,y1,aNorm,bNorm);

	if(!(y1 - y0))
	{
		Screen[(y0 + 40) * 80 + 40 + x0] = aNorm;
		Screen[(y1 + 40) * 80 + 40 + x1] = bNorm;
	}
	else
	{
		int xadd = ((x1 - x0) << 8) / (y1 - y0);
		int nadd = ((bNorm - aNorm)) / (y1 - y0);
		int x = ((x0 + 40) << 8);// + 127;
		int n = (aNorm);
		for(int i = y0 + 40;i < y1 + 40;i++)
		{
			printf("%i, (%i,%i)\n",n,(x >> 8) - 40,i - 40);
			Screen[i * 80 + (x >> 8)] = n >> 8;
			x += xadd;
			n += nadd;
		}
	}
}
//////////////////////////////////////////////////////
#define	TEST_TOP	1
#define	TEST_BOTTOM	2
#define	TEST_LEFT	4
#define	TEST_RIGHT	8
void	GetBound(VEC2 &v0,VEC2 &v1,int Bound_v0,int Bound_v1)
{
	VEC2 nv0 = v0;
	VEC2 nv1 = v1;
	if(Bound_v0)
		nv0 = GetBoundVec(v1,v0);
	if(Bound_v1)
		nv1 = GetBoundVec(v0,v1);
	v0 = nv0;
	v1 = nv1;
	Screen[(nv1.y + 40) * 80 + 40 + nv1.x] = '#'-'a';
	Screen[(nv0.y + 40) * 80 + 40 + nv0.x] = '#'-'a';
}
VEC2 	GetBoundVec(VEC2 v0,VEC2 v1)
{
	int check = TEST_TOP | TEST_BOTTOM | TEST_LEFT | TEST_RIGHT;
	int check_first = 0;

	int xdir = v1.x - v0.x;
	int ydir = v1.y - v0.y;
	if(xdir > 0) 
		check ^= TEST_LEFT;
	else
	if(xdir < 0) 
		check ^= TEST_RIGHT;
	else
	if(xdir == 0) 
	{
		check ^= TEST_LEFT | TEST_RIGHT;
		check_first = 0;
	}

	if(ydir > 0) 
	{
		check ^= TEST_TOP;
		check_first = check;
		if(xdir < 0) xdir = -xdir;
		if(xdir > ydir)
			check_first ^= TEST_BOTTOM;
		else
			check_first &= 0xffffffff^(TEST_LEFT | TEST_RIGHT);
	}
	else
	if(ydir < 0) 
	{
		check ^= TEST_BOTTOM;
		check_first = check;
		if(xdir < 0) xdir = -xdir;
		ydir = -ydir;
		if(xdir > ydir)
			check_first ^= TEST_TOP;
		else
			check_first &= 0xffffffff^(TEST_LEFT | TEST_RIGHT);
	}
	else
	if(ydir == 0) 
	{
		check ^= TEST_TOP | TEST_BOTTOM;
		check_first = 0;
	}

	return Cut(v0,v1,check,check_first);
}
//////////////////////////////////////////////////////
VEC2 Cut(VEC2 v0,VEC2 v1,int check,int check_first)
{
	VEC2 vnew;
	int fault = 0;
	int xdir = v1.x - v0.x;
	int ydir = v1.y - v0.y;

	printf("%i,%i\n",check,check_first);
	if(check_first)
	{
		printf("check first ");
		if(check_first & TEST_LEFT)
		{
			printf("left\n");
			int y = ydir * (Left - v0.x) / xdir + v0.y;
			if(y < Top || y > Bottom)
				fault = 1;
			else
			{
				vnew.y = y;
				vnew.x = Left;
			}
		}
		else
		if(check_first & TEST_RIGHT)
		{
			printf("right\n");
			int y = ydir * (Right - v0.x) / xdir + v0.y;
			if(y < Top || y > Bottom)
				fault = 1;
			else
			{
				vnew.y = y;
				vnew.x = Right;
			}
		}
		else
		if(check_first & TEST_TOP)
		{
			printf("top\n");
			int x = xdir * (Top - v0.y) / ydir + v0.x;
			if(x < Left || x > Right)
				fault = 1;
			else
			{
				vnew.x = x;
				vnew.y = Top;
			}
		}
		else
		if(check_first & TEST_BOTTOM)
		{
			printf("bottom \n");
			int x = xdir * (Bottom - v0.y) / ydir + v0.x;
			if(x < Left || x > Right)
				fault = 1;
			else
			{
				vnew.x = x;
				vnew.y = Bottom;
			}
		}
		check ^=check_first;
		if(fault == 0) 
			return vnew;
	}

	printf("check ");
	if(check & TEST_LEFT)
	{
		printf("left\n");
		vnew.y = ydir * (Left - v0.x) / xdir + v0.y;
		vnew.x = Left;
	}
	else
	if(check & TEST_RIGHT)
	{
		printf("right\n");
		vnew.y = ydir * (Right - v0.x) / xdir + v0.y;
		vnew.x = Right;
	}
	else
	if(check & TEST_TOP)
	{
		printf("top\n");
		vnew.x = xdir * (Top - v0.y) / ydir + v0.x;
		vnew.y = Top;
	}
	else
	if(check & TEST_BOTTOM)
	{
		printf("bottom \n");
		vnew.x = xdir * (Bottom - v0.y) / ydir + v0.x;
		vnew.y = Bottom;
	}
	return vnew;
}
//////////////////////////////////////////////////////
void CalculateEdgeSplit()
{
	printf("CalculateEdgeSplit\n");

	for(int i = 0;i < 12;i++) EdgesCalced[i] = -1;

	for(int j = 0;j < 6;j++)
	{
		if(!Polygons[j].visible) continue;
		for(int e = 0;e < 4;e++)
		{
			int i = Polygons[j].edges[e];
			if(EdgesCalced[i] != -1) continue;
			if(EdgeVisible[i])
			{
				EdgesCalced[i] = Vec2ColCount; 
				int a = Edges[i].a;
				int b = Edges[i].b;
				int p = 0;

				if(Vectors2D[b].y < Vectors2D[a].y)
				{
					int z = a;
					a = b;
					b = z;
					p++;
				}
				else
					p++;

				VEC2 va = Vectors2D[a];
				VEC2 vb = Vectors2D[b];

				int aNorm = -Normals[a].z;
				int bNorm = -Normals[b].z;
				aNorm = (ACos[aNorm + 256] * SHADEFACTOR) + 127;
				bNorm = (ACos[bNorm + 256] * SHADEFACTOR) + 127;

				int NormDiff = bNorm - aNorm;
				VEC2 vDiff;
				vDiff.x = (vb.x - va.x);// << 8;
				vDiff.y = (vb.y - va.y);// << 8;

				int iaNorm = (aNorm) & 0xffffff00;
				int ibNorm = (bNorm) & 0xffffff00;
				if(aNorm <= bNorm)
					iaNorm+=256;
				else
					ibNorm-=256;

				int u = (ibNorm - iaNorm) >> 8;
				int nAdd = 0x100;
				if(u < 0) 
				{
					u = -u;
					p = -1;
					nAdd = -0x100;
				}
//				printf("cut: %i (%i,%i),%i,(%i,%i)\n",u,iaNorm, ibNorm,p,vDiff.x,vDiff.y);
				int n = iaNorm - aNorm;
				for(int j = 0;j < u + p;j++)
				{
					int nNorm = n;
					VEC2COL nVec;
					nVec.v.x = (vDiff.x * nNorm / NormDiff + va.x);
					nVec.v.y = (vDiff.y * nNorm / NormDiff + va.y);
					nVec.c = ((n + aNorm) >> 8);
					Vec2Col[Vec2ColCount++] = nVec;
					n += nAdd;
				}
				EdgesCalcedLast[i] = Vec2ColCount; 
			}
		}
	}
}
//////////////////////////////////////////////////////