/*
 *  QSApp.h
 *  Crucible
 *
 *  Created by Etienne on 30/12/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

@interface NSObject (QSApp)
- (BOOL) completedLaunch;
- (NSResponder *) globalKeyEquivalentTarget;
- (void) setGlobalKeyEquivalentTarget:(NSResponder *)value;
- (void) addEventDelegate:(id)eDelegate;
- (void) removeEventDelegate:(id)eDelegate;
@end