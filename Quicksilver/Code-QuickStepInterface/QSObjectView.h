

#import <AppKit/AppKit.h>

#import <QSCore/QSObject.h>

@class QSInterfaceController;

typedef enum {
	QSRejectDropMode = 0, // Ignores Drops
	QSSelectDropMode = 1, // Selects Dropped objects
	QSActionDropMode = 2, // Can perform actions, but not change selection
	QSFullDropMode = 3 // Actions as well as change selection
} QSObjectDropMode;


@interface QSObjectView : NSControl <NSDraggingSource> {
	NSString *searchString;
	BOOL dragImageDraw;
	BOOL dragAcceptDraw;

	BOOL performingDrag;
	NSDictionary *nameAttributes;
	NSDictionary *detailAttributes, *liteDetailAttributes;

	NSTimer *iconLoadTimer;


	QSObjectDropMode dropMode;

	QSObject *draggedObject;
	NSString *dragAction;
	NSDragOperation lastDragMask;

	BOOL initiatesDrags;
	BOOL shouldSpring;
	NSImage *draggedImage;
	
	QSObject *previousObjectValue;
}
- (QSObject *)draggedObject;
- (void)setDraggedObject:(QSObject *)newDraggedObject;

- (NSString *)searchString;
- (void)setSearchString:(NSString *)newSearchString;

- (id)objectValue;
- (void)setObjectValue:(QSBasicObject *)newObject;

/**
 Identical to setObjectValue: in this class. See the interface for
 QSCollectingSearchObjectView, where this does something useful.
 @param newObject the object to select
 **/
- (void)redisplayObjectValue:(QSObject *)newObject;

- (QSObject *)previousObjectValue;
- (void)setPreviousObjectValue:(QSObject *)aValue;

- (QSObjectDropMode) dropMode;
- (void)setDropMode:(QSObjectDropMode)aDropMode;

- (BOOL)acceptsDrags;

- (BOOL)initiatesDrags;
- (void)setInitiatesDrags:(BOOL)flag;
- (NSString *)dragAction;
- (void)setDragAction:(NSString *)aDragAction;

- (QSInterfaceController *)controller;
- (NSSize)cellSize;
- (void)mouseClicked:(NSEvent *)theEvent;

- (void)delete:(id)sender;
@end
