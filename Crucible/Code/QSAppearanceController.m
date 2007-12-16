//
//  QSAppearanceController.m
//  Quicksilver
//
//  Created by Alcor on 3/9/05.

//

#import "QSAppearanceController.h"

#import "NSColor_QSModifications.h"
id QSAppearance=nil;

@implementation QSAppearanceController

+ (id)sharedInstance{
    if (!QSAppearance) QSAppearance = [[[self class] allocWithZone:[self zone]] init];
  return QSAppearance;
}

- (id)init{
	if ((self=[super init])){
	[self  bind:@"accentColor"
				 toObject:[NSUserDefaultsController sharedUserDefaultsController]
			  withKeyPath:@"values.QSAppearance1A"
				  options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName
													  forKey:@"NSValueTransformerName"]];
	
	
	}	
	return self;
}

- (NSColor *)accentColor{
	if (!accentColor){
		
	}
	return accentColor;
}
- (void)setAccentColor:(NSColor *)color{
	[accentColor release];
	accentColor=[color retain];
	[NSColor setAccentColor:color]; 
}
@end
