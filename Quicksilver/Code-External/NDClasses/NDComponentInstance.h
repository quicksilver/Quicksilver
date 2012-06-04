/*
	NDComponentInstance.h

	Created by Nathan Day on 20.05.03 under a MIT-style license. 
	Copyright (c) 2008 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */

/*!
	@header NDComponentInstance
	@abstract Header file for <tt>NDComponentInstance</tt>.
	@discussion Declare the class <tt>NDComponentInstance</tt> which is used with <tt>NDScriptData</tt>
	@related NDComponentInstance
	@related NDScriptData
	@related NDScriptData_Protocols
	@version 1.0.0
 */

#import <Cocoa/Cocoa.h>
#import "NDScriptData_Protocols.h"

#ifdef NDTurnLoggingOff
#define NDLogOSAError( OS_ERROR_ ) ((OS_ERROR_) == noErr)
#else
#define NDLogOSAError( OS_ERROR_ ) NDLogOSStatusBody( (OS_ERROR_), __FILE__, __func__, __LINE__, # OS_ERROR_, stringForOSAError )
#endif

NSString * stringForOSAError( const OSStatus anError );

extern const NSString	* NDAppleScriptOffendingObject,
								* NDAppleScriptPartialResult;

/*!
	@class NDComponentInstance
	@abstract A class to represent a component instance.
	@discussion A component instance is a connection to a component (osa component) used to compile and execute AppleScripts. This class is to be used with <tt>NDScriptData</tt>.
 */
@interface NDComponentInstance : NSObject <NDScriptDataSendEvent, NDScriptDataActive, NDScriptDataAppleEventResumeHandler, NSCopying>
{
@private
	ComponentInstance							instanceRecord;
	struct
	{
		id<NDScriptDataSendEvent>					target;
		BOOL										currentProcessOnly;
	}											sendAppleEvent;
	id<NDScriptDataActive>						activeTarget;
	id<NDScriptDataAppleEventResumeHandler>		appleEventResumeHandler;
//	id<NDScriptDataAppleEventSpecialHandler>	appleEventSpecialHandler;
	OSASendUPP									defaultSendProcPtr;
	SRefCon										defaultSendProcRefCon;
	OSAActiveProcPtr							defaultActiveProcPtr;
	SRefCon										defaultActiveProcRefCon;
	AEEventHandlerUPP							defaultResumeProcPtr;
	SRefCon										defaultResumeProcRefCon;
	BOOL										executeAppleEventInMainThread;
}

/*!
	@method sharedComponentInstance
	@abstract Returns the shared component instance.
	@discussion This is the single component all <tt>NDScriptData</tt>s use if you do not give it a <tt>NDComponentInstance</tt>. The shared component instance has a connection with the default OSA Apple component.
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
	@method setAppleEventSendTarget:currentProcessOnly:
	@abstract  sets the object that any handles any AppleEvent the script atempts to send.
	@discussion If the send target is set any AppleEvents are sent to the send target to be processed, otherwise <tt>NDComponentInstance</tt> will handle the event itself by utilising the OSA default send procedure. One use of this is when executing a script in thread any AppleEvents that require user interaction sent to the current procees need to be sent from the main thread. This method retains the target so if the target retains the <tt>NDScriptData</tt> that is used by the component you will have to set the target to target to nil to release the component and hence close the compoent instance. If you don't do this, not only will you have a memory leak you will use up component instances.
	@param  target An object that implements the protocol <tt>NDScriptDataSendEvent</tt>.
	@param flag If <tt>YES</tt> then only AppleEvents for the current process are sent to the AppleEvent send target, otherwise all AppleEvents are sent to the send target.
 */
- (void)setAppleEventSendTarget:(id<NDScriptDataSendEvent>)target currentProcessOnly:(BOOL)flag;
/*!
	@method setAppleEventSendTarget:
	@abstract  sets the object that any handles any AppleEvent the script atempts to send.
	@discussion If the send target is set any AppleEvents are sent to the send target to be processed, otherwise <tt>NDComponentInstance</tt> will handle the event itself by utilising the OSA default send procedure. One use of this is when executing a script in thread any AppleEvents that require user interaction sent to the current procees need to be sent from the main thread. This method retains the target so if the target retains the <tt>NDScriptData</tt> that is used by the component you will have to set the target to target to nil to release the component and hence close the compoent instance. If you don't do this, not only will you have a memory leak you will use up component instances.
	@param  target An object that implements the protocol <tt>NDScriptDataSendEvent</tt>.
 */
- (void)setAppleEventSendTarget:(id<NDScriptDataSendEvent>)target;

/*!
	@method setExecuteAppleEventInMainThread:
	@abstract Set all AppleEvents targeted to the current process through the main thread, this is neccessary when running scripts within a thread that require user GUI interaction. This function throws an exception if it fails.
	@discussion <#descriptionFunction#>.
	@param  flag YES to set execution in main thread on.
*/
- (void)setExecuteAppleEventInMainThread:(BOOL)flag;
- (BOOL)executeAppleEventInMainThread;

