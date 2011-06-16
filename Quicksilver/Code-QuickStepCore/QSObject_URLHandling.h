

#import <Foundation/Foundation.h>

#import "QSObject.h"

@interface QSURLObjectHandler : NSObject
@end
@interface QSObject (URLHandling)
+ (QSObject *)URLObjectWithURL:(NSString *)urlString title:(NSString *)title;
- (id)initWithURL:(NSString *)urlString title:(NSString *)title;
- (NSString *)cleanQueryURL:(NSString *)query;
- (void)assignURLTypesWithURL:(NSString *)urlString; // allows existing objects to set themselves up as URLs
@end