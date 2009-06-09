/*
 Copyright 2007 Blacktree, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "QSActionHandler.h"

@implementation QSActionHandler
// Object Handler Methods

- (NSString *)identifierForObject:(id <QSObject>)object {
	return [object objectForType:QSActionType];
}

- (NSString *)detailsOfObject:(QSObject *)object {
	NSString *newDetails = [[(QSAction *)object bundle] safeLocalizedStringForKey:[object identifier] value:@"missing" table:@"QSAction-description"];
    
	if ([newDetails isEqualToString:@"missing"])
		newDetails = nil;
    
	if (!newDetails)
		newDetails = [[(QSAction *)object actionDict] objectForKey:@"description"];
	
	return newDetails;
}

- (void)setQuickIconForObject:(QSObject *)object {
    [object setIcon:[NSImage imageNamed:@"defaultAction"]];
}

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped {
	return NO;
}

- (BOOL)loadIconForObject:(QSObject *)object {
	NSImage *icon = nil;
	NSString *name = [[(QSAction *)object actionDict] objectForKey:@"icon"];
	if (!icon)
		icon = [QSRez imageWithExactName:[object identifier]];
        
	if (!icon && name)
		icon = [QSResourceManager imageNamed:name inBundle:[object bundle]];
	
	if (icon)
		[object setIcon:icon];
    
	return NO;
}

@end
