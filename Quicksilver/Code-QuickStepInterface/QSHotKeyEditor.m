#import "QSApp.h"
#import "QSHotKeyEditor.h"
#import "QSHotKeyEvent.h"

@implementation QSHotKeyCell
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj {
	NSLog(@"set up editor %@", textObj);
	id instance = [QSHotKeyFieldEditor sharedInstance];
	[super setUpFieldEditorAttributes:instance];
	return instance;
}
- (id)init {
	if ((self = [super init])) {
		[self setEditable:YES];
		[self setSelectable:YES];
		[self setBezeled:YES];
	}
	return self;
}
- (void)validateEditing { NSLog(@"validate");  }
@end

@implementation QSHotKeyControl
+ (Class)cellClass { return [QSHotKeyCell class]; }
- (void)awakeFromNib {
	QSHotKeyCell *aCell = [[QSHotKeyCell alloc] init];
	[self setCell:aCell];
}
- (void)textDidEndEditing:(NSNotification*)aNotification { NSLog(@"notif %@", aNotification);  }
- (void)setStringValue:(NSString *)string {
//	NSLog(@"string %@", string);
	[super setStringValue:string];
}
@end

@implementation QSHotKeyFieldEditor
+ (id)sharedInstance {
	static NSWindowController *_sharedInstance = nil;
	if (!_sharedInstance)
		_sharedInstance = [[[self class] allocWithZone:nil] init];
	return _sharedInstance;
}
- (void)_disableHotKeyOperationMode {
	CGSConnection conn = _CGSDefaultConnection();
	CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyDisable);
	[(QSApp *)NSApp setGlobalKeyEquivalentTarget:self];
}
- (void)_restoreHotKeyOperationMode {
	CGSConnection conn = _CGSDefaultConnection();
	CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyEnable);
	[(QSApp *)NSApp setGlobalKeyEquivalentTarget:nil];
}
- (void)_windowDidBecomeKeyNotification:(id)fp8 { [self _disableHotKeyOperationMode];  }
- (void)_windowDidResignKeyNotification:(id)fp8 { [self _restoreHotKeyOperationMode];  }
- (id)init {
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancel) name:NSApplicationWillResignActiveNotification object:nil];
		//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancel) name:NSWindowDidResignKeyNotification object:nil];
		[self setFieldEditor:YES];
		[self alignCenter:nil];
		//NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 16, 16)];

		//[self addSubview:cancelButton];
		[self setSelectable:NO];
		[cancelButton setAutoresizingMask:NSViewMinXMargin];
		[cancelButton setTarget:self];
		[cancelButton setAction:@selector(clear:)];
		[cancelButton setTitle:@"x"];
	}
	return self;
}
- (void)viewDidMoveToWindow {
	//	[cancelButton setBounds:NSMakeRect(NSWidth([self bounds]) -16, 0, 16, 16)];
}
- (void)clear:(id)sender {}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (BOOL)shouldSendEvent:(NSEvent *)event {
	if ([event type] == NSKeyDown) {
		[self keyDown:event];
		return NO;
	} else {
		return YES;
	}
}

#if 0
- (void)setSelectedRange:(NSRange)charRange {
	//NSLog(@"select %d %d '%@'", charRange.location, charRange.length, [self string]);
	[super setSelectedRange:charRange];
}
#endif

- (BOOL)becomeFirstResponder {
	defaultString = [[self string] copy];
	BOOL status = [super becomeFirstResponder];
	validCombo = NO;
	[(QSApp *)[NSApplication sharedApplication] addEventDelegate:self];
	[self _disableHotKeyOperationMode];
	[self setSelectedRange:NSMakeRange(0, [[self string] length])];
	return status;
}

- (NSRange) selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity {
	return NSMakeRange(0, [[super string] length]);
}

