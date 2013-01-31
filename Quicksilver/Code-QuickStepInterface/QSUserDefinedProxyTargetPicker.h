//
//  QSUserDefinedProxyTargetPicker.h
//  Quicksilver
//
//  Created by Rob McBroom on 2012/12/20.
//
//

#import <QSInterface/QSInterface.h>
@class QSUserDefinedProxySource;

@interface QSUserDefinedProxyTargetPicker : QSInterfaceController
{
    QSObject *representedObject;
    QSUserDefinedProxySource *entrySource;
}
@property (assign) QSObject *representedObject;
@property (assign) QSUserDefinedProxySource *entrySource;

@end
