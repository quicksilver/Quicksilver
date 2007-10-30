//
//  MyDistViewItem.h
//  UKDistributedView
//
//  Created by Uli Kusterer on Wed Jun 25 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


// Class for storing list items used by MyDataSource:

@interface MyDistViewItem : NSObject
{
	NSString*		title;
	NSImage*		image;
	NSPoint			position;
}

-(id)	initWithTitle: (NSString*)theTitle andImage: (NSImage*)img;

-(NSString*)	title;
-(void)			setTitle: (NSString*)theTitle;

-(NSImage*)		image;
-(void)			setImage: (NSImage*)img;

-(NSPoint)		position;
-(void)			setPosition: (NSPoint)pos;

@end
