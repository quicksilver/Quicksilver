//
//  QSUserDefinedProxyTargetPicker.h
//  Quicksilver
//
//  Created by Rob McBroom on 2012/12/20.
//
//

#import <QSInterface/QSInterface.h>

#import "QSUserDefinedProxySource.h"

@interface QSUserDefinedProxyTargetPicker : QSInterfaceController
{
    __weak QSObject *representedObject;
    __weak QSUserDefinedProxySource *entrySource;
}
@property (weak) QSObject *representedObject;
@property (weak) QSUserDefinedProxySource *entrySource;

@end
