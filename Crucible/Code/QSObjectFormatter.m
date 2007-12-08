

#import "QSObjectFormatter.h"

#import "QSObject.h"
#import "QSObject_PropertyList.h"
#import "QSObject_StringHandling.h"

@implementation QSObjectFormatter
- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error{
//if (error)
//            *error = NSLocalizedString(@"Couldn’t convert to float", @"Error converting");
    *obj =[QSObject objectWithString:string];
    return YES;
}
- (NSString *)stringForObjectValue:(id)anObject{
    return [anObject name];
}
- (NSString *)editingStringForObjectValue:(id)anObject{
    return [anObject details];
}

@end
