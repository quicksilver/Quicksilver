

#import <Foundation/Foundation.h>

#import "QSObject.h"

@interface QSURLObjectHandler : NSObject
@end
@interface QSObject (URLHandling)
+ (QSObject *)URLObjectWithURL:(NSString *)url title:(NSString *)title;
- (id)initWithURL:(NSString *)url title:(NSString *)title;
- (NSString *)cleanQueryURL:(NSString *)query;
@end