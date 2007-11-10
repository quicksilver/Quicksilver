//
//  QSMiscFunctions.m
//  Quicksilver
//
//  Created by Alcor on 7/16/04.

//

#import "QSMiscFunctions.h"


NSString *formattedContactName(NSString *firstName,NSString *lastName,NSString *middleName,NSString *prefix, NSString *suffix){
	BOOL lastNameFirst=NO; //[[ABAddressBook sharedAddressBook]defaultNameOrdering]==kABLastNameFirst;
	if (lastName || firstName){
		NSMutableArray *nameArray=[NSMutableArray arrayWithCapacity:5];
		if (prefix) [nameArray addObject:prefix];
		if (firstName) [nameArray addObject:firstName];
		if (middleName) [nameArray addObject:middleName];
		if (lastName){
			if (lastNameFirst)
				[nameArray insertObject:[NSString stringWithFormat:([nameArray count]?@"%@,":@"%@"),lastName] atIndex:0];
			else
				if (lastName) [nameArray addObject:lastName];
		}
		if (suffix) [nameArray addObject:suffix];
		return [nameArray componentsJoinedByString:@" "];
	}
	return nil;
}
