

#import <Foundation/Foundation.h>

@protocol QSParser
- (BOOL)validParserForPath:(NSString *)path;
- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings;
- (NSArray *)objectsFromURL:(NSURL *)url withSettings:(NSDictionary *)settings;

- (NSArray *)objectsFromData:(NSData *)data encoding:(NSStringEncoding)encoding settings:(NSDictionary *)settings source:(NSURL *)source;
@end

@interface QSParser : NSObject <QSParser> {}
- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings;
- (BOOL)validParserForPath:(NSString *)path;
@end


