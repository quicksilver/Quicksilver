//
//  QSDirectoryParser.h
//  Quicksilver
//
//  Created by Alcor on 4/6/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>



#import <QSCore/QSParser.h>
@interface QSDirectoryParser : QSParser

- (NSArray *)objectsFromPath:(NSString *)path depth:(NSInteger)depth types:(NSArray *)types excludeTypes:(NSArray *)excludes descend:(BOOL)descendIntoBundles;
@end

