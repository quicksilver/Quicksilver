//
//  QSTaskViewController.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 11/26/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QSTask;

@interface QSTaskViewController : NSViewController

@property (strong) IBOutlet QSTask *task;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;

- (instancetype)initWithTask:(QSTask *)task;

- (IBAction)cancel:(id)sender;

@end
