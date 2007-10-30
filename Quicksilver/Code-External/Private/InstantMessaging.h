@class BuddyPicture;
@class AddressCard;
@class IMService;

@interface People:NSObject
{
    NSMutableArray *_people;
    int _order;
    int _order2;
    char _dirty;
    int _coalesceCount;
    Class _personClass;
    char _compareEffectiveStatus;
}

- init;
- (void)dealloc;
- (void)setPersonClass:(Class)fp8;
- (void)_checkPerson:fp8;
- (char)dirty;
- (void)setDirty:(char)fp8;
- (void)saveChanges;
- (int)count;
- (int)indexOfPerson:fp8;
- (char)containsPerson:fp8;
- personAtIndex:(int)fp8;
- personWithEmail:fp8;
- people;
- objectEnumerator;
- addressCardWithUID:fp8;
- (void)_countChanged;
- (void)postNotificationNamed:fp8 person:fp12;
- (void)addedPerson:fp8;
- (void)_addedPeople:fp8;
- (void)removedPerson:fp8;
- (void)beginCoalescedChanges;
- (void)endCoalescedChanges;
- (char)coalescingChanges;
- (char)addPerson:fp8;
- (char)removePerson:fp8;
- (void)removePersonAtIndex:(int)fp8;
- (char)removePeopleFromArray:fp8;
- (char)addPeopleFromArray:fp8 skipMe:(char)fp12;
- (char)addPeopleFromArray:fp8;
- (void)addPeopleFromArray:fp8 atIndex:(int)fp12;
- (int)sortOrder;
- (int)secondarySortOrder;
- (void)setSortOrder:(int)fp8;
- (void)setSortOrder:(int)fp8 secondary:(int)fp12;
- (unsigned long)_sortContext;
- (void)_resort;

@end

@interface AddressBookPeople:People
{
    int _transactionLevel;
    NSMutableDictionary *_adding;
    NSMutableDictionary *_removing;
}

+ (char)initBuddyList;
+ (void)loadBuddyList;
+ buddies;
- init;
- (void)setSortOrder:(int)fp8 secondary:(int)fp12;
- (void)person:fp8 buddyStatusChanged:(char)fp12;
- (void)_doAdd:fp8 toDict:fp12;
- (char)_changeBuddyList:fp8 groups:fp12 adding:(char)fp16;
- (char)addPeople:fp8 toGroups:fp12;
- (char)removePeople:fp8 fromGroups:fp12;
- (char)addPerson:fp8 toGroups:fp12;
- (char)removePerson:fp8 fromGroups:fp12;
- (char)changeAddressCard:fp8 toHavePresentities:fp12 inGroups:fp16;

@end


@interface People(Actions)
+ bestPresentitiesForPeople:fp8;
+ (char)allPeopleOnline:fp8;
+ (char)allPeopleOffline:fp8;
+ (char)allPeopleCanReceiveIMs:fp8;
+ (char)allPeopleCanReceiveDirectIMs:fp8;
+ (char)allPeople:fp8 haveCapability:(unsigned int)fp12;
+ (char)allPeopleCanReceiveFiles:fp8;
+ (char)allPeopleAreSharingFiles:fp8;
+ (char)allPeopleCanChat:fp8;
+ (char)allPeopleHaveEMailAddresses:fp8;
+ (char)personCanVC:fp8;
+ (char)personCanTwoWayVC:fp8;
+ (char)personCanAudioChat:fp8;
+ (char)personCanTwoWayAudioChat:fp8;
+ sharedTuneURLOfPresentity:fp8;
+ (char)personIsSharingTunes:fp8;
+ (char)validateMenuItem:fp8 forPeople:fp12;
+ (char)doDefaultActionForPeople:fp8;
+ (char)_sendMessageToPeople:fp8 style:(int)fp12;
+ (char)sendMessageToPeople:fp8;
+ (char)startChatWithPeople:fp8;
+ (char)startVCWithSelectedPerson:fp8;
+ (char)startAudioChatWithSelectedPerson:fp8;
+ (char)sendDirectMessageToPeople:fp8;
+ (char)contactPerson:fp8;
+ (char)sendFileToPeople:fp8 inPeopleController:fp12;
+ (char)browseSharedFilesOfPeople:fp8;
+ (char)composeEMailToPeople:fp8;
+ (char)openMailtoURLWithAddresses:fp8;
+ (char)playSharedTuneOfPerson:fp8 inPeopleController:fp12;
+ (void)setDesiredChatFrame:(struct _NSRect)fp8;
+ (struct _NSRect)desiredChatFrame;
+ (void)retitleAddBuddyItem:fp8 forPresentity:fp12;
@end


@interface Person:NSObject <NSCopying>
{
    BuddyPicture *_picture;
    int _status;
    NSString *_statusMsg;
    NSAttributedString *_attributedStatusMessage;
    NSDate *_whenStatusChanged;
    int _prevStatus;
    NSString *_prevStatusMsg;
    NSColor *_balloonColor;
    int _animating:1;
    int _customPictureChecked:1;
}

+ (void)_loadStatusImages;
+ (void)_statusImagesChanged:fp8;
+ imageNameForStatus:(int)fp8;
+ imageForStatus:(int)fp8;
+ nameOfStatus:(int)fp8;
+ (char)usesAlternateStatusImages;
+ (void)setUsesAlternateStatusImages:(char)fp8;
+ cannedColors;
+ attributedStatusMessageForString:fp8;
+ (double)lengthOfAnimation;
- initWithStatus:(int)fp8 message:fp12;
- init;
- (void)dealloc;
- (void)setPersonStatus:(int)fp8;
- (void)_postNotificationName:fp8;
- copyWithZone:(struct _NSZone *)fp8;
- owner;
- asPresentity;
- asAddressCard;
- ownerOrSelf;
- promoteToAddressCard;
- presentities;
- bestPresentity;
- bestPresentityForService:fp8;
- (char)hasName;
- name;
- firstName;
- lastName;
- email;
- nameAndEmail;
- balloonColor;
- (void)setBalloonColor:fp8;
- (unsigned int)capabilities;
- (char)hasCapability:(unsigned int)fp8;
- (char)isBuddy;
- groups;
- (int)status;
- nameOfStatus;
- (int)previousStatus;
- (int)effectiveStatus;
- statusMessage;
- attributedStatusMessage;
- previousStatusMessage;
- (double)idleTime;
- (char)justLoggedIn;
- (void)_clearAttributedStatusMessageCache;
- (void)clearAttributedStatusMessageCache;
- (void)_setStatus:(int)fp8 message:fp12;
- (double)timeSinceStatusChanged;
- (char)isAnimating;
- tooltipString;
- (float)transitionPhase:(float)fp8;
- (float)transitionAlphaTo:(float)fp8 from:(float)fp12 throbs:(int)fp16;
- customPicture;
- (char)_customPictureChecked;
- _createCustomPicture;
- (void)_forgetCustomPicture;
- genericPicture;
- picture;
- image;
- (char)hasPicture;
- (void)setPicture:fp8;
- (void)_setPicture:fp8;
- (void)setPictureFromImage:fp8;
- (void)drawNameIn:(struct _NSRect)fp8 flipped:(char)fp24;
- smallStatusIcon;
- (int)compareFirstNames:fp8;
- (int)compareLastNames:fp8;
- (int)compareStatusThenFirstNames:fp8;
- (int)compareStatusThenLastNames:fp8;

@end


@interface Presentity:Person <NSCoding>
{
    IMService *_service;
    NSString *_id;
    NSString *_firstName;
    NSString *_lastName;
    NSString *_email;
    NSDictionary *_otherServiceIDs;
    unsigned int _capabilities;
    char _isBuddy;
    AddressCard *_owner;
    NSMutableArray *_altOwners;
    BuddyPicture *_customPicture;
    NSDate *_idleSince;
    NSDictionary *_extraProps;
    NSSet *_groups;
}

+ presentitiesForABPerson:fp8;
- initWithService:fp8 ID:fp12;
- (void)release;
- (void)dealloc;
- initWithCoder:fp8;
- (void)encodeWithCoder:fp8;
- (char)isMyLogin;
- (char)justLoggedIn;
- description;
- (char)isBuddy;
- (void)setIsBuddy:(char)fp8;
- asPresentity;
- presentities;
- bestPresentity;
- bestPresentityForService:fp8;
- (void)_setOwner:fp8;
- (void)addOwner:fp8;
- (void)removeOwner:fp8;
- owner;
- ownerNotMe;
- owners;
- (void)makeOwnersPerformSelector:(SEL)fp8 withObject:fp12;
- service;
- (char)hasName;
- name;
- firstName;
- lastName;
- (void)setFirstName:fp8 lastName:fp12;
- email;
- (void)setEmail:fp8;
- ID;
- nameAndID;
- (void)setOtherServiceIDs:fp8;
- otherServiceIDs;
- presentityForOtherService:fp8;
- (char)matchesPresentity:fp8;
- promoteToAddressCard;
- (int)compareIDs:fp8;
- tooltipString;
- balloonColor;
- groups;
- (void)setGroups:fp8;
- (void)clearAttributedStatusMessageCache;
- extraProperties;
- (void)requestValueOfProperty:fp8;
- (char)setValue:fp8 ofExtraProperty:fp12;
- (void)setExtraProperties:fp8;
- location;
- IDWithoutLocation;
- presentityWithoutLocation;
- existingPresentityWithoutLocation;
- dependentPresentities;
- (char)isDependentOnPresentity:fp8;
- (unsigned int)capabilities;
- (void)setCapabilities:(unsigned int)fp8;
- (void)statusChanged:(int)fp8 message:fp12;
- (void)statusMessageChanged:fp8;
- (void)statusChanged:(int)fp8;
- (void)requestStatusMessage;
- nameOfStatus;
- (double)idleTime;
- (void)setIdleSince:fp8;
- (void)_postNotificationName:fp8;
- (void)_ownerInfoChanged:fp8;
- (void)_ownerPictureChanged:fp8;
- picture;
- genericPicture;
- (void)setCustomPictureData:fp8;
- _createCustomPicture;
- customPictureRegardlessOfBlocking;
- (void)_ownerPictureBlockingChanged;
- nowPlayingString;
- (char)_isMyIDInList:fp8;
- (char)isBlocked;
- (void)setBlocked:(char)fp8;

@end



@interface AddressCard:Person <ABImageClient>
{
    ABPerson *_abPerson;
    NSMutableArray *_presentities;
    Presentity *_bestPresentity;
    NSString *_abFirstName;
    NSString *_abLastName;
    NSString *_abFullName;
    int _pictureLoadTag;
    int _dirty:1;
}

- initWithABPerson:fp8 addPresentities:(char)fp12 registerUID:(char)fp16;
- initWithABPerson:fp8;
- initWithPresentity:fp8 name:fp12;
- initWithPresentity:fp8;
- (void)dealloc;
- (void)_computeStatus;
- description;
- owner;
- asAddressCard;
- ownerOrSelf;
- promoteToAddressCard;
- abPerson;
- (char)hasName;
- name;
- firstName;
- lastName;
- (void)_setFirstName:fp8 lastName:fp12;
- (void)setFirstName:fp8 lastName:fp12;
- email;
- (void)setEmails:fp8;
- location;
- (unsigned int)capabilities;
- (char)isBuddy;
- (char)justLoggedIn;
- (double)idleTime;
- groups;
- (void)clearAttributedStatusMessageCache;
- presentities;
- presentitiesForService:fp8;
- bestPresentity;
- bestPresentityForService:fp8;
- bestAVPresentityVideo:(char)fp8;
- (void)_presentityStatusChanged:fp8;
- (void)_presentity:fp8 buddyStatusChanged:(char)fp12;
- (void)_presentityInfoChanged:fp8;
- (void)_presentityGroupsChanged:fp8;
- (void)_presentityPictureChanged:fp8;
- (void)_notifyVCardPresentitiesChanged;
- (char)_addPresentity:fp8 andUpdateABPerson:(char)fp12;
- (char)_removePresentity:fp8 andUpdateABPerson:(char)fp12;
- (void)addPresentity:fp8 andUpdateABPerson:(char)fp12;
- (void)removePresentity:fp8 andUpdateABPerson:(char)fp12;
- (char)_setPresentities:fp8 andUpdateABPerson:(char)fp12;
- (void)setPresentities:fp8 andUpdateABPerson:(char)fp12;
- tooltipString;
- picture;
- (char)hasPicture;
- _createCustomPicture;
- (void)consumeImageData:fp8 forTag:(int)fp12;
- (void)setPicture:fp8;
- (char)blockingPresentityPictures;
- (void)setBlockingPresentityPictures:(char)fp8;

@end
@interface AddressCard(AddressBook)
+ existingAddressCardWithUID:fp8;
+ addressCardWithUID:fp8;
+ existingAddressCardWithABPerson:fp8;
+ addressCardWithABPerson:fp8;
+ (char)initializeGMe;
+ (char)isGMeInitialized;
+ (void)_initAddressBookSyncing;
+ (void)_addressBookChanged:fp8;
- (void)_registerByUID;
- (void)_unregister;
- (char)dirty;
- (void)setDirty:(char)fp8;
- (void)saveChanges;
- (void)addToAddressBook;
- (void)removeFromAddressBook;
- (void)_abPersonChanged;
- (void)_setABPerson:fp8;
- (void)openInAddressBookAndEdit:(char)fp8;
@end


@interface MeCard:AddressCard
{
}

- (void)setFirstName:fp8 lastName:fp12;
- _createCustomPicture;
- (void)setPicture:fp8;
- (void)myPictureChanged;

@end



 






@interface Chat:NSObject
{
    IMService *_service;
    int _style;
    char _hasUnread;
    char _secureXfer;
    NSString *_subject;
    NSMutableArray *_messages;
    NSMutableArray *_allPeople;
    NSDocument *_chatDoc;
    NSString *_transcript;
    NSString *_address;
    NSMutableDictionary *_properties;
}

+ (void)setChatListPersistence:(int)fp8;
+ chatList;
+ (void)setViewer:fp8;
+ viewer;
- initWithService:fp8 style:(int)fp12;
- (void)dealloc;
- (void)addToChatList;
- (void)_removeFromChatList;
- (char)isComposing;
- (char)isActive;
- (char)isChat;
- (int)style;
- styleName;
- (void)setStyle:(int)fp8;
- (void)_notifyStatusChanged;
- (char)hasUnreadMessages;
- (void)setUnreadMessages:(char)fp8;
- service;
- otherPerson;
- otherPeople;
- (char)fromMe;
- (char)isSecureXfer;
- subject;
- address;
- messages;
- (unsigned int)realMessageCount;
- allPeople;
- peopleDeciding;
- dateCreated;
- dateModified;
- description;
- valueOfProperty:fp8;
- (void)setValue:fp8 ofProperty:fp12;
- chatDoc;
- (void)setChatDoc:fp8;
- (char)isOpenInWindow;
- (void)notifyOpenedByChatController:fp8;
- (void)display;
- (void)removePermanently;
- dataRepresentation;
- (char)writeToFile:fp8 ofType:fp12;

@end








@protocol FZServiceListener <NSObject>
- (oneway void)service:fp8 handleVCOOB:fp12 action:(unsigned long)fp16 param:(unsigned long)fp20;
- (oneway void)service:fp8 counterProposalFrom:fp12 properties:fp16;
- (oneway void)service:fp8 cancelVCInviteFrom:fp12;
- (oneway void)service:fp8 responseToVCRequest:fp12 properties:fp16;
- (oneway void)service:fp8 invitedToVC:fp12 properties:fp16;
- (oneway void)service:fp8 buddy:fp12 shareDirectory:fp16 listing:fp20;
- (oneway void)service:fp8 shareUploadStarted:fp12;
- (oneway void)service:fp8 requestOutgoingFileXfer:fp12;
- (oneway void)service:fp8 requestIncomingFileXfer:fp12;
- (oneway void)service:fp8 chat:fp12 member:fp16 statusChanged:(int)fp20;
- (oneway void)service:fp8 chat:fp12 showError:fp16;
- (oneway void)service:fp8 chat:fp12 messageReceived:fp16;
- (oneway void)service:fp8 chat:fp12 statusChanged:(int)fp16;
- (oneway void)service:fp8 directIMRequestFrom:fp12 invitation:fp16;
- (oneway void)service:fp8 invitedToChat:fp12 isChatRoom:(char)fp16 invitation:fp20;
- (oneway void)service:fp8 buddyGroupsChanged:fp12;
- (oneway void)service:fp8 youAreDesignatedNotifier:(char)fp12;
- (oneway void)service:fp8 buddyPictureChanged:fp12 imageData:fp16;
- (oneway void)shutdownAV;
- (oneway void)service:fp8 providePiggyback:(char)fp12;
- (oneway void)service:fp8 buddyPropertiesChanged:fp12;
- (oneway void)service:fp8 capabilitiesChanged:(unsigned int)fp12;
- (oneway void)service:fp8 loginStatusChanged:(int)fp12 message:fp16 reason:(int)fp20;
- (oneway void)service:fp8 defaultsChanged:fp12;
@end


@interface IMService:NSObject <FZServiceListener>
{
    Presentity *_loginPresentity;
    NSString *_password;
    int _loginStatus;
    NSDate *_timeOfLogin;
    NSMutableDictionary *_presentities;
    id _remoteService;
    NSString *_name;
    NSString *_shortName;
    NSString *_internalName;
    NSString *_loginID;
    NSDictionary *_serviceDefaults;
    NSString *_addressBookProperty;
    NSArray *_emailDomains;
    unsigned int _capabilities;
    int _acceptableFormats;
    NSMutableDictionary *_chats;
    NSMutableSet *_specialPresentities;
    char _isDesignatedNotifier;
    char _iconChecked;
    char _defaultBuddyIconChecked;
    NSImage *_icon;
    NSArray *_defaultBuddyIcons;
    NSDictionary *_IDToCardMap;
    int _IDSensitivity;
    char _needToFlushBuddyList;
    char _syncedWithRemoteBuddyList;
    char _hasActiveConference;
    NSMutableArray *_deferredInvitations;
    NSArray *_buddyGroups;
    NSPanel *_errorPanel;
    NSTextField *_errorTimestampField;
    NSTextField *_errorTitleField;
    NSTextField *_errorMessageField;
    NSImageView *_errorIcon;
}

