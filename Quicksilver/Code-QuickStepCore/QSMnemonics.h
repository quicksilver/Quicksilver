

#import <Foundation/Foundation.h>


@interface QSMnemonics : NSObject {
	dispatch_queue_t write_queue;
	NSMutableDictionary *mnemonics;
	NSMutableDictionary *abbrevMnemonics;
	NSMutableDictionary *objectMnemonics;
	NSMutableDictionary *recentMnemonics;
	NSTimer *writeTimer;
}
+ (id)sharedInstance;

- (NSDictionary *)objectMnemonics;
- (NSDictionary *)objectMnemonicsForID:(NSString *)key;

- (NSArray *)abbrevMnemonicsForString:(NSString *)key;
- (void)removeAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key;
- (BOOL)addAbbrevMnemonic:(NSString *)mnem forObject:(QSObject *)object;
//- (void)addAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key relativeToID:(NSString *)above;
- (BOOL)addAbbrevMnemonic:(NSString *)mnem forObject:(QSObject *)object immediately:(BOOL)immediately;
- (BOOL)addAbbrevMnemonic:(NSString *)mnem forObject:(QSObject *)object relativeToID:(NSString *)above immediately:(BOOL)immediately;
- (void)removeObjectMnemonic:(NSString *)mnem forID:(NSString *)key;
- (BOOL)addObjectMnemonic:(NSString *)mnem forObject:(QSObject *)object;

- (void)writeItems:(id)sender;

@end
