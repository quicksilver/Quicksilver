//
//  DRColorPermutator.m
//  iConMerge
//
//  Created by chmod007 on Sat Nov 10 2001.
//  Copyright (c) 2002 Infinity-to-the-Power-of-Infinity. All rights reserved.
//
//  Changed by Travis Mcleskey Sun Jan 13 2002.

#import "DRColorPermutator.h"

#import "math.h"
#import "stdio.h"

#define RLUM    (0.3086)
#define GLUM    (0.6094)
#define BLUM    (0.0820)

#define OFFSET_R        0
#define OFFSET_G        1
#define OFFSET_B        2
#define OFFSET_A        3

/* 
 *	printmat -	
 *		print a 4 by 4 matrix
 */
/*
static void printmat(mat)
float mat[4][4];
{
    int x, y;

    fprintf(stderr,"\n");
    for(y=0; y<4; y++) {
	for(x=0; x<4; x++) 
	   fprintf(stderr,"%f ",mat[y][x]);
       	fprintf(stderr,"\n");
    }
    fprintf(stderr,"\n");
}
*/
/* 
 *	applymatrixtoself -	
 *		use a matrix to transform colors.
 */
static void applymatrixtoself(lptr,mat,n,alpha)
unsigned long *lptr;
float mat[4][4];
int n;
BOOL alpha;
{
    int ir, ig, ib, r, g, b;
    unsigned char *cptr;

    cptr = (unsigned char *)lptr;
    while(n--) {
	ir = cptr[OFFSET_R];
	ig = cptr[OFFSET_G];
	ib = cptr[OFFSET_B];
	r = ir*mat[0][0] + ig*mat[1][0] + ib*mat[2][0] + mat[3][0];
	g = ir*mat[0][1] + ig*mat[1][1] + ib*mat[2][1] + mat[3][1];
	b = ir*mat[0][2] + ig*mat[1][2] + ib*mat[2][2] + mat[3][2];
	if(r<0) r = 0;
	if(r>255) r = 255;
	if(g<0) g = 0;
	if(g>255) g = 255;
	if(b<0) b = 0;
	if(b>255) b = 255;
	cptr[OFFSET_R] = r;
	cptr[OFFSET_G] = g;
	cptr[OFFSET_B] = b;
	cptr += 3 + alpha;
    }
}




/* 
 *	applymatrixintodest -	
 *		use a matrix to transform colors.
 */
static void applymatrixintodest(src,dest,mat,n,alpha)
unsigned long *src; // src
unsigned long *dest; // dest
float mat[4][4];
int n;
BOOL alpha;
{
    int ir, ig, ib, r, g, b;
    unsigned char *sptr = (unsigned char *)src, *dptr = (unsigned char *)dest;

    while(n--) {
	ir = sptr[OFFSET_R];
	ig = sptr[OFFSET_G];
	ib = sptr[OFFSET_B];
	r = ir*mat[0][0] + ig*mat[1][0] + ib*mat[2][0] + mat[3][0];
	g = ir*mat[0][1] + ig*mat[1][1] + ib*mat[2][1] + mat[3][1];
	b = ir*mat[0][2] + ig*mat[1][2] + ib*mat[2][2] + mat[3][2];
	if(r<0) dptr[OFFSET_R] = 0;
	else if(r>255) dptr[OFFSET_R] = 255;
        else dptr[OFFSET_R] = r;
	if(g<0) dptr[OFFSET_G] = 0;
	else if(g>255) dptr[OFFSET_G] = 255;
        else dptr[OFFSET_G] = g;
	if(b<0) dptr[OFFSET_B] = 0;
	else if(b>255) dptr[OFFSET_B] = 255;
        else dptr[OFFSET_B] = b;
        if(alpha) dptr[3] = sptr[3];
	sptr += 3 + alpha;
	dptr += 3 + alpha;
    }
}



/* 
 *	matrixmult -	
 *		multiply two matricies
 */
static void  matrixmult(a,b,c)
float a[4][4], b[4][4], c[4][4];
{
    int x, y;
    float temp[4][4];

    for(y=0; y<4 ; y++)
        for(x=0 ; x<4 ; x++) {
            temp[y][x] = b[y][0] * a[0][x]
                       + b[y][1] * a[1][x]
                       + b[y][2] * a[2][x]
                       + b[y][3] * a[3][x];
        }
    for(y=0; y<4; y++)
        for(x=0; x<4; x++)
            c[y][x] = temp[y][x];
}

/* 
 *	identmat -	
 *		make an identity matrix
 */