+ (char)userAccountHasBeenSetup;
+ mostLoggedInService;
+ (char)autoLoginEnabled;
+ (void)setAutoLoginEnabled:(char)fp8;
+ (void)loginAllAvailableServices;
+ (void)loginAllServices;
+ (void)logoutAllServices;
+ (void)disconnectAllServices;
+ serviceWithInternalName:fp8;
+ (void)initialize;
+ presentityWithEmailID:fp8;
+ nameOfLoginStatus:(int)fp8;
+ (int)myStatus;
+ (int)_myStatus;
+ (unsigned long)myIdleTime;
+ (char)_setMyStatusMessage:fp8;
+ myStatusMessage;
+ (void)setMyStatus:(int)fp8 message:fp12;
+ (void)updateMyStatus:(int)fp8 message:fp12 idleSince:fp16;
+ (void)_handleDaemonException:fp8;
+ _daemonProxy;
+ (void)_launchOrWaitForDaemon;
+ (void)_makeConnectionAndLaunch:(char)fp8;
+ remoteDaemon;
+ (void)terminateDaemon;
+ (char)isDaemonLaunched;
+ (char)connectToDaemonWithLaunch:(char)fp8;
+ (void)disconnectFromDaemon:(char)fp8;
+ (void)preventReconnect;
+ allServices;
+ (void)setValue:fp8 ofPersistentProperty:fp12;
+ valueOfPersistentProperty:fp8;
+ (void)daemonPersistentProperty:fp8 changedTo:fp12;
+ (void)_connectionDidDie:fp8;
+ (void)connectionDidDie:fp8;
+ (void)addressBookChanged;
+ (void)setHasActiveConference:(char)fp8;
+ (void)_setInitialVCCaps:fp8;
+ (void)_Q8TimeoutTimerTriggered:fp8;
+ (void)updateQ8Dialog:fp8;
+ (void)vcMicrophoneChanged:fp8;
+ (void)vcHardwareChangedBroadcastChanges:fp8;
+ (void)vcHardwareChanged:fp8 duringLaunch:(char)fp12;
+ (void)_setServiceVCCapsCamera:(char)fp8 mic:(char)fp12 activeConference:(char)fp16;
+ _firstService;
+ (char)cameraConnected;
+ (char)microphoneConnected;
+ (char)hasActiveConference;
+ (char)cameraCapable;
+ (char)microphoneCapable;
+ (char)blockMicStatus;
+ (void)setBlockMicStatus:(char)fp8;
+ (char)blockCameraStatus;
+ (void)setBlockCameraStatus:(char)fp8;
+ (void)openNotesChanged:fp8;
+ (char)_sendStatus:fp8;
+ _myPictureData:fp8;
+ myPicture;
+ (void)setMyPicture:fp8;
+ (void)_sendGMeStatus;
+ (char)setStatus:(int)fp8 message:fp12;
+ (void)myStatusChanged:fp8;
- (void)dealloc;
- copyWithZone:(struct _NSZone *)fp8;
- (Class)presentityClass;
- existingPresentityWithID:fp8;
- presentityWithID:fp8;
- (char)emailAddressIsID:fp8;
- allPresentities;
- arrayOfAllPresentities;
- canonicalFormOfID:fp8;
- (char)equalID:fp8 andID:fp12;
- loginSettings;
- (void)setLoginSettings:fp8;
- loginID;
- (void)setLoginID:fp8;
- loginPresentity;
- (int)serviceLoginStatus;
- serviceLoginStatusMessage;
- (void)setServiceLoginStatus:(int)fp8;
- (void)setServiceLoginStatus:(int)fp8 errorMessage:fp12;
- (void)_displayDisconnectAlertWithTitle:fp8 message:fp12;
- (void)_displayDisconnectAlert:fp8 wasConnected:(char)fp12;
- (void)windowWillClose:fp8;
- (void)_nowLoggedIn;
- (void)_nowLoggedOut;
- (char)justLoggedIn;
- (int)compareNames:fp8;
- (char)hasCapability:(unsigned int)fp8;
- (char)registerNewAccount:fp8;
- createChatRoomName;
- (void)_handleDaemonException:fp8;
- _hookupWithFZService:fp8;
- initWithFZService:fp8;
- reinitWithFZService:fp8;
- (void)_displayDeferredInvitations;
- (void)_syncWithRemoteBuddies;
- (void)disconnect:(char)fp8;
- name;
- shortName;
- internalName;
- description;
- icon;
- (int)emailDomainOfID:fp8;
- defaultBuddyIconForPresentity:fp8;
- (unsigned int)capabilities;
- (void)_updateCapabilities:(unsigned int)fp8;
- (void)service:fp8 capabilitiesChanged:(unsigned int)fp12;
- (char)isDesignatedNotifier;
- (void)_refreshLoginID;
- addressBookProperty;
- emailDomains;
- _IDToCardMap;
- (void)_clearIDToCardMap;
- (void)_registerPresentity:fp8;
- (void)_unregisterPresentity:fp8;
- presentitiesForABPerson:fp8;
- (void)addPresentity:fp8 toABPerson:fp12;
- (char)removePresentity:fp8 fromABPerson:fp12;
- serviceDefaults;
- (void)writeServiceDefaults:fp8;
- (oneway void)service:fp8 defaultsChanged:fp12;
- (char)enabled;
- (void)setEnabled:(char)fp8;
- (void)_login:(char)fp8;
- (void)login;
- (void)loginIfAvailable;
- (void)logout;
- (void)service:fp8 loginStatusChanged:(int)fp12 message:fp16 reason:(int)fp20;
- (oneway void)service:fp8 providePiggyback:(char)fp12;
- (void)service:fp8 buddyPropertiesChanged:fp12;
- (oneway void)service:fp8 buddyPictureChanged:fp12 imageData:fp16;
- (char)setValue:fp8 ofExtraProperty:fp12 ofPerson:fp16;
- (void)requestProperty:fp8 ofPerson:fp12;
- (void)_connectAllPresentities;
- (void)_disconnectAllPresentities;
- specialPresentities;
- buddyGroups;
- (oneway void)service:fp8 buddyGroupsChanged:fp12;
- (char)renameGroup:fp8 to:fp12;
- (char)changeBuddyList:fp8 add:(char)fp12 groups:fp16;
- _chatWithID:fp8;
- _visibleChatToHookUpWithID:fp8;
- (void)_rememberChat:fp8;
- (void)_forgetChat:fp8;
- (void)_forgetAllChats;
- _attachInlineFiles:fp8 toAttributedString:fp12;
- _createInstantMessage:fp8;
- _createFZMessage:fp8;
- _createChatWithID:fp8 message:fp12 style:(int)fp16;
- (char)_registerChat:fp8 withMessage:fp12;
- (void)_reconnectChat:fp8 toIncomingID:fp12;
- goToChatNamed:fp8;
- (char)invitePerson:fp8 toChat:fp12 withMessage:fp16;
- (char)respond:(char)fp8 toInvitationToChat:fp12;
- (int)sendMessage:fp8 toChat:fp12;
- (char)leaveChatRoom:fp8;
- (char)setPerson:fp8 isIgnored:(char)fp12 inChat:fp16;
- (void)service:fp8 youAreDesignatedNotifier:(char)fp12;
- (oneway void)service:fp8 directIMRequestFrom:fp12 invitation:fp16;
- (oneway void)service:fp8 invitedToChat:fp12 isChatRoom:(char)fp16 invitation:fp20;
- (void)service:fp8 chat:fp12 statusChanged:(int)fp16;
- (void)service:fp8 chat:fp12 messageReceived:fp16;
- (void)service:fp8 chat:fp12 member:fp16 statusChanged:(int)fp20;
- (void)service:fp8 chat:fp12 showError:fp16;
- (char)sendFile:fp8 toPerson:fp12;
- _createIncomingFileFromFZXfer:fp8;
- (void)service:fp8 requestIncomingFileXfer:fp12;
- (void)service:fp8 requestOutgoingFileXfer:fp12;
- (char)requestShareDirectoryListing:fp8 ofBuddy:fp12;
- getSharedFile:fp8 ofBuddy:fp12;
- (void)service:fp8 shareUploadStarted:fp12;
- (void)service:fp8 buddy:fp12 shareDirectory:fp16 listing:fp20;
- (void)requestVCWithBuddy:fp8 properties:fp12;
- (void)respondToVCRequestWithBuddy:fp8 properties:fp12;
- (void)cancelVCRequestWithBuddy:fp8;
- (void)sendVCCounterProposalToBuddy:fp8 properties:fp12;
- (void)sendVCOOBToBuddy:fp8 action:(unsigned long)fp12 param:(unsigned long)fp16;
- (void)service:fp8 invitedToVC:fp12 properties:fp16;
- (void)service:fp8 cancelVCInviteFrom:fp12;
- (void)shutdownAV;
- (void)service:fp8 counterProposalFrom:fp12 properties:fp16;
- (void)service:fp8 handleVCOOB:fp12 action:(unsigned long)fp16 param:(unsigned long)fp20;
- (void)service:fp8 responseToVCRequest:fp12 properties:fp16;
- chatFromDaemonChatID:fp8;
- addNotificationFrom:fp8 type:(int)fp12 subject:fp16 when:fp20;
- (void)removeNotificationWithID:fp8;
- (char)setStatus:(int)fp8 message:fp12;
- (void)blockMessages:(char)fp8 fromID:fp12;
- (void)setBlockList:fp8;
- blockList;
- (void)setAllowList:fp8;
- allowList;
- (void)setBlockingMode:(int)fp8;
- (int)blockingMode;
- (char)blockIdleStatus;
- (void)setBlockIdleStatus:(char)fp8;
- (char)blockOtherAddresses;
- (void)setBlockOtherAddresses:(char)fp8;

@end

@interface IMService(IMService_GetService)
+ aimService;
+ subnetService;
@end


