//
//  KeyComboPanel.h
//
//  Created by Quentin D. Carnicelli on Thu Jun 18 2002.
//  Copyright (c) 2002 Subband inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KeyCombo;

@interface KeyComboPanel : NSObject
{
    IBOutlet id mTextField;
	
	KeyCombo* mKeyCombo;
}

+ (id)sharedPanel;

- (int)runModal;
- (NSWindow*)window;

- (KeyCombo*)keyCombo;
- (void)setKeyCombo: (KeyCombo*)combo;

- (void)setKeyName: (NSString*)name;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)clear:(id)sender;

@end

