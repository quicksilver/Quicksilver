//
//  QSTask.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 6/29/05. Adapted by Florian Heckl on 20/08/10.
//

#import <Cocoa/Cocoa.h>
#import "QSObject.h"
@class QSTask;
@interface NSObject (QSTaskDelegate)
- (NSImage *)iconForTask:(QSTask *)task;
@end

@interface QSTask : NSViewController {
	NSString *identifier;
	NSString *name;
	NSString *status;
	CGFloat progress; //0 to 1, -1 is indeterminate
	QSObject *result;
	NSImage *icon;
	id delegate;

	SEL cancelAction;
	id cancelTarget;
	BOOL running;
	BOOL showProgress;
	NSArray *subtasks;
	QSTask *parentTask;
}
+ (QSTask *)taskWithIdentifier:(NSString *)identifier;
+ (QSTask *)findTaskWithIdentifier:(NSString *)identifier;
- (void)startTask:(id)sender;
- (void)stopTask:(id)sender;

- (IBAction)cancel:(id)sender;

- (NSString *)identifier;
- (void)setIdentifier:(NSString *)value;

- (NSString *)name;
- (void)setName:(NSString *)value;

- (NSString *)status;
- (void)setStatus:(NSString *)value;

- (CGFloat) progress;
- (void)setProgress:(CGFloat)value;

- (QSObject *)result;
- (void)setResult:(QSObject *)value;

- (SEL) cancelAction;
- (void)setCancelAction:(SEL)value;

- (id)cancelTarget;
- (void)setCancelTarget:(id)value;

- (BOOL)showProgress;
- (void)setShowProgress:(BOOL)value;

- (NSArray *)subtasks ;
- (void)setSubtasks:(NSArray *)value ;

- (NSImage *)icon;
- (void)setIcon:(NSImage *)newIcon;
- (id)delegate;
- (void)setDelegate:(id)newDelegate;

@end