static void identmat(matrix)
float *matrix;
{
    *matrix++ = 1.0;    /* row 1        */
    *matrix++ = 0.0;
    *matrix++ = 0.0;
    *matrix++ = 0.0;
    *matrix++ = 0.0;    /* row 2        */
    *matrix++ = 1.0;
    *matrix++ = 0.0;
    *matrix++ = 0.0;
    *matrix++ = 0.0;    /* row 3        */
    *matrix++ = 0.0;
    *matrix++ = 1.0;
    *matrix++ = 0.0;
    *matrix++ = 0.0;    /* row 4        */
    *matrix++ = 0.0;
    *matrix++ = 0.0;
    *matrix++ = 1.0;
}

/* 
 *	xformpnt -	
 *		transform a 3D point using a matrix
 */
static void  xformpnt(matrix,x,y,z,tx,ty,tz)
float matrix[4][4];
float x,y,z;
float *tx,*ty,*tz;
{
    *tx = x*matrix[0][0] + y*matrix[1][0] + z*matrix[2][0] + matrix[3][0];
    *ty = x*matrix[0][1] + y*matrix[1][1] + z*matrix[2][1] + matrix[3][1];
    *tz = x*matrix[0][2] + y*matrix[1][2] + z*matrix[2][2] + matrix[3][2];
}

/* 
 *	cscalemat -	
 *		make a color scale marix
 */
static void  cscalemat(mat,rscale,gscale,bscale)
float mat[4][4];
float rscale, gscale, bscale;
{
    float mmat[4][4];

    mmat[0][0] = rscale;
    mmat[0][1] = 0.0;
    mmat[0][2] = 0.0;
    mmat[0][3] = 0.0;

    mmat[1][0] = 0.0;
    mmat[1][1] = gscale;
    mmat[1][2] = 0.0;
    mmat[1][3] = 0.0;


    mmat[2][0] = 0.0;
    mmat[2][1] = 0.0;
    mmat[2][2] = bscale;
    mmat[2][3] = 0.0;

    mmat[3][0] = 0.0;
    mmat[3][1] = 0.0;
    mmat[3][2] = 0.0;
    mmat[3][3] = 1.0;
    matrixmult(mmat,mat,mat);
}

/* 
 *	lummat -	
 *		make a luminance marix
 */
/*
static void  lummat(mat)
float mat[4][4];
{
    float mmat[4][4];
    float rwgt, gwgt, bwgt;

    rwgt = RLUM;
    gwgt = GLUM;
    bwgt = BLUM;
    mmat[0][0] = rwgt;
    mmat[0][1] = rwgt;
    mmat[0][2] = rwgt;
    mmat[0][3] = 0.0;

    mmat[1][0] = gwgt;
    mmat[1][1] = gwgt;
    mmat[1][2] = gwgt;
    mmat[1][3] = 0.0;

    mmat[2][0] = bwgt;
    mmat[2][1] = bwgt;
    mmat[2][2] = bwgt;
    mmat[2][3] = 0.0;

    mmat[3][0] = 0.0;
    mmat[3][1] = 0.0;
    mmat[3][2] = 0.0;
    mmat[3][3] = 1.0;
    matrixmult(mmat,mat,mat);
}
*/
/* 
 *	saturatemat -	
 *		make a saturation marix
 */
static void  saturatemat(mat,sat)
float mat[4][4];
float sat;
{
    float mmat[4][4];
    float a, b, c, d, e, f, g, h, i;
    float rwgt, gwgt, bwgt;

    rwgt = RLUM;
    gwgt = GLUM;
    bwgt = BLUM;

    a = (1.0-sat)*rwgt + sat;
    b = (1.0-sat)*rwgt;
    c = (1.0-sat)*rwgt;
    d = (1.0-sat)*gwgt;
    e = (1.0-sat)*gwgt + sat;
    f = (1.0-sat)*gwgt;
    g = (1.0-sat)*bwgt;
    h = (1.0-sat)*bwgt;
    i = (1.0-sat)*bwgt + sat;
    mmat[0][0] = a;
    mmat[0][1] = b;
    mmat[0][2] = c;
    mmat[0][3] = 0.0;

    mmat[1][0] = d;
    mmat[1][1] = e;
    mmat[1][2] = f;
    mmat[1][3] = 0.0;

    mmat[2][0] = g;
    mmat[2][1] = h;
    mmat[2][2] = i;
    mmat[2][3] = 0.0;

    mmat[3][0] = 0.0;
    mmat[3][1] = 0.0;
    mmat[3][2] = 0.0;
    mmat[3][3] = 1.0;
    matrixmult(mmat,mat,mat);
}

