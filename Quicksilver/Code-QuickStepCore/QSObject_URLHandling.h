

#import <Foundation/Foundation.h>

#import "QSObject.h"

@interface QSURLObjectHandler : NSObject

/*!
 @buildWebSearchIconForURL
 @abstract   Builds a new icon that is a composite of the DefaultBookmarkIcon (globe) and a website's favIcon
 @discussion Returns a new icon with a favicon superimposed on the 'DefaultBookmarkIcon' icon and 'Find' icon
 Called in QSObject_URLHandling.m
 @param      object The web search object to set the favicon for
 */
- (void)buildWebSearchIconForObject:(QSObject *)object;

/*!
 *    favIcon
 *    @abstract   Creates a favicon image for a given URL
 *    @discussion For this function to work the user must have an internet connection
 *                FavIcons are collected from g.etfv.co
 *    @param      urlString The input URL string to match
 *    @result     An NSImage if there was a match, otherwise nil
 */
- (NSImage *)getFavIcon:(NSString *)urlString;

@end
@interface QSObject (URLHandling)
+ (QSObject *)URLObjectWithURL:(NSString *)urlString title:(NSString *)title;
- (id)initWithURL:(NSString *)urlString title:(NSString *)title;
- (NSString *)cleanQueryURL:(NSString *)query;
- (void)assignURLTypesWithURL:(NSString *)urlString; // allows existing objects to set themselves up as URLs
@end