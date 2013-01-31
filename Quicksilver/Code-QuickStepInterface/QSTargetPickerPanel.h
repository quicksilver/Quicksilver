//
//  QSTargetPickerPanel.h
//  Quicksilver
//
//  Created by Patrick Robertson on 20/01/2013.
//
//

#import <Cocoa/Cocoa.h>

@interface QSTargetPickerPanel : QSBorderlessWindow {
    IBOutlet QSSearchObjectView *searchObjView;
}


@property (readonly) QSSearchObjectView *searchObjView;
@end
