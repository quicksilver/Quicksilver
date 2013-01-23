#pragma mark User Agent

#define kQSUserAgent [NSString stringWithFormat:@"Quicksilver/%@ OSX/%@ (%@)",\
					 (NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey),\
					 [NSApplication macOSXFullVersion], @"x86"]

#pragma mark Search URLs

#define QUERY_KEY @"***"

#pragma mark Syncrhonous Results

#define kQSResultArrayKey @"resultArray"

#pragma mark Bundle ID

#define kQSBundleID @"com.blacktree.Quicksilver"

#pragma mark Actions

// strings:
#define kActionClass                @"actionClass"
#define kActionProvider             @"actionProvider"
#define kActionSelector             @"actionSelector"
#define kActionSendMessageToClass   @"actionSendToClass"
#define kActionAlternate            @"alternateAction"
#define kActionScript               @"actionScript"
#define kActionHandler              @"actionHandler"
#define kActionEventClass           @"actionEventClass"
#define kActionEventID              @"actionEventID"

#define kActionArgumentCount        @"argumentCount" // Number, if undefined, calculates from selector

// strings:
#define kActionIcon                 @"icon"
#define kActionName                 @"name"
#define kActionUserData             @"userData"
#define kActionIdentifier           @"id"

// arrays:
#define kActionDirectTypes          @"directTypes"
#define kActionDirectFileTypes      @"directFileTypes"
#define kActionIndirectTypes        @"indirectTypes"
#define kActionResultType           @"resultTypes" // Unused ?

// BOOLs:
#define kActionRunsInMainThread     @"runInMainThread"
#define kActionDisplaysResult       @"displaysResult"
#define kActionIndirectOptional     @"indirectOptional"
#define kActionReverseArguments     @"reverseArguments"
#define kActionSplitPluralArguments @"splitPlural"
#define kActionValidatesObjects     @"validatesObjects"
#define kActionInitialize           @"initialize"
#define kActionEnabled              @"enabled"
#define kActionResolvesProxy        @"resolvesProxy"

// NSNumber (float) :
#define kActionPrecedence @"precedence"