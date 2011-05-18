



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
 @buildWebSearchIconWithIcon
 @abstract   Builds a new icon that is a composite of the DefaultBookmarkIcon (globe) and a website's favIcon
 @discussion Sets the icon for the object  (defaults to DefaultBookmarkIcon)
 and loads a second icon called "Find". The first icon is
 drawn at 128x128. The second icon is scaled and drawn
 at an offset to create the composite.
 Called in QSHTMLLinkParser.m and the Web Search Plugin
 @param      useIconFile Name of the source (first) icon.
 @result     Returns the new 128x128 image or nil.
 */
- (NSImage *)buildWebSearchIconForObject:(NSString *)urlString;

- (NSImage *)imageNamed:(NSString *)name;

/*!
 *    favIcon
 *    @abstract   Matches a URL string with a favIcon NSImage
 *    @discussion For this function to work the favIcon dictionary must
 *                by populated.  Currently that is done through Safari (need the
 *                updated plugin).
 *    @param      url The input URL string to match
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
