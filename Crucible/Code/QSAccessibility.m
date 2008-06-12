#import "QSAccessibility.h"
#import <ApplicationServices/ApplicationServices.h>
#import "unistd.h"
#import <SecurityFoundation/SFAuthorization.h>
#import <Security/Security.h>
//extern Boolean 

void QSEnableAccessibilityIfNeeded() {}

void QSEnableAccessibility() {
	if (AXAPIEnabled()) return;
	
	OSStatus myStatus;
	AuthorizationItem myAuthorizationExecuteRight = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights myAuthorizationRights = {1, &myAuthorizationExecuteRight};
	NSString *prompt = NSLocalizedString(@"Authentication is required to allow access for assistive devices. This will allow applications to share additional information with each other, but may pose a security risk.\n\nThis option may also be enabled in the Universal Access preference pane.\n\n", @"QSEnableAccessibility prompt");
	char *icon="/System/Library/PreferencePanes/UniversalAccessPref.prefPane/Contents/Resources/UniversalAccessPref.tiff";
	AuthorizationItem kAuthEnv[] = {
	{ kAuthorizationEnvironmentPrompt, [prompt length], (char*)[prompt UTF8String], 0},
	{ kAuthorizationEnvironmentIcon, strlen(icon), icon, 0 } };
	
	AuthorizationEnvironment myAuthorizationEnvironment = { 2, kAuthEnv };
	
	AuthorizationFlags myFlags = kAuthorizationFlagDefaults;    
	myFlags = kAuthorizationFlagDefaults |           //8
		kAuthorizationFlagInteractionAllowed |           //9
		kAuthorizationFlagPreAuthorize |         //10
		kAuthorizationFlagExtendRights;         //11
	SFAuthorization *auth = [SFAuthorization authorizationWithFlags:myFlags rights:&myAuthorizationRights environment:&myAuthorizationEnvironment];
	FILE *myCommunicationsPipe = NULL;
	char myReadBuffer[128];
	
	char * myArguments[] = { "/private/var/db/.AccessibilityAPIEnabled", NULL };
	
	myStatus = AuthorizationExecuteWithPrivileges(
												  [auth authorizationRef],
                                                  "/usr/bin/touch",
                                                  kAuthorizationFlagDefaults,
                                                  myArguments,          //15
												  &myCommunicationsPipe
                                                  );         //16
	
	//QSLog(@"status %d",myStatus);
	if (myStatus == errAuthorizationSuccess) {
		for(;;) {
			int bytesRead = read( fileno( myCommunicationsPipe ), myReadBuffer, sizeof( myReadBuffer ));
			if (bytesRead < 1) break;
			write( fileno(stdout), myReadBuffer, bytesRead );
		}
	}		
}

