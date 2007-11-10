//
//  QSGroupObjectSource.m
//  Quicksilver
//
//  Created by Alcor on 4/5/05.

//

#import "QSGroupObjectSource.h"


@implementation QSGroupObjectSource
/*
 + (void)initialize{
	 
	 DRColorPermutator *perm=[[[DRColorPermutator alloc]init]autorelease];
	 [perm rotateHueByDegrees:-158 preservingLuminance:NO fromScratch:YES];
	 [perm changeSaturationBy:0.8 fromScratch:NO];
	 
	 NSImage *tintedImage=[[QSResourceManager imageNamed:@"GenericFolderIcon"]copy];
	 [perm applyToRepsOfImage:tintedImage];
	 
	 [tintedImage setName:@"TintedFolderIcon"];
 }
 */
- (BOOL)isVisibleSource{return YES;}

- (NSImage *) iconForEntry:(NSDictionary *)dict{return [NSImage imageNamed:@"CatalogGroup"];}

- (NSArray *) objectsForEntry:(NSDictionary *)dict{
    return nil;
}
@end
