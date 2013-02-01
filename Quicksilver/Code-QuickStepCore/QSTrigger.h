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
	QSCommand *command;
	NSMutableArray *children;
    BOOL activated;
}
+ (id)triggerWithDictionary:(NSDictionary *)info;
- (id)initWithDictionary:(NSDictionary *)dict;

- (QSCommand *)command;
- (void)setCommand:(QSCommand*)newCommand;

// Naming methods
- (NSString *)name;
- (BOOL)hasCustomName;
- (void)setName:(NSString *)name;

- (NSString *)identifier;

- (BOOL)isPreset;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)enabled;
- (void)setEnabledDoNotNotify:(BOOL)enabled;
- (id)manager;
- (BOOL)usesPresetCommand;
- (id)objectForKey:(NSString *)key;
- (NSDictionary *)dictionaryRepresentation;
- (void)reactivate;
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)setType:(NSString *)type;
- (NSString *)path;
- (NSString *)type;
- (NSString *)parentID;
- (QSTrigger *)parent;
- (BOOL)activated;
- (void)setActivated: (BOOL)flag;
- (void)initializeTrigger;
- (BOOL)isGroup;
- (NSString *)triggerDescription;
- (NSString *)triggerSet;
- (NSMutableDictionary *)info;
- (BOOL)execute;
@end