/*











@protocol Node <NSObject>
- (void)finished;
- (void)childFinished:fp8;
- (void)addText:fp8;
- createChild:fp8;
@end



@protocol PeopleControllerDelegate
- (char)addPersonWithoutID:fp8;
- filterPersonFromPasteboard:fp8;
- (char)aboutToResort;
- (char)canRemovePeople;
- (char)canAddPeople;
- (float)alphaForStatus:(int)fp8;
- alternateStatusTextForPerson:fp8;
- (void)peopleChanged:fp8;
- (char)peopleController:fp8 pleaseCutPeople:fp12;
- (char)peopleController:fp8 pleasePastePeople:fp12;
@end


@protocol FZDaemonListener <NSObject>
- (oneway void)daemonPersistentProperty:fp8 changedTo:fp12;
- (oneway void)openNotesChanged:fp8;
- (oneway void)myStatusChanged:fp8;
@end

@protocol FileDragOutViewDelegate <NSObject>
- (void)fileDoubleClicked:fp8;
- (void)file:fp8 draggedTo:fp12 isDuplicate:(char)fp16;
@end

@protocol FZXferListener <NSObject>
- (oneway void)file:fp8 transferEndedWithError:(int)fp12;
- (oneway void)file:fp8 updateProgressTransferComplete:(int)fp12;
- (oneway void)file:fp8 updateProgressCurrentFileComplete:fp12 result:(int)fp16;
- (oneway void)file:fp8 updateProgressCurrentFile:fp12 currentFileNum:(unsigned int)fp16 totalFiles:(unsigned int)fp20 currentFileSentBytes:(unsigned int)fp24 currentFileSize:(unsigned int)fp28 totalSentBytes:(unsigned int)fp32 totalSize:(unsigned int)fp36;
@end



@protocol FileTransferDelegate <NSObject>
- (void)currentFile:fp8 currentFileSize:(unsigned int)fp12 currentSentBytes:(unsigned int)fp16 totalTransferProgress:(float)fp20 timeRemaining:fp24 message:fp28;
@end
@class IncomingFile;
@class Presentity;

@interface InstantMessage:NSObject <NSCoding>
{
    Presentity *_sender;
    NSDate *_time;
    NSAttributedString *_text;
    NSColor *_bgColor;
    IncomingFile *_file;
    int _flags;
}

+ fromMeOnService:fp8 withText:fp12 outgoingFile:fp16 flags:(int)fp20;
- initWithSender:fp8 time:fp12 text:fp16 incomingFile:fp20 flags:(int)fp24;
- initWithSender:fp8 time:fp12 string:fp16 incomingFile:fp20 flags:(int)fp24;
- initWithCoder:fp8;
- (void)encodeWithCoder:fp8;
- (void)dealloc;
- description;
- sender;
- (char)fromMe;
- time;
- text;
- (void)setText:fp8;
- displayText_showingName:(char)fp8 markIfEmpty:(char)fp12;
- backgroundColor;
- (void)setBackgroundColor:fp8;
- incomingFile;
- outgoingFile;
- (int)flags;
- (char)finished;
- (char)isEmpty;
- (char)isEmote;

@end

@class BuddyPicture;

@interface Person:NSObject <NSCopying>
{
    BuddyPicture *_picture;
    int _status;
    NSString *_statusMsg;
    NSAttributedString *_attributedStatusMessage;
    NSDate *_whenStatusChanged;
    int _prevStatus;
    NSString *_prevStatusMsg;
    NSColor *_balloonColor;
    int _animating:1;
    int _customPictureChecked:1;
}

+ (void)_loadStatusImages;
+ (void)_statusImagesChanged:fp8;
+ imageNameForStatus:(int)fp8;
+ imageForStatus:(int)fp8;
+ nameOfStatus:(int)fp8;
+ (char)usesAlternateStatusImages;
+ (void)setUsesAlternateStatusImages:(char)fp8;
+ cannedColors;
+ attributedStatusMessageForString:fp8;
+ (double)lengthOfAnimation;
- initWithStatus:(int)fp8 message:fp12;
- init;
- (void)dealloc;
- (void)setPersonStatus:(int)fp8;
- (void)_postNotificationName:fp8;
- copyWithZone:(struct _NSZone *)fp8;
- owner;
- asPresentity;
- asAddressCard;
- ownerOrSelf;
- promoteToAddressCard;
- presentities;
- bestPresentity;
- bestPresentityForService:fp8;
- (char)hasName;
- name;
- firstName;
- lastName;
- email;
- nameAndEmail;
- balloonColor;
- (void)setBalloonColor:fp8;
- (unsigned int)capabilities;
- (char)hasCapability:(unsigned int)fp8;
- (char)isBuddy;
- groups;
- (int)status;
- nameOfStatus;
- (int)previousStatus;
- (int)effectiveStatus;
- statusMessage;
- attributedStatusMessage;
- previousStatusMessage;
- (double)idleTime;
- (char)justLoggedIn;
- (void)_clearAttributedStatusMessageCache;
- (void)clearAttributedStatusMessageCache;
- (void)_setStatus:(int)fp8 message:fp12;
- (double)timeSinceStatusChanged;
- (char)isAnimating;
- tooltipString;
- (float)transitionPhase:(float)fp8;
- (float)transitionAlphaTo:(float)fp8 from:(float)fp12 throbs:(int)fp16;
- customPicture;
- (char)_customPictureChecked;
- _createCustomPicture;
- (void)_forgetCustomPicture;
- genericPicture;
- picture;
- image;
- (char)hasPicture;
- (void)setPicture:fp8;
- (void)_setPicture:fp8;
- (void)setPictureFromImage:fp8;
- (void)drawNameIn:(struct _NSRect)fp8 flipped:(char)fp24;
- smallStatusIcon;
- (int)compareFirstNames:fp8;
- (int)compareLastNames:fp8;
- (int)compareStatusThenFirstNames:fp8;
- (int)compareStatusThenLastNames:fp8;

@end

@interface AutoSendTextField:NSTextField
{
    NSDate *_firstKey;
    NSDate *_lastKey;
    NSTimer *_timer;
    int _disableAutoSend:1;
    int _nonEmpty:1;
    int _significantChange:1;
    int _dirty:1;
}

+ (void)initialize;
- (void)prepareToRelease;
- (void)dealloc;
- (char)textChangedSinceSent;
- (void)setDirty:(char)fp8;
- (void)setAutoSend:(char)fp8;
- (void)_autoSend:(int)fp8;
- (void)_timerFired;
- (char)textView:fp8 shouldChangeTextInRange:(struct _NSRange)fp12 replacementString:fp20;
- (void)textDidChange:fp8;
- (char)performKeyEquivalent:fp8;

@end
@class IMService;

@class AnimatingTableView;

@interface PeopleController:People
{
    AnimatingTableView *_table;
    NSMenu *_contextualMenu;
    id _delegate;
    int _viewFlags;
    char _awokenFromNib;
    char _draggable;
    int _rolloverRow;
    int *_trackingRectTags;
    unsigned int _numTrackingRectTags;
    int _trackingRectTagsArraySize;
    IMService *_serviceFilter;
    NSTableColumn *_nameColumn;
    NSTableColumn *_pictureColumn;
    NSTableColumn *_cameraColumn;
    NSTimer *_animator;
    NSTimer *_idleUpdater;
    NSMutableSet *_selectedPeople;
}

+ (int)getSortOrderDefault:fp8 key:fp12 fallback:(int)fp16;
+ (char)pasteboardContainsPeople:fp8;
+ peoplePasteboardTypes;
- (void)_statusIndicatorDidChange:fp8;
- (void)_blockDragStatusDidChange:fp8;
- (void)awakeFromNib;
- init;
- (void)dealloc;
- delegate;
- (void)setDelegate:fp8;
- (void)_countChanged;
- tableView;
- (void)detachFromTableView;
- menu;
- (char)isPersonSelectedAtIndex:(int)fp8;
- selectedPeople;
- pictureColumn;
- nameColumn;
- (void)sortByTableColumn:fp8;
- (void)_highlightSortedColumn;
- (void)_makePictureColumnVisible:(char)fp8;
- serviceFilter;
- (void)setServiceFilter:fp8;
- filteredPresentityFor:fp8;
- filteredPersonFor:fp8;
- (void)setDraggable:(char)fp8;
- (float)alphaForPerson:fp8 throbs:(int)fp12;
- displayNameForPerson:fp8;
- displayStatusForPerson:fp8;
- (float)widthToFitNames;
- (int)numberOfRowsInTableView:fp8;
- tableView:fp8 objectValueForTableColumn:fp12 row:(int)fp16;
- tableView:fp8 objectValueForRow:(int)fp12;
- (void)tableView:fp8 willDisplayCell:fp12 forTableColumn:fp16 row:(int)fp20;
- (char)_mouseInVCButton:fp8 trackMouse:(char)fp12;
- (char)tableView:fp8 acceptsFirstMouse:fp12;
- (char)tableView:fp8 mouseDown:fp12;
- (char)tableView:fp8 writeRows:fp12 toPasteboard:fp16;
- (unsigned int)tableView:fp8 validateDrop:fp12 proposedRow:(int)fp16 proposedDropOperation:(int)fp20;
- _cachePasteboardData:fp8;
- (char)tableView:fp8 acceptDrop:fp12 row:(int)fp16 dropOperation:(int)fp20;
- (char)tableView:fp8 canPasteFromPasteboard:fp12;
- (char)tableView:fp8 pasteFromPasteboard:fp12;
- (char)tableView:fp8 canDeleteRows:fp12;
- (char)tableView:fp8 deleteRows:fp12;
- (void)tableView:fp8 didClickTableColumn:fp12;
- (struct _NSRect)_imageRectForRow:(int)fp8;
- (void)_removeAllTrackingRects;
- (void)_updateVCTrackingRects;
- (void)tableViewDidEndLiveResize:fp8;
- (void)mouseExited:fp8;
- (void)_mouseEntered:(int)fp8;
- (void)mouseEntered:fp8;
- (void)refreshVCTracking;
- (void)_addToolTips;
- toolTipForPerson:fp8;
- view:fp8 stringForToolTip:(int)fp12 point:(struct _NSPoint)fp16 userData:(void *)fp24;
- (void)_rememberSelection;
- (void)_restoreSelection;
- (void)redrawRow:(int)fp8;
- (void)redrawRowForPerson:fp8;
- (void)redrawAllRows;
- (void)personPictureChanged:fp8;
- (void)personInfoChanged:fp8;
- (void)_startAnimation;
- (void)stopAnimation;
- (void)animate;
- (void)_startIdleUpdater;
- (void)_updateIdleTimes;
- (void)addedPerson:fp8;
- (void)personStatusChanged:fp8;
- (void)beginCoalescedChanges;
- (void)_startTimers;
- (void)endCoalescedChanges;
- (void)_addedPeople:fp8;
- (char)addPerson:fp8;
- (char)removePerson:fp8;
- (char)removePeopleFromArray:fp8;
- (char)addPeopleFromArray:fp8;
- (void)addPeopleFromArray:fp8 atIndex:(int)fp12;
- (void)setSortOrder:(int)fp8 secondary:(int)fp12;
- (void)copyRows:fp8 toPasteboard:fp12;
- canPasteFrom:fp8;
- _personToAddFromABPerson:fp8 isOK:(char *)fp12;
- peopleFromPasteboard:fp8;
- (char)_pastePeople:fp8;
- (char)pasteFrom:fp8;
- (void)setAllowsDrop:(char)fp8;
- (void)sendMessageToSelectedPeople;
- (void)sendDirectMessageToSelectedPeople;
- (void)startChatToSelectedPeople;
- (void)sendFileToSelectedPeople;
- (void)browseSharedFilesOfSelectedPeople;
- (void)playSharedTuneOfSelectedPerson;
- (void)composeEMailToSelectedPeople;
- (void)startVCWithSelectedPerson;
- (void)startAudioChatWithSelectedPerson;
- (void)showSelectedPersonInAddressBookAndEdit:(char)fp8;
- (void)doDefaultActionToSelectedPeople;
- (void)tableView:fp8 returnKeyPressedAtRow:(int)fp12;
- (void)_updateLayout;
- (void)setHides:(int)fp8 to:(char)fp12;
- (void)toggleHides:(int)fp8;
- (char)hides:(int)fp8;

@end

@interface NSTableView(ContextualMenus)
- menuForEvent:fp8;
@end
@class Presentity;

@interface FileSender:NSObject
{
    NSPanel *_confirmPanel;
    NSTextField *_messageField;
    NSButton *_dontAskAgainBox;
    NSString *_filePath;
    Presentity *_receiver;
    NSWindow *_originatingWindow;
    struct _NSPoint _centerPointInWindow;
}

+ (void)sendFile:fp8 toPerson:fp12 atPosition:(struct _NSPoint)fp16 inWindow:fp24;
+ (void)sendFile:fp8 toPerson:fp12 inPeopleController:fp16;
- initWithFile:fp8 receiver:fp12 position:(struct _NSPoint)fp16 inWindow:fp24;
- (void)dealloc;
- (char)_isFolder;
- (void)_sendFile;
- (void)_runConfirmPanel;
- (void)start:fp8;
- (void)cancel:fp8;
- (void)_runOpenPanel;
- (void)_openPanelDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;

@end
@class ChatTextView;

@interface ChatLayoutManager:NSLayoutManager
{
    ChatTextView *_chatTextView;
}

- initWithChatTextView:fp8;
- (void)setExtraLineFragmentRect:(struct _NSRect)fp8 usedRect:(struct _NSRect)fp24 textContainer:fp40;
- (void)drawBackgroundForGlyphRange:(struct _NSRange)fp8 atPoint:(struct _NSPoint)fp16;

@end

@class ChatTextView;

@interface ChatTypesetter:NSATSTypesetter
{
    ChatTextView *_chatTextView;
}

- initWithChatTextView:fp8;
- (void)setChatTextView:fp8;
- (float)paragraphSpacingAfterCharactersInRange:(struct _NSRange)fp8 withProposedLineFragmentRect:(struct _NSRect)fp16;

@end

@class IncomingFile;
@class Chat;
@class MessageRenderer;

@interface ChatTextView:NSTextView
{
    Chat *_chat;
    MessageRenderer *_renderer;
    NSMutableArray *_messages;
    ChatTypesetter *_typesetter;
    int _viewFlags;
    char _pendingRebuildLayout;
    char _suppressAutoscroll;
    char _pinToBottomOnResize;
    IncomingFile *_fileBeingDragged;
    NSString *_fileDragDestination;
    char _fileDragIsDup;
    NSMenu *_viewMenu;
}

+ (void)initialize;
+ rendererMenuItems;
- (void)restoreDefaultBackground;
- (void)_commonInitialization;
- initWithFrame:(struct _NSRect)fp8;
- (void)awakeFromNib;
- (void)dealloc;
- chat;
- (void)setChat:fp8;
- (void)suppressAutoscroll:(char)fp8;
- messages;
- (void)setBackgroundImage:fp8;
- (char)setBackgroundImageFile:fp8;
- (float)savedScrollPosition;
- (void)restoreSavedScrollPosition:(float)fp8;
- (void)setViewFlag:(int)fp8 toValue:(char)fp12;
- (void)setViewFlags:(int)fp8;
- (char)isViewFlagOn:(int)fp8;
- (int)viewFlags;
- messageRenderer;
- (void)setMessageRenderer:fp8;
- (char)setMessageRendererClass:fp8;
- messageAtCharacterIndex:(int)fp8;
- messageAtOrAfterCharacterIndex:(int)fp8;
- (struct _NSRange)textRangeOfMessage:fp8 locationHint:(int)fp12;
- paragraphStyleOfMessage:fp8;
- (struct _NSRect)rawBoundsOfMessage:fp8 locationHint:(int)fp12;
- (struct _NSRect)rawBoundsOfMessage:fp8;
- (char)_isLayoutComplete;
- (struct _NSRect)boundsOfMessage:fp8 locationHint:(int)fp12;
- (struct _NSRect)boundsOfMessage:fp8;
- (void)_sizeImagesToFit:fp8 widthChangingBy:(float)fp12;
- (void)setFrameSize:(struct _NSSize)fp8;
- (char)_isMostRecent:(int)fp8;
- (void)_drawViewBackgroundInRect:(struct _NSRect)fp8;
- viewForPrintingWithInfo:fp8;
- (void)adjustPageHeightNew:(float *)fp8 top:(float)fp12 bottom:(float)fp16 limit:(float)fp20;
- (void)viewWillStartLiveResize;
- (void)resizeWithOldSuperviewSize:(struct _NSSize)fp8;
- (void)viewDidEndLiveResize;
- (void)defineTooltips;
- formatDate:fp8 roundInterval:(int)fp12 longFormat:(char)fp16;
- view:fp8 stringForToolTip:(int)fp12 point:(struct _NSPoint)fp16 userData:(void *)fp24;
- (void)layoutManager:fp8 didCompleteLayoutForTextContainer:fp12 atEnd:(char)fp16;
- (void)_message:fp8 saveTo:fp12;
- (void)_saveFileFromMessage:fp8 toFile:fp12 isDup:(char)fp16;
- (void)_saveFileFromMessage:fp8;
- (void)savePanelDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)_replaceSheetDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)clickedOnLink:fp8 atIndex:(unsigned int)fp12;
- (void)textView:fp8 doubleClickedOnCell:fp12 inRect:(struct _NSRect)fp16 atIndex:(unsigned int)fp32;
- (char)dragSelectionWithEvent:fp8 offset:(struct _NSSize)fp12 slideBack:(char)fp20;
- (unsigned int)draggingSourceOperationMaskForLocal:(char)fp8;
- namesOfPromisedFilesDroppedAtDestination:fp8;
- _attachmentStringForFile:fp8 inMessage:fp12;
- (struct _NSRange)addMessage:fp8 replacingRange:(struct _NSRange)fp12;
- (void)_addTimestamp:fp8;
- (int)findUnfinishedMessageFrom:fp8 returningRange:(struct _NSRange *)fp12;
- (void)offsetMessageRangesBy:(int)fp8 startingAt:(int)fp12;
- (void)_autoscrollWithAnimationSuppressed:(char)fp8;
- (void)setNeedsDisplayInRectOfMessage:fp8;
- (void)addMessage:fp8 atEnd:(char)fp12 replacingMessage:fp16 performActions:(char)fp20;
- (void)clearAllMessages;
- (void)addSampleMessage:fp8;
- (void)_reformatOutgoingMessages:(char)fp8;
- (void)reformatOutgoingColors;
- (void)reformatOutgoingFonts;
- (char)hasFEEInstalled;
- (void)_addInfoBannerMessage:fp8;
- (void)addChatInfoBanner;
- (void)_setVerticalSpacer:(float)fp8;
- (void)_rebuildEntireDocument;
- (void)insertTab:fp8;
- (void)insertNewline:fp8;
- (void)insertText:fp8;
- (void)_chatMessagesChanged:fp8;
- (void)_personInfoChanged:fp8;
- (void)_chatComposingChanged;
- (void)windowDidBecomeMain:fp8;
- (void)chooseBackgroundImage:fp8;
- (void)openPanelDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)clearBackground:fp8;
- (void)setRendererFromMenuItem:fp8;
- (void)_setShowsPictures:(char)fp8 names:(char)fp12;
- (void)toggleShowPictures:fp8;
- (void)toggleShowNames:fp8;
- (void)setChatShowsNames:fp8;
- (void)setChatShowsPictures:fp8;
- (void)setChatShowsNamesAndPictures:fp8;
- writablePasteboardTypes;
- (char)writeSelectionToPasteboard:fp8 type:fp12;
- (char)validateMenuItem:fp8;
- (unsigned int)_operationForDrag:fp8;
- (unsigned int)draggingEntered:fp8;
- (unsigned int)draggingUpdated:fp8;
- (void)draggingExited:fp8;
- (char)prepareForDragOperation:fp8;
- (char)performDragOperation:fp8;
- (void)concludeDragOperation:fp8;

@end
@class BuddyPicture;
@class AddressCard;
@class IMService;

@interface DaemonListenerStub:NSObject <FZDaemonListener>
{
}

- (oneway void)myStatusChanged:fp8;
- (oneway void)openNotesChanged:fp8;
- (oneway void)daemonPersistentProperty:fp8 changedTo:fp12;

@end

@interface Prefs:NSObject
{
}

+ (char)boolForKey:fp8 defaultValue:(char)fp12;
+ (int)integerForKey:fp8 defaultValue:(int)fp12;
+ (float)floatForKey:fp8 defaultValue:(float)fp12;
+ (void)readBuddyListSettings:fp8 fromDict:fp12;
+ dictFromBuddyListSettings:fp8;
+ (void)setBool:(char)fp8 forKey:fp12;
+ (char)offlineOnQuit;
+ (void)setOfflineOnQuit:(char)fp8;
+ (char)knockKnock;
+ (void)setKnockKnock:(char)fp8;
+ (char)showMyLoginIdInBuddyList;
+ (void)setShowMyLoginIdInBuddyList:(char)fp8;
+ (char)showAdvancedCameraSettings;
+ (void)setShowAdvancedCameraSettings:(char)fp8;
+ (char)menuExtraIsVisible;
+ (long)setMenuExtraIsVisible:(char)fp8;

@end

@interface KeyWindow:NSWindow
{
}

- (char)canBecomeKeyWindow;

@end

@interface NSWindow(iChatWindowLocation)
+ windowsWithOrigin:(struct _NSPoint)fp8 screen:fp16 withDelegateClass:(Class)fp20;
@end

@interface NSSound(FezExtention)
+ soundForPath:fp8;
@end

@interface NSButton(FezAdditions)
- (void)setIMFrameworkImageNamed:fp8 altImageNamed:fp12;
@end

@interface NSWindow(FezAdditions)
- (struct _NSRect)frame:(struct _NSRect)fp8 constrainedToScreen:fp24;
- (void)setFrame:(struct _NSRect)fp8 constrainedToScreen:fp24 display:(char)fp28 animate:(char)fp32;
- (void)setFrame:(struct _NSRect)fp8 constrainedToScreen:fp24 display:(char)fp28;
- (void)setFrame:(struct _NSRect)fp8 constrainedToScreen:fp24;
- (void)morphToFrame:(struct _NSRect)fp8;
- (void)dragWithEvent:fp8;
- (char)hasVisibleDrawer;
- (float)minFrameWidthWithTitle:fp8;
@end

@interface NSMutableAttributedString(TruncationExtensions)
- (void)truncateToFit:(float)fp8 range:(struct _NSRange)fp12;
- (void)truncateToFit:(float)fp8;
@end

@interface NSMutableAttributedString(FezExtensions)
+ attributedStringWithHTML:fp8 defaultFont:fp12;
- (void)addAttribute:fp8 value:fp12 range:(struct _NSRange)fp16 notOnAttribute:fp24;
- (void)setAlignment:(int)fp8;
@end

@interface NSAttributedString(TruncationExtensions)
- (struct _NSRange)adjustRange:(struct _NSRange)fp8;
- truncatedStringToFit:(float)fp8 range:(struct _NSRange)fp12;
- truncatedStringToFit:(float)fp8;
@end

@interface NSBezierPath(TreyAdditions)
+ roundedRectPathInRect:(struct _NSRect)fp8 radius:(float)fp24;
@end

@interface NSTextView(FezUtilAdditions)
- (char)writeAttributedStringSelectionToPasteboard:fp8;
- (char)pasteAttributedStringFromPasteboard:fp8;
@end

@interface NSTextField(JensAdditions)
- (char)textIsNonEmpty;
- rawAttributedStringValue;
@end

@interface NSView(FezUtilAdditions)
- (void)_reposition:(int)fp8;
- (void)bringToFront;
- (void)sendToBack;
- (void)setMaxX:(float)fp8;
- (void)setFocusRingNeedsDisplay;
@end

@interface NSColor(FezUtilAdditions)
+ menuWindowBackgroundColor;
- (void)_showPatternImageRepWindows;
@end

@interface NSImage(JensAdditions)
+ imageNamed:fp8 inBundle:fp12;
- (struct _NSSize)largestRepSize;
- (void)drawNicelyScaledInRect:(struct _NSRect)fp8 operation:(int)fp24 fraction:(float)fp28;
- (void)drawNicelyScaledInRect:(struct _NSRect)fp8 inView:fp24 operation:(int)fp28 fraction:(float)fp32;
- (void)drawStretchedInFrame:(struct _NSRect)fp8 inView:fp24 capWidth:(float)fp28 alpha:(float)fp32;
- imageWithMaxSize:(int)fp8;
- imageWithMaxSize:(int)fp8 withLeftPad:(int)fp12;
- JPEGDataWithMaxSize:(float)fp8 compression:(float)fp12;
- (char)writeJPEGDataWithCompression:(float)fp8 toFile:fp12;
- temporaryJPEGFileWithCompression:(float)fp8;
- bitmapImageRep;
@end

@interface IncomingFile:NSObject
{
    NSString *_name;
    struct _meta;
    NSString *_mimeType;
    id _remoteXfer;
    Presentity *_sender;
    NSString *_savePath;
    char _isTempFile;
    char _wasSaved;
    id _delegate;
}

- initWithName:fp8 metadata:fp12 fzXfer:fp16;
- (void)dealloc;
- (void)_removeSelfAsListener;
- (void)_handleDaemonException:fp8;
- (void)setSender:fp8;
- sender;
- name;
- (unsigned long long)size;
- (char)isDirectory;
- (unsigned long)hfsType;
- (unsigned long)hfsCreator;
- (unsigned short)hfsFlags;
- (void  *)metadata;
- displayName;
- MIMEType;
- _createTempFile;
- kindString;
- (char)isExecutable;
- icon;
- emptyFileWrapper;
- sourceURL;
- (void)_reportError:fp8 onFile:fp12;
- (char)checkSavePath:fp8 window:fp12;
- (void)declineTransfer;
- (char)_acceptIncomingFileToPath:fp8;
- (char)saveAs:fp8 delegate:fp12;
- savePath;
- (char)wasSaved;
- delegate;
- (void)setDelegate:fp8;
- (void)stopTransfer;
- downloadedData;
- (void)_clearDownload;

@end

@interface HFSFileManager:NSFileManager
{
}

+ defaultManager;
+ defaultHFSFileManager;
- (char)existingPath:fp8 toFSRef:(void *)fp12;
- (char)existingPath:fp8 toFSSpec:(void *)fp12;
- (char)path:fp8 toParentFSRef:(void *)fp12 andFileName:(id *)fp16;
- fileAttributesAtPath:fp8 traverseLink:(char)fp12;
- (char)changeFileAttributes:fp8 atPath:fp12;
- kindStringForFile:fp8;
- MIMETypeOfFile:fp8;
- MIMETypeOfFileWithName:fp8 hfsType:(unsigned long)fp12 hfsCreator:(unsigned long)fp16;
- displayNameOfFileWithName:fp8 hfsFlags:(unsigned short)fp12;
- (long long)fileSizeAtPath:fp8;
- (long long)totalSizeAtPath:fp8 fileCount:(int *)fp12;
- (char)isNonPublicAttrs:(unsigned long)fp8 forDir:(char)fp12;
- (char)isNonPublicFileAtPath:fp8 traverseLink:(char)fp12;

@end

@interface NSDictionary(HFSFileAttributes)
- fileCreationDate;
- (unsigned long)fileHFSType;
- (unsigned long)fileHFSCreator;
- (unsigned short)fileHFSFlags;
- (unsigned long long)fileHFSResourceForkSize;
@end


@interface NullNode:NSObject <Node>
{
}

+ (void)initialize;
+ createNullNode;
- createChild:fp8;
- (void)addText:fp8;
- (void)childFinished:fp8;
- (void)finished;

@end

@interface GenericNode:NullNode
{
    NSString *_name;
    NSDictionary *_attrs;
    NSMutableArray *_elements;
    NSMutableString *_curText;
}

- initWithHeader:fp8;
- (void)dealloc;
- (void)_finishText;
- createChild:fp8;
- (void)addText:fp8;
- (void)childFinished:fp8;
- (void)finished;
- name;
- attributes;
- attributeNamed:fp8;
- firstElementNamed:fp8;
- elements;
- text;
- description;

@end


@interface PlainTextNode:NullNode
{
    NSMutableString *_text;
}

- init;
- initWithInitialText:fp8;
- (void)dealloc;
- (void)addText:fp8;
- text;

@end


@interface RawXMLNode:PlainTextNode
{
    NSString *_name;
}

- initWithHeader:fp8;
- stripNamespaceFrom:fp8;
- initWithHeader:fp8 initialText:fp12;
- (void)dealloc;
- createChild:fp8;
- (void)addText:fp8;
- (void)childFinished:fp8;
- (void)finished;
- text;

@end
@class NodeHeader;
@interface XMLStreamer:NSObject
{
    NSMutableArray *_stack;
    NodeHeader *_header;
    unsigned short _separator;
    void *_parser;
    char _parsing;
}

- (void)_createParser;
- initWithRoot:fp8 namespaceSeparatorChar:(unsigned short)fp12;
- (void)dealloc;
- (void)reset;
- (void)_beginNodeNamed:(const STR)fp8 attributes:(const STR *)fp12;
- (void)_nodeData:(const STR)fp8 length:(int)fp12;
- (void)_endNode;
- (char)isParsing;
- (char)parse:fp8;
- (void *)getBufferOfSize:(int)fp8;
- (char)parseBufferWithLength:(int)fp8;
- (char)endParse;
- (int)xmlError;

@end

@interface NodeHeader:NSObject
{
    STR _name;
    STR *_attrs;
}

- (void)_setName:(const STR)fp8 attributes:(const STR *)fp12;
- name;
- (const STR)Cname;
- attributeNamed:fp8;
- attributeNamedC:(const STR)fp8;
- (const STR)CattributeNamedC:(const STR)fp8;
- attributes;

@end

@interface OptionalScrollView:NSScrollView
{
}

- (void)reflectScrolledClipView:fp8;
- (void)_doScroller:fp8;

@end

@interface FezExtendedTableView:NSTableView
{
    float _fullRowHeight;
    char _settingFrame;
}

- initWithFrame:(struct _NSRect)fp8;
- (void)tile;
- (void)keyDown:fp8;
- (char)acceptsFirstMouse:fp8;
- (void)mouseDown:fp8;
- (void)viewDidEndLiveResize;
- (void)setFrame:(struct _NSRect)fp8;
- (void)setFrameSize:(struct _NSSize)fp8;
- (void)viewDidMoveToWindow;
- (void)viewDidMoveToSuperview;
- selectedRows;
- (char)validateMenuItem:fp8;
- (void)cut:fp8;
- (void)copy:fp8;
- (void)paste:fp8;
- (void)delete:fp8;
- (float)fullRowHeight;
- (void)setRowHeight:(float)fp8;
- (void)setIntercellSpacing:(struct _NSSize)fp8;
- (char)_wantsLiveResizeToUseCachedImage;
- (void)highlightSelectionInClipRect:(struct _NSRect)fp8;
- (char)drawsSelection;

@end

@interface NSObject(FezExtendedTableViewDataSource)
- (char)tableView:fp8 canPasteFromPasteboard:fp12;
- (char)tableView:fp8 pasteFromPasteboard:fp12;
- (char)tableView:fp8 canDeleteRows:fp12;
- (char)tableView:fp8 deleteRows:fp12;
@end

@class IncomingFileStream;
@interface IncomingFileURL:IncomingFile
{
    NSURL *_url;
    IncomingFileStream *_stream;
    int _bytesReceived;
    double _lastTimeNotified;
    char _gotContentType;
}

- initWithURL:fp8 fzXfer:fp12;
- initWithURL:fp8 metadata:fp12 mimeType:fp16 fzXfer:fp20;
- (void)_clearDownload;
- (void)dealloc;
- sourceURL;
- (char)saveAs:fp8 delegate:fp12;
- (void)stopTransfer;
- (void)_streamOpenCompleted;
- (void)_streamDataReceived:(unsigned long)fp8;
- (void)_streamEnded;
- (void)_streamErrorOccurred:fp8;

@end
@class FolderNode;
@class FileNode;


@interface IncomingFolderURL:IncomingFile <FileTransferDelegate>
{
    NSURL *_url;
    char _triedToGetContents;
    FolderNode *_contents;
    FileNode *_source;
    FileNode *_current;
    IncomingFileURL *_incomingFile;
    int _bytesReceived;
}

- initWithURL:fp8 metadata:fp12 fzXfer:fp16;
- (void)dealloc;
- sourceURL;
- MIMEType;
- contents;
- (char)saveAs:fp8 delegate:fp12;
- (void)_reportError:fp8;
- (void)_clearDownload;
- (char)_beginDownload:fp8;
- (void)currentFile:fp8 currentFileSize:(unsigned int)fp12 currentSentBytes:(unsigned int)fp16 totalTransferProgress:(float)fp20 timeRemaining:fp24 message:fp28;
- (void)stopTransfer;

@end

@interface OutgoingFile:IncomingFile
{
    NSString *_filePath;
}

- initWithFile:fp8 fzXfer:fp12;
- initWithFile:fp8;
- (void)dealloc;
- filePath;
- icon;
- (char)saveAs:fp8 delegate:fp12;

@end

@interface FezNSTextAttachment:NSTextAttachment
{
    NSImage *_image;
}

- initWithImage:fp8;
- (void)dealloc;
- initWithCoder:fp8;
- (void)encodeWithCoder:fp8;
- (void)setFileWrapper:fp8;
- fileWrapper;
- attachmentCell;
- description;

@end

@interface MessageRenderer:NSObject
{
    NSTextView *_view;
    int _align;
    int _viewFlags;
}

+ (void)initialize;
+ colorForMessage:fp8;
- initWithView:fp8;
- (void)setForcedAlignment:(int)fp8;
- (void)setViewFlags:(int)fp8;
- (float)noTimestampSpacer;
- (float)minimumHeightForMessage:fp8;
- (float)gapAboveMessage:fp8 previousMessage:fp12;
- (float)gapBelowMessage:fp8 nextMessage:fp12;
- (struct _NSRect)boundsOfMessage:fp8 withTextBounds:(struct _NSRect)fp12;
- (void)maxBoundsOutsetTop:(float *)fp8 bottom:(float *)fp12;
- paragraphStyleForMessage:fp8;
- (void)drawPictureOfSender:fp8 inRect:(struct _NSRect)fp12 fraction:(float)fp28;
- (void)drawBackgroundForMessage:fp8 mostRecent:(char)fp12 textBounds:(struct _NSRect)fp16;
- (char)shouldDrawPictures;
- (char)shouldShowNameForMessage:fp8;
- (char)customEmptyMessages;

@end

@interface BoxMessageRenderer:MessageRenderer
{
}

- (float)noTimestampSpacer;
- paragraphStyleForMessage:fp8;
- (struct _NSRect)boundsOfMessage:fp8 withTextBounds:(struct _NSRect)fp12;
- (struct _NSRect)_boundsOfPictureForMessage:fp8 inRect:(struct _NSRect)fp12;
- (void)drawBackgroundForMessage:fp8 mostRecent:(char)fp12 textBounds:(struct _NSRect)fp16;
- (char)shouldShowNameForMessage:fp8;
- (float)minimumHeightForMessage:fp8;
- (float)gapBelowMessage:fp8 nextMessage:fp12;
- (void)maxBoundsOutsetTop:(float *)fp8 bottom:(float *)fp12;

@end


@interface NSView(NSViewShouldHaveAVisibleBitLikeEveryOtherFrameworkInExistance)
- (char)visible;
- (void)setVisible:(char)fp8;
@end



@interface ChatFieldEditor:NSTextView
{
    char _allowsAttachments;
    char _allowsInlineImages;
}

- initWithFrame:(struct _NSRect)fp8;
- (void)dealloc;
- (char)validateMenuItem:fp8;
- (void)addFontTrait:fp8;
- (void)toggleContinuousSpellChecking:fp8;
- (void)changeFont:fp8;
- (void)setMarkedText:fp8 selectedRange:(struct _NSRange)fp12;
- (void)insertText:fp8;
- (void)smileyPicked:fp8;
- (void)setAllowsAttachments:(char)fp8;
- (void)setAllowsInlineImages:(char)fp8;
- (char)canAttachFile;
- (char)canFileBeAttachedInline:fp8;
- (void)_showAttachErrorSheetWithMessage:fp8;
- (char)insertAttachedFile:fp8;
- attachedFileFrom:fp8;
- (void)sendFile:fp8;
- (void)sendSong:fp8;
- (void)_attachmentChosen:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- acceptableDragTypes;
- readablePasteboardTypes;
- (char)readSelectionFromPasteboard:fp8 type:fp12;
- (void)_clearParagraphStyle;
- (void)concludeDragOperation:fp8;
- writablePasteboardTypes;
- (char)writeSelectionToPasteboard:fp8 type:fp12;
- (void)paste:fp8;
- selectedLink_adjustingSelection:(char)fp8;
- (void)applyLinkToSelection:fp8;
- (char)insertLinkAtSelection:fp8 withText:fp12;
- (void)clickedOnLink:fp8 atIndex:(unsigned int)fp12;
- (void)setTypingAttributes:fp8;
- (void)_setTypingAttributesForSelection:(struct _NSRange)fp8;
- (void)_fixAttrsOnSelectionChange:fp8;

@end

@interface FontAndColor:NSObject
{
    NSFont *_font;
    NSColor *_color;
}

- initWithFont:fp8 color:fp12;
- (void)dealloc;
- color;
- (char)isEqualTo:fp8;

@end

@interface XHTMLGenerator:NSObject
{
    NSAttributedString *_text;
    char _isXHTML;
    NSColor *_fgColor;
    NSColor *_bgColor;
    NSMutableArray *_tagStack;
    NSMutableArray *_tagValueStack;
    NSMutableString *_out;
}

+ XHTMLFromAttributedString:fp8 defaultBGColor:fp12;
+ HTMLFromAttributedString:fp8 defaultBGColor:fp12;
+ plainTextFromAttributedString:fp8;
+ parseHTML:fp8 isXHTML:(char)fp12 resultingBGColor:(id *)fp16;
- initWithAttributedString:fp8;
- (void)dealloc;
- (void)setXHTML:(char)fp8;
- (void)setDefaultForegroundColor:fp8;
- (void)setDefaultBackgroundColor:fp8;
- _valueOfTag:fp8;
- (void)_pushTag:fp8 tagValue:fp12 attributesAndValues:fp16;
- (void)_pushTag:fp8 tagValue:fp12 attribute:fp16 value:fp20;
- (void)_popTag;
- (void)_popAllTags;
- (void)_popTag:fp8 ifValueNot:fp12;
- (void)_generateHTMLForString:fp8 attributes:fp12;
- generateXHTML;
- generatePlainText;

@end

@interface SmileyToolbarItem:NSToolbarItem
{
}

- initWithPopUpButton:fp8;
- currentTextView;
- (void)validate;
- (char)validateMenuItem:fp8;
- (void)insertSmiley:fp8;

@end

@interface StretchyImage:NSObject <NSCopying>
{
    NSImage *_template;
    NSColor *_centerColor;
    NSColor *_leftPattern;
    NSColor *_rightPattern;
    NSColor *_topPattern;
    NSColor *_bottomPattern;
    float _leftWidth;
    float _rightWidth;
    float _topHeight;
    float _bottomHeight;
    struct _NSRect _templateTopLeft;
    struct _NSRect _templateTopEdge;
    struct _NSRect _templateTopRight;
    struct _NSRect _templateLeftEdge;
    struct _NSRect _templateRightEdge;
    struct _NSRect _templateBottomLeft;
    struct _NSRect _templateBottomEdge;
    struct _NSRect _templateBottomRight;
    char _isBackground;
}

- (void)_xplitLeft:(struct _NSRect *)fp8 mid:(struct _NSRect *)fp12 right:(struct _NSRect *)fp16;
- _patternFromRect:(struct _NSRect)fp8;
- (void)_createPatterns;
- initWithTemplate:fp8 left:(float)fp12 right:(float)fp16 top:(float)fp20 bottom:(float)fp24;
- initWithDictionary:fp8;
- initWithFlippedStretchyImage:fp8;
- copyWithZone:(struct _NSZone *)fp8;
- (void)dealloc;
- (void)setCenterColor:fp8;
- (char)isBackground;
- (void)setIsBackground:(char)fp8;
- (void)_drawPattern:fp8 inRect:(struct _NSRect)fp12;
- (void)drawInRect:(struct _NSRect)fp8;
- (void)_fillImage:fp8 withColor:fp12;
- (void)fillWithColor:fp8;

@end

@interface TiledBalloonRenderer:MessageRenderer
{
    NSMutableDictionary *_paragraphStyles;
    NSMutableDictionary *_participantNames;
}

+ (void)initialize;
+ (void)setPersonIconMargin:(float)fp8;
+ (float)personIconMargin;
+ (void)setPersonTextMargin:(float)fp8;
+ (float)personTextMargin;
+ (void)initBalloonDicts;
+ balloonForColor:fp8 fromMe:(char)fp12;
- initWithView:fp8;
- (void)dealloc;
- attributedStringForName:fp8;
- styleForWidth:(float)fp8;
- paragraphStyleForMessage:fp8;
- (float)noTimestampSpacer;
- (float)gapAboveMessage:fp8 previousMessage:fp12;
- (float)gapBelowMessage:fp8 nextMessage:fp12;
- (void)maxBoundsOutsetTop:(float *)fp8 bottom:(float *)fp12;
- (char)customEmptyMessages;
- (struct _NSRect)_boundsOfBalloonForMessage:fp8 inRect:(struct _NSRect)fp12;
- (struct _NSRect)_boundsOfPictureForMessage:fp8 inRect:(struct _NSRect)fp12;
- (struct _NSRect)_boundsOfName:fp8 forMessage:fp12 inRect:(struct _NSRect)fp16;
- (struct _NSRect)boundsOfMessage:fp8 withTextBounds:(struct _NSRect)fp12;
- _thoughtBubbleForMessage:fp8;
- (void)_drawThoughtBubbleForMessage:fp8 inRect:(struct _NSRect)fp12;
- (void)drawBackgroundForMessage:fp8 mostRecent:(char)fp12 textBounds:(struct _NSRect)fp16;

@end



@interface SavedChat:Chat
{
}

+ savedChatDirectory;
+ (void)reloadSavedChats;
- initWithTranscriptFile:fp8;
- initWithSavedData:fp8;
- (void)dealloc;
- (char)_loadFromArray:fp8;
- (char)_load;
- (char)_loadFromData:fp8;
- messages;

@end

@interface ActiveChat:Chat
{
    char _active;
    int _joinState;
    char _displayOnJoin;
    char _finishedByMe;
    char _announcePeople;
    NSMutableArray *_curPeople;
    NSMutableSet *_peopleDeciding;
    NSMutableSet *_ignoredPeople;
    NSString *_ID;
}

- initWithService:fp8 style:(int)fp12;
- initWithMessage:fp8 style:(int)fp12;
- (void)dealloc;
- ID;
- (void)setID:fp8;
- (char)isComposing;
- (void)setService:fp8;
- (void)setPeople:fp8;
- (char)isActive;
- (void)setDisplayOnJoin:(char)fp8;
- (int)joinState;
- (void)setJoining;
- (void)setHasJoined:(char)fp8;
- curPeople;
- peopleDeciding;
- (void)setSubject:fp8;
- (void)setAddress:fp8;
- (char)isChatWithBuddySecure:fp8;
- (char)autoSave;
- (void)notifyUser;
- (char)respondToInvitation:(char)fp8;
- (char)waitTillJoined;
- (void)finish;
- (void)_finishedWithMessage:fp8;
- (char)wasFinishedByMe;
- (void)_postNotificationName:fp8 key:fp12 object:fp16 key:fp20 object:fp24 key:fp28 object:fp32;
- (void)_postMemberChange:fp8 status:(int)fp12;
- (void)showError:fp8;
- (void)addMessage:fp8 atEnd:(char)fp12 replacingMessageAtIndex:(int)fp16;
- (int)_findUnfinishedMessageFrom:fp8;
- (void)addMessage:fp8;
- (void)addInitialComposeMessage;
- (void)addAnnouncementString:fp8;
- (void)notifyMessageAdded:fp8;
- (char)sendMessage:fp8;
- (void)setAnnouncePeople:(char)fp8;
- (void)_removeDeciding:fp8;
- (void)addPerson:fp8;
- (void)removePerson:fp8;
- (void)invitePerson:fp8 withMessage:fp12;
- (void)invitePeople:fp8 withMessage:fp12;
- (void)_personChanged:fp8;
- (void)setPerson:fp8 isIgnored:(char)fp12;
- (char)personIsIgnored:fp8;
- (void)_member:fp8 statusChanged:(int)fp12;

@end

@interface LinkSheetController:NSObject
{
    NSTextField *_linkTextField;
    NSButton *_okButton;
}

- (void)controlTextDidChange:fp8;

@end

@interface ChatController:NSObject <PeopleControllerDelegate>
{
    NSView *_enclosingView;
    ChatInputLine *_inputLine;
    NSTextField *_whyIsInputLineGoneField;
    AnimatingTabView *_inputLineTabView;
    NSView *_participantsArea;
    PeopleController *_people;
    NSDrawer *_peopleDrawer;
    ChatTextView *_transcript;
    NSMenu *_chatContextMenu;
    ChooseBuddyButton *_chooseIDButton;
    NSWindow *_chooseIDSheet;
    NSPanel *_linkSheet;
    ExtendedTextField *_linkTextField;
    NSWindow *_inviteMsgSheet;
    NSTextField *_inviteMsgText;
    NSTextField *_inviteMsgLabel;
    NSView *_buttonArea;
    NSButton *_notifyAccept;
    NSButton *_notifyReject;
    NSButton *_notifyBlock;
    float _buttonAmountVisible;
    NSString *_origNotifyAcceptTitle;
    NSWindow *_chatOptionsSheet;
    NSPopUpButton *_chatOptionsStyle;
    ExtendedTextField *_chatOptionsName;
    ChatFieldEditor *_fieldEditor;
    Chat *_chat;
    char _primaryController;
    char _chooseIDMenuIsValid;
    char _requestedCustomID;
    char _isDeciding;
    char _msgsHidden;
    char _finishChatWhenClosed;
    StagedChatNotifier *_notifier;
    NSWindow *_window;
    char _resizingInputLine;
    float _inputLineRightMargin;
}

+ chatControllerInstalledInView:fp8;
- (void)_hookUpToWindow:fp8;
- (void)awakeFromNib;
- (void)_finishChat;
- (void)dealloc;
- (void)handleChatWindowClosing:fp8;
- window;
- selectedPresentities;
- implicitlySelectedPresentity;
- (char)isComposing;
- chat;
- (void)_updateFinishButton;
- (void)setChat:fp8;
- (void)setChatRoomName:fp8;
- (char)finishesChatWhenClosed;
- (void)setFinishesChatWhenClosed:(char)fp8;
- inputLine;
- fieldEditor;
- (void)_updateInputLineAttachmentSupport;
- (char)inputLineHasFocus;
- (void)setPrimaryChatController:(char)fp8;
- _activeChatChat;
- (char)_serviceMightChat;
- displayName:(char)fp8;
- (void)_postDisplayNameChanged;
- (void)_postPeopleChanged;
- (int)style;
- people;
- notifier;
- (char)isActive;
- (void)_adjustInputLineHeightBy:(float)fp8;
- (void)_setInputLineHeight:(float)fp8;
- (void)_showInputLine:(char)fp8;
- (void)_msgStyleChanged:fp8;
- (void)controlTextDidChange:fp8;
- (void)_inputLineDidEndLiveResize:fp8;
- (char)resizingInputLine;
- (char)inputLineCanAttachFile;
- transcriptView;
- (void)insertText:fp8;
- (void)tabView:fp8 willSwitchFromTab:(int)fp12 toTab:(int)fp16 effect:(int *)fp20 direction:(int *)fp24;
- (char)isInputLineVisible;
- (void)_updateInputLineTabView:fp8;
- (char)areParticipantsVisible;
- (void)showParticipants:fp8;
- (void)hideParticipants:fp8;
- (void)toggleParticipants:fp8;
- (void)personDoubleClicked:fp8;
- (void)toggleHidePictures:fp8;
- (void)toggleHideAudioStatus:fp8;
- (void)toggleHideVideoStatus:fp8;
- (void)sortByStatus:fp8;
- (void)sortByFirstName:fp8;
- (void)sortByLastName:fp8;
- (void)addLink:fp8;
- (void)acceptLinkText:fp8;
- (void)cancelLinkSheet:fp8;
- (void)removeLinkSheet:fp8;
- (void)_linkSheetDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (char)textView:fp8 clickedOnLink:fp12 atIndex:(unsigned int)fp16;
- _messageTextAndFlags:(int *)fp8;
- (char)_sendMessage:(char)fp8 forceEmpty:(char)fp12 forceSend:(char)fp16;
- (void)_clearInputLine;
- (void)cancelMessage:fp8;
- (void)_sendMessage;
- (void)sendMessage:fp8;
- (void)sendPartialMessage:fp8;
- (char)canSendPartialMessage;
- (char)textField:fp8 didChangeSignificantly:(int)fp12;
- (char)control:fp8 textShouldBeginEditing:fp12;
- (void)requestCustomID;
- (void)composeEMail:fp8;
- (void)sendSong:fp8;
- (void)sendFile:fp8;
- (void)insertSmiley:fp8;
- (void)setRendererFromMenuItem:fp8;
- (void)startAudioChat:fp8;
- (void)startOneWayAudioChat:fp8;
- (void)startVC:fp8;
- (void)startOneWayVC:fp8;
- (char)canUseInputField;
- (void)_reformatOutgoingColors;
- (void)_reformatOutgoingFonts;
- (char)validateMenuItem:fp8;
- (void)_memberChanged:fp8;
- (void)finishChat:fp8;
- (void)ignore:fp8;
- (void)block:fp8;
- (void)_blockSheetDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)_chatStatusChanged:fp8;
- (void)_chatComposingStatusChanged:fp8;
- (void)_chatErrorPosted:fp8;
- (void)_showErrorSheet:fp8;
- (void)_addNewPresentities:fp8;
- (void)_personInfoChanged:fp8;
- (void)buddySelected:fp8;
- (void)chooseBuddySheetCanceled:fp8;
- alternateStatusTextForPerson:fp8;
- (float)alphaForStatus:(int)fp8;
- (char)canAddPeople;
- (char)canRemovePeople;
- (void)_syncPeopleWithChat;
- (void)_adjustChatStyle;
- (char)peopleController:fp8 pleasePastePeople:fp12;
- (char)peopleController:fp8 pleaseCutPeople:fp12;
- (void)peopleChanged:fp8;
- (char)aboutToResort;
- filterPersonFromPasteboard:fp8;
- (char)addPersonWithoutID:fp8;
- (void)setIsDeciding:(char)fp8 doKnockKnock:(char)fp12 withChatNotifier:fp16;
- (void)forgetNotifier:fp8;
- (char)isDeciding;
- (void)setVisiblePortionOfNotifyButtons:(float)fp8;
- (void)acceptNotification:fp8;
- (void)rejectNotification:fp8;
- (void)blockNotification:fp8;
- (void)_runInviteSheetForInvitees:fp8;
- (void)acceptInviteMessage:fp8;
- (void)cancelInviteMessage:fp8;
- (void)_inviteMsgDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)chooseBackgroundImage:fp8;
- (void)clearBackground:fp8;
- (void)toggleShowPictures:fp8;
- (void)toggleShowNames:fp8;
- (void)setChatShowsNames:fp8;
- (void)setChatShowsPictures:fp8;
- (void)setChatShowsNamesAndPictures:fp8;
- (void)_updateChatModeSheet;
- (void)chooseChatOptions:fp8;
- (void)pickChatMode:fp8;
- (void)acceptChatOptions:fp8;
- (void)cancelChatOptions:fp8;
- (void)_chatOptionsDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;

@end

@interface FZMessage:NSObject <NSCoding, NSCopying>
{
    NSString *_sender;
    NSDate *_time;
    int _bodyFormat;
    NSString *_body;
    NSDictionary *_attributes;
    NSString *_outgoingFile;
    NSArray *_inlineFiles;
    id _incomingFile;
    int _flags;
}

- copyWithZone:(struct _NSZone *)fp8;
- replacementObjectForPortCoder:fp8;
- initWithCoder:fp8;
- (void)encodeWithCoder:fp8;
- init;
- initWithSender:fp8 format:(int)fp12 body:fp16;
- initWithSender:fp8 time:fp12 format:(int)fp16 body:fp20 attributes:fp24 incomingFile:fp28 outgoingFile:fp32 inlineFiles:fp36 flags:(int)fp40;
- (void)dealloc;
- sender;
- time;
- (int)bodyFormat;
- body;
- attributes;
- incomingFile;
- outgoingFile;
- inlineFiles;
- (int)flags;
- (char)isFinished;
- (char)isEmpty;
- (void)setSender:fp8;
- (void)setTime:fp8;
- (void)setAttributes:fp8;
- (void)setIncomingFile:fp8;
- (void)setOutgoingFile:fp8;
- (void)setInlineFiles:fp8;
- (void)setFlags:(int)fp8;
- (void)setBody:fp8 format:(int)fp12;
- (void)adjustIsEmptyFlag;

@end

@interface NSUserDefaults(FezAdditions)
- iChatDomain;
- (void)setiChatDomain:fp8;
@end

@interface NSFileManager(FezAdditions)
- (char)makeDirectoriesInPath:fp8 mode:(int)fp12;
- uniqueFilename:fp8 atPath:fp12 ofType:fp16;
@end

@interface NSCalendarDate(FezAdditions)
- (int)daysAgo;
@end

@interface NSDate(FezAdditions)
- (int)daysAgo;
@end

@interface NSData(FezAdditions)
+ dataWithHexString:fp8;
- (unsigned int)_SHA1Into:(unsigned char [20])fp8;
- SHA1Data;
- SHA1HexString;
- hexString;
@end

@interface NSURL(FezAdditions)
- URLByAppendingPathComponent:fp8;
@end

@interface NSSet(FezAdditions)
- enumerateObjectsNotInSet:fp8;
@end

@interface NSDictionary(FezAdditions)
- dictionaryFromChanges:fp8;
@end

@interface NSMutableArray(FezAdditions)
+ nonRetainingArray;
- (void)applySelector:(SEL)fp8;
- (void)applySelector:(SEL)fp8 withObject:fp12;
@end

@interface NSArray(FezAdditions)
- (char)containsObjectIdenticalTo:fp8;
- (unsigned int)indexOfObject:fp8 matchingComparison:(SEL)fp12;
- (char)containsObject:fp8 matchingComparison:(SEL)fp12;
- arrayByApplyingSelector:(SEL)fp8;
- arrayByApplyingSelector:(SEL)fp8 withObject:fp12;
- arrayByFilteringOutBySelector:(SEL)fp8 withObject:fp12;
@end

@interface NSMutableAttributedString(FezAdditions)
- (void)trimWhitespace;
- (void)replaceAttribute:fp8 value:fp12 withValue:fp16;
- (void)removeCharactersWithAttribute:fp8;
@end

@interface NSAttributedString(FezAdditions)
- (char)attribute:fp8 existsInRange:(struct _NSRange)fp12;
@end

@interface NSMutableString(FezAdditions)
- (void)replaceSubstring:fp8 with:fp12;
@end

@interface NSString(FezAdditions)
- (char)isEqualToIgnoringCase:fp8;
- (unsigned int)hexValue;
- trimmedString;
- stringByRemovingURLEscapes;
- stringByAddingURLEscapes;
- stringByReplacing:fp8 with:fp12;
- commaSeparatedComponents;
@end

@interface NSObject(FezAdditions)
- (char)isNull;
@end


@interface MenuButton:NSButton
{
}

- (void)mouseDown:fp8;
- (void)performClick:fp8;

@end

@interface MenuComboBox:NSComboBox
{
    NSButtonCell *_cbButtonCell;
}

- (void)awakeFromNib;
- (void)statusPopUp:fp8;

@end

@interface ActionsController:NSObject
{
    NSPopUpButton *_eventsPopUp;
    NSButton *_playSoundCheckbox;
    NSButton *_repeatSoundCheckbox;
    NSButton *_speakCheckbox;
    NSButton *_bounceDockCheckbox;
    NSButton *_repeatBounceCheckbox;
    NSButton *_oneShotCheckbox;
    NSTextField *_oneShotLineTwo;
    SoundPopUpButton *_soundsPopUp;
    ExtendedTextField *_speakText;
    NSSlider *_volumeSlider;
    Person *_buddy;
    NSMutableDictionary *_actionSet;
    int _eventNumber;
    char _eventActionsChanged;
    char _actionsChanged;
    id _delegate;
}

+ prefsKey:fp8;
+ fullPathOfSoundInActions:fp8;
+ (char)continuousVCRingEnabled;
+ (void)setContinuousVCRingEnabled:(char)fp8;
+ (void)_rebounce:fp8;
+ (void)_appDidBecomeActive:fp8;
+ (void)_repeatSound:fp8;
+ (void)_playSoundFromFile:fp8 repeat:(char)fp12;
+ (void)_stopRepeatingSoundFromFile:fp8;
+ actionsForEvent:(int)fp8 withPerson:fp12;
+ (void)setActions:fp8 forEvent:(int)fp12 withPerson:fp16;
+ performActionsForEvent:(int)fp8 withPerson:fp12;
+ (void)stopEventActions:fp8;
- (void)setDelegate:fp8;
- (void)awakeFromNib;
- (void)dealloc;
- (char)hasChangesPending;
- (void)_rememberEventChanges;
- (void)saveChanges;
- (void)loadFromDefaults;
- (void)setBuddy:fp8;
- buddy;
- (void)_updateEventsPopUpIcons;
- (void)_addItemWithTag:(int)fp8;
- (void)_fillEventsPopUpWith:(int)fp8;
- (void)_fillEventsPopUp:(char)fp8;
- (void)_enableOneShot:(char)fp8;
- _actionsForEvent:(int)fp8;
- (void)_updateActions;
- (void)eventSelected:fp8;
- (char)_anyActionsChecked;
- (void)actionChecked:fp8;
- (void)soundSelected:fp8;
- alternateSoundDirs;
- titleForSoundFile:fp8;
- (void)controlTextDidChange:fp8;
- (void)speakText:fp8;
- (void)volumeChanged:fp8;

@end

@interface CustomBannerView:NSView
{
    Presentity *_sender;
    OpenGLBannerLayer *_layer;
    char _isAudio;
}

- initWithFrame:(struct _NSRect)fp8 buddy:fp24 audio:(char)fp28 oneWay:(char)fp32;
- (void)dealloc;
- (void)drawRect:(struct _NSRect)fp8;
- (void)setFrameSize:(struct _NSSize)fp8;
- (void)cancelInvitation;
- (void)declineInvitation;
- (float)dxToFitBanner;

@end

@interface CustomImageView:NSImageView
{
}

- (void)mouseDown:fp8;

@end

@interface CustomWindow:NSWindow
{
    StagedChatNotifier *notifier;
}

- (void)setNotifier:fp8;
- (void)sendEvent:fp8;

@end

@interface StagedChatNotifier:NSObject
{
    ActiveChat *_chat;
    NSWindow *_realWindow;
    NSWindow *_floaterWindow;
    NSWindow *_realMsgFloaterWindow;
    struct _NSPoint _floaterOffset;
    struct _NSPoint _realMsgFloaterOffset;
    struct _NSSize _origRealSize;
    float _prevRealHeight;
    char _canHideShowRealWindow;
    char _shouldRestoreSize;
    char _msgsHidden;
    int _stage;
    struct CGAffineTransform _finalXform;
    NSString *_openNoteID;
    int _inviteType;
    char _audioOnly;
    char _oneWay;
    NSDictionary *_eventActions;
    ChatController *_controller;
    ChatTextView *_transcript;
    NSDictionary *_vcProperties;
    AVChatController *_avChatController;
    StagedFileNotifier *_fileNotifier;
    IncomingFile *_file;
    Presentity *_sender;
}

+ (void)openOnChat:fp8;
+ (void)openOnIncomingFile:fp8 sender:fp12;
+ (void)openOnIncomingVC:fp8 properties:fp12;
+ (void)_stopVCRequestFrom:fp8 isRescind:(char)fp12;
+ (void)rescindVCRequestFrom:fp8;
+ (void)declineVCRequestFrom:fp8;
+ (void)addItemsToMenu:fp8 atIndex:(unsigned int)fp12 fromData:fp16 target:fp20 action:(SEL)fp24;
+ notifierWithType:(int)fp8 fromID:fp12;
+ (void)orderFrontNotifierWithID:fp8;
- (char)_collidesWithExistingWindow:(struct _NSRect)fp8;
- (void)_positionRealWindowInCorner:(char)fp8;
- (void)_installRealWindowNotifications;
- _grabRealBitsInRect:(struct _NSRect)fp8 fromView:fp24;
- (void)_makeRealWindowMsgRect:(struct _NSRect *)fp8 knockRect:(struct _NSRect *)fp12;
- (void)_restoreRealWindowSettings;
- (struct _NSRect)_makeRealFileNotifierWindow;
- (char)_makeRealVCNotifierWindow;
- (void)_makeVCFloaterWindow;
- (void)_makeFloaterWindowGrabbingRect:(struct _NSRect)fp8 knockKnock:(char)fp24;
- (void)_performActionsForEvent:(int)fp8;
- (void)_stopEventActions;
- initWithChat:fp8;
- initWithIncomingFile:fp8 sender:fp12;
- initForVCWith:fp8 properties:fp12;
- callerProperties;
- (void)disconnectFromChatController:fp8;
- (void)dealloc;
- (void)_setFloaterScale:(float)fp8;
- (void)_animateFloaterDisplay;
- (void)_doFrameOfFloaterDisplay:fp8;
- (void)orderFrontRealWindow;
- (void)_animateRealDisplay;
- (void)_doFrameOfRealDisplay:fp8;
- (void)_animateRealHiding;
- (void)_doFrameOfRealHiding:fp8;
- (void)_animateRealSizeRestore;
- (void)_waitForChatAcceptance;
- (void)_closeDownShop:(char)fp8;
- (void)acceptNotification;
- (void)_rejectNotificationAndCloseRealWindow:(char)fp8;
- (void)rejectNotification;
- (void)blockNotification;
- (void)clearKnockKnock;
- (void)_blockSheetDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)_chatStatusChanged:fp8;
- (void)_realWindowWillClose:fp8;
- (void)_realWindowDidResize:fp8;
- (void)_realWindowResignedMain:fp8;
- (void)_realWindowBeginSheet:fp8;
- (void)_realWindowEndSheet:fp8;
- (void)_appWillHide:fp8;
- (void)_appDidUnhide:fp8;
- (void)windowDidMove:fp8;
- (void)windowWillClose:fp8;

@end

@interface XHTMLEncoder:NSObject
{
}

+ (void)initialize;
+ (void)encodeText:fp8 asXHTML:(char)fp12 into:fp16 charsToEncode:fp20;
+ (void)encodeText:fp8 asXHTML:(char)fp12 into:fp16;
+ encodeText:fp8 asXHTML:(char)fp12;
+ encodeNonAsciiCharsIn:fp8 asXHTML:(char)fp12;
+ stripTagsFromHTML:fp8;

@end

@interface AnimatingTableView:FezExtendedTableView
{
    char _animationEnabled;
    NSMutableArray *_refArray;
    NSMutableArray *_indexMapping;
    NSTimer *_timer;
    NSDate *_startTime;
    double _animationTime;
    int _curTableRows;
    struct _NSRange _movementRange;
    struct _NSRect _movementRect;
    double _spline;
    NSImage **_rowCache;
    int _rowCacheSize;
}

- (float)_normalRowOffset:(int)fp8;
- (struct _NSPoint)_animatedRowOrigin:(int)fp8;
- (void)_clearRowCache;
- (void)_finishAnimation;
- (void)dealloc;
- (void)logDebugInfo;
- _mappingFromRefArray;
- (void)rememberIndexes;
- (void)animateMovementOverTime:(double)fp8;
- (void)oneStep:fp8;
- (void)setAnimationEnabled:(char)fp8;
- (char)isAnimationEnabled;
- (char)drawsSelection;
- (void)_drawHighlightForRowCache;
- (void)drawRow:(int)fp8 clipRect:(struct _NSRect)fp12;
- (struct _NSRect)frameOfCellAtColumn:(int)fp8 row:(int)fp12;
- (struct _NSRange)rowsInRect:(struct _NSRect)fp8;
- (int)numberOfRows;
- (void)tile;
- (void)reloadData;

@end

@interface ABPerson(Fez)
+ cardFromPasteboardContent:fp8;
+ cardFromVCardData:fp8;
+ cardWithFirstName:fp8 lastName:fp12;
- (char)mergeVCardWithABPerson:fp8;
- bestAddressBookMatch;
- (void)setFirstName:fp8 lastName:fp12;
- fullName;
- firstName;
- (void)setFirstName:fp8;
- lastName;
- (void)setLastName:fp8;
- emails;
- (void)setEmails:fp8;
- (char)isInAddressBook;
- (void)setID:fp8 forProperty:fp12 withLabel:fp16;
- _allAIMHandles;
- macDotComEmails;
- macDotComEmail;
- aimHandles;
- (void)appendID:fp8 toProperty:fp12 withLabel:fp16;
@end

@interface ABAddressBook(Fez)
- existingABPersonWithFirstName:fp8 lastName:fp12;
- existingABPersonWithFirstName:fp8 andLastName:fp12 orEmail:fp16;
- existingABPersonForPerson:fp8;
@end

@interface DaemonicIncomingFile:IncomingFile <FZXferListener>
{
    unsigned long _startTime;
    NSBundle *_fezBundle;
    char _xferStarted;
}

+ stringFromError:(int)fp8;
- initWithFZXfer:fp8;
- (oneway void)file:fp8 updateProgressCurrentFile:fp12 currentFileNum:(unsigned int)fp16 totalFiles:(unsigned int)fp20 currentFileSentBytes:(unsigned int)fp24 currentFileSize:(unsigned int)fp28 totalSentBytes:(unsigned int)fp32 totalSize:(unsigned int)fp36;
- (oneway void)file:fp8 updateProgressCurrentFileComplete:fp12 result:(int)fp16;
- (oneway void)file:fp8 updateProgressTransferComplete:(int)fp12;
- (oneway void)file:fp8 transferEndedWithError:(int)fp12;
- (char)saveAs:fp8 delegate:fp12;
- downloadedData;
- (void)stopTransfer;

@end

@interface DaemonicOutgoingFile:OutgoingFile <FZXferListener>
{
    unsigned long _startTime;
    unsigned int _totalSize;
    NSBundle *_fezBundle;
}

- initWithFZXfer:fp8;
- (void)setDelegate:fp8;
- (oneway void)file:fp8 updateProgressCurrentFile:fp12 currentFileNum:(unsigned int)fp16 totalFiles:(unsigned int)fp20 currentFileSentBytes:(unsigned int)fp24 currentFileSize:(unsigned int)fp28 totalSentBytes:(unsigned int)fp32 totalSize:(unsigned int)fp36;
- (oneway void)file:fp8 updateProgressCurrentFileComplete:fp12 result:(int)fp16;
- (oneway void)file:fp8 updateProgressTransferComplete:(int)fp12;
- (oneway void)file:fp8 transferEndedWithError:(int)fp12;
- (void)stopTransfer;

@end

@interface FileProgress:NSWindowController <FileTransferDelegate>
{
    NSTextField *_messageField;
    NSTextField *_itemField;
    NSTextField *_progressField;
    NSTextField *_timeRemainingField;
    NSProgressIndicator *_progressBar;
    Presentity *_buddy;
    Chat *_chat;
    IncomingFile *_inFile;
    OutgoingFile *_outFile;
    char _isIncoming;
    int _action;
}

+ (void)setNextWindowTopCenter:(struct _NSPoint)fp8;
+ (void)setWindowControllerForFileTransferPlacement:fp8;
+ openOnOutgoingFile:fp8 sender:fp12 chat:fp16;
+ openOnIncomingFile:fp8 sender:fp12 chat:fp16;
+ openOnIncomingFile:fp8 sender:fp12 action:(int)fp16;
+ fileTransferList;
+ (char)anyActiveFileTransfers;
- (void)_addSelfToFileTransferList;
- (void)abortFileTransfer:fp8;
- initOutgoingWithSender:fp8 outgoingFile:fp12 chat:fp16;
- initIncomingWithSender:fp8 incomingFile:fp12 chat:fp16;
- (void)dealloc;
- (void)windowDidLoad;
- (void)stop:fp8;
- buddy;
- (char)isDirectory;
- (void)_finished;
- (void)currentFile:fp8 currentFileSize:(unsigned int)fp12 currentSentBytes:(unsigned int)fp16 totalTransferProgress:(float)fp20 timeRemaining:fp24 message:fp28;

@end

@interface NameTableCell:NSCell
{
    PeopleController *_peopleController;
    char _oneLine;
    char _disabled;
    int _imageIndex;
    struct _NSRect _imageRect;
}

- initWithPeopleController:fp8;
- copyWithZone:(struct _NSZone *)fp8;
- (void)_redisplay:fp8;
- (char)trackMouseDown:fp8 inRect:(struct _NSRect)fp12 ofView:fp28;
- (char)continueTracking:(struct _NSPoint)fp8 at:(struct _NSPoint)fp16 inView:fp24;
- (void)stopTracking:(struct _NSPoint)fp8 at:(struct _NSPoint)fp16 inView:fp24 mouseIsUp:(char)fp28;
- (char)_tracking;
- (void)setOneLine:(char)fp8;
- (char)oneLine;
- (void)setDisabled:(char)fp8;
- (char)isDisabled;
- _currentImage;
- (void)_setNoImage;
- (void)_setImageIsVideo:(char)fp8 state:(int)fp12;
- (void)_setImageState:(int)fp8;
- (void)setNoImage;
- (char)hasImage;
- (void)setImageIsVideo:(char)fp8 state:(int)fp12;
- (void)setImageState:(int)fp8;
- (char)imageIsVideo;
- (int)imageState;
- (struct _NSSize)imageSize;
- (struct _NSRect)imageRectForFrame:(struct _NSRect)fp8;
- (void)drawInteriorWithFrame:(struct _NSRect)fp8 inView:fp24;

@end

@interface PeoplePicker:NSObject
{
    ABPeoplePickerController *peoplePickerController;
    NSWindow *_window;
    NSView *pickerView;
}

- init;
- (void)dealloc;
- (void)awakeFromNib;
- peoplePickerController;
- (void)enableMultiplePeopleSelection:(char)fp8;

@end

@interface AccountVerifier:NSObject
{
    NSWindow *window;
    NSTextField *_firstName;
    NSTextField *_lastName;
    NSPopUpButton *_accountTypePopUp;
    ExtendedTextField *_accountName;
    NSSecureTextField *_accountPassword;
    NSButton *_okButton;
    NSString *_macDotComEmail;
    NSString *_iToolsAccount;
    NSString *_aimHandle;
    NSString *_fieldValue;
    FezStartupController *startupController;
    char meRecordExists;
}

- (void)awakeFromNib;
- (void)dealloc;
- (void)setStartupController:fp8;
- (void)setMacDotComEmail:fp8;
- (void)setAIMHandle:fp8;
- (void)setIToolsAccount:fp8;
- (void)setFieldValue:fp8;
- (void)_storeAccountNameForInternetConfig:fp8;
- (void)_storeAccountNameForFez:fp8;
- _passwordForIToolsAccount:fp8;
- (char)_hasAllInformation;
- (char)getAccountInfo;
- (void)stopModalWindow:fp8;
- (void)signUp:fp8;
- (void)clearFields:fp8;
- (void)controlTextDidChange:fp8;
- (void)displayAccountInfo:fp8;

@end

@interface StagedFileNotifier:NSWindowController <FileTransferDelegate, FileDragOutViewDelegate>
{
    NSView *_fromView;
    NSImageView *_picture;
    NSTextField *_name;
    FileDragOutView *_fileIcon;
    NSTextField *_fileInfo;
    NSButton *_notifyAccept;
    NSButton *_notifyReject;
    NSButton *_notifyBlock;
    StagedChatNotifier *_notifier;
    Presentity *_sender;
    IncomingFile *_file;
    char _forceSaveAs;
    int _action;
    NSString *_originalSaveTitle;
}

+ stagedFileNotifierWithFile:fp8 sender:fp12 notifier:fp16;
- initNotifierWithIncomingFile:fp8 sender:fp12 notifier:fp16;
- fromView;
- (void)dealloc;
- (void)windowDidLoad;
- (void)flagsChanged:fp8;
- (void)acceptButtonPressed:fp8;
- (void)savePanelDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)_replaceSheetDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)fileDoubleClicked:fp8;
- (void)file:fp8 draggedTo:fp12 isDuplicate:(char)fp16;
- (void)internalFile:fp8 draggedTo:fp12 isDuplicate:(char)fp16;
- (void)rejectButtonPressed:fp8;
- (void)blockButtonPressed:fp8;
- (void)currentFile:fp8 currentFileSize:(unsigned int)fp12 currentSentBytes:(unsigned int)fp16 totalTransferProgress:(float)fp20 timeRemaining:fp24 message:fp28;

@end

@interface FileDragOutView:NSImageView
{
    IncomingFile *_file;
    id _delegate;
    struct _NSPoint _clickLoc;
    NSString *_dropPath;
    char _isDup;
}

- (void)setFile:fp8;
- (void)dealloc;
- (void)setDelegate:fp8;
- (void)mouseDown:fp8;
- (void)mouseDragged:fp8;
- (unsigned int)draggingSourceOperationMaskForLocal:(char)fp8;
- (void)pasteboard:fp8 provideDataForType:fp12;
- (void)draggedImage:fp8 endedAt:(struct _NSPoint)fp12 operation:(unsigned int)fp20;

@end

@interface FezStartupController:NSObject
{
    NSWindow *window;
    NSProgressIndicator *progressIndicator;
    AccountVerifier *accountVerifier;
    NSWindow *instructionsPanel;
    char databaseFound;
    char meRecordFound;
    char setupCompleted;
}

- (char)isSetupComplete;
- init;
- (void)dealloc;
- (void)finishSetup;
- (void)databaseConversionDidBegin:fp8;
- (void)databaseConversionDidEnd:fp8;
- (void)startConversion;
- (char)_oldDatabaseExists;
- (char)setup;
- (void)setWantsRendezvousChat:fp8;

@end

@interface Prefs_Blocking:NSPreferencesModule
{
    NSMatrix *blockingModeMatrix;
    NSTextField *blockingInfoLabel;
    NSButton *blockIdleCheckbox;
    NSButton *blockAddressesCheckbox;
    NSButton *editAllowListButton;
    NSButton *editBlockListButton;
    BlockListController *blockListController;
    int oldStatus;
}

- init;
- (void)dealloc;
- (void)awakeFromNib;
- viewForPreferenceNamed:fp8;
- (void)updateUI;
- (void)_serviceLoginStatusChanged:fp8;
- (char)isResizable;
- (void)willBeDisplayed;
- (void)blockingModeChanged:fp8;
- (void)allowIdleChanged:fp8;
- (void)blockAddressesChanged:fp8;

@end

@interface BlockListController:NSObject
{
    NSView *prefsView;
    NSPanel *editListPanel;
    NSButton *addButton;
    NSButton *deleteButton;
    NSTableView *tableView;
    NSTextField *tableLabel;
    Prefs_Blocking *prefsController;
    char _dirty;
    char _blockStopEditing;
    int _mode;
    NSMutableArray *_list;
}

- (void)dealloc;
- (void)_setupControls;
- (void)_showList;
- (void)_listEditingDidEnd:fp8 returnCode:(int)fp12 contextInfo:fp16;
- (void)showBlockList:fp8;
- (void)showAllowList:fp8;
- (void)doneEditing:fp8;
- (void)addRow:fp8;
- (void)deleteRow:fp8;
- (void)tableViewSelectionDidChange:fp8;
- (void)controlTextDidBeginEditing:fp8;
- (void)controlTextDidEndEditing:fp8;
- (int)numberOfRowsInTableView:fp8;
- tableView:fp8 objectValueForTableColumn:fp12 row:(int)fp16;
- (void)_stopEditing:fp8;
- (void)_emptyList;
- (void)tableView:fp8 setObjectValue:fp12 forTableColumn:fp16 row:(int)fp20;
- (char)tableView:fp8 shouldEditTableColumn:fp12 row:(int)fp16;

@end

@interface PrefsBlockingTableView:NSTableView
{
}

- (void)textDidEndEditing:fp8;

@end

@interface ServicePopUp:NSPopUpButton
{
    unsigned int _requiredCapabilities;
    NSMutableArray *_disabled;
}

- (void)dealloc;
- (void)_updateMenu;
- (void)awakeFromNib;
- (void)requireCapabilities:(unsigned int)fp8;
- (void)disableService:fp8;
- (void)serviceStatusChanged:fp8;
- selectedService;
- (void)selectService:fp8;

@end

@interface DaemonicService:IMService
{
}

+ alloc;

@end

@interface FolderViewerDoc:ViewerDoc
{
    IncomingFolderURL *_incoming;
    NSOutlineView *_outline;
    NSButton *_openButton;
    NSButton *_saveButton;
    NSTextField *_fromField;
}

- (char)setupFromIncomingFile:fp8;
- (void)dealloc;
- windowNibName;
- (void)windowControllerDidLoadNib:fp8;
- nodeForOutlineItem:fp8;
- outlineView:fp8 child:(int)fp12 ofItem:fp16;
- (char)outlineView:fp8 isItemExpandable:fp12;
- (int)outlineView:fp8 numberOfChildrenOfItem:fp12;
- outlineView:fp8 objectValueForTableColumn:fp12 byItem:fp16;
- (void)outlineView:fp8 willDisplayCell:fp12 forTableColumn:fp16 item:fp20;
- _selectedNode;
- (void)_saveSelectionOrOpen:(char)fp8;
- (void)openSelection:fp8;
- (void)saveSelection:fp8;
- (void)outlineViewSelectionDidChange:fp8;
- dataRepresentationOfType:fp8;
- (char)readFromURL:fp8 ofType:fp12;

@end

@interface TextViewerDoc:ViewerDoc
{
    NSAttributedString *_text;
    NSDictionary *_docAttrs;
    NSTextView *_textView;
}

- (void)dealloc;
- windowNibName;
- (void)windowControllerDidLoadNib:fp8;
- (char)loadDataRepresentation:fp8 ofType:fp12;
- (char)writeToFile:fp8 ofType:fp12;

@end

@interface MovieViewerDoc:ViewerDoc
{
    NSMovie *_movie;
    NSMovieView *_movieView;
    char _alreadyOpened;
}

+ openOnMP3Stream:fp8 sender:fp12 inPeopleController:fp16;
+ (long)openStreamInITunes:fp8;
- (void)dealloc;
- windowNibName;
- (void)windowControllerDidLoadNib:fp8;
- (char)windowShouldClose:fp8;
- (char)readFromURL:fp8 ofType:fp12;
- (char)readFromFile:fp8 ofType:fp12;
- (char)loadDataRepresentation:fp8 ofType:fp12;
- (char)writeToFile:fp8 ofType:fp12;

@end

@interface ImageViewerDoc:ViewerDoc
{
    NSData *_sourceData;
    NSImage *_image;
    NSImageView *_imageView;
}

- (char)setupFromIncomingFile:fp8;
- (void)dealloc;
- windowNibName;
- (void)windowControllerDidLoadNib:fp8;
- (char)loadDataRepresentation:fp8 ofType:fp12;
- (char)writeToFile:fp8 ofType:fp12;

@end

@interface ViewerDoc:NSDocument
{
    unsigned int _hfsType;
    unsigned int _hfsCreator;
    unsigned short _hfsFlags;
    NSString *_name;
    NSString *_mimeType;
    char _saveDisabled;
    PeopleController *_centerOnController;
    Person *_centerOnPerson;
}

+ _docClassForViewingMIMEType:fp8 canStream:(char *)fp12;
+ (int)canViewIncomingFile:fp8;
+ (int)canViewMIMEType:fp8;
+ (char)openOnIncomingFile:fp8 streaming:(char)fp12;
- (char)setupFromIncomingFile:fp8;
- (void)close;
- (void)dealloc;
- (void)_setFileAttributes:fp8;
- (void)positionWindowOnPerson:fp8 inPeopleController:fp12;
- (void)windowControllerDidLoadNib:fp8;
- (void)setSaveEnabled:(char)fp8;
- (char)saveEnabled;
- (char)validateMenuItem:fp8;

@end

@interface OpenGLLayer:NSObject
{
    unsigned int maskTextureID;
    unsigned int layerWidth;
    unsigned int layerHeight;
    unsigned int textureCapability;
    unsigned int pixelFormat;
    unsigned int pixelType;
    struct _CompositorPoint position;
    struct _CompositorPoint dimensions;
    float opacity;
    float bordercolor[4];
    unsigned char flags;
    void *prior;
    void *next;
    char layerIsValid;
    char isVisible;
    NSString *name;
    NSMutableDictionary *userInfo;
    STR layerMask;
    char maskChanged;
    unsigned int autoresizingMask;
    NSMutableArray *subLayers;
    unsigned int positionInSubLayers;
    float zOrder;
    OpenGLLayerModel *layerModel;
}

+ (void)initialize;
+ (struct _NSSize)CIFSize;
+ sequentialLayerName:fp8;
+ (char)supportsGL_APPLE_client_storage;
+ (char)supportsGL_EXT_texture_rectangle;
+ (char)supportsGL_APPLE_ycbcr_422;
+ (char)supportsGL_ARB_multitexture;
- initWithFrame:(struct _NSRect)fp8;
- (void)dealloc;
- description;
- (void)setLayerIsValid:(char)fp8;
- (void)setIsVisible:(char)fp8;
- (void)setIsVisible:(char)fp8 recursive:(char)fp12;
- (char)isVisible;
- userInfo;
- (void)setUserInfo:fp8;
- (void)_parentMovedFrom:(struct _CompositorPoint)fp8 to:(struct _CompositorPoint)fp16;
- (struct _NSPoint)location;
- (void)setLocation:(struct _NSPoint)fp8;
- (void)_parent:fp8 resizedFrom:(struct _CompositorPoint)fp12 to:(struct _CompositorPoint)fp20;
- (struct _NSSize)size;
- (void)setSize:(struct _NSSize)fp8;
- (void)setAutoresizingMask:(unsigned int)fp8;
- (unsigned int)autoresizingMask;
- (void)containerViewResizedFrom:(struct _NSSize)fp8 to:(struct _NSSize)fp16;
- name;
- (void)setName:fp8;
- (void)setOpacity:(float)fp8;
- (float)opacity;
- (void)_setLayerModel:fp8;
- layerModel;
- (void)setUsesAlphaBlending:(char)fp8;
- (void)updateBuffer;
- (void)compositeLayer;
- subLayers;
- allLayers;
- (int)positionInSubLayers;
- (void)addSubLayer:fp8 underSelf:(char)fp12 underSiblings:(char)fp16;
- (char)removeSubLayer:fp8;
- subLayerWithName:fp8;
- subLayerWithPrefix:fp8;
- (int)relativePositionOfSubLayer:fp8;
- (void)takeSubLayersFrom:fp8;
- (void)performSelector:(SEL)fp8 recursive:(char)fp12;
- (void)recursiveCompositeLayer;
- (char)containsPoint:(struct _NSPoint)fp8;
- (int)handleMouseUpAtPoint:(struct _NSPoint)fp8;
- (int)handleMouseDownAtPoint:(struct _NSPoint)fp8;
- (int)handleMouseDraggedAtPoint:(struct _NSPoint)fp8;

@end

@interface NSWindowGraphicsContext(CGLayerContext)
- initWithCoreGraphicsContext:(struct CGContext *)fp8;
@end

@interface OpenGLLayerModel:NSObject
{
    NSMutableArray *layers;
    OpenGLLayer *specialLayers[2];
    char needsDisplay;
}

- init;
- (void)dealloc;
- (void)setNeedsDisplay:(char)fp8;
- (char)needsDisplay;
- (void)addLayer:fp8;
- (void)removeLayer:fp8;
- layers;
- allLayers;
- layerWithName:fp8;
- (void)addSpecialLayer:(int)fp8 layer:fp12;
- specialLayer:(int)fp8;
- (void)addRemoteVCLayer:fp8;
- (void)addLocalVCLayer:fp8;
- remoteVCLayer;
- localVCLayer;
- (void)makeAllLayersPerformSelector:(SEL)fp8;
- (void)moveLayer:fp8 positionedAbove:(char)fp12 relativeTo:fp16;
- (void)compositeAllLayers;
- layerContainingPoint:(struct _NSPoint)fp8;

@end

@interface OpenGLLayerView:NSOpenGLView
{
    OpenGLLayerModel *layerModel;
    OpenGLLayer *selectedlayer;
    struct _NSPoint selectpointoffset;
    NSImage *offscreenImage;
    STR buffer;
    float bgRed;
    float bgGreen;
    float bgBlue;
    char viewportNeedsUpdate;
    char suspendDrawing;
}

- initWithFrame:(struct _NSRect)fp8 masterContext:fp24;
- initWithFrame:(struct _NSRect)fp8;
- (void)dealloc;
- (char)isFlipped;
- (void)setLayerModel:fp8;
- layerModel;
- (void)setViewportNeedsUpdate:(char)fp8;
- (void)setViewportSize:(struct _NSSize)fp8;
- (void)setFrameSize:(struct _NSSize)fp8;
- (void)compositeLayers;
- (void)handleSuspendDrawing:fp8;
- (void)handleResumeDrawing:fp8;
- (void)drawRect:(struct _NSRect)fp8;
- (void)drawGLBackground;
- bitmapImageFromSurfaceInRect:(struct _NSRect)fp8;
- bitmapImageFromSurface;
- (void)hideGLSurfaceAndDisplaySnapshot;
- (void)unhideGLSurface;
- (void)setBackgroundRed:(float)fp8 green:(float)fp12 blue:(float)fp16;
- (void)setBackgroundGray:(float)fp8;
- (void)setBackgroundColor:fp8;
- (struct _NSSize)adjustWindow:fp8 proposedSize:(struct _NSSize)fp12;
- (char)saveVideoSnapshotToFile:fp8;

@end

@interface OpenGLVideoConferenceLayer:OpenGLTextureLayer
{
    int scalingType;
    char isLocal;
}

- initWithSize:(struct _NSSize)fp8 layerName:fp16 isRemote:(char)fp20;
- (void)dealloc;
- (void)setScalingType:(int)fp8;
- (int)scalingType;
- (void)videoConferenceFrameDidChange;
- (void)render;
- (void)renderTexture;

@end

@interface VideoConferenceLayerView:OpenGLLayerView
{
    VideoChatController *_videoChatController;
    VCLayoutController *_layoutController;
}

- initWithFrame:(struct _NSRect)fp8 videoChatController:fp24;
- (void)dealloc;
- (void)setLayerModel:fp8;
- videoChatController;
- (void)resetCursorRects;
- (void)resetLayout;
- (char)acceptsFirstResponder;
- (void)mouseDown:fp8;
- (void)mouseUp:fp8;
- (void)mouseMoved:fp8;
- (void)mouseDragged:fp8;
- (void)setFrameSize:(struct _NSSize)fp8;
- (void)viewDidEndLiveResize;
- layoutController;
- (unsigned int)draggingSourceOperationMask;
- (unsigned int)_operationForDrag:fp8;
- (unsigned int)draggingEntered:fp8;
- (unsigned int)draggingUpdated:fp8;
- (void)draggingExited:fp8;
- (char)prepareForDragOperation:fp8;
- (char)performDragOperation:fp8;
- (void)concludeDragOperation:fp8;

@end

@interface FileBrowser:NSWindowController
{
    Presentity *_source;
    FolderNode *_root;
    NSString *_headerFormat;
    NSOutlineView *_outline;
    NSImageView *_sourcePicture;
    NSTextField *_header;
    NSProgressIndicator *_spinner;
    NSButton *_openButton;
    NSButton *_saveButton;
}

+ openFileShareBrowserForPresentity:fp8;
- initWithSource:fp8 rootFolder:fp12;
- initWithSource:fp8;
- (void)dealloc;
- (void)windowDidLoad;
- (void)windowWillClose:fp8;
- source;
- (void)_syncSpinner;
- (void)_syncHeader;
- (void)_requestDirectoryContents:fp8;
- (void)_receivedDirectory:fp8;
- (void)_sourceChanged:fp8;
- (void)sourceOfflineSheetDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)_sourcePictureChanged:fp8;
- nodeForOutlineItem:fp8;
- (char)outlineView:fp8 isItemExpandable:fp12;
- (int)outlineView:fp8 numberOfChildrenOfItem:fp12;
- outlineView:fp8 child:(int)fp12 ofItem:fp16;
- outlineView:fp8 objectValueForTableColumn:fp12 byItem:fp16;
- (void)outlineView:fp8 willDisplayCell:fp12 forTableColumn:fp16 item:fp20;
- _selectedNode;
- (void)_saveSelectionOrOpen:(char)fp8;
- (void)openSelection:fp8;
- (void)saveSelection:fp8;
- (void)refreshList:fp8;
- (void)composeEMail:fp8;
- (void)sendMessage:fp8;
- (void)sendDirectMessage:fp8;
- (void)startChat:fp8;
- (void)outlineViewSelectionDidChange:fp8;
- (char)validateMenuItem:fp8;

@end

@interface FolderNodeParser:NSObject <Node>
{
    NSURL *_url;
    FolderNode *_root;
}

- initWithContentsOfURL:fp8;
- initWithXMLFolderData:fp8 fromURL:fp12;
- (void)dealloc;
- root;
- createChild:fp8;
- (void)addText:fp8;
- (void)childFinished:fp8;
- (void)finished;

@end

@interface FolderNode:FileNode
{
    NSMutableArray *_contents;
    NSArray *_visibleContents;
    NSURL *_url;
    int _contentsKnown:1;
    int _contentsRequested:1;
}

- initWithParent:fp8 header:fp12;
- (void)dealloc;
- URL;
- (void)_setURL:fp8;
- createChild:fp8;
- (char)totalSizeKnown;
- (unsigned int)totalSize;
- icon;
- kind;
- children;
- (char)childrenKnown;
- (char)childrenRequested;
- (void)setChildrenRequested:(char)fp8;
- (char)isFolder;
- (char)recursiveChildrenRequested;
- visibleChildren;
- (char)isVisiblyFolder;
- firstChild;
- childNamed:fp8;
- followPath:fp8;
- (void)replaceContentsWith:fp8;
- createIncomingFile;

@end

@interface FileNode:NullNode
{
    FolderNode *_parent;
    NSString *_name;
    NSString *_mimeType;
    struct ? _meta;
    NSImage *_icon;
    NSString *_kind;
}

- initWithParent:fp8 header:fp12;
- (void)dealloc;
- createChild:fp8;
- name;
- (const struct ? *)metadata;
- (char)totalSizeKnown;
- (unsigned int)totalSize;
- (char)isFolder;
- (char)isVisiblyFolder;
- parent;
- (char)isInvisible;
- (void)_setParent:fp8;
- totalSizeDisplayString;
- root;
- path;
- description;
- URL;
- nextNode;
- (void)replaceContentsWith:fp8;
- createIncomingFile;
- _createTempFile;
- MIMEType;
- icon;
- kind;

@end

@interface Prefs_FileXfer:NSPreferencesModule
{
    NSButton *_enableAIMCheckbox;
    NSButton *_enableRendezvousCheckbox;
    NSTextField *_pathField;
    NSPopUpButton *_accessPopUp;
}

- init;
- (void)dealloc;
- _sharePoint;
- (void)_setupCheckbox:fp8 forServiceNamed:fp12;
- (void)_setupPointPathField;
- (void)_setupBlockPopUp;
- viewForPreferenceNamed:fp8;
- (void)willBeDisplayed;
- (void)moduleWasInstalled;
- (void)toggleSharing:fp8;
- (void)chooseFolder:fp8;
- (void)openPanelDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)setAccess:fp8;

@end

@interface OpenGLCGBitmapContextLayer:OpenGLTextureLayer
{
    struct CGContext *cgBitmapContext;
    char shouldReverseRender;
    int textureMappingType;
    float borderLeft;
    float borderRight;
    float borderTop;
    float borderBottom;
    char mapCenter;
}

- initWithSize:(struct _NSSize)fp8 layerName:fp16;
- (void)dealloc;
- (void)setTextureMappingType:(int)fp8;
- (void)setBorderTextureMappingInsetLeft:(float)fp8 right:(float)fp12 top:(float)fp16 bottom:(float)fp20;
- (int)textureMappingType;
- (void)setMapCenter:(char)fp8;
- (void)setShouldReverseRender:(char)fp8;
- (void)clearContext;
- (void)invalidateLayer;
- (void)updateBuffer;
- (void)draw;
- (void)_renderTexture;
- (void)renderUnscaledTexture;
- (void)renderBorder;
- (void)renderTexture;

@end

@interface OpenGLPNGLayer:OpenGLCGBitmapContextLayer
{
    struct CGImage *image;
}

- initWithSize:(struct _NSSize)fp8 layerName:fp16 fileURL:fp20;
- (void)dealloc;
- (void)draw;

@end

@interface OpenGLFullScreenController:NSObject
{
    OpenGLFullScreenWindow *fullScreenWindow;
    VideoConferenceLayerView *vcLayerView;
    OpenGLLayerModel *layerModel;
    NSView *originalVCLayerViewContainer;
    struct _NSRect originalVCLayerViewFrame;
    VideoChatController *videoChatController;
    struct _NSPoint localLocation;
    float redMin;
    float redMax;
    float redGamma;
    float greenMin;
    float greenMax;
    float greenGamma;
    float blueMin;
    float blueMax;
    float blueGamma;
    int scalingType;
    char dockAutohidePref;
    char conferenceEnding;
    unsigned int displayCount;
    struct _CGDirectDisplayID *vcDirectDisplayID;
    float debounceTime;
    double totalGammaFadeTime;
    double gammaFadePauseTime;
    double showDockTimeStamp;
}

- (struct _CGDirectDisplayID *)fullScreenIDForController:fp8;
- (char)isFullScreenCapableForController:fp8 display:(struct _CGDirectDisplayID *)fp12;
- initWithVideoChatController:fp8;
- (void)dealloc;
- videoChatController;
- (void)fade:(int)fp8;
- (void)handleAppWillResignActiveApplication:fp8;
- (void)windowDidResignMain:fp8;
- (void)setupFullScreenDisplay;
- (void)shutDownFullScreenDisplay;
- (void)setConferenceEnding:(char)fp8;
- (void)displayLayers;
- (void)setScalingType:(int)fp8;
- (void)toggleFullScreen:fp8;
- (void)updateMinibar;
- (void)toggleMute:fp8;
- (void)togglePause:fp8;
- (char)validateMenuItem:fp8;
- (void)copy:fp8;

@end

@interface InputArea:NSView
{
    NSView *_minibar;
    AnimatingTabView *_tabView;
    NSButton *_vcInviteButton;
    NSButton *_vcAcceptFromTextButton;
    NSButton *_vcAcceptVCOnlyButton;
    float _minHeight;
    int _mode;
}

- (void)awakeFromNib;
- (void)_setTabViewStretchy:(char)fp8;
- (float)setMode:(int)fp8;
- (int)mode;
- (float)minHeight;
- tabView;
- (void)tabView:fp8 willSwitchFromTab:(int)fp12 toTab:(int)fp16 effect:(int *)fp20 direction:(int *)fp24;
- (void)tabViewTransitionWillBegin:fp8;
- (void)tabViewTransitionDidFinish:fp8;

@end

@interface SocketStream:NSObject
{
    struct __CFReadStream *_in;
    struct __CFWriteStream *_out;
    struct ? _streamCallbackContext;
    STR _readBuffer;
    NSMutableData *_outBuffer;
    char _inOpened;
    char _outOpened;
    char _closing;
    struct __CFHTTPMessage *_httpResponse;
    double _connectTimeout;
    NSTimer *_connectTimer;
}

- init;
- (void)dealloc;
- (void)setConnectTimeout:(double)fp8;
- (struct ?)connectToHost:fp8 port:(unsigned short)fp12 security:(struct __CFString *)fp16;
- (struct ?)connectToHTTPURL:fp8 method:fp12 extraHeaders:fp16;
- (struct ?)connectToSocket:(int)fp8;
- (struct ?)_finishConnecting:(char)fp8;
- (void)_stopConnectionTimer;
- (void)_connectTimedOut;
- (void)disconnect;
- (void)close;
- (void)_finishClosing;
- (struct __CFReadStream *)inputStream;
- (struct __CFWriteStream *)outputStream;
- (struct ?)inputError;
- (struct ?)outputError;
- (char)inputOpened;
- (char)outputOpened;
- valueOfResponseHeader:fp8;
- (void)_errorOccurred:(void *)fp8;
- (void)errorOccurred:(struct ?)fp8 onStream:(void *)fp16;
- (void)_openCompleted:(void *)fp8;
- (void)openCompleted:(void *)fp8;
- (void)dataReceived:fp8;
- (void)EOFReached;
- (void)_dataReceived;
- (long)_writeFromBuffer;
- (char)writeData:fp8;
- (char)isReadyForData;
- (void)pleaseSendMoreData;
- (void)_canAcceptBytes;

@end

@interface IncomingFileStream:SocketStream
{
    IncomingFileURL *_owner;
    NSString *_filePath;
    struct FSRef _fileFSRef;
    NSMutableData *_header;
    char _isAppleSingle;
    struct _NSRange _dataRange;
    struct _NSRange _rsrcRange;
    NSMutableDictionary *_fileAttributes;
    unsigned int _inputPos;
    short _dataForkRef;
    short _rsrcForkRef;
    int _state;
}

- initWithIncomingFileURL:fp8;
- (void)dealloc;
- (void)_closeOutput;
- (void)disconnect;
- (char)saveAs:fp8;
- (int)_parseAppleSingleHeader:fp8;
- (char)_writeBytes:(const void *)fp8 len:(unsigned long)fp12 toFork:(short *)fp16 withRange:(struct _NSRange)fp20;
- (char)_parseBytes:(const void *)fp8 length:(unsigned long)fp12 atEOF:(char)fp16;
- (void)errorOccurred:(struct ?)fp8 onStream:(void *)fp16;
- (void)openCompleted:(void *)fp8;
- (void)dataReceived:fp8;
- (void)EOFReached;

@end

@interface ChooseBuddyButton:MenuButton
{
    int _nCustomItems;
    IMService *_service;
    Person *_selectedPerson;
    char _registered;
    char _menuIsValid;
    NSImage *_savedImage;
    NSWindow *_customIDSheet;
    ExtendedTextField *_customIDText;
    NSButton *_customIDOK;
}

- (void)awakeFromNib;
- (void)dealloc;
- (void)setService:fp8;
- selectedPerson;
- (void)_registerForNotifications;
- (void)_personChanged:fp8;
- (void)_buddyListChanged:fp8;
- (void)_addItemForPerson:fp8 toMenu:fp12 showingDetails:(char)fp16;
- (void)_rebuildBuddyMenu;
- (void)mouseDown:fp8;
- (void)_selectPerson:fp8;
- (void)_personSelected:fp8;
- (void)chooseCustomID:fp8;
- (void)windowDidUpdate:fp8;
- (void)acceptCustomID:fp8;
- (void)cancelCustomID:fp8;
- (void)_chooseIDDidEnd:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)setEnabled:(char)fp8;
- (void)drawRect:(struct _NSRect)fp8;

@end

@interface NSObject(ChooseBuddyButtonDelegate)
- (void)chooseBuddySheetCanceled:fp8;
@end

@interface BuddyIconCell:NSCell
{
    PeopleController *_peopleController;
    struct _NSSize _iconSize;
}

- initWithPeopleController:fp8;
- (void)setIconSize:(struct _NSSize)fp8;
- (struct _NSSize)iconSize;
- (void)drawInteriorWithFrame:(struct _NSRect)fp8 inView:fp24;

@end

@interface VCInfoController:NSWindowController
{
    NSTimer *_statsTimer;
    NSTextField *_statRemoteFramerateAverage;
    NSTextField *_statRemoteBitrateAverage;
    NSTextField *_statLocalFramerateAverage;
    NSTextField *_statLocalBitrateAverage;
    NSTextField *_statVideoNetworkIndicator;
    NSProgressIndicator *_statVideoNetworkProgressIndicator;
    NSTextField *_statAudioNetworkIndicator;
    NSProgressIndicator *_statAudioNetworkProgressIndicator;
    NSTextField *_callDuration;
    NSView *_errorLogContainer;
    NSTextView *_errorLogTextView;
}

+ (void)showInfoWindow;
+ (void)addErrorLog:fp8;
+ (void)clearErrorLogs;
- (void)awakeFromNib;
- (char)windowShouldClose:fp8;
- (struct _NSRect)windowWillUseStandardFrame:fp8 defaultFrame:(struct _NSRect)fp12;
- (void)dealloc;
- (void)_resizeWindowBy:(float)fp8;
- (void)_updateErrorLogUI;
- (void)refreshStats:fp8;

@end

@interface OpenGLAttributedStringLayer:OpenGLCGBitmapContextLayer
{
    NSAttributedString *attributedString;
    struct CGShadowStyle shadowStyle;
    struct CGStyle *style;
    struct _NSSize cacheSize;
}

- initWithAttributedString:fp8 layerName:fp12;
- (void)dealloc;
- attributedString;
- (void)draw;
- (void)setSize:(struct _NSSize)fp8;

@end

@interface OpenGLBannerLayer:OpenGLCGBitmapContextLayer
{
    struct CGImage *_cgBuddyIcon;
    struct CGImage *_cgVCIcon;
    NSAttributedString *_bannerTitle;
    NSAttributedString *_bannerName;
    char _nameOnTop;
    struct CGShadowStyle shadowStyle;
    struct CGStyle *style;
    NSView *_bannerView;
    char _useBuddyIcon;
}

- initWithBuddyIcon:fp8 bannerTitle:fp12 bannerName:fp16 nameOnTop:(char)fp20 isAudio:(char)fp24 useOpenGL:(char)fp28 layerName:fp32;
- initAsPause:(char)fp8 useOpenGL:(char)fp12 layerName:fp16;
- (void)dealloc;
- (void)_setBannerView:fp8;
- (void)_drawIcon:(struct CGImage *)fp8 inContext:(struct CGContext *)fp12;
- (void)_drawIconsInContext:(struct CGContext *)fp8;
- (void)_drawTitlesInContext:(struct CGContext *)fp8;
- (void)draw;
- (void)renderTexture;
- (void)setSize:(struct _NSSize)fp8;
- (void)drawBannerInView:fp8;
- (float)minWidthToFitText;

@end

@interface OpenGLTextureLayer:OpenGLLayer
{
    unsigned short bytesPerPixel;
    id renderDelegate;
    unsigned int rowBytes;
    int layerType;
    char textureInitialized;
    unsigned int textureWidth;
    unsigned int textureHeight;
    unsigned int textureID;
    float blackTint;
    char applicationIsTerminating;
    char needsPixelClipping;
}

- initWithSize:(struct _NSSize)fp8 layerName:fp16 layerType:(int)fp20;
- (void)dealloc;
- (unsigned long)textureID;
- (void)setLayerWidth:(unsigned long)fp8 height:(unsigned long)fp12;
- (void)setOpenGLTextureDataProvider:fp8;
- (int)layerType;
- renderDelegate;
- (void)setRenderDelegate:fp8;
- (void)_updateAlphaBlending;
- (void)setBlackTint:(float)fp8;
- (void)setOpacity:(float)fp8;
- (float)blackTint;
- userInfo;
- (void)setUserInfo:fp8;
- (void)setTextureID:(unsigned long)fp8;
- (void)setupTexture;
- (void)updateBuffer;
- (void)insertMaskIntoARGBLayer;
- (void)invalidateLayer;
- (void)reverseRenderTexture;
- (void)renderTexture;
- (void)compositeLayer;
- (void)setTextureInitialized:(char)fp8;
- (struct _NSSize)layerSize;
- (struct _NSSize)textureSize;
- textureDataProvider;
- (STR)buffer;
- (void)handleProviderBufferDidChangeNotification:fp8;
- (void)handleApplicationWillTerminate:fp8;

@end

@interface OpenGLProgressLayer:OpenGLCGBitmapContextLayer
{
    struct CGImage **_images;
    NSTimer *_redrawTimer;
    NSDate *_spinStartDate;
}

- initWithSize:(struct _NSSize)fp8 layerName:fp16;
- (void)setIsVisible:(char)fp8 recursive:(char)fp12;
- (void)dealloc;
- (void)draw;
- (void)setSize:(struct _NSSize)fp8;

@end

@interface CoreGraphicsUtilities:NSObject
{
}

+ (struct CGImage *)CGImageFromNSImage:fp8;

@end

@interface EffectView:NSView
{
    NSImage *_startImage;
    NSImage *_endImage;
    NSDate *_startTime;
    double _effectTime;
    int _effect;
    int _direction;
    float _prevProgress;
}

- initWithFrame:(struct _NSRect)fp8 startImage:fp24 endImage:fp28;
- (void)dealloc;
- (void)doEffect:(int)fp8 direction:(int)fp12 time:(double)fp16;
- (void)_doFadeEffect:(float)fp8 inRect:(struct _NSRect)fp12;
- (void)_doSlideEffect:(float)fp8 inRect:(struct _NSRect)fp12 moveOld:(char)fp28 moveNew:(char)fp32;
- (void)_doZoomEffect:(float)fp8 inRect:(struct _NSRect)fp12 scale:(char)fp28;
- (void)_doSplitEffect:(float)fp8 inRect:(struct _NSRect)fp12 horiz:(char)fp28 wipe:(char)fp32;
- (void)_setNeedsDisplay;
- (void)drawRect:(struct _NSRect)fp8;
- (char)doingEffect;

@end

@interface AnimatingTabView:NSTabView
{
    char _transitionsEnabled;
    char _synchronous;
    double _transitionTime;
    EffectView *_effectView;
}

- (void)_commonInit;
- initWithFrame:(struct _NSRect)fp8;
- initWithCoder:fp8;
- (void)setTransitionsEnabled:(char)fp8;
- (char)areTransitionsEnabled;
- (void)setSynchronous:(char)fp8;
- (char)isSynchronous;
- (void)setTransitionTime:(double)fp8;
- (double)transitionTime;
- (char)inTransition;
- _imageOfCurrentTabView;
- _scratchWindowWithVerticalAdjustment:(float)fp8;
- (void)_newTabViewItem:fp8 currentImage:(id *)fp12 newImage:(id *)fp16;
- (void)_notifyDelegate:(SEL)fp8;
- (void)_effectComplete;
- (void)selectTabViewItem:fp8;

@end

@interface OpenGLMinibarLayer:OpenGLCGBitmapContextLayer
{
    struct CGImage *cgEndButtonImage;
    struct CGImage *cgEndButtonDownImage;
    struct CGImage *cgMuteButtonImage;
    struct CGImage *cgMuteButtonDownImage;
    struct CGImage *cgFullScreenButtonImage;
    struct CGImage *cgFullScreenButtonDownImage;
    struct CGRect endButtonRect;
    struct CGRect muteButtonRect;
    struct CGRect fullScreenButtonRect;
    char muteButtonOn;
    int mouseDownButton;
    char mouseDownButtonHighlighted;
}

- initWithLayerName:fp8;
- (void)dealloc;
- (struct _NSRect)endButtonFrame;
- (struct _NSRect)muteButtonFrame;
- (struct _NSRect)fullScreenButtonFrame;
- (void)draw;
- (char)rect:(struct CGRect)fp8 containsPoint:(struct _NSPoint)fp24;
- (int)handleMouseUpAtPoint:(struct _NSPoint)fp8;
- (int)handleMouseDownAtPoint:(struct _NSPoint)fp8;
- (int)handleMouseDraggedAtPoint:(struct _NSPoint)fp8;
- (void)setMuteButtonOn:(char)fp8;

@end

@interface CenteredView:NSView
{
    char _horiz;
    char _vert;
}

- (void)superviewDidResize;
- (void)awakeFromNib;
- (void)dealloc;
- (void)setCenteredHoriz:(char)fp8;
- (void)setCenteredVert:(char)fp8;
- (char)centeredHoriz;
- (char)centeredVert;

@end



@interface ExtendedTextField:NSTextField
{
    char _allowsLineBreaks;
    char _romanOnly;
    char _switchedToRoman;
}

+ (struct _NSRange)_rangeOfNewlinesInString:fp8 range:(struct _NSRange)fp12;
- (void)awakeFromNib;
- (void)dealloc;
- (void)setAllowsLineBreaks:(char)fp8;
- (char)allowsLineBreaks;
- (void)setRomanOnly:(char)fp8;
- (char)isRomanOnly;
- (char)textView:fp8 doCommandBySelector:(SEL)fp12;
- (void)textDidChange:fp8;
- (void)_disableKeyboardMenu;
- (char)becomeFirstResponder;
- (void)windowDidBecomeKey:fp8;
- (void)_restoreKeyboardMenu;
- (void)textDidEndEditing:fp8;
- (void)windowDidResignKey:fp8;
- (void)setEnabled:(char)fp8;

@end

@interface SmileyCell:NSButtonCell
{
}

- (void)drawInteriorWithFrame:(struct _NSRect)fp8 inView:fp24;

@end

@interface SmileyGrid:NSMatrix
{
}

- (void)_layoutCells:(int)fp8;
- (void)setUpWithImages:fp8;
- (void)highlightCell:(char)fp8 atPosition:(int)fp12;
- (int)arrowKeyDown:(unsigned short)fp8 fromSelectedItem:(int)fp12;

@end

@interface SmileyButton:NSButton
{
}

- (void)mouseDown:fp8;

@end

@interface SmileyPicker:NSObject
{
    NSView *_smileyView;
    SmileyGrid *_smileyGrid;
    NSTextField *_smileyNameField;
    NSTextField *_smileyTextField;
    NSWindow *_window;
    NSTimer *_timer;
    int _numFlashes;
}

+ smileyList;
+ smileyMenuItems;
+ smileyNumber:(int)fp8;
+ installSmileyButtonInView:fp8 margin:(struct _NSSize)fp12;
+ pickSmileyFromButton:fp8;
- (struct _NSRect)windowFrameForSmileyButton:fp8;
- (void)_updateTextFieldsForItem:(int)fp8;
- (int)_trackMenuSelection;
- (void)_fadeOut:fp8;
- (void)_doFlash:fp8;
- (void)_flashItem:(int)fp8;
- (int)_trackMouseDownInWindow:fp8 withSelectedItem:(int)fp12;
- (int)_runKeyboardEventLoop;
- (int)_runEventLoop;
- (int)pickSmileyFromButton:fp8;
- (void)awakeFromNib;

@end

@interface Prefs_Camera:NSPreferencesModule
{
    CollapseView *cameraCollapseView;
    NSPopUpButton *cameraPulldownMenu;
    CollapseView *micCollapseView;
    NSPopUpButton *micPulldownMenu;
    CollapseView *soundOutputDeviceCollapseView;
    NSPopUpButton *soundOutputDevicePulldownMenu;
    NSTabView *cameraTabView;
    CameraPreferencesView *cameraView;
    NSTextField *noCameraTextField;
    CollapseView *volumeCollapseView;
    VolumeIndicator *volumeIndicator;
    AudioInputSampler *audioInputSampler;
    CollapseView *lightingCollapseView;
    NSPopUpButton *bandwidthPulldownMenu;
    DisclosureButton *settingsButton;
    CollapseView *settingsCollapseView;
    CameraSettingsController *settingsController;
    NSButton *launchOnCameraCheckbox;
    NSButton *repeatedRingCheckbox;
    char stayingOnVideoPrefs;
    char videoPrefsWindowWasClosed;
    char didCancel;
}

- (void)dealloc;
- (char)isResizable;
- viewForPreferenceNamed:fp8;
- (void)saveChanges;
- (void)willBeDisplayed;
- (void)moduleWasInstalled;
- (void)moduleWillBeRemoved;
- (void)_updateUIElement:(int)fp8 animate:(char)fp12;
- _noneStr;
- (int)_updateDeviceList:fp8 name:fp12 popUp:fp16;
- (int)_updateCameraList;
- (int)_updateMicList;
- (int)_updateSoundOutputDeviceList;
- (void)_startStopAV;
- (void)_prefsChangedNotification:fp8;
- (void)changeCamera:fp8;
- (void)changeMicrophone:fp8;
- (void)changeSoundOutputDevice:fp8;
- (void)_setBandwidth:(unsigned int)fp8;
- (void)changeBandwidth:fp8;
- (void)changeLaunchOnCamera:fp8;
- (void)changeRepeatedRing:fp8;
- (void)toggleSettings:fp8;
- (void)privateResizeHack;
- (void)setStayingOnVideoPrefs:(char)fp8;
- (char)videoPrefsWindowWasClosed;
- (void)setVideoPrefsWindowWasClosed:(char)fp8;
- (void)setDidCancel:(char)fp8;

@end

@interface NSPreferencesModule(PrivateImpls)
- (void)setMinSize:(struct _NSSize)fp8;
@end

@interface CameraPreferencesView:OpenGLLayerView
{
    OpenGLTextureLayer *_layer;
    OpenGLLayerModel *_model;
    struct _NSRect _oldTrackingRect;
    char _videoCapable;
    char _abortedVideo;
    char _videoIsStarted;
    NSString *_videoErrorMessage;
    char registeredForNotifications;
}

- initWithFrame:(struct _NSRect)fp8;
- (void)dealloc;
- videoErrorMessage;
- (void)setVideoErrorMessage:fp8;
- layerName;
- (void)createLayerWithName:fp8;
- (void)_irisStateNotification:fp8;
- (void)_cameraChangedNotification:fp8;
- (char)videoIsStarted;
- (void)_removeCameraPrefsNotifications;
- (char)canStartVideo;
- (void)startVideo;
- (void)restartVideo;
- (void)abortVideo;
- (void)stopVideo;
- (void)mouseDown:fp8;
- (void)setCameraOnState:(char)fp8;
- (void)drawRect:(struct _NSRect)fp8;
- (void)handleNewFrame:fp8;
- (void)setFrame:(struct _NSRect)fp8;
- (void)reshape;
- (void)handleShutdownAVPreview:fp8;

@end

@interface AutoAway:NSObject
{
    NSPanel *_welcomeBackPanel;
    NSTextField *_messageField;
    NSButton *_dontShowAgainCheckbox;
    NSString *_availableMessage;
    char _idleWhileAway;
    char _canceledWelcomeBack;
    char _autoAway;
    NSTimer *_autoAwayTimer;
}

+ (void)install;
+ (int)welcomeBackMode;
+ (void)setWelcomeBackMode:(int)fp8;
+ (char)autoAwayEnabled;
+ (void)setAutoAwayEnabled:(char)fp8;
+ (double)autoAwayDelay;
+ (void)setAutoAwayDelay:(double)fp8;
- init;
- (void)dealloc;
- (void)_myStatusChanged:fp8;
- (void)_welcomeBack;
- (void)_autoAwayTimerFired;
- (void)_clearAutoAwayTimer;
- (void)_startAutoAwayTimer;
- (void)awakeFromNib;
- (void)goAvailable:fp8;
- (void)dontGoAvailable:fp8;
- (void)windowWillClose:fp8;

@end

@interface RecentPicture:NSObject
{
    NSString *_originalImageName;
    NSImage *_originalImage;
    struct _NSRect _crop;
    NSData *_smallIconData;
}

+ pictureDirPath;
+ (int)maxRecents;
+ _infoFilePath;
+ (char)purgeExtras;
+ (void)_saveChanges;
+ recentPictures;
+ recentSmallIcons;
+ currentPicture;
+ (void)noCurrentPicture;
+ (void)removeAllButCurrent;
- initWithOriginalImage:fp8 crop:(struct _NSRect)fp12 smallIcon:fp28;
- initWithOriginalImage:fp8;
- initWithInfo:fp8;
- (void)dealloc;
- _infoToSave;
- originalImagePath;
- originalImage;
- croppedImage;
- smallIcon;
- (struct _NSRect)crop;
- (void)setCrop:(struct _NSRect)fp8 smallIcon:fp24;
- (void)_removePermanently;
- (void)setCurrent;

@end

@interface DVDPopUpItemMatrix:NSMatrix
{
}

- (void)mouseDown:fp8;

@end

@interface DVDPopUpMatrixButton:NSButton
{
    IconPopUp *_popUp;
}

- iconPopUp;
- (void)dealloc;
- (void)mouseDown:fp8;
- (void)addItemWithTitle:fp8;
- (void)addItemsWithTitles:fp8;
- (void)insertItemWithTitle:fp8 atIndex:(int)fp12;
- (void)addItemWithImage:fp8;
- (void)addItemsWithImages:fp8;
- (void)insertItemWithImage:fp8 atIndex:(int)fp12;
- (int)indexOfSelectedItem;
- (void)selectItemAtIndex:(int)fp8;
- itemArray;
- (int)numberOfItems;
- (int)numberOfItemsPerRow;
- (void)setNumberOfItemsPerRow:(int)fp8;
- (struct _NSSize)itemSize;
- (void)setItemSize:(struct _NSSize)fp8;

@end

@interface DVDPopUpMatrixItemCell:NSMenuItemCell
{
}

- (void)drawImageWithFrame:(struct _NSRect)fp8 inView:fp24;
- (void)drawInteriorWithFrame:(struct _NSRect)fp8 inView:fp24;

@end

@interface IconPopUp:NSObject
{
    NSMutableArray *menuItems;
    DVDPopUpItemMatrix *menuMatrix;
    DVDPopUpItemMatrix *textMatrix;
    NSTextField *titleField;
    unsigned int nIconItems;
    NSWindow *menuWind;
    unsigned int numItemsPerRow;
    unsigned int minNumberOfRows;
    unsigned int selectedItem;
    NSTimer *fadeTimer;
    NSTimer *flashTimer;
    char isFading;
    char isFlashing;
    int flashCount;
}

- init;
- (void)dealloc;
- (int)_updateSelectedItem:(int)fp8 forKeyDown:(unsigned short)fp12;
- (void)_highlightSelectedItem:(int)fp8;
- (int)_trackMouseDownInWindow:fp8 withSelectedItem:(int)fp12;
- (int)trackKeyEvent:fp8 inView:fp12;
- (int)trackMouseEvent:fp8 inView:fp12;
- (int)popUpWithEvent:fp8 inView:fp12;
- (void)setTitle:fp8;
- (void)addItemWithTitle:fp8;
- (void)addItemsWithTitles:fp8;
- (void)insertItemWithTitle:fp8 atIndex:(int)fp12;
- (void)addItemWithImage:fp8;
- (void)addItemsWithImages:fp8;
- (void)addItemsWithImagesInReverseOrder:fp8;
- (void)insertItemWithImage:fp8 atIndex:(int)fp12;
- (int)indexOfSelectedItem;
- imageOfSelectedItem;
- (void)selectItemAtIndex:(int)fp8;
- itemArray;
- (int)numberOfItems;
- (int)numberOfImageItems;
- (int)numberOfItemsPerRow;
- (void)setNumberOfItemsPerRow:(int)fp8;
- (void)setMinNumberOfRows:(int)fp8;
- (struct _NSSize)itemSize;
- (void)setItemSize:(struct _NSSize)fp8;
- (struct _NSSize)itemSpacing;
- (void)setItemSpacing:(struct _NSSize)fp8;
- (void)_popUpMenuFromView:fp8;
- (void)_emptyMatrix:fp8;
- (void)_updateMenuMatrix;
- (int)_trackMenuSelectionInMatrix:fp8;
- (int)_trackMenuSelection;
- (void)_flashSelectedPopUpItem;
- (void)fadePopUpWindowImmediately;
- (void)_fadePopUpWindow;

@end

@interface OpenGLTextureController:NSObject
{
    NSWindow *masterWindow;
    NSOpenGLContext *masterOpenGLContext;
    NSOpenGLView *masterOpenGLView;
    unsigned int remoteVideoTextureID;
    unsigned int localVideoTextureID;
    unsigned int bannerLayerTextureID;
    unsigned int previewLabelLayerTextureID;
    unsigned int bannerTextLayerTextureID;
    unsigned int progressLayerTextureID;
    unsigned int localBorderLayerTextureID;
    NSMutableDictionary *providerMap;
    NSMutableDictionary *textureIDMap;
    OpenGLTextureDataProvider *delayedProvider;
    char noRemotePackets;
}

+ openGLTextureController;
+ (char)hasActiveLocalVideoClients;
- init;
- (void)dealloc;
- masterOpenGLContext;
- masterOpenGLView;
- (void)setNoRemotePackets:(char)fp8;
- (void)startStreamForLayer:fp8;
- (unsigned long)textureIDForLayerWithName:fp8;
- providerForTextureID:(unsigned long)fp8;
- videoProviderForLayer:fp8 size:(struct _NSSize)fp12;
- imageProviderForLayer:fp8 size:(struct _NSSize)fp12;
- providerForLayer:fp8 size:(struct _NSSize)fp12;
- (void)handleVCConferenceDidEnd:fp8;
- (void)removeLayer:fp8;
- (void)handleLayerWillDeallocateNotification:fp8;

@end

@interface NSMutableDictionary(PrivateConvenienceMethods)
- objectForIntKey:(int)fp8;
- (void)setObject:fp8 forIntKey:(int)fp12;
- (void)removeObjectForIntKey:(int)fp8;
- (int)intForKey:fp8;
- (void)setInt:(int)fp8 forKey:fp12;
@end

@interface OpenGLTextureDataProvider:NSObject
{
    STR buffer;
    STR waitingToBeFreedPreviewBuffer;
    char hasPushedData;
    unsigned int textureID;
    unsigned int layerType;
    unsigned int bytesPerPixel;
    unsigned int textureCapability;
    unsigned int textureWidth;
    unsigned int textureHeight;
    unsigned int pixelFormat;
    unsigned int pixelType;
    unsigned int layerWidth;
    unsigned int layerHeight;
    int clientCount;
    int bufferType;
    STR layerMask;
    unsigned int maskTextureID;
    char maskChanged;
    char doSetup;
    char postedResumeDrawing;
    int skippedFrameCount;
}

- (STR)bufferForSize:(struct _NSSize)fp8;
- initWithSize:(struct _NSSize)fp8 layerType:(int)fp16;
- (void)dealloc;
- (void)setBufferType:(int)fp8;
- (unsigned long)layerWidth;
- (unsigned long)layerHeight;
- (unsigned int)textureWidth;
- (unsigned int)textureHeight;
- (STR)buffer;
- (void)setTextureID:(unsigned long)fp8;
- (unsigned long)textureID;
- (void)setHasPushedData:(char)fp8;
- (void)handleNewFrame:fp8;
- (unsigned long)setupTexture;
- (unsigned long)invalidateLayer;
- (void)handleVCStoppedUsingPreviewBuffer:fp8;
- (void)verifyBufferForSize:(struct _NSSize)fp8;
- (unsigned int)clientCount;
- (void)incrementClientCount;
- (void)decrementClientCount;
- (void)handleFreeBuffer:fp8;
- (void)waitForFreeNotification;
- (void)release;
- (void)convertYUVToARGB:fp8 isRemote:(char)fp12;

@end

@interface AutoManualSlider:NSSlider
{
}

- (double)logicalValue;
- (void)setLogicalValue:(double)fp8;
- (char)automatic;
- (void)constrainValueWhileDragging;
- (char)sendAction:(SEL)fp8 to:fp12;

@end

@interface AudioChatController:AVChatController
{
    VolumeIndicator *_volumeIndicator;
    NSTextField *_statusField;
    NSProgressIndicator *_progressIndicator;
    NSTextField *_messageField;
    float _messageTabWindowHeight;
    char _referToConnectionDoctor;
}

+ (char)isVideoController;
- windowNibName;
- (void)windowDidLoad;
- (void)windowWillClose:fp8;
- (void)_selectTab:(int)fp8;
- _stringForChatState:(int)fp8;
- longWindowTitle;
- (struct _NSRect)_textReplyWindowFrame;
- (void)toggleMute:fp8;
- (void)_setMessage:fp8;
- (void)logError:fp8;
- (void)avChat:fp8 changedToState:(int)fp12 fromState:(int)fp16;

@end

@interface AVChat:NSObject
{
    int _state;
    Presentity *_presentity;
    AVChatController *_owner;
    char _isCaller;
    char _isVideo;
    char _dataOut;
    char _dataIn;
    char _Q8IrisOpen;
    FZVideoConferenceController *_vcc;
    NSData *_connectData;
    NSDictionary *_callerProperties;
    char _isListening;
    char _isPreviewing;
    char _isCounterProposalConnect;
    char _hasPendingAccept;
    char _hasPendingInit;
    int _pendingResponse;
    int _errorCode;
    NSDictionary *_errorDict;
    char _didRemoteMute;
    char _didRemotePause;
    char _localNetworkStall;
    char _remoteNetworkStall;
    char _isTerminating;
    char _isFrameworkReady;
    char _iTunesStateChanged;
    char _needToSendEndConferenceNotification;
    NSTimer *_timeoutTimer;
    NSTimer *_screenSaverBlockingTimer;
}

+ (void)_updateActiveConference;
+ chatList;
+ activeConference;
+ (char)isPersonInActiveConference:fp8;
+ avChatWaitingForReplyFromPresentity:fp8;
+ _chatForPresentity:fp8 owner:fp12 asCaller:(char)fp16 video:(char)fp20;
+ (char)isStateFinal:(int)fp8;
+ (char)isStateActive:(int)fp8;
+ (char)shouldAcceptIncomingVideoConferenceRequestFromUser:fp8;
- (void)_updatePresentityInBuddyList;
- initWithPresentity:fp8 owner:fp12 asCaller:(char)fp16 video:(char)fp20;
- (void)setCallerProperties:fp8;
- (void)goToFirstState;
- (void)_destroyTimer:(id *)fp8;
- (void)dealloc;
- description;
- (void)clearOwner;
- owner;
- presentity;
- (char)isCaller;
- (char)isVideo;
- (char)isStateFinal;
- (char)isStateActive;
- (void)_blockScreenSaver:fp8;
- (void)_subscribeToVCNotifications;
- (void)_setState:(int)fp8;
- (void)_setStateDisconnected;
- (int)state;
- (char)isPreviewing;
- (char)dataOut;
- (char)dataIn;
- (void)inviteToConference;
- (void)cancelInvitation;
- (void)acceptInvitation:(char)fp8;
- (void)timeoutTimerTriggered:fp8;
- (void)connectWithData:fp8;
- (void)startVCOnMainThread:fp8;
- (void)_reportError:fp8;
- (void)_counterPropose:fp8;
- (void)connectProc:fp8;
- (int)errorCode;
- errorDictionary;
- (void)_setErrorDictionary:fp8;
- (void)_setActiveConference;
- (void)endConference;
- (void)setMute:(char)fp8;
- (char)isMute;
- (void)toggleMute;
- (void)setPaused:(char)fp8;
- (char)isPaused;
- (void)togglePaused;
- (char)isQ8IrisOpen;
- (void)setRemoteMute:(char)fp8;
- (char)isRemoteMute;
- (void)toggleRemoteMute;
- (void)setRemotePaused:(char)fp8;
- (char)isRemotePaused;
- (void)toggleRemotePaused;
- (char)didRemoteMute;
- (char)didRemotePause;
- (char)isLocalNetworkStalled;
- (char)isRemoteNetworkStalled;
- (float)audioVolume;
- (void)setAudioVolume:(float)fp8;
- _createResponseDictionary:(int)fp8;
- (char)_notifySystemVC:(char)fp8;
- (void)handleStatusChanged:fp8;
- (void)handleVideoConferenceNotification:fp8;
- (char)_shouldAcceptIncomingVideoConferenceRequestFromUser:fp8;

@end

@interface AVChatController:NSWindowController
{
    NSWindow *_avWindow;
    AnimatingTabView *_phaseTab;
    MuteButton *_muteButton;
    NSSlider *_volumeSlider;
    StagedChatNotifier *_notifier;
    AVChat *_avChat;
    NSString *_errorMessage;
    char _handledAVShutdown;
}

+ initiateInvitationTo:fp8;
+ receiveInvitationFrom:fp8 notifier:fp12;
+ (char)isVideoController;
- description;
- initWithPresentity:fp8 asCaller:(char)fp12 notifier:fp16;
- (void)_vcCapsChanged;
- (void)windowDidLoad;
- (void)windowWillClose:fp8;
- (void)dealloc;
- avChat;
- (void)showSelectedBuddyInfo:fp8;
- (void)showInAddressBook:fp8;
- (void)addABuddy:fp8;
- (void)startChat:fp8;
- (void)sendMessage:fp8;
- (void)sendDirectMessage:fp8;
- (void)composeEMail:fp8;
- (void)sendFile:fp8;
- (void)acceptVC:fp8;
- (void)declineVC:fp8;
- (void)textReplyVC:fp8;
- (void)endConference:fp8;
- (void)toggleMute:fp8;
- (void)volumeChanged:fp8;
- (char)validateMenuItem:fp8;
- shortWindowTitle;
- longWindowTitle;
- (void)_updateWindowTitle;
- (void)windowDidResize:fp8;
- (struct _NSRect)_textReplyWindowFrame;
- (void)tabView:fp8 willSwitchFromTab:(int)fp12 toTab:(int)fp16 effect:(int *)fp20 direction:(int *)fp24;
- (void)_setErrorMessage:fp8;
- _errorLogForNoPackets:fp8 isAudio:(char)fp12;
- _errorLogForDict:fp8;
- (void)logError:fp8;
- (void)avChat:fp8 changedToState:(int)fp12 fromState:(int)fp16;
- (void)avChatIrisStateChanged:fp8;
- (void)avChatRemoteMuteOrPausedChanged:fp8;
- (void)avChatLocalNetworkStallChanged:fp8;
- (void)avChatRemoteNetworkStallChanged:fp8;
- (void)handleShutdownAVConference:fp8;

@end

@interface VideoChatController:AVChatController
{
    MetalDivider *_vcBox;
    NSButton *_fullScreenButton;
    VideoConferenceLayerView *_vcLayerView;
    NSTimer *_timer;
    OpenGLLayerModel *_layerModel;
    OpenGLFullScreenController *_fullScreenController;
    int _restoreTab;
    struct _NSSize _savedMinSize;
}

+ (char)isVideoController;
- initWithPresentity:fp8 asCaller:(char)fp12 notifier:fp16;
- (void)dealloc;
- vcLayerView;
- (void)_setupBannerContent;
- (void)_setupPreview;
- (void)_setupVC;
- (void)_displayLayers:fp8;
- (void)_handleFrameNotification:fp8;
- (void)_listenForVideoFrame:(int)fp8;
- (int)_currentTab;
- (void)_doShowTab:(int)fp8;
- (void)_showTab:(int)fp8;
- windowNibName;
- (void)windowDidLoad;
- (void)windowWillClose:fp8;
- (struct _NSSize)windowWillResize:fp8 toSize:(struct _NSSize)fp12;
- (char)windowShouldZoom:fp8 toFrame:(struct _NSRect)fp12;
- (void)windowWillMiniaturize:fp8;
- (void)windowDidDeminiaturize:fp8;
- (void)_saveWindowFrame;
- (void)_restoreSavedWindowFrame;
- longWindowTitle;
- (void)cancelVCInvite:fp8;
- (void)doVCInvite:fp8;
- (void)_updateRemoteVideoStateIndicators;
- (void)_updateLocalVideoStateIndicators;
- (void)toggleMute:fp8;
- (void)togglePause:fp8;
- (void)toggleFullScreen:fp8;
- (void)stopFullScreen;
- (void)takeVideoSnapshot:fp8;
- (void)toggleShowVideoSettings:fp8;
- (void)copy:fp8;
- (char)validateMenuItem:fp8;
- (void)logError:fp8;
- (void)avChat:fp8 changedToState:(int)fp12 fromState:(int)fp16;
- (void)avChatIrisStateChanged:fp8;
- (void)avChatRemoteMuteOrPausedChanged:fp8;
- (void)avChatLocalNetworkStallChanged:fp8;
- (void)avChatRemoteNetworkStallChanged:fp8;
- (char)canSendFile;
- (char)sendFile:fp8 droppedAtPosition:(struct _NSPoint)fp12;
- (char)showingVideoSettings;
- (void)showVideoSettings:(char)fp8;

@end

@interface VolumeIndicator:NSView
{
    float _floatValue;
    char _isRemote;
    char _isMute;
    NSImage *_onImage;
    NSImage *_offImage;
    NSImage *_muteImage;
    float _numSlices;
}

- _loadScaledImage:fp8;
- (void)_updateNumSlices:(float)fp8;
- (void)awakeFromNib;
- (void)dealloc;
- (void)setFrameSize:(struct _NSSize)fp8;
- (char)mouseDownCanMoveWindow;
- (void)setFloatValue:(float)fp8;
- (float)floatValue;
- (void)takeFloatValueFrom:fp8;
- (void)setNumberValue:fp8;
- (void)setRemote:(char)fp8;
- (char)isRemote;
- (void)setMute:(char)fp8;
- (char)isMute;
- (void)toggleMute:fp8;
- (float)_splicePointFor:(float)fp8;
- (void)_invalidateValue:(float)fp8 to:(float)fp12;
- (void)drawRect:(struct _NSRect)fp8;

@end

@interface MetalDivider:NSBox
{
}

+ (void)initialize;
- (void)awakeFromNib;
- (void)drawRect:(struct _NSRect)fp8;

@end

@interface RecessedButton:NSButton
{
}

- _buttonImageDefault:(char)fp8 down:(char)fp12;
- (void)_drawImage:fp8 inBounds:(struct _NSRect)fp12;
- (char)_isDefaultButton;
- (void)drawRect:(struct _NSRect)fp8;
- (void)mouseDown:fp8;

@end

@interface RecessedTextField:NSTextField
{
}

- (void)drawRect:(struct _NSRect)fp8;

@end

@interface OpenGLFullScreenWindow:NSWindow
{
    OpenGLFullScreenController *openGLFullScreenController;
}

- initWithContentRect:(struct _NSRect)fp8 styleMask:(unsigned int)fp24 backing:(int)fp28 defer:(char)fp32 controller:fp36 screen:fp40;
- (char)canBecomeKeyWindow;
- (char)canBecomeMainWindow;
- (void)keyDown:fp8;

@end

@interface AudioOutputSampler:AudioInputSampler
{
}

+ (id *)sharedSampler;
- (float)level;
- (void)_addObserver:fp8;
- (char)_removeObserver:fp8;

@end

@interface AudioInputSampler:NSObject
{
    NSMutableSet *_observers;
    NSTimer *_levelTimer;
    FZVideoConferenceController *_vcc;
}

+ (id *)sharedSampler;
+ (void)addObserver:fp8;
+ (void)removeObserver:fp8;
- init;
- (void)dealloc;
- (void)_setObserverLevels:fp8;
- (void)startSampling;
- (void)stopSampling;
- (void)_addObserver:fp8;
- (char)_removeObserver:fp8;
- (float)level;
- (void)broadcastMicLevel:fp8;

@end

@interface VCLayoutController:NSObject
{
    VideoConferenceLayerView *_container;
    OpenGLLayerModel *_layerModel;
    char _isPreview;
    char _isFullScreen;
    char _hasPIP;
    NSDate *_transitionStartTime;
    NSTimer *_timer;
    float _PIPScale;
    struct _RectPosition _PIPPosition;
    NSDate *_bannerSlideStartTime;
    int _trackingRectTag;
    NSString *_bannerLayerName;
}

+ (void)_showMute:(char)fp8 pause:(char)fp12 off:(char)fp16 stalled:(char)fp20 large:(char)fp24 blackOpacity:(float)fp28 inLayer:fp32;
+ (void)showCameraOff:(char)fp8 inLayer:fp12;
- (void)_syncPositionPrefsRead:(char)fp8;
- (void)_syncScalePrefRead:(char)fp8;
- initWithContainer:fp8 videoOut:(char)fp12 videoIn:(char)fp16;
- (void)setLayerModel:fp8;
- (void)stopPreviewTransition;
- (void)dealloc;
- _bannerLayer;
- container;
- (float)PIPScale;
- (struct _RectPosition)PIPPosition;
- (char)isPreview;
- (float)_transitionProgressReverse:(char)fp8;
- (void)setPreview:(char)fp8;
- (void)setFullScreen:(char)fp8;
- (char)isFullScreen;
- (void)_takeSnapshotOf:fp8;
- (void)freezeFrame;
- (void)fitWindowToBannerHorizOnly:(char)fp8;
- (struct _NSSize)_PIPSizeForContainerSize:(struct _NSSize)fp8;
- (struct _NSRect)_PIPFrameForBounds:(struct _NSRect)fp8;
- (struct _NSRect)_bannerFrameLow:(char)fp8;
- (void)_setBanner:fp8 autoresizingMaskLow:(char)fp12;
- (char)_bannerShouldBeLow;
- (void)_updateBannerLayout;
- (void)updateLayout;
- (void)containerDidEndLiveResize;
- _createVCLayerNamed:fp8 size:(struct _NSSize)fp12 isRemote:(char)fp20;
- createPreviewLayer;
- createLocalLayerOfSize:(struct _NSSize)fp8;
- createRemoteLayerOfSize:(struct _NSSize)fp8;
- (void)createWhitePreviewLayer;
- (void)showPreviewLabel:(char)fp8;
- _nextBannerLayerName;
- _removeBanner:fp8 andExtractBG:(char)fp12;
- (void)_installBG:fp8 withFrame:(struct _NSRect)fp12 behindBannerLayer:fp28;
- (void)setBannerIcon:fp8 title:fp12 name:fp16 nameOnTop:(char)fp20 showProgress:(char)fp24;
- (void)removeBanner;
- (void)showConnectionDoctorLabel;
- (void)showLocalMute:(char)fp8 pause:(char)fp12 off:(char)fp16 stalled:(char)fp20;
- (void)showRemoteMute:(char)fp8 pause:(char)fp12 stalled:(char)fp16;
- (unsigned int)_autoresizingMask;
- (void)_createResizeIndicatorIn:fp8;
- (void)_showResizeIndicator;
- (void)_hideResizeIndicator;
- (void)_removeResizeIndicator;
- (void)_addResizeTrackingRect;
- (void)_updateResizeTrackingRect;
- (void)resetCursorRects;
- (void)_addPIPBorderRegular:(char)fp8;
- (float)_maxMinibarWidth;
- (void)_createMinibarForPIP:fp8;
- (void)_hideMinibar;
- (void)_hideMinibarAndCursor;
- (void)_dontHideMinibar;
- (void)_hideMinibarAndCursorAfterDelay;
- (void)_showMinibar;
- (void)_resizePIPWithOriginalSize:(struct _NSSize)fp8;
- (void)_setupBannerSlideForPIPFrame:(struct _NSRect)fp8 slideOnCollision:(char)fp24;
- (void)_slideBanner;
- (void)_finishBannerSlide;
- (void)_animateLayer:fp8 from:(struct _NSRect)fp12 to:(struct _NSRect)fp28;
- (void)_animatePIPFrom:(struct _NSRect)fp8 to:(struct _NSRect)fp24;
- (void)_movePIPWithStartFrame:(struct _NSRect)fp8 baseOffset:(struct _NSSize)fp24 useFistCursor:(char)fp32;
- (void)mouseDownAt:(struct _NSPoint)fp8;
- (void)mouseUpAt:(struct _NSPoint)fp8;
- (void)mouseMovedAt:(struct _NSPoint)fp8;
- (void)mouseEntered:fp8;
- (void)mouseExited:fp8;
- (void)mouseDraggedAt:(struct _NSPoint)fp8;

@end

@interface BalloonRenderer:NSObject
{
}

+ (void)initialize;
- (void)drawBalloonForMessage:fp8 inView:fp12 inRect:(struct _NSRect)fp16 withTailOnRight:(char)fp32;
- (struct _NSRect)addTailToRect:(struct _NSRect)fp8 withTailOnRight:(char)fp24;
- (struct _NSRect)removeTailFromRect:(struct _NSRect)fp8 withTailOnRight:(char)fp24;

@end

@interface ChatInputLineCell:NSTextFieldCell
{
}

- (void)drawInteriorWithFrame:(struct _NSRect)fp8 inView:fp24;
- (void)editWithFrame:(struct _NSRect)fp8 inView:fp24 editor:fp28 delegate:fp32 event:fp36;
- (void)selectWithFrame:(struct _NSRect)fp8 inView:fp24 editor:fp28 delegate:fp32 start:(int)fp36 length:(int)fp40;
- (void)_drawFocusRingWithFrame:(struct _NSRect)fp8;

@end

@interface ChatInputLine:AutoSendTextField
{
    NSButton *_smileyButton;
}

- (void)awakeFromNib;
- (void)dealloc;
- (void)viewDidEndLiveResize;
- _preparedFieldEditor;
- (void)pickSmiley:fp8;
- (void)smileyPicked:fp8;
- (void)_windowDidLoseKey:fp8;

@end

@interface OpenGLMetalLayer:OpenGLCGBitmapContextLayer
{
    struct CGImage *gradientImage;
    struct CGPattern *scratchPattern;
    struct CGColorSpace *scratchPatternSpace;
    struct CGPath *leftPath;
    struct CGPath *rightPath;
    unsigned int width;
    unsigned int height;
    unsigned int halfWidth;
    unsigned int halfHeight;
}

- initWithSize:(struct _NSSize)fp8 cornersOnTop:(char)fp16 layerName:fp20;
- (void)dealloc;
- (void)setSize:(struct _NSSize)fp8;
- (void)drawMetalInRect:(struct CGRect)fp8 clipRect:(struct CGRect)fp24 context:(struct CGContext *)fp40;
- (void)draw;
- (void)renderTexture;

@end

@interface PIWLayer:OpenGLTextureLayer
{
    char reverseRender;
}

- initWithSize:(struct _NSSize)fp8 layerName:fp16;
- (void)setQ8IrisOpen:(char)fp8;
- (void)setFlipped:(char)fp8;
- (char)flipped;
- (void)renderTexture;

@end

@interface CameraSettingsController:NSObject
{
    AutoManualSlider *focusSlider;
    AutoManualSlider *brightnessSlider;
    AutoManualSlider *contrastSlider;
    AutoManualSlider *colorSlider;
    AutoManualSlider *sharpnessSlider;
    NSPopUpButton *lightingPopup;
}

- (void)_prefsChangedNotification:fp8;
- (void)awakeFromNib;
- (void)dealloc;
- (void)refreshSettings:fp8;
- (void)changeColor:fp8;
- (void)changeBrightness:fp8;
- (void)changeConstrast:fp8;
- (void)changeFocus:fp8;
- (void)changeSharpness:fp8;
- (void)changeLighting:fp8;
- (void)resetSettings:fp8;
- (void)saveAllSettings:fp8;

@end

@interface NSPopUpButton(NSPopUpButton_LightingProfileAdditions)
- (int)lightingProfile;
- (void)selectLightingProfile:(int)fp8;
@end

@interface FZVideoConferenceController:VideoConferenceController
{
    char _everOpenedCamera;
    char _openCameraRequired;
    char _recacheSelectedCamera;
    VCCamera *_cachedSelectedCamera;
}

+ (char)hasBeenInitialized;
+ sharedInstance;
+ newcameraList;
- initWithLocalIPAddress:fp8;
- (void)dealloc;
- (void)_postPrefsChangedNotification:fp8;
- (void)_hardwareCapsNotification:fp8;
- (char)setPreferredMic;
- (char)selectMicrophone:fp8;
- _defaultsMicrophone;
- _UIDFromMicrophone:fp8;
- micNamePref;
- (void)_selectSoundOutputDevice;
- (char)selectSoundOutputDevice:fp8;
- soundOutputdeviceNamePref;
- (char)openCamera;
- (int)cancelPreview;
- (char)closeCamera;
- (char)currentCameraIsQ8;
- (char)getCameraIrisState;
- (char)selectCameraByGUID:fp8;
- (void)_selectCamera;
- _defaultsCamera;
- cameraGUIDPref;
- (void)forceCameraRecache;
- selectedCamera;
- (void)setCameraSettingsFromDefaults;
- (char)setColor:(float)fp8;
- (float)color;
- (char)setBrightness:(float)fp8;
- (float)brightness;
- (char)setContrast:(float)fp8;
- (float)contrast;
- (char)setFocus:(float)fp8;
- (float)focus;
- (char)setSharpness:(float)fp8;
- (float)sharpness;
- (int)lightingProfile;

@end

@interface OpenGLColorLayer:OpenGLCGBitmapContextLayer
{
    float redComponent;
    float greenComponent;
    float blueComponent;
    float alphaComponent;
}

- initWithSize:(struct _NSSize)fp8 layerName:fp16;
- initWithSize:(struct _NSSize)fp8 layerName:fp16 deviceRed:(float)fp20 green:(float)fp24 blue:(float)fp28 alpha:(float)fp32;
- (void)setDeviceRed:(float)fp8 green:(float)fp12 blue:(float)fp16 alpha:(float)fp20;
- (void)draw;

@end

@interface OpenGLCapabilities:NSObject
{
    struct GCCaps *glCapabilities;
    int screenCount;
}

+ openGLCapabilities;
+ (long)vramForDisplayID:(struct _CGDirectDisplayID *)fp8;
+ (char)hasLowVideoMemory;
+ (char)canSupportVideoConference;
+ (char)requiresSwitchToDepth16;
+ (char)supportsFullScreenModeForDisplay:(struct _CGDirectDisplayID *)fp8;
+ (char)exceedsOriginalTiBook;
+ (char)isSupportedSystem;
- (void)dealloc;
- extensionsForContext:fp8;
- (const STR)rendererNameForContext:fp8;
- (void)querySystemOpenGLCapabilities;
- (char)requiresDepth16:(struct GCCaps *)fp8;
- (char)supportsGL_EXT_texture_rectangle:(struct GCCaps *)fp8;
- (char)supportsGL_APPLE_ycbcr_422:(struct GCCaps *)fp8;
- (char)supportsGL_APPLE_client_storage:(struct GCCaps *)fp8;
- (char)supportsGL_ARB_multitexture:(struct GCCaps *)fp8;
- (struct GCCaps *)glCapabilities;

@end

@interface MuteButton:NSButton
{
    char _isRemote;
    NSImage *_disabledImage;
}

- (void)dealloc;
- (char)isRemote;
- (void)setRemote:(char)fp8;
- _disabledImage;
- (void)drawRect:(struct _NSRect)fp8;

@end

@interface BuddyPicture:NSObject
{
    NSData *_data;
    NSImage *_image;
    struct _NSSize _size;
    NSMutableArray *_cache;
    Person *_owner;
}

- initWithData:fp8 owner:fp12;
- initWithImage:fp8 owner:fp12;
- (void)dealloc;
- description;
- owner;
- data;
- (struct _NSSize)size;
- (void)cacheImage;
- (void)flushCaches;
- _image;
- image;
- imageWithMaxSize:(int)fp8;
- TIFFRepresentation;
- (void)drawInRect:(struct _NSRect)fp8 operation:(int)fp24 fraction:(float)fp28;
- (void)drawInRect:(struct _NSRect)fp8 inView:fp24 operation:(int)fp28 fraction:(float)fp32;

@end

@interface SelfPreviewController:NSWindowController
{
    MetalDivider *_vcBevel;
    NSPopUpButton *_lightingPopUp;
    CameraPreferencesView *_cameraView;
    NSTabView *_cameraTabView;
    NSTextField *_noCameraTextField;
    VolumeIndicator *_volumeIndicator;
}

+ (void)showSelfPreview;
- (void)_updateUI;
- (void)_startStopAV;
- (void)_setWindowTitle;
- (void)_prefsChangedNotification:fp8;
- (void)windowDidLoad;
- (void)windowWillClose:fp8;
- (struct _NSSize)windowWillResize:fp8 toSize:(struct _NSSize)fp12;
- (void)windowWillMiniaturize:fp8;
- (void)windowDidDeminiaturize:fp8;
- (void)copy:fp8;
- (void)takeVideoSnapshot:fp8;
- (void)lightingChanged:fp8;

@end

@interface BacktracingException:NSException
{
}

+ (void)install;
+ (void)setSignificantRaiseHandler:(UNKNOWN *)fp8;
+ backtraceSkippingFrames:(int)fp8;
+ (void)logBacktraceSkippingFrames:(int)fp8 withMessage:fp12;
+ backtrace;
+ (void)logBacktraceWithMessage:fp8;
- initWithName:fp8 reason:fp12 userInfo:fp16;
- backtrace;
- (void)raise;
- (void)raiseWithoutReporting;

@end

@interface MetalPopUpButton:NSPopUpButton
{
}

- (void)_installCellSubclass;
- (void)awakeFromNib;

@end

@interface MetalPopUpButtonCell:NSPopUpButtonCell
{
    NSImage *_regularImage;
    NSImage *_highlightedImage;
}

- initTextCell:fp8 pullsDown:(char)fp12;
- (void)dealloc;
- (void)_drawImageWithFrame:(struct _NSRect)fp8 inView:fp24;
- (void)drawWithFrame:(struct _NSRect)fp8 inView:fp24;

@end

@interface CollapseView:NSClipView
{
    float _expandedHeight;
}

- initWithFrame:(struct _NSRect)fp8;
- (void)awakeFromNib;
- (char)isCollapsed;
- _highestAncestor:fp8;
- (void)_resizeWindowToFrame:(struct _NSRect)fp8 animate:(char)fp24;
- (void)collapse:(char)fp8;
- (void)collapse:(char)fp8 animate:(char)fp12;
- (void)toggleCollapsed:fp8;
- (void)takeStateFromSender:fp8;

@end

@interface NSView(CollapseView_Additions)
- (void)_setAutoresizingVerticalMask:(int)fp8;
@end

@interface DisclosureButton:NSButton
{
}

- (void)awakeFromNib;

@end

@interface BorderView:NSView
{
    NSColor *_color;
    float _thickness;
}

- (void)_commonInit;
- initWithCoder:fp8;
- initWithFrame:(struct _NSRect)fp8;
- (void)dealloc;
- color;
- (void)setColor:fp8;
- (float)thickness;
- (void)setThickness:(float)fp8;
- (void)drawRect:(struct _NSRect)fp8;

@end

@interface OpenGLCameraPreferencesLayer:OpenGLTextureLayer
{
}

- initWithSize:(struct _NSSize)fp8 layerName:fp16;
- (void)renderTexture;

@end

@interface NicelyScaledImageView:NSImageView
{
}

- (void)drawRect:(struct _NSRect)fp8;

@end

@interface Prefs_General:NSPreferencesModule
{
    NSButton *autoLoginCheckbox;
    NSButton *showStatusMenuCheckbox;
    NSButton *offlineOnQuitCheckbox;
    NSButton *useShapeForStatusCheckbox;
    NSMatrix *welcomeBackMode;
    NSButton *autoAwayCheckbox;
    NSButton *autoAwayTimeField;
    NSButton *enableGroupsCheckbox;
    NSPopUpButton *downloadPathPopupButton;
    NSString *_downloadPath;
}

+ (void)setEnableGroups:(char)fp8;
- (void)dealloc;
- (char)isResizable;
- viewForPreferenceNamed:fp8;
- (void)initializeFromDefaults;
- (void)saveChanges;
- (void)changeOfflineOnQuit:fp8;
- (void)changeShowFezStatus:fp8;
- (void)changeAutoLogin:fp8;
- (void)changeUseShapesForStates:fp8;
- (void)changeWelcomeBackMode:fp8;
- (void)changeAutoAway:fp8;
- (void)changeAutoAwayTime:fp8;
- (void)changeEnableGroups:fp8;
- (void)_updateGroupsCheckbox;
- (void)changeDownloadPath:fp8;
- (void)_pathChosen:fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)_setupDownloadPathMenu;

@end

@interface NetworkChangeNotifier:NSObject
{
    struct __SCDynamicStore *_store;
    struct __CFRunLoopSource *_runLoopSource;
}

+ (char)enableNotifications;
+ (void)disableNotifications;
- (void)_sendNotification;
- (char)_listenForChanges;
- init;
- (void)dealloc;

@end

@interface CustomFontHTMLDocument:HTMLDocument
{
    NSFont *_defaultFont;
}

+ basicAttributedStringWithHTMLString:fp8 defaultFont:fp12;
- (void)dealloc;
- (void)setDefaultFont:fp8;
- defaultFont;
- newDocumentRenderingState;

@end
*/
