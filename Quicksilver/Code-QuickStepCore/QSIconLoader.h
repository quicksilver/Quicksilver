#import <Foundation/Foundation.h>

@class QSIconLoader;

@interface NSObject (QSIconLoaderDelegate)
- (void)iconLoader:(QSIconLoader *)loader loadedIndex:(NSInteger)i inArray:(NSArray *)array;
@end

#define QSIconLoaderDelegateCanceled @"QSIconLoaderDelegateCanceled"

@interface QSIconLoader : NSObject {
	NSArray *objectArray;
	BOOL loaderValid;
    __block BOOL isLoading;

	__block NSRange loadRange;
	__block NSRange newRange;
	NSObject *delegate;
	NSInteger modulation;
}
+ (id)loaderWithArray:(NSArray *)newArray;
+ (void)invalidateLoaderForDelegate:(id)delegate;

- (void)loadIconsInRange:(NSRange)range;
- (NSObject *)delegate;
- (void)setDelegate:(NSObject *)aDelegate;

- (void)invalidate;
- (BOOL)isLoading;

- (NSInteger) modulation;
- (void)setModulation:(NSInteger)newModulation;
@end
