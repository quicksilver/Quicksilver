/*!
	@header NDAppleScriptObject_Protocols
	@abstract Header file for the protocols <tt>NDAppleScriptObjectSendEvent</tt> and <tt>NDAppleScriptObjectActive</tt>
	@discussion The protocols <tt>NDAppleScriptObjectSendEvent</tt> and <tt>NDAppleScriptObjectActive</tt> are used by <tt>NDAppleScriptObject</tt>
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

/*!
	@protocol NDAppleScriptObjectSendEvent
	@abstract Protocol used by <tt><a href="../../../NDAppleScriptObject/index.html" target="_top">NDAppleScriptObject</a></tt>
	@discussion The protocol <tt>NDAppleScriptObjectSendEvent</tt> is implemented by any object that wishes to act as an AppleEvent send target as passed to the method <tt>setAppleEventSendTarget:</tt>.
 */
@protocol NDAppleScriptObjectSendEvent <NSObject>
/*!
	@method sendAppleEvent:sendMode:sendPriority:timeOutInTicks:idleProc:filterProc:
	@abstract Passes an event to be executed by a AppleScript to the receiver
	@discussion Called every time the AppleScript is about to send an AppleEvent. The method <tt>sendAppleEvent:sendMode:sendPriority:timeOutInTicks:idleProc:filterProc:</tt> can be used to intercept every AppleEvent that the AppleScript would send so that it can be modified or redirected. For example AppleEvent for GUI interaction like &ldquo;display dialog&rdquo; need to be sent within the main run loop and thread. The class <tt>NDAppleScriptObject</tt> implements this protocol it&rsquo;s self and so you can pass this message onto your <tt>NDAppleScriptObject</tt> object.
	@param appleEventDescriptor An <tt>NSAppleEventDescriptor</tt> containing the event to be sent.
	@param sendMode Specifies various options for how the server application should handle the Apple event. To obtain a value for this parameter, you add together constants to set bits that specify the reply mode, the interaction level, the application switch mode, the reconnection mode, and the return receipt mode. The constants are described in <tt>AESendMode</tt> . 
	@param sendPriority A value that specifies the priority for processing the Apple event. You can specify normal or high priority, using the constants described in <tt>AESendMode</tt> . 
	@param timeOutInTicks If the reply mode specified in the <tt>sendMode</tt> parameter is <tt>kAEWaitReply</tt>, or if a return receipt is requested, this parameter specifies the length of time (in ticks) that the client application is willing to wait for the reply or return receipt from the server application before timing out. Most applications should use the <tt>kAEDefaultTimeout</tt> constant, which tells the Apple Event Manager to provide an appropriate timeout duration. If the value of this parameter is <tt>kNoTimeOut</tt>, the Apple event never times out. These constants are described in &ldquo;Timeout Constants&rdquo; .
	@param idleProc <p>A universal procedure pointer to a function that handles events (such as update, operating-system, activate, and null events) that your application receives while waiting for a reply. Your idle function can also perform other tasks (such as displaying a wristwatch or spinning beach ball cursor) while waiting for a reply or a return receipt.</p>
	<p>If your application specifies the kAEWaitReply flag in the <tt>sendMode</tt> parameter then it must provide an idle function&mdash;otherwise, you can pass a value of <tt>NULL</tt> for this parameter. For more information on the idle function, see <tt>AEIdleProcPtr</tt>.</p>
	@param filterProc A universal procedure pointer to a function that determines which incoming Apple events should be received while the handler waits for a reply or a return receipt. If your application doesn&rsquo;t need to filter Apple events, you can pass a value of <tt>NULL</tt> for this parameter. If you do so, no application-oriented Apple events are processed while waiting. For more information on the filter function, see <tt>AEFilterProcPtr</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> contain the result.
 */
- (NSAppleEventDescriptor *)sendAppleEvent:(NSAppleEventDescriptor *)appleEventDescriptor sendMode:(AESendMode)sendMode sendPriority:(AESendPriority)sendPriority timeOutInTicks:(long)timeOutInTicks idleProc:(AEIdleUPP)idleProc filterProc:(AEFilterUPP)filterProc;
@end

/*!
@protocol NDAppleScriptObjectActive
@abstract Protocol used by <tt><a href="../../../NDAppleScriptObject/index.html" target="_top">NDAppleScriptObject</a></tt>
@discussion The protocol <tt>NDAppleScriptObjectActive</tt> is implemented by any object that wishes to.
*/
@protocol NDAppleScriptObjectActive <NSObject>
/*!
	@method appleScriptActive
	@abstract Method called periodical during script execution.
	@discussion Allows you to do some processing durring execution of a AppleScript with the same thread.
	@result Returns <tt>NO</tt> to specify some error occurred.
 */
- (BOOL)appleScriptActive;
@end