/*!
	@method appleEventSendTarget
	@abstract returns the object that handles any AppleEvents
	@discussion See the method <tt>setAppleEventSendTarget: </tt>for a discussion.
	@result the AppleEvent send target.
 */
- (id<NDScriptDataSendEvent>)appleEventSendTarget;

/*!
	@method appleEventSendCurrentProcessOnly
	@abstract Are AppleEvents sent to the send target for the current process only.
	@discussion As set in the method <tt>setAppleEventSendTarget:currentProcessOnly:</tt>
	@result If <tt>YES</tt> then only AppleEvents for the current process are sent to the AppleEvent send target, otherwise all AppleEvents are sent to the send target.
 */
- (BOOL)appleEventSendCurrentProcessOnly;

/*!
	@method setActiveTarget:
	@abstract sets the object which is periodicly sent the message <tt>appleScriptActive:</tt>.
	@discussion will the script is running it will periodocly give up time for you to do some other processing.
	@param  target An object that implements the protocol <tt>NDScriptDataActive</tt>.
 */
- (void)setActiveTarget:(id<NDScriptDataActive>)target;

/*!
	@method activeTarget
	@abstract returns the active target as set by the method <tt>setActiveTarget:</tt>
	@discussion See the method <tt>setActiveTarget:</tt> for a discussion.
 */
- (id<NDScriptDataActive>)activeTarget;

//- (void)setAppleEventSpecialHandler:(id<NDScriptDataAppleEventSpecialHandler>)handler;
//- (id<NDScriptDataAppleEventSpecialHandler>)appleEventSpecialHandler;

/*!
	@method setAppleEventResumeHandler:
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@param handler <#disc#>
	@result <#result#>
 */
- (void)setAppleEventResumeHandler:(id<NDScriptDataAppleEventResumeHandler>)handler;

/*!
	@method appleEventResumeHandler
	@abstract <#Abstract#>
	@discussion <#Discussion#>
	@result <#result#>
 */
- (id<NDScriptDataAppleEventResumeHandler>)appleEventResumeHandler;
/*!
	@method error
	@abstract Get AppleScript Errors.
	@discussion You can use <tt>error</tt> to get information about errors that occured durring execution or compilation. The returned error info dictionary may contain entries that use any combination of the following keys, including no entries at all. The dictionary returns all of the same keys as within the error dictionary returned with some of  Apples <tt>NSAppleScript</tt> methods.
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Constant</th><th>Description</th></tr></thead>
				<tr>
					<td align="center"><tt>NSAppleScriptErrorMessage</tt></td>
					<td>An <tt>NSString</tt> that supplies a detailed description of the error condition.</td>
				</tr>
				<tr>
					<td align="center"><tt>NSAppleScriptErrorNumber</tt></td>
					<td>An <tt>NSNumber</tt> that specifies the error number.</td>
				</tr>
				<tr>
					<td align="center"><tt>NSAppleScriptErrorAppName</tt></td>
					<td>An <tt>NSString</tt> that specifies the name of the application that generated the error.</td>
				</tr>
				<tr>
					<td align="center"><tt>NSAppleScriptErrorBriefMessage</tt></td>
					<td>An <tt>NSString</tt> that provides a brief description of the error.</td>
				</tr>
				<tr>
					<td align="center"><tt>NSAppleScriptErrorRange</tt></td>
					<td>An <tt>NSValue</tt> that specifies a range.</td>
				</tr>
				<tr>
					<td align="center"><tt>NDAppleScriptOffendingObject</tt></td>
					<td>An <tt>NSAppleEventDescriptor</tt> that specifies an offending object.</td>
				</tr>
				<tr>
					<td align="center"><tt>NDAppleScriptPartialResult</tt></td>
					<td>An object that represent a partial result</td>
				</tr>
		</table>
	</blockquote></blockquote>
	@result A <tt>NSDictionary</tt>  containing error information
 */
- (NSDictionary *)error;

/*!
	@method name
	@abstract Get component name.
	@discussion Returns the name of the recieves component if available; otherwise <tt>nil</tt> is returned.
	@result Returns a <tt>NSString</tt> for the components name or <tt>nil</tt>.
 */
- (NSString *)name;

/*!
	@method isEqualToComponentInstance:
	@abstract Test if two components are equivalent.
	@discussion Returns <tt>YES</tt> if the reciever referes to the same <tt>ComponentInstance</tt> as <tt>componentInstance</tt>
	@param componentInstance The component instance to compare with.
	@result Returns <tt>YES</tt> if the <tt>NDComponentInstance</tt> <tt><i>componentInstance</i></tt> is equivalent to the receiver.
 */
- (BOOL)isEqualToComponentInstance:(NDComponentInstance *)componentInstance;

@end
