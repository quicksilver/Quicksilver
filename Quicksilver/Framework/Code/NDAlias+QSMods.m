//
//  NDAlias+QSMods.m
//  Quicksilver
//
//  Created by Alcor on Fri Mar 05 2004.

//

#import "NDAlias+QSMods.h"


@implementation NDAlias (QSMods)
- (NSString *)quickPath
{
    
    CFStringRef pathString=nil;
    FSCopyAliasInfo (
                     aliasHandle,
                     NULL,NULL,
                     &pathString,
                     NULL,
                     NULL
                     );
    
    // QSLog(@"alias %@",pathString);
    return [(NSString *)pathString autorelease];
}
@end


