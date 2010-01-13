



#import <Foundation/Foundation.h>

extern id QSRez;

@interface QSResourceManager : NSObject {
	NSMutableDictionary *resourceDict;
	NSString *resourceOverrideFolder;
	NSDictionary *resourceOverrideList;
}
+ (void)initialize;
+ (id)sharedInstance;
+ (NSImage *)imageNamed:(NSString *)name;

+ (NSImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
- (NSImage *)imageNamed:(NSString *)name;
- (NSImage *)imageWithLocatorInformation:(id)locator;

- (void)addResourcesFromDictionary:(NSDictionary *)dict;
- (NSString *)pathWithLocatorInformation:(id)locator;
- (NSImage *)imageWithExactName:(NSString *)name;
//- (NSImage *)daedalusImage;

- (NSString *)pathForImageNamed:(NSString *)name;
@end
