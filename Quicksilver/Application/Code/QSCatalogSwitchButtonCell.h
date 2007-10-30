

#import <Foundation/Foundation.h>


@interface QSCatalogSwitchButtonCell : NSButtonCell {
	int state;
    bool falseMixedState;
}
- (bool)falseMixedState;
- (void)setFalseMixedState:(bool)flag;
@end