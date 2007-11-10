//
//  QSObject (ColorHandling).m
//  Quicksilver
//
//  Created by Alcor on 8/30/04.

//

#import "QSObject+ColorHandling.h"


@implementation QSObject (ColorHandling)
- (NSColor *)colorValue{
	return [NSUnarchiver unarchiveObjectWithData:[self objectForType:NSColorPboardType]];
}
@end


@implementation QSColorObjectHandler : NSObject
- (BOOL)objectHasChildren:(id <QSObject>)object{return NO;}
- (void)setQuickIconForObject:(QSObject *)object{
	[object setIcon:[[NSWorkspace sharedWorkspace]iconForFileType:@"'clpt'"]];
}

- (BOOL)loadIconForObject:(QSObject *)object{
	NSImage *image=[[[NSImage alloc]initWithSize:NSMakeSize(128,128)]autorelease];

	   NSRect rect=NSMakeRect(0,0,128,128);
	   
	   
	   NSBezierPath *roundRect=[NSBezierPath bezierPath];
	   [roundRect appendBezierPathWithRoundedRectangle:rect withRadius:NSHeight(rect)/8];
	   
	   [image lockFocus];
	   [[object colorValue]set];
	   [roundRect fill]; 
	   [image unlockFocus];
	   [object setIcon:image];
	   return YES;
}
- (NSString *)identifierForObject:(id <QSObject>)object{return nil;}

- (NSString *)detailsOfObject:(QSObject *)object{return nil;}
@end