- (BOOL)resignFirstResponder {
	defaultString = nil;
	[(QSApp *)[NSApplication sharedApplication] removeEventDelegate:self];
	[self _restoreHotKeyOperationMode];
	return [super resignFirstResponder];
}
- (void)cancel {
	if ([[self window] firstResponder] == self) {
#ifdef DEBUG
		if (VERBOSE) NSLog(@"Cancel");
#endif
        /* TODO: Check what is actually delegate */
		[[self window] makeFirstResponder:(NSResponder *)[self delegate]];
	}
}
- (void)flagsChanged:(NSEvent *)theEvent {
    NSString *newString = stringForModifiers([theEvent modifierFlags]);
	[self setString:[newString length] ? newString:defaultString];
}
- (void)setDictionaryStringWithEvent:(NSEvent *)theEvent {
	NSUInteger modifiers = [theEvent modifierFlags];
	unsigned short keyCode = [theEvent keyCode];
	NSString *characters = (keyCode == 48) ? @"\t" : [theEvent charactersIgnoringModifiers];
	//	NSLog(@"event %@", theEvent);
	if ([theEvent modifierFlags] & (NSCommandKeyMask | NSFunctionKeyMask | NSControlKeyMask | NSAlternateKeyMask) ) {
	  	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:modifiers] , @"modifiers", [NSNumber numberWithUnsignedShort:keyCode], @"keyCode", characters, @"character", nil];
		validCombo = YES;
		NSString *string = [[NSString alloc] initWithData:[NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:nil] encoding:NSUTF8StringEncoding];
		[self setString:string];
	} else if ([theEvent keyCode] == 53) {
		[self setString:@"Old"];
	} else if ([theEvent keyCode] == 48) {
		//[super sendEvent:theEvent];
	} else if ([theEvent keyCode] == 51) { //Delete
		validCombo = YES;
		NSString *string = [[NSString alloc] initWithData:[NSPropertyListSerialization dataFromPropertyList:[NSDictionary dictionary] format:NSPropertyListXMLFormat_v1_0 errorDescription:nil] encoding:NSUTF8StringEncoding];
		[self setString:string];
	} else {
		NSBeep();
	}
	[[self window] makeFirstResponder:nil];
}
- (void)keyDown:(NSEvent *)theEvent { [self setDictionaryStringWithEvent:theEvent]; }
- (BOOL)performKeyEquivalent:(id)theEvent {
	[self setDictionaryStringWithEvent:theEvent];
	return YES;
}
- (NSString *)string {
	if (validCombo) return [super string];
	return @"Old";
}
@end

@implementation QSHotKeyField

+ (void)initialize {
	[self exposeBinding:@"hotKey"];
}

- (id)initWithFrame:(NSRect)aFrame {
	if ( self = [super initWithFrame:aFrame] ) {
		[self setEditable:NO];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aCoder {
	if ( self = [super initWithCoder:aCoder] ) {
		[self setEditable:NO];
	}
	return self;
}

- (void)awakeFromNib {
	// Remap value binding to hotKey dictionary
	NSDictionary *binding = [self infoForBinding:@"value"];
	[self unbind:@"value"];
	[self bind:@"hotKey" toObject:[binding objectForKey:NSObservedObjectKey] withKeyPath:[binding objectForKey:NSObservedKeyPathKey] options:[binding objectForKey:NSOptionsKey]];
}

- (NSDictionary *)hotKeyDictForEvent:(NSEvent *)event {
	NSUInteger modifiers = [event modifierFlags];
	unsigned short keyCode = [event keyCode];
//	NSString *character = (keyCode == 48) ? @"\t" : [event charactersIgnoringModifiers];
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:modifiers] , @"modifiers", [NSNumber numberWithUnsignedShort:keyCode] , @"keyCode", nil];
}

