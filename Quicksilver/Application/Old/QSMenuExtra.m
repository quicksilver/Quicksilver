

#import "QSMenuExtra.h"
#import "QSMenuExtraView.h"
#import "DRColorPermutator.h"




@implementation QSMenuExtra


- initWithBundle:(NSBundle *)bundle {
    
    // NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    // Menu item we are setting up at first
//    NSMenuItem			*menuItem;
	
	// Allow super to init
    self = [super initWithBundle:bundle];
    if (!self) return nil;
    
	connection=nil;
    qsBundle=[NSBundle bundleWithPath:
        [[NSWorkspace sharedWorkspace]absolutePathForAppBundleWithIdentifier:@"com.blacktree.Quicksilver"]];
    
    NSImage *menuImage=[[[NSImage alloc]initWithContentsOfFile:[qsBundle pathForResource:@"QuicksilverMenu" ofType:@"png"]]autorelease];
    NSImage *pressedMenuImage=[[[NSImage alloc]initWithContentsOfFile:[qsBundle pathForResource:@"QuicksilverMenuPressed" ofType:@"png"]]autorelease];
    
	// DRColorPermutator *perm=[[[DRColorPermutator alloc]init]autorelease];
	// [perm changeBrightnessBy:-0.8 fromScratch:YES];
    // [perm offsetColorsRed:-1.0 green:1.0 blue:0.0 fromScratch:NO];
    //  [perm rotateHueByDegrees:hue*360 preservingLuminance:NO fromScratch:NO];
    
    [menuImage setName:@"QuicksilverMenuNormal"];    
	[pressedMenuImage setName:@"QuicksilverMenuPressed"]; 
	
	//QSLog(@"image %@",menuImage);
	//QSLog(@"image %@",pressedMenuImage);
	// [perm applyToBitmapImageRep:(NSBitmapImageRep *)[[NSImage imageNamed:@"QuicksilverMenuNormal"] bestRepresentationForDevice:nil]];
    
    
	[self setView:[[QSMenuExtraView alloc] initWithFrame:[[self view]frame] menuExtra:self]];
    [[self view]setDelegate:self];
    
	//   [self setTarget:self];
	// [self setAction:@selector(openQS:)];
    [self setTitle:@"QS"];
	
	[[self view] setImage:[NSImage imageNamed:@"QuicksilverMenuNormal"]];
	[[self view] setAlternateImage:[NSImage imageNamed:@"QuicksilverMenuPressed"]];
	
 //   int i=0;
    
 //   menu = [[NSMenu alloc] initWithTitle:@"Silver"];
    
   // menuItem = (NSMenuItem *)[menu insertItemWithTitle:@"Launch QS" action:@selector(openQS:) keyEquivalent:@"" atIndex:i++];
    //[menuItem setTarget:self];
    
    //[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object: nil];
    //[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(appLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object: nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidInitialize:) name:NSConnectionDidInitializeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidDie:) name:NSConnectionDidDieNotification object:nil];
    
   // [self setMenu:[self gmenu]];
	
	
    return self;
    
} // initWithBundle

- (void)appLaunched:(NSNotification *)notif{
    NSString *terminatedApp=[[notif userInfo] objectForKey:@"NSApplicationName"];
    if ([terminatedApp isEqualToString:@"Quicksilver"]){
        [self setLength:0];
        qsRunning=YES;
    }
}
- (void)appTerminated:(NSNotification *)notif{
    NSString *terminatedApp=[[notif userInfo] objectForKey:@"NSApplicationName"];
    if ([terminatedApp isEqualToString:@"Quicksilver"]){
        [self setLength:22];
        
        qsRunning=NO;
    }
    
}
-(void)restartSystemUIServer{
    [[NSUserDefaults standardUserDefaults]synchronize];
    kill([[NSProcessInfo processInfo] processIdentifier],SIGKILL);
}


- (void)dealloc {
	[super dealloc];
}

-(void)openQS:(id)sender{
	[[NSWorkspace sharedWorkspace]launchApplication:@"Quicksilver"];
}


- (NSConnection *)connection { 
	if (!connection){
		[self setConnection:[NSConnection connectionWithRegisteredName:@"QuicksilverControllerConnection" host:nil]];

		id proxy=[[connection rootProxy]retain];
		if (proxy){
			[proxy setProtocolForProxy:@protocol(QSController)];
		}else{
			QSLog(@"Unable to connect to Quicksilver");
		}  
	}	return connection;
}

- (void)setConnection:(NSConnection *)aConnection
{
    [connection release];
    connection = [aConnection retain];
	[connection setDelegate:self];
	
}


- (void)connectionDidInitialize:(NSNotification*)notif{
	// if (VERBOSE) 
	//	if ([notif object]==connection)
	QSLog(@"Connection Initialized: %d",[notif object]);
}
- (void)connectionDidDie:(NSNotification*)notif{
	// if (VERBOSE) 
	
	if ([notif object]==connection){
		
		QSLog(@"Connection Died: %d",[notif object]);
		[self setConnection:nil];
	}
}

//- (NSMenu *)statusMenu{
//	return [self menu];
//}
- (NSMenu *)menu {
	//    return nil;
	//if (!remoteMenu){
	QSLog(@"getMenu");
	remoteMenu=[[self qsController] statusMenuWithQuit];
	QSLog([remoteMenu title]);
	//}
	
	//	id image=[[self qsController]daedalusImage];
	//[[self qsController]daedalusImage];
	QSLog(@"menu %@",menu);
	//		
	if (remoteMenu)
	return remoteMenu;

	//   if (qsRunning) return nil;
    return menu;
}

- (NSDistantObject <QSController> *)qsController {
	return (NSDistantObject <QSController> *)[[self connection]rootProxy];}


@end
