//
//  NSData_RangeExtensions.m
//  Quicksilver
//
//  Created by Alcor on 7/30/04.

//

#import "NSData_RangeExtensions.h"


@implementation NSData (RangeExtensions)
// This function is a modification of OmniFoundation's  - (BOOL)containsData:(NSData *)data; to return an offset
- (unsigned)offsetOfData:(NSData *)data;
{
    unsigned const char *selfPtr, *selfEnd, *selfRestart, *ptr, *ptrRestart, *end;
    unsigned myLength, otherLength;
	
	unsigned offset=0;
    ptrRestart = [data bytes];
    otherLength = [data length];
    if (otherLength == 0)
        return 0;
    end = ptrRestart + otherLength;
    selfRestart = [self bytes];
    myLength = [self length];
    if (myLength < otherLength) // This test is a nice shortcut, but it's also necessary to avoid crashing: zero-length CFDatas will sometimes(?) return NULL for their bytes pointer, and the resulting pointer arithmetic can underflow.
        return NSNotFound;
    selfEnd = selfRestart + (myLength - otherLength);
	
    /* A note on the goto in the following code, for the structure-obsessed among us: it could be replaced with a flag and a 'break', yes, but since that code path is the most common one (and gcc3 doesn't optimize out control-flow flags) it seems worth the potential disapprobation from the use of reviled goto. */
    
    while(selfRestart <= selfEnd) {
        selfPtr = selfRestart;
        ptr = ptrRestart;
        while(ptr < end) {
            if (*ptr++ != *selfPtr++)
                goto notThisOffset;
        }
        return offset;
		
notThisOffset:
			
			selfRestart++;
		offset++;
    }
    return NSNotFound;
}
@end
