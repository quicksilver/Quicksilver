/*!
	@header NDComponentInstance
	@abstract Header file for <tt>NDComponentInstance</tt>.
	@discussion Declare the class <tt>NDComponentInstance</tt> which is used with <tt>NDAppleScriptObject</tt>
 */

#import <Cocoa/Cocoa.h>
#import "NDAppleScriptObject_Protocols.h"

/*!
	@class NDComponentInstance
	@abstract A class to represent a component instance.
	@discussion A component instance is a connection to a component (osa component) used to compile and execute AppleScripts. This class is to be used with <tt>NDAppleScriptObject</tt>.
 */
@interface NDComponentInstance : NSObject <NDAppleScriptObjectSendEvent, NDAppleScriptObjectActive>
{
@private
	ComponentInstance						scriptingComponent;
	id<NDAppleScriptObjectSendEvent>	sendAppleEventTarget;
	id<NDAppleScriptObjectActive>		activeTarget;
	OSASendUPP								defaultSendProcPtr;
	long										defaultSendProcRefCon;
	OSAActiveProcPtr						defaultActiveProcPtr;
	long										defaultActiveProcRefCon;

}

/*!
	@method sharedComponentInstance
	@abstract Returns the shared component instance.
	@discussion This is the single component all <tt>NDAppleScriptObject</tt>s use if you do not give it a <tt>NDComponentInstance</tt>. The shared component instance has a connection with the default OSA Apple component.
	@result  Returns <tt>NDComponentInstance</tt> component.
 */
+ (id)sharedComponentInstance;

/*!
	@method closeSharedComponentInstance
	@abstract Close the shared component instance.
	@discussion This can be called before you application closes or when it has finished with the shared component instance.
 */
+ (void)closeSharedComponentInstance;

/*!
	@method findNextComponent:
	@abstract Finds the next OSA component.
	@discussion Can be used by init methods that take a component parameter so that a script can be connected to it own OSA component. This is useful if you want to execute AppleScripts within separate threads as each OSA component is not thread safe.
	@result  Returns a OSA component.
 */
+ (Component)findNextComponent;

/*!
	@method componentInstance
	@abstract Allocates and initializes a <tt>NDComponentInstance</tt>
	@discussion Returns a <tt>NDComponentInstance</tt> with a connection to the default OSA Apple component.
	@result A <tt>NDComponentInstance</tt>
  */
+ (id)componentInstance;
/*!
	@method componentInstanceWithComponent:
	@abstract Allocates and initializes a <tt>NDComponentInstance</tt>
	@discussion Returns a <tt>NDComponentInstance</tt> with a connection to the supplied component.
	@param component A component, if <tt>NULL</tt> then the default AppleScript component is used..
	@result A <tt>NDComponentInstance</tt>
  */
+ (id)componentInstanceWithComponent:(Component)component;

/*!
	@method init
	@abstract Intializes a <tt>NDComponentInstance</tt>.
	@discussion The receiver opens a connection with the default AppleScript component.
	@result The initialized <tt>NDComponentInstance</tt>
	 */
- (id)init;
/*!
	@method initWithComponent:
	@abstract Intialize a <tt>NDComponentInstance</tt>.
	@discussion The receiver opens a connection with the supplied component.
	@param component A component, if <tt>NULL</tt> then the default AppleScript component is used..
	@result The initialized <tt>NDComponentInstance</tt>
  */
- (id)initWithComponent:(Component)component;

/*!
	@method setFinderAsDefaultTarget.
	@abstract  sets the default target as Finder for any AppleEvents
	@discussion passes the Finders creator code to <tt>setDefaultTargetAsCreator:</tt>.
 */
- (void)setFinderAsDefaultTarget;
	/*!
	@method setDefaultTarget:
	@abstract  sets the default target for any AppleEvents.
	@discussion any AppleEvents not enclosed in a tell statement by default go to the current
				process (your application). With this method you can provide a different default target.
	@param  defaultTarget an <tt>NSAppleEventDescriptor</tt> containing the target descriptor
 */
- (void)setDefaultTarget:(NSAppleEventDescriptor *)defaultTarget;
/*!
	@method setDefaultTargetAsCreator:
	@abstract  sets the default target, specified by creator code, for any AppleEvents
	@discussion same as setDefaultTarget: but passing the creator code of an application to specify the
				target process.
	@param creator an <tt>OSType</tt> creator code of the processes application.
 */
- (void)setDefaultTargetAsCreator:(OSType)creator;
/*!
	@method setAppleEventSendTarget:.
	@abstract  sets the object that any handles any AppleEvent the script atempts to send.
	@discussion If the send target is set any AppleEvents are sent to the send target to be processed, otherwise <tt>NDComponentInstance</tt> will handle the event itself by utilising the OSA default send procedure. One use of this is when executing a script in thread any AppleEvents that require user interaction sent to the current procees need to be sent from the main thread.
	@param  target An object that implements the protocol <tt>NDAppleScriptObjectSendEvent</tt>.
 */
- (void)setAppleEventSendTarget:(id<NDAppleScriptObjectSendEvent>)target;
/*!
	@method appleEventSendTarget
	@abstract returns the object that handles any AppleEvents
	@discussion See the method <tt>setAppleEventSendTarget: </tt>for a discussion.
	@result the AppleEvent send target.
 */
- (id<NDAppleScriptObjectSendEvent>)appleEventSendTarget;

/*!
	@method setActiveTarget:
	@abstract sets the object which is periodicly sent the message <tt>appleScriptActive:</tt>.
	@discussion will the script is running it will periodocly give up time for you to do some other processing.
	@param  target An object that implements the protocol <tt>NDAppleScriptObjectActive</tt>.
 */
- (void)setActiveTarget:(id<NDAppleScriptObjectActive>)target;

/*!
	@method activeTarget
	@abstract returns the active target as set by the method <tt>setActiveTarget:</tt>
	@discussion See the method <tt>setActiveTarget:</tt> for a discussion.
 */
- (id<NDAppleScriptObjectActive>)activeTarget;

@end