- (NSDictionary *)hotKey { return hotKey;  }
- (void)setHotKey:(NSDictionary *)newHotKey {
	if (hotKey != newHotKey) {
		hotKey = newHotKey;
		NSDictionary *binding = [self infoForBinding:@"hotKey"];
		if (binding)
			[[binding objectForKey:NSObservedObjectKey] setValue:hotKey forKeyPath:[binding objectForKey:NSObservedKeyPathKey]];
		[self updateStringForHotKey];
	}
}

- (void)updateStringForHotKey {
	if ([hotKey isKindOfClass:[NSDictionary class]]) {
		NSString *descrip = [[QSHotKeyEvent hotKeyWithDictionary:hotKey] stringValue];
		[self setStringValue:descrip?descrip:@""];
	} else if (hotKey) {
		[self setStringValue:@"invalid"];
	} else {
		[self setStringValue:@""];
	}
}

- (IBAction)set:(id)sender {
	[self absorbEvents];
}

- (void)mouseDown:(NSEvent *)event {
	[self absorbEvents];
}

- (void)timerFire:(NSTimer *)timer {
	NSTimeInterval t = [[NSDate date] timeIntervalSinceReferenceDate];
	t = fmod(t, 1.0);
	t = (sin(t*M_PI*2)+1)/2;
	NSColor *newColor = [[NSColor textBackgroundColor] blendedColorWithFraction:t ofColor:[NSColor selectedTextBackgroundColor]];
	[self setBackgroundColor:newColor];
}

- (void)absorbEvents {
	[[self window] makeFirstResponder:self];
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.1] interval:0.1 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];

	//	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[self setBackgroundColor:[NSColor selectedTextBackgroundColor]];
	[setButton setState:NSOnState];
	[[self cell] setPlaceholderString:[self stringValue]];
	[self setStringValue:@"Set Keys"];
	[[self window] display];
	NSEvent *theEvent;

	CGSConnection conn = _CGSDefaultConnection();
	CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyDisable);
	BOOL collectEvents = YES;
	while(collectEvents) {
		theEvent = [NSApp nextEventMatchingMask:NSKeyDownMask | NSFlagsChangedMask | NSLeftMouseDownMask | NSAppKitDefinedMask | NSSystemDefinedMask untilDate:[NSDate dateWithTimeIntervalSinceNow:10.0] inMode:NSDefaultRunLoopMode dequeue:YES];
		switch ([theEvent type]) {
			case NSKeyDown: {
//				unsigned short keyCode = [theEvent keyCode];
//				NSString *characters = (keyCode == 48) ? @"\t" : [theEvent charactersIgnoringModifiers];
				if ([theEvent modifierFlags] & (NSCommandKeyMask | NSFunctionKeyMask | NSControlKeyMask | NSAlternateKeyMask) ) {
					[self setHotKey:[self hotKeyDictForEvent:theEvent]];
					collectEvents = NO;
				} else if ([theEvent keyCode] == 53) { //Escape
					collectEvents = NO;
				} else if ([theEvent keyCode] == 48) { //Tab
					[[self window] makeFirstResponder:[self nextKeyView]];
					collectEvents = NO;
				} else if ([theEvent keyCode] == 51) { //Delete
					[self setHotKey:nil];
					collectEvents = NO;
				} else {
					NSBeep();
				}
			}
			break;
			case NSFlagsChanged: {
                NSString *newString = stringForModifiers([theEvent modifierFlags]);

				//NSLog(@"%@", newString);
				[self setStringValue:[newString length] ? newString : @""];
				[self display];
				[setButton display];
				break;
			}
			case NSSystemDefined:
			case NSAppKitDefined:
			case NSLeftMouseDown:
				if (![self containsEvent:theEvent] && ![setButton containsEvent:theEvent]) {
					//Absorb events on self or setButton
					[NSApp postEvent:theEvent atStart:YES];
				}
				collectEvents = NO;
			default:
			break;
		}
	}
	[timer invalidate];
	CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyEnable);
	[self updateStringForHotKey];
	[self setBackgroundColor:[NSColor textBackgroundColor]];
	[setButton setState:NSOffState];
}


@end