/* 
 *	offsetmat -	
 *		offset r, g, and b
 */
/*
static void  offsetmat(mat,roffset,goffset,boffset)
float mat[4][4];
float roffset, goffset, boffset;
{
    float mmat[4][4];

    mmat[0][0] = 1.0;
    mmat[0][1] = 0.0;
    mmat[0][2] = 0.0;
    mmat[0][3] = 0.0;

    mmat[1][0] = 0.0;
    mmat[1][1] = 1.0;
    mmat[1][2] = 0.0;
    mmat[1][3] = 0.0;

    mmat[2][0] = 0.0;
    mmat[2][1] = 0.0;
    mmat[2][2] = 1.0;
    mmat[2][3] = 0.0;

    mmat[3][0] = roffset;
    mmat[3][1] = goffset;
    mmat[3][2] = boffset;
    mmat[3][3] = 1.0;
    matrixmult(mmat,mat,mat);
}
*/
/* 
 *	xrotate -	
 *		rotate about the x (red) axis
 */
static void  xrotatemat(mat,rs,rc)
float mat[4][4];
float rs, rc;
{
    float mmat[4][4];

    mmat[0][0] = 1.0;
    mmat[0][1] = 0.0;
    mmat[0][2] = 0.0;
    mmat[0][3] = 0.0;

    mmat[1][0] = 0.0;
    mmat[1][1] = rc;
    mmat[1][2] = rs;
    mmat[1][3] = 0.0;

    mmat[2][0] = 0.0;
    mmat[2][1] = -rs;
    mmat[2][2] = rc;
    mmat[2][3] = 0.0;

    mmat[3][0] = 0.0;
    mmat[3][1] = 0.0;
    mmat[3][2] = 0.0;
    mmat[3][3] = 1.0;
    matrixmult(mmat,mat,mat);
}

/* 
 *	yrotate -	
 *		rotate about the y (green) axis
 */
static void  yrotatemat(mat,rs,rc)
float mat[4][4];
float rs, rc;
{
    float mmat[4][4];

    mmat[0][0] = rc;
    mmat[0][1] = 0.0;
    mmat[0][2] = -rs;
    mmat[0][3] = 0.0;

    mmat[1][0] = 0.0;
    mmat[1][1] = 1.0;
    mmat[1][2] = 0.0;
    mmat[1][3] = 0.0;

    mmat[2][0] = rs;
    mmat[2][1] = 0.0;
    mmat[2][2] = rc;
    mmat[2][3] = 0.0;

    mmat[3][0] = 0.0;
    mmat[3][1] = 0.0;
    mmat[3][2] = 0.0;
    mmat[3][3] = 1.0;
    matrixmult(mmat,mat,mat);
}

/* 
 *	zrotate -	
 *		rotate about the z (blue) axis
 */
static void  zrotatemat(mat,rs,rc)
float mat[4][4];
float rs, rc;
{
    float mmat[4][4];

    mmat[0][0] = rc;
    mmat[0][1] = rs;
    mmat[0][2] = 0.0;
    mmat[0][3] = 0.0;

    mmat[1][0] = -rs;
    mmat[1][1] = rc;
    mmat[1][2] = 0.0;
    mmat[1][3] = 0.0;

    mmat[2][0] = 0.0;
    mmat[2][1] = 0.0;
    mmat[2][2] = 1.0;
    mmat[2][3] = 0.0;

    mmat[3][0] = 0.0;
    mmat[3][1] = 0.0;
    mmat[3][2] = 0.0;
    mmat[3][3] = 1.0;
    matrixmult(mmat,mat,mat);
}

/* 
 *	zshear -	
 *		shear z using x and y.
 */
static void  zshearmat(mat,dx,dy)
float mat[4][4];
float dx, dy;
{
    float mmat[4][4];

    mmat[0][0] = 1.0;
    mmat[0][1] = 0.0;
    mmat[0][2] = dx;
    mmat[0][3] = 0.0;

    mmat[1][0] = 0.0;
    mmat[1][1] = 1.0;
    mmat[1][2] = dy;
    mmat[1][3] = 0.0;

    mmat[2][0] = 0.0;
    mmat[2][1] = 0.0;
    mmat[2][2] = 1.0;
    mmat[2][3] = 0.0;

    mmat[3][0] = 0.0;
    mmat[3][1] = 0.0;
    mmat[3][2] = 0.0;
    mmat[3][3] = 1.0;
    matrixmult(mmat,mat,mat);
}

/* 
 *	simplehuerotatemat -	
 *		simple hue rotation. This changes luminance 
 */
