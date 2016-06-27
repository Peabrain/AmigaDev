#include	<stdio.h>
#include	<math.h>
//////////////////////////////////////////////////////
#define	PI 3.141592653589793
#define	SINCOS 1024
//////////////////////////////////////////////////////
typedef struct VEC
{
	int	x,y,z;	
}VEC;
typedef	struct POLYGON
{
	int	a,b,c,d;	// -1 = means no vector
}POLYGON;
//////////////////////////////////////////////////////
VEC	VectorsOrg[8] = 
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
POLYGON	Polygons[] = 
{
	{0,1,2,3},
	{1,6,5,2},
	{6,7,4,5},
	{7,0,3,4},
	{7,6,1,0},
	{3,2,5,4}
};
VEC Vectors[8];
int RotationMatrix[] = 
{
	65536,0,0,0,
	0,65536,0,0,
	0,0,65536,0,
};
int WinkelA = (0) & (SINCOS - 1),WinkelB = (0) & (SINCOS - 1),WinkelC = (0) & (SINCOS - 1);
//////////////////////////////////////////////////////
int	Sin[SINCOS];
int	Cos[SINCOS];
//////////////////////////////////////////////////////
void	Init();
void	CalculateVectors();
void	PrintVectors();
int	Dot(VEC v0,VEC v1);
VEC 	Cross(VEC v0,VEC v1);
bool	IsPolygonVisible(int p,VEC source);
void	CheckPolygonsVisible(VEC source);
void	CalculateRotationMatrix();
VEC 	CalculateVector(VEC v);
//////////////////////////////////////////////////////
int	main()
{
	VEC source = {0,0,0};
	Init();
	CalculateRotationMatrix();
	CalculateVectors();	
	PrintVectors();
	CheckPolygonsVisible(source);
}
//////////////////////////////////////////////////////
void	Init()
{
	for(int i = 0;i < SINCOS;i++)
	{
		Sin[i] = (int)(sin(PI * 2.0 * (double)i / SINCOS) * 256.0);
		Cos[i] = (int)(cos(PI * 2.0 * (double)i / SINCOS) * 256.0);
	}
}
//////////////////////////////////////////////////////
void	CalculateVectors()
{
	for(int i = 0;i < sizeof(VectorsOrg)/sizeof(VEC);i++)
		Vectors[i] = CalculateVector(VectorsOrg[i]);
}
//////////////////////////////////////////////////////
void	PrintVectors()
{
	printf("--------\n");
	printf("Vectors:\n");
	printf("--------\n");
	for(int i = 0;i < sizeof(VectorsOrg)/sizeof(VEC);i++)
		printf("x: %i, y: %i, z: %i\n",Vectors[i].x,Vectors[i].y,Vectors[i].z);
}
//////////////////////////////////////////////////////
int	Dot(VEC v0,VEC v1)
{
	return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z;
}
//////////////////////////////////////////////////////
VEC 	Cross(VEC v0,VEC v1)
{
	VEC v;
	v.x = v0.y * v1.z - v0.z * v1.y;
	v.y = v0.z * v1.x - v0.x * v1.z;
	v.z = v0.x * v1.y - v0.y * v1.x;
	return v;
}
//////////////////////////////////////////////////////
bool	IsPolygonVisible(int p,VEC source)
{
	VEC v0,v1,v,s;
	v0.x = Vectors[Polygons[p].a].x - Vectors[Polygons[p].b].x;
	v0.y = Vectors[Polygons[p].a].y - Vectors[Polygons[p].b].y;
	v0.z = Vectors[Polygons[p].a].z - Vectors[Polygons[p].b].z;
	v1.x = Vectors[Polygons[p].c].x - Vectors[Polygons[p].b].x;
	v1.y = Vectors[Polygons[p].c].y - Vectors[Polygons[p].b].y;
	v1.z = Vectors[Polygons[p].c].z - Vectors[Polygons[p].b].z;
	v = Cross(v0,v1);
	s.x = source.x - Vectors[Polygons[p].b].x;
	s.y = source.y - Vectors[Polygons[p].b].y;
	s.z = source.z - Vectors[Polygons[p].b].z;
	float	dot = Dot(v,s);
	if(dot > 1) return true;
	return false;
}
//////////////////////////////////////////////////////
void	CheckPolygonsVisible(VEC source)
{

	for(int i = 0;i < sizeof(Polygons)/sizeof(POLYGON);i++)
	{
		if(IsPolygonVisible(i,source))
			printf("Polygon: %i visible\n",i);
	}
}
//////////////////////////////////////////////////////
// cos(a) * cos(b) 			cos(c) * sin(b) + sin(c) * sin(a) * cos(b) 		sin(c) * sin(b) − cos(c) * sin(a) * cos(b)
// −cos(a) * sin(b) 		cos(c) * cos(b) − sin(c) * sin(a) * sin(b) 		sin(c) * cos(b) + cos(c) * sin(a) * sin(b)
// sin(a) 					−sin(c) * cos(a) 								cos(c) * cos(a)

