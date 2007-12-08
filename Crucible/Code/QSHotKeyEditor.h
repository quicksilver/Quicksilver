

#import <Foundation/Foundation.h>


@interface QSHotKeyControl : NSTextField
{
	//NSTextView* fieldEditor;
	//	NSString* keyString;
	//	NSMutableArray* observers;
	//	BOOL isObservingFocus;
	//	BOOL shouldSelectNextKeyView;
	//	int isDiscarding;
	//	
	@private
	unsigned short		keyCode;
	unichar				character;
	unsigned long		modifierFlags;
}
//- (void)setKeyString:(NSString*)aKeyString;

@end

@interface QSHotKeyField : NSTextField
{
	IBOutlet NSButton *setButton;
	@private
	NSDictionary *hotKey;
}
- (IBAction)set:(id)sender;
- (NSDictionary *)hotKey;
- (void)setHotKey:(NSDictionary *)newHotKey;

- (void)updateStringForHotKey;
- (void)absorbEvents;
@end

@interface QSHotKeyCell : NSTextFieldCell
{
}
@end

@interface QSHotKeyFormatter : NSFormatter
@end
@interface QSHotKeyFieldEditor : NSTextView
{
   // ConfigurableKeysMgr *mMaster;
    NSNumber *mVirtualKey;
    unsigned int mModifiers;
 
    BOOL mOperationModeEnabled;
    unsigned int mSavedHotKeyOperatingMode;
    BOOL validCombo;
	
//	unsigned short		keyCode;
	unichar				character;
	unsigned long		modifierFlags;
	id					oldWindowDelegate;
	BOOL				oldWindowDelegateHandledEvents;
	NSButton *			cancelButton;
	NSString *			defaultString;
}
+ (id)sharedInstance;
- (void)_disableHotKeyOperationMode;
- (void)_restoreHotKeyOperationMode;
- (void)_windowDidBecomeKeyNotification:(id)fp8;
- (void)_windowDidResignKeyNotification:(id)fp8;
//- (id)initConfigKeyEditorWithMaster:(id)fp8;
- (void)dealloc;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
//- (void)mouseDown:(id)fp8;
- (void)keyDown:(NSEvent *)theEvent;
- (BOOL)performKeyEquivalent:(id)fp8;


@end
