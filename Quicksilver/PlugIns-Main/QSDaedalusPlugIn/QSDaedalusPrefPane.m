

#import "QSDaedalusPrefPane.h"
#import <QSCore/QSResourceManager.h>

@implementation QSDaedalusPrefPane
- (id)init {
    self = [super initWithBundle:[NSBundle bundleForClass:[QSDaedalusPrefPane class]]];
    if (self) {
    }
    return self;
}

- (NSString *) mainNibName{
	return @"QSDaedalusPrefPane";
}

@end
