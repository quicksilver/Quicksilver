//
//  QSTrigger.h
//  Quicksilver
//
//  Created by Alcor on 6/19/05.
//  Copyright 2005 Blacktree, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSCommand.h"


@interface QSTrigger : NSObject {
	NSMutableDictionary *info;
	//QSCommand *command;
	NSMutableArray *children;
	BOOL activated;
}
+ (id)triggerWithInfo:(NSDictionary *)info;
- (QSCommand *)command;
- (id)initWithInfo:(NSDictionary *)dict;
- (BOOL)isPreset;
- (BOOL)enabled;
-(void)setEnabled:(BOOL)enabled;
-(void)disable;
- (id)manager;
- (BOOL)usesPresetCommand;
- (id)objectForKey:(NSString *)key;
- (NSDictionary *)dictionaryRepresentation;
-(void)reactivate;
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)setType:(NSString *)type;
- (NSArray *)path;
- (NSString *)type;
-(NSString *)parentID;
- (NSArray *)parent;
- (BOOL) activated;
- (void) setActivated: (BOOL) flag;


@end
