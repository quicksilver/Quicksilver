//
//  QSSeparatorObject.h
//  Quicksilver
//
//  Created by Alcor on Fri Jun 11 2004.

//

#import <Foundation/Foundation.h>
#import "QSObject.h"

@interface QSSeparatorObject : QSBasicObject{
	NSString *name;	
}
+(id)separator;
+(id)separatorWithName:(NSString *)newName;
@end