static void  simplehuerotatemat(mat,rot)
float mat[4][4];
float rot;
{
    float mag;
    float xrs, xrc;
    float yrs, yrc;
    float zrs, zrc;

/* rotate the grey vector into positive Z */
    mag = sqrt(2.0);
    xrs = 1.0/mag;
    xrc = 1.0/mag;
    xrotatemat(mat,xrs,xrc);

    mag = sqrt(3.0);
    yrs = -1.0/mag;
    yrc = sqrt(2.0)/mag;
    yrotatemat(mat,yrs,yrc);

/* rotate the hue */
    zrs = sin(rot*M_PI/180.0);
    zrc = cos(rot*M_PI/180.0);
    zrotatemat(mat,zrs,zrc);

/* rotate the grey vector back into place */
    yrotatemat(mat,-yrs,yrc);
    xrotatemat(mat,-xrs,xrc);
}

/* 
 *	huerotatemat -	
 *		rotate the hue, while maintaining luminance.
 */
static void  huerotatemat(mat,rot)
float mat[4][4];
float rot;
{
    float mmat[4][4];
    float mag;
    float lx, ly, lz;
    float xrs, xrc;
    float yrs, yrc;
    float zrs, zrc;
    float zsx, zsy;

    identmat(mmat);

/* rotate the grey vector into positive Z */
    mag = sqrt(2.0);
    xrs = 1.0/mag;
    xrc = 1.0/mag;
    xrotatemat(mmat,xrs,xrc);
    mag = sqrt(3.0);
    yrs = -1.0/mag;
    yrc = sqrt(2.0)/mag;
    yrotatemat(mmat,yrs,yrc);

/* shear the space to make the luminance plane horizontal */
    xformpnt(mmat,RLUM,GLUM,BLUM,&lx,&ly,&lz);
    zsx = lx/lz;
    zsy = ly/lz;
    zshearmat(mmat,zsx,zsy);

/* rotate the hue */
    zrs = sin(rot*M_PI/180.0);
    zrc = cos(rot*M_PI/180.0);
    zrotatemat(mmat,zrs,zrc);

/* unshear the space to put the luminance plane back */
    zshearmat(mmat,-zsx,-zsy);

/* rotate the grey vector back into place */
    yrotatemat(mmat,-yrs,yrc);
    xrotatemat(mmat,-xrs,xrc);

    matrixmult(mmat,mat,mat);
}

@implementation DRColorPermutator

- (id) init
{
    self = [super init];
    
    if( self )
    {
        identmat(matrix);
    }
    
    return self;
}

- (void) changeSaturationBy:(float)amount fromScratch:(BOOL)scratch
{
    if(scratch) identmat(matrix);
    saturatemat( matrix, amount );
}

- (void) rotateHueByDegrees:(float)degrees preservingLuminance:(BOOL)preserve fromScratch:(BOOL)scratch
{
    if(scratch) identmat(matrix);
    if( preserve )
    {
        huerotatemat( matrix, degrees );
    }
    else
    {
        simplehuerotatemat( matrix, degrees );
    }
}

- (void) changeBrightnessBy:(float)amount fromScratch:(BOOL)scratch
{
    if(scratch) identmat(matrix);
    cscalemat(matrix,amount,amount,amount);
}

- (void) offsetColorsRed:(float)ramount green:(float)gamount blue:(float)bamount fromScratch:(BOOL)scratch
{
    if(scratch) identmat(matrix);
    cscalemat(matrix,ramount,gamount,bamount);
}

- (void) applyToBitmapImageRep:(NSBitmapImageRep*)rep
{
    unsigned long *repData = (unsigned long*)[rep bitmapData];
    
    applymatrixtoself(repData, matrix, [rep pixelsHigh]*[rep pixelsWide],[rep hasAlpha]);
}

// Added by JNJ
- (void) applyToRepsOfImage:(NSImage*)image{
    NSBitmapImageRep *rep;
    NSEnumerator *reps=[[image representations]objectEnumerator];
    while (rep=[reps nextObject])
        if ([rep isKindOfClass:[NSBitmapImageRep class]])
            [self applyToBitmapImageRep:rep];
}


- (void) applyToBitmapImageRep:(NSBitmapImageRep*)src andPutResultIn:(NSBitmapImageRep*)dest
{
    unsigned long *srcData = (unsigned long*)[src bitmapData], *destData = (unsigned long*)[dest bitmapData];
    
    applymatrixintodest(srcData, destData, matrix, [src pixelsHigh]*[src pixelsWide],[src hasAlpha]);
}



@end
