

#import <Foundation/Foundation.h>


@interface QSMnemonics : NSObject {
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
- (void)addAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key;
//- (void)addAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key relativeToID:(NSString *)above;
- (void)addAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key immediately:(BOOL)immediately;
- (void)addAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key relativeToID:(NSString *)above immediately:(BOOL)immediately;
- (void)removeObjectMnemonic:(NSString *)mnem forID:(NSString *)key;
- (void)addObjectMnemonic:(NSString *)mnem forID:(NSString *)key;

- (void)writeItems:(id)sender;

@end
