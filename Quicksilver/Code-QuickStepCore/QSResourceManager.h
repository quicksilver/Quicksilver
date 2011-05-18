



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

/*!
 @buildWebSearchIconForURL
 @abstract   Builds a new icon that is a composite of the DefaultBookmarkIcon (globe) and a website's favIcon
 @discussion Returns a new icon with a favicon superimposed on the 'DefaultBookmarkIcon' icon and 'Find' icon
			 Called in QSObject_URLHandling.m
 @param      urlString The input URL string to collect the favicon from
 @result     Returns the new 128x128 image or nil.
 */
- (NSImage *)buildWebSearchIconForURL:(NSString *)urlString;

- (NSImage *)imageNamed:(NSString *)name;

/*!
 *    favIcon
 *    @abstract   Matches a URL string with a favIcon NSImage
 *    @discussion For this function to work the user must have an internet connection
 *                FavIcons are collected from g.etfv.co
 *    @param      urlString The input URL string to match
 *    @result     An NSImage if there was a match, otherwise nil
 */
- (NSImage *)getFavIcon:(NSString *)urlString;

- (NSImage *)imageWithLocatorInformation:(id)locator;
- (void)addResourcesFromDictionary:(NSDictionary *)dict;
- (NSString *)pathWithLocatorInformation:(id)locator;
- (NSImage *)imageWithExactName:(NSString *)name;
//- (NSImage *)daedalusImage;

- (NSString *)pathForImageNamed:(NSString *)name;
@end
