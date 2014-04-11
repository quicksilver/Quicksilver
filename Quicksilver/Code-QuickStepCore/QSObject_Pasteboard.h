

#import <Foundation/Foundation.h>

#import "QSObject.h"

extern NSString *QSPasteboardObjectIdentifier;
extern NSString *QSPasteboardObjectAddress;

@interface QSObject (Pasteboard) <NSPasteboardWriting, NSPasteboardReading>
+ (id)objectWithPasteboard:(NSPasteboard *)pasteboard;
- (id)initWithPasteboard:(NSPasteboard *)pasteboard;
+ (id)objectWithClipping:(NSString *)clippingFile;
- (id)initWithClipping:(NSString *)clippingFile;
- (void)guessName;
- (BOOL)putOnPasteboardAsPlainTextOnly:(NSPasteboard *)pboard;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes;
- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type;
- (NSData *)dataForType:(NSString *)dataType;
- (void)addContentsOfClipping:(NSString *)path;
@end
