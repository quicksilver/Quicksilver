

#import "QSResizingInterfaceController.h"

#import "QSSearchObjectView.h"
#import "QSAction.h"
#import "QSTextProxy.h"
@implementation QSResizingInterfaceController


- (id)initWithWindowNibName:(NSString *)nib {
    self = [super initWithWindowNibName:nib];
    if (self) {
        expandTimer=nil;
        expanded=YES;  
    }
    return self;
}




- (void)showIndirectSelector:(id)sender{
    [super showIndirectSelector:sender];
    [self resetAdjustTimer];
}
- (void)hideIndirectSelector:(id)sender{
    [super hideIndirectSelector:sender];
    [self resetAdjustTimer];
}



- (void)resetAdjustTimer{
    
    if([[self window]isVisible]){
        if (![expandTimer isValid]){
            [expandTimer release];
            expandTimer = [[NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(adjustWindow:) userInfo:nil repeats:NO]retain];
        }else{
            [expandTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
        }   
    }else{
        [self adjustWindow:self];   
    }
}

- (void)adjustWindow:(id)sender{
	QSAction *action=(QSAction *)[aSelector objectValue];
    int argumentCount=[action argumentCount];
	
//	QSLog(@"adjust x%d",argumentCount);
    NSResponder *firstResponder=[[self window]firstResponder];
    if (argumentCount==2){
		BOOL indirectOptional=[[[[aSelector objectValue]actionDict]objectForKey:kActionIndirectOptional]boolValue];
		
//		   QSLog(@"adjust %d",indirectOptional);
        if (indirectOptional){
            if (firstResponder==iSelector
                || firstResponder==[iSelector currentEditor]
                || ([iSelector objectValue]!=nil && ![[iSelector objectValue]objectForType:QSTextProxyType])){
                [self expandWindow:sender];
                return;
            }
        }else{
            [self expandWindow:sender];
            return;
        }
    }
	    [self contractWindow:sender];
 
}

- (void)firstResponderChanged:(NSResponder *)aResponder{
    if (aResponder==iSelector || aResponder==[iSelector currentEditor]){
        QSAction *action=(QSAction *)[aSelector objectValue];
        int argumentCount=[action argumentCount];
        BOOL indirectOptional=[[[[aSelector objectValue]actionDict]objectForKey:kActionIndirectOptional]boolValue];
		
        if (argumentCount==2 && indirectOptional && (aResponder==iSelector || aResponder==[iSelector currentEditor]))
            [self adjustWindow:self];
    }     
}

- (void)expandWindow:(id)sender{ 
    expanded=YES;
}

- (void)contractWindow:(id)sender{
    expanded=NO;
}

- (BOOL)expanded {return expanded; }
@end
