#import <Foundation/Foundation.h>

@class QSIconLoader;

@interface NSObject (QSIconLoaderDelegate)
- (void)iconLoader:(QSIconLoader *)loader loadedIndex:(NSInteger)i inArray:(NSArray *)array;
@end

#define QSIconLoaderDelegateCanceled @"QSIconLoaderDelegateCanceled"

@interface QSIconLoader : NSObject {
	NSArray *array;
	NSIndexSet *loadedIndexes;
	BOOL loaderValid;
	NSThread *loadThread;

	NSRange loadRange;
	NSRange newRange;
	NSObject *delegate;
	NSInteger modulation;
}
+ (id)loaderWithArray:(NSArray *)newArray;
- (void)loadIconsInRange:(NSRange)range;
- (NSObject *)delegate;
- (void)setDelegate:(NSObject *)aDelegate;

- (void)invalidate;
- (BOOL)isLoading;

- (NSInteger) modulation;
- (void)setModulation:(NSInteger)newModulation;
+ (void)invalidateLoaderForDelegate:(id)delegate;
@end
