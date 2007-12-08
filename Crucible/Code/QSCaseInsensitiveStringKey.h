

#import <Foundation/Foundation.h>

//  ----- CaseInsensitiveStringKey.h 

#import <Foundation/Foundation.h> 

@interface QSCaseInsensitiveStringKey : NSObject { 
NSString *original; 
} 

+ (QSCaseInsensitiveStringKey *) fromString: (NSString *)originalString; 
- (id)copyWithZone:(NSZone *)zone; 
- (NSString *) string; 
- (void) setString: (NSString *)originalString; 
- (unsigned) hash; 
- (BOOL) isEqual: (id)anObject; 
//- (NSString *) description; 
@end 


@interface NSString (QSCaseInsensitiveStringKey)
- (QSCaseInsensitiveStringKey *)insensitiveKey;
@end