// cAcB 					cCsB + sCsAcB 				sCcB − cCsAcB
// −cAsB			 		cCcB − sCsAsB 				sCcB + cCsAsB
// sin(a) 					−sCcA			 			cCcA
void	CalculateRotationMatrix()
{
	int cAcB = (Cos[WinkelA] * Cos[WinkelB]) >> 8;
	int cAsB = (Cos[WinkelA] * Sin[WinkelB]) >> 8;
	int sCsB = (Sin[WinkelC] * Sin[WinkelB]) >> 8;
	int cCsB = (Cos[WinkelC] * Sin[WinkelB]) >> 8;
	int cCcB = (Cos[WinkelC] * Cos[WinkelB]) >> 8;
	int sCcB = (Sin[WinkelC] * Cos[WinkelB]) >> 8;
	int sCcA = (Sin[WinkelC] * Cos[WinkelA]) >> 8;
	int cCcA = (Cos[WinkelC] * Cos[WinkelA]) >> 8;
	int sCsA = (Sin[WinkelC] * Sin[WinkelA]) >> 8;
	int sCsAcB = (sCsA * Cos[WinkelB]) >> 8;
	int sCsAsB = (sCsA * Sin[WinkelB]) >> 8;
	int cCsA = (Cos[WinkelC] * Sin[WinkelA]) >> 8;
	int cCsAcB = (cCsA * Cos[WinkelB]) >> 8;
	int cCsAsB = (cCsA * Sin[WinkelB]) >> 8;

	RotationMatrix[4 * 0 + 0] = cAcB;			RotationMatrix[4 * 0 + 1] = cCsB + sCsAcB;		RotationMatrix[4 * 0 + 2] = sCsB - cCsAcB;
	RotationMatrix[4 * 1 + 0] = -cAsB;			RotationMatrix[4 * 1 + 1] = cCcB - sCsAsB;		RotationMatrix[4 * 1 + 2] = sCcB + cCsAsB;
	RotationMatrix[4 * 2 + 0] = Sin[WinkelA];	RotationMatrix[4 * 2 + 1] = -sCcA;				RotationMatrix[4 * 2 + 2] = cCcA;

	RotationMatrix[4 * 0 + 3] = 0;
	RotationMatrix[4 * 1 + 3] = 0;
	RotationMatrix[4 * 2 + 3] = 512;
}
//////////////////////////////////////////////////////
VEC 	CalculateVector(VEC v)
{
	VEC r;
	r.x = ((v.x * RotationMatrix[4 * 0 + 0] + v.y * RotationMatrix[4 * 0 + 1] + v.z * RotationMatrix[4 * 0 + 2]) >> 8) + RotationMatrix[4 * 0 + 3];
	r.y = ((v.x * RotationMatrix[4 * 1 + 0] + v.y * RotationMatrix[4 * 1 + 1] + v.z * RotationMatrix[4 * 1 + 2]) >> 8) + RotationMatrix[4 * 1 + 3];
	r.z = ((v.x * RotationMatrix[4 * 2 + 0] + v.y * RotationMatrix[4 * 2 + 1] + v.z * RotationMatrix[4 * 2 + 2]) >> 8) + RotationMatrix[4 * 2 + 3];
	return r;
}
//////////////////////////////////////////////////////
