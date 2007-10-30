

#import "QSMenuView.h"


@implementation QSMenuView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[[NSTableView alloc]init];
		
	//	NSTableView *tableView=[[NSTableView alloc]initWithFrame:NSZeroRect];
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}

@end
