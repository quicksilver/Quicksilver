//
//  QSSyncManager.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 1/2/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSSyncManager.h"

#import "QSTriggerCenter.h"
#define clientID @"com.blacktree.QuicksilverSync"
@implementation QSSyncManager

mSHARED_INSTANCE_CLASS_METHOD
- (void)setup{
	if ([[ISyncManager sharedManager] isEnabled] == NO) return;
	
	
	[self registerSchema];	
	ISyncClient *client=[self getSyncClient];
	[client setShouldSynchronize:YES 
			   withClientsOfType:ISyncClientTypeServer];
	[client setSyncAlertHandler:self selector:
		@selector(client:mightWantToSyncEntityNames:)];
    
	//	[[ISyncManager sharedManager] snapshotOfRecordsInTruthWithEntityNames:[NSArray arrayWithObject:@"com.blacktree.QuicksilverSync.trigger"] usingIdentifiersForClient:client]		;	
	QSLog(@"client %@",client);
	
}
- (void)client:(ISyncClient *)client mightWantToSyncEntityNames:(NSArray *)entityNames{
	QSLog(@"sync %@",client);
	//ISyncSession *session = 
	//        [ISyncSession beginSessionWithClient:client
	//								 entityNames:
	//								  beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
	[ISyncSession beginSessionInBackgroundWithClient:client entityNames:entityNames target:self selector:@selector(client:beginSession:)];
}

-(void)client:(ISyncClient *)client beginSession:(ISyncSession *)session{
	NSArray *entityNames=[NSArray arrayWithObject:@"com.blacktree.QuicksilverSync.trigger"];
	[session clientWantsToPushAllRecordsForEntityNames:entityNames];
	
	if ([session shouldPushAllRecordsForEntityName:@"com.blacktree.QuicksilverSync.trigger"]){
		foreach(trigger,[[QSTriggerCenter sharedInstance]triggers]){
			NSDictionary *record=[NSDictionary dictionaryWithObjectsAndKeys:
				@"com.blacktree.QuicksilverSync.trigger",ISyncRecordEntityNameKey,
				[trigger info],@"content",nil];
			[session pushChangesFromRecord:record withIdentifier:[trigger identifier]];
			QSLog(@"snap %@",[[session snapshotOfRecordsInTruth]recordsWithIdentifiers:[NSArray arrayWithObject:[trigger identifier]]]);
		}
	}
	NSString *entityName;
	NSEnumerator *entityEnumerator = [entityNames objectEnumerator];
	NSMutableArray *filteredEntityNames = [NSMutableArray array];
	while (entityName = [entityEnumerator nextObject]){
		if ([session shouldPullChangesForEntityName:entityName])
			[filteredEntityNames addObject:entityName];
		if ([session shouldReplaceAllRecordsOnClientForEntityName:entityName]) {
			QSLog(@"should remove");
		}
		
	}
	
	
	QSLog(@"filtered %@",filteredEntityNames);
	
	if ([session prepareToPullChangesForEntityNames:filteredEntityNames beforeDate:[NSDate distantFuture]]){
		QSLog(@"prepared");
		NSEnumerator *enumerator=[session changeEnumeratorForEntityNames:filteredEntityNames];
		ISyncChange *change;
		while(change=[enumerator nextObject]){
			NSString *recordID=[change recordIdentifier];
			NSDictionary *record=[change record] ;
			NSString *identifier=[record objectForKey:kItemID];
			QSTrigger *trigger=[[QSTriggerCenter sharedInstance]triggerWithID:identifier];
			
			QSLog(@"pull for trigger %@ %@ %@",trigger, identifier,record);
			[session clientAcceptedChangesForRecordWithIdentifier:recordID formattedRecord:record newRecordIdentifier:nil];
		}
		
		
	}else{
		QSLog(@"shouldn't plul");	
	}
	
	QSLog(@"finish");
	
	[session finishSyncing];
	
}
- (void)registerSchema{
	
	NSString *schemaPath=[[NSBundle mainBundle]pathForResource:@"QuicksilverSync" ofType:@"syncschema"];
	BOOL status=[[ISyncManager sharedManager] registerSchemaWithBundlePath:schemaPath];
	QSLog(@"path %@ %d",schemaPath,status);
	
	
}

// Returns a sync client for this application
- (ISyncClient *)getSyncClient {
    // Get an existing client
    ISyncClient *client = [[ISyncManager sharedManager] clientWithIdentifier:clientID];
    if (client != nil) {
        return client;
    }
	
    client = [[ISyncManager sharedManager] registerClientWithIdentifier:clientID
													descriptionFilePath:[[NSBundle mainBundle] pathForResource:@"ClientDescription" ofType:@"plist"]];
	
    return client;
}

@end
