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
	int dot;			// Gouraudfactor
}POLYGON;
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
	{{0,1,2,3},{0,1,2,3}},
	{{1,6,5,2},{9,5,10,1}},
	{{6,7,4,5},{6,7,4,5}},
	{{7,0,3,4},{8,3,11,7}},
	{{7,6,1,0},{6,9,0,8}},
	{{3,2,5,4},{2,10,4,11}}
};
VEC3 Vectors[8];
VEC2 Vectors2D[8];
int RotationMatrix[] = 
{
	0,0,0,0,
	0,0,0,0,
	0,0,0,0,
};
int WinkelX = (-128) & (SINCOS - 1),WinkelY = (0) & (SINCOS - 1),WinkelZ = (128) & (SINCOS - 1);
//////////////////////////////////////////////////////
int	Sin[SINCOS];
int	Cos[SINCOS];
int EdgeVisible[12];
//////////////////////////////////////////////////////
void	Init();
void	CalculateVectors();
void	PrintVectors();
int	Dot(VEC3 v0,VEC3 v1);
VEC3 	Cross(VEC3 v0,VEC3 v1);
bool	IsPolygonVisible(int p,VEC3 source);
void	CheckPolygonsVisible(VEC3 source);
void	CalculateRotationMatrix();
VEC3 	CalculateVector(VEC3 v);
//////////////////////////////////////////////////////
int	main()
{
	VEC3 source = {0,0,0};
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
	for(int i = 0;i < 12;i++) EdgeVisible[i] = 0;
}
//////////////////////////////////////////////////////
void	CalculateVectors()
{
	for(int i = 0;i < sizeof(VectorsOrg)/sizeof(VEC3);i++)
	{
		Vectors[i] = CalculateVector(VectorsOrg[i]);
		Vectors2D[i].x = (Vectors[i].x * 1024 / Vectors[i].z) / 8;
		Vectors2D[i].y = (Vectors[i].y * 1024 / Vectors[i].z) / 8;
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
bool	IsPolygonVisible(int p,VEC3 source)
{
	VEC3 v0,v1,v,s;
	v0.x = Vectors[Polygons[p].vertices[0]].x - Vectors[Polygons[p].vertices[1]].x;
	v0.y = Vectors[Polygons[p].vertices[0]].y - Vectors[Polygons[p].vertices[1]].y;
	v0.z = Vectors[Polygons[p].vertices[0]].z - Vectors[Polygons[p].vertices[1]].z;
	v1.x = Vectors[Polygons[p].vertices[2]].x - Vectors[Polygons[p].vertices[1]].x;
	v1.y = Vectors[Polygons[p].vertices[2]].y - Vectors[Polygons[p].vertices[1]].y;
	v1.z = Vectors[Polygons[p].vertices[2]].z - Vectors[Polygons[p].vertices[1]].z;
	v = Cross(v0,v1);
	s.x = source.x - Vectors[Polygons[p].vertices[1]].x;
	s.y = source.y - Vectors[Polygons[p].vertices[1]].y;
	s.z = source.z - Vectors[Polygons[p].vertices[1]].z;
	int	dot = Dot(v,s);
	Polygons[p].dot = dot;
	if(dot > 1) return true;
	return false;
}
//////////////////////////////////////////////////////
void	CheckPolygonsVisible(VEC3 source)
{

	for(int i = 0;i < sizeof(Polygons)/sizeof(POLYGON);i++)
	{
		if(IsPolygonVisible(i,source))
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
