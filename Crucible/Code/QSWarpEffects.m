//
//  QSWarpEffects.m
//  Quicksilver
//
//  Created by Alcor on 10/3/04.

//

#import "QSWarpEffects.h"
#import "QSWindowAnimation.h"
#include <Carbon/Carbon.h>
#include <stdio.h>
#include <unistd.h>


#define W 2
#define H 31
#define NUM 100

//#define LEFT 100.0
//#define TOP 100.0
//#define WIDTH 250.0
//#define HEIGHT 300.0

#define X1 (LEFT - WIDTH/3)
#define Y1 (TOP + HEIGHT/2)
#define X2 (X1 + WIDTH/2)
#define Y2 (Y1 - HEIGHT/2)
#define X3 (X1 + WIDTH*2/3)
#define Y3 (Y1 + HEIGHT/2)

static inline float bezier(float p1, float p2, float p3, float t) {
	float nt = 1 - t;
	return p1 * nt * nt + 2 * p2 * t * nt + p3 * t * t;
}
//void QSLogMesh(CGPointWarp **mesh,int width,int height){
//	//mesh->local.x;
//	QSLog(@"Mesh!");
//	int i,j;
//	for (i=0;i<width;i++){
//		for (j=0;j<height;j++){
//			QSLog(@"[%d][%d] - (%f,%f) (%f,%f)",i,j,0,0,0,0,mesh[i][j].local.x,mesh[i][j].local.y,mesh[i][j].global.x,mesh[i][j].global.y);	
//			
//		}	
//	}
//}
//
CGPointWarp *QSTestMeshEffect(QSWindowAnimation *hp,float f,int *w, int*h){
	NSWindow *window=hp->_window;
	*w=W;
	*h=H;
	
	CGPointWarp mesh[H][W];
	int i;
	
	NSRect frame=[window frame];
	float TOP=NSMaxY(frame);
	float LEFT=NSMinX(frame);
	float HEIGHT=NSHeight(frame);
	float WIDTH=NSWidth(frame);
	
	float nt = 1-f;
	double x1, y1, x2, y2, x3, y3;
	x1 = LEFT - (LEFT - X1) * nt;
	y1 = TOP - (TOP - Y1) * nt;
	x2 = LEFT - (LEFT - X2) * nt;
	y2 = (TOP+(HEIGHT/2)) - ((TOP+(HEIGHT/2)) - Y2) * nt;
	x3 = LEFT - (LEFT - X3) * nt;
	y3 = (TOP+HEIGHT) - ((TOP+HEIGHT) - Y3) * nt;
	for (i = 0; i < H; i++) {
		float t = (float) i / (H - 1);
		mesh[i][0].local.x = 0;
		mesh[i][0].local.y = t * HEIGHT;
		mesh[i][0].global.x =LEFT+ sin(bezier(x1, x2, x3, t));
		mesh[i][0].global.y = bezier(y1, y2, y3, t);
		
		mesh[i][1].local.x = WIDTH;
		mesh[i][1].local.y = mesh[i][0].local.y;
		mesh[i][1].global.x =  WIDTH + mesh[i][0].global.x;
		mesh[i][1].global.y = mesh[i][0].global.y;
	}
	//QSLogMesh(mesh,W,H);
	
	//QSLog(@"xet %x %d",mesh,CGSSetWindowWarp(_CGSDefaultConnection(), [window windowNumber], W, H, mesh));
	
	//for (j = 0; j < NUM; j++) {
	//	CGSSetWindowWarp(_CGSDefaultConnection(), [window windowNumber], W, H, mesh);
	//	usleep(5000);
	//}
	
  size_t size=sizeof(CGPointWarp)*H*W;
  return memcpy(malloc(size), mesh, size);
  
  return NULL;
}
