//
//  MyDistViewItem.m
//  UKDistributedView
//
//  Created by Uli Kusterer on Wed Jun 25 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import "MyDistViewItem.h"


@implementation MyDistViewItem

-(id)	initWithTitle: (NSString*)theTitle andImage: (NSImage*)img
{
	if( self = [super init] )
	{
		title = [theTitle retain];
		image = [img retain];
		position = NSMakePoint( 0,0 );
	}
	
	return self;
}

-(NSString*)	title
{
	return title;
}


-(void)	setTitle: (NSString*)theTitle
{
	[theTitle retain];
	[title release];
	title = theTitle;
}

-(NSImage*)		image
{
	return image;
}


-(void)	setImage: (NSImage*)img
{
	[img retain];
	[image release];
	image = img;
}

-(NSPoint)		position
{
	return position;
}


-(void)	setPosition: (NSPoint)pos
{
	position = pos;
}


@end
