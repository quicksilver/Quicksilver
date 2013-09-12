#import <Foundation/Foundation.h>

#import "QSActionProvider.h"

@interface QSTextActions : QSActionProvider {
}

@property (strong, nonatomic) NSWindow *currentLargeTypeWindow;

- (void)typeString:(NSString *)string;

@end
