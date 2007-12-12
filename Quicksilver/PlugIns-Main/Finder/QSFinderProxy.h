
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <QSFoundation/QSFoundation.h>
#import <QSCore/QSCore.h>


#import "QSFSBrowserMediator.h"

@interface QSFinderProxy : NSObject <QSFSBrowserMediator> {
NSAppleScript *finderScript;
}
+ (id)sharedInstance;

- (BOOL)revealFile:(NSString *)file;
- (NSArray *)selection;
- (NSArray *)copyFiles:(NSArray *)files toFolder:(NSString *)destination;
- (NSArray *)moveFiles:(NSArray *)files toFolder:(NSString *)destination;
- (NSArray *)moveFiles:(NSArray *)files toFolder:(NSString *)destination shouldCopy:(BOOL)copy;
- (NSArray *)deleteFiles:(NSArray *)files;

- (NSAppleScript *)finderScript;
- (void)setFinderScript:(NSAppleScript *)aFinderScript;

@end
