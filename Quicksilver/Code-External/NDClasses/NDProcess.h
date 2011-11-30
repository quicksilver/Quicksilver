/*
	NDProcess.h

	Created by Nathan Day on 27.05.02 under a MIT-style license. 
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
	@header NDProcess
	@abstract Header file for the class <tt>NDProcess</tt> and categories of <tt>NDProcess</tt>
	@discussion <p><tt>NDProcess</tt> is a cocoa wrapper for Apples Process Manager</p>
 */


#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

/*!
	@class NDProcess
	@abstract Class to represent a process.
	@discussion Provides a simplified Cocoa interface to Apples Pocess Manager API. Some of the methods will return instances that are reused if you do not retain them, methods that do so are identified in there documentation.
 */
@interface NDProcess : NSObject
{
@private
	ProcessSerialNumber			processSerialNumber;
	ProcessInfoRec				infoRec;
	NSString					* name;
	NSURL						* url;
}

/*!
	@method initWithProcessSerialNumber:
	@abstract Initialises a <tt>NDProcess</tt>.
	@discussion Initialises a the recevier with a process serial number.
	@param processSerialNumber The process serial number.
	@result A initialised <tt>NDProcess</tt>
 */
- (id)initWithProcessSerialNumber:(ProcessSerialNumber)processSerialNumber;

/*!
	@method processSerialNumber
	@abstract Get the Process Serial Number
	@discussion Returns the process serial number for the recevier
	@result A process serial number.
 */
- (ProcessSerialNumber)processSerialNumber;

/*!
	@method isFrontProcess
	@abstract Is the process the front process.
	@discussion Determines if the recevier is for a process that is currently front.
	@result Returns <tt>YES</tt> if the process is front.
 */
- (BOOL)isFrontProcess;

/*!
	@method isCurrentProcess
	@abstract Is the process the current process.
	@discussion Determines if the recevier is for a process that is current.
	@result Returns <tt>YES</tt> if the process is current.
 */
- (BOOL)isCurrentProcess;

/*!
	@method makeFrontProcessFrontWindowOnly:
	@abstract Bring the process to front.
	@discussion Attempts to bring the process to front. If the <tt>flag</tt> is set then only the front most window of the process is made front.
	@param flag If <tt>YES</tt> then only the front most window of the process is brought to front, if <tt>NO</tt> then all of the window for the process are made front.
	@result Returns <tt>YES</tt> if the process did come to front. 
 */
- (BOOL)makeFrontProcessFrontWindowOnly:(BOOL)flag;

/*!
	@method makeFrontProcess
	@abstract Bring the process to front.
	@discussion Attempts to bring the process to front.
	@result Returns <tt>YES</tt> if the process did come to front. 
 */
- (BOOL)makeFrontProcess;

/*!
	@method wakeUpProcess
	@abstract Wake up the process.
	@discussion Wakes up the process.
	@result Returns <tt>YES</tt> if the process did wakr up.. 
 */
- (BOOL)wakeUpProcess;


@end

/*!
	@category NDProcess(Construction)
	@abstract <tt>NDProcess</tt> construction methods.
	@discussion Most of the time you should use one of these methods to create <tt>NDProcess</tt> objects.
 */
@interface NDProcess (Construction)

/*!
	@method initWithCurrentProcess
	@abstract Initialises a <tt>NDProcess</tt>.
	@discussion Initialises the recevier for the current process.
	@result A initialised <tt>NDProcess</tt>
 */
- (id)initWithCurrentProcess;

/*!
	@method initWithFrontProcess
	@abstract Initialises a <tt>NDProcess</tt>.
	@discussion Initialises the recevier for the front process.
	@result A initialised <tt>NDProcess</tt>
 */
- (id)initWithFrontProcess;

	/*!
	@method initWithProcessID:
	@abstract Initialises a <tt>NDProcess</tt>.
	@discussion Initialises a the recevier with the process ID <tt><i>pid</i></tt>.
	@param pid The process ID.
	@result A initialised <tt>NDProcess</tt>
	 */
- (id)initWithProcessID:(pid_t)pid;

/*!
	@method everyProcess
	@abstract Get every process.
	@discussion Returns a <tt>NSArray</tt> of <tt>NDProcess</tt>s for every process.
	@result An <tt>NSArray</tt> of <tt>NDProcess</tt>s.
 */
+ (NSArray *)everyProcess;

/*!
	@method everyProcessNamed:
	@abstract Get every process of supplied name.
	@discussion Returns every process with a given name, the process name does not have to unique.
	@param name The process name to find.
	@result An <tt>NSArray</tt> of <tt>NDProcess</tt>s.
 */
+ (NSArray *)everyProcessNamed:(NSString *)name;


/*!
	@method processWithProcessSerialNumber:
	@abstract Returns a new <tt>NDProcess</tt>.
	@discussion Returns a <tt>NDProcess</tt> for the process with the given process serial number.
	@param processSerialNumber A valid process serial number.
	@result A <tt>NDProcess</tt> object.
 */
+ (NDProcess *)processWithProcessSerialNumber:(ProcessSerialNumber)processSerialNumber;

/*!
	@method currentProcess
	@abstract Returns a new <tt>NDProcess</tt>.
	@discussion Returns a <tt>NDProcess</tt> for the current process.
	@result A <tt>NDProcess</tt> object.
 */
+ (NDProcess *)currentProcess;

/*!
	@method frontProcess
	@abstract Returns a new <tt>NDProcess</tt>.
	@discussion Returns a <tt>NDProcess</tt> for the front process.
	@result A <tt>NDProcess</tt> object.
 */
+ (NDProcess *)frontProcess;

/*!
	@method processWithProcessID
	@abstract Returns a new <tt>NDProcess</tt>.
	@discussion Returns a <tt>NDProcess</tt> for the process with the UNIX process ID <tt><i>pid</i></tt>.
	@result A <tt>NDProcess</tt> object.
 */
+ (NDProcess *)processWithProcessID:(pid_t)pid;

/*!
	@method firstProcessNamed:
	@abstract Returns a new <tt>NDProcess</tt>.
	@discussion Returns a <tt>NDProcess</tt> for the first process with the supplied name.
	@param name The name to look for.
	@result A <tt>NDProcess</tt> object.
 */
+ (NDProcess *)firstProcessNamed:(NSString *)name;

/*!
	@method processForURL:
	@abstract Returns a new <tt>NDProcess</tt>.
	@discussion Returns a <tt>NDProcess</tt> for the process with the supplied url, the url can be to the executable file within an appication package.
	@param URL The url of the process to return.
	@result A <tt>NDProcess</tt> object.
 */
+ (NDProcess *)processForURL:(NSURL *)URL;

/*!
	@method processForPath:
	@abstract Returns a new <tt>NDProcess</tt>.
	@discussion Returns a <tt>NDProcess</tt> for the process with the supplied path, the path can be to the executable file within an appication package.
	@param path The path of the process to return.
	@result A <tt>NDProcess</tt> object.
 */
+ (NDProcess *)processForPath:(NSString *)path;

/*!
	@method processForApplicationURL:
	@abstract Returns a new <tt>NDProcess</tt>.
	@discussion Returns a <tt>NDProcess</tt> for the process with the supplied url, if the url is to an application package then the <tt>NDProcess</tt> returned is for the file identified by the <tt>CFBundleExecutable</tt> key int the <tt>Info.plist</tt> file.
	@param URL The url of the process to return.
	@result A <tt>NDProcess</tt> object.
 */
+ (NDProcess *)processForApplicationURL:(NSURL *)URL;

/*!
	@method processForApplicationPath:
	@abstract Returns a new <tt>NDProcess</tt>.
	@discussion Returns a <tt>NDProcess</tt> for the process with the supplied path, if the path is to an application package then the <tt>NDProcess</tt> returned is for the file identified by the <tt>CFBundleExecutable</tt> key int the <tt>Info.plist</tt> file.
	@result A <tt>NDProcess</tt> object.
 */
+ (NDProcess *)processForApplicationPath:(NSString *)path;

	/*!
	@method everyProcessForBeginingWithURL:
	@abstract Returns a new <tt>NDProcess</tt>.
	@discussion Returns a <tt>NSArray</tt> of <tt>NDProcess</tt> for the processes with in the supplied url, the url can be to the executable file within an appication package or a package its self or even a folder.
	@param URL The url of the process to return.
	@result A <tt>NDProcess</tt> object.
 */
+ (NSArray *)everyProcessBeginingWithURL:(NSURL *)URL;

/*!
	@method everyProcessBeginingWithPath:
	@abstract Returns a <tt>NSArray</tt> of <tt>NDProcess</tt>s contained within the given path..
	@discussion Returns a <tt>NSArray</tt> of <tt>NDProcess</tt> for the processes with in the supplied path, the path can be to the executable file within an appication package or a package its self or even a folder.
	@param path The path of the process to return.
	@result A <tt>NDProcess</tt> object.
 */
+ (NSArray *)everyProcessBeginingWithPath:(NSString *)path;

/*!
	@method processesEnumerater
	@abstract Returns a <tt>NSEnumerator</tt> for every process.
	@discussion The <tt>NSEnumerator</tt> will step through every process. WARNING: the instances returned from this enumerator will be reuses unless you retain them, before calling nextObject again.
	@result A <tt>NSEnumerator</tt> for every process.
 */
+ (NSEnumerator *)processesEnumerater;

/*!
	@method isNoProcess
	@abstract Get type of process.
	@discussion Is the process serial number <tt>kNoProcess</tt>.
	@result Returns <tt>YES</tt> if process serial number is <tt>kNoProcess</tt>
 */
- (BOOL)isNoProcess;

/*!
	@method isSystemProcess
	@abstract Get type of process.
	@discussion Is the process serial number <tt>kSystemProcess</tt>.
	@result Returns <tt>YES</tt> if process serial number is <tt>kSystemProcess</tt>
 */
- (BOOL)isSystemProcess;

/*!
	@method isValid
	@abstract Is the process valid.
	@discussion Attempts to get <tt>ProcessInfoRec</tt> and return true if no error. The process may not be running any more.
	@result Returns <tt>YES</tt> if the is process valid.
 */
- (BOOL)isValid;

@end

/*!
	@category NDProcess(ProcessInfoRec)
	@abstract Methods to get additional process info.
	@discussion These methods return information from the <tt>ProcessInfoRec</tt> sttruct.
 */
@interface NDProcess (ProcessInfoRec)

/*!
	@method name
	@abstract Process name.
	@discussion The name of the process. For applications, this field contains the name of the application as designated by the user at the time the application was opened. For example, for foreground applications, the name is the name as it appears in the Dock.
	@result A <tt>NSString</tt> containing the name.
 */
- (NSString *)name;

/*!
	@method type
	@abstract Process type
	@discussion The file type of the application, generally <tt>'APPL'</tt> for applications and <tt>'appe'</tt> for background-only applications launched at startup.
	@result A four char code.
 */
- (OSType)type;

/*!
	@method signature
	@abstract Process signature
	@discussion The signature of the file containing the process (for example, the signature of the TeachText application is <tt>'ttxt'</tt>).
	@result A four char code.
 */
- (OSType)signature;

/*!
	@method mode
	@abstract Process mode
	@discussion Process mode flags. These flags indicate whether the process is an application or desk accessory. For applications, this field also returns information specified in the application’s <tt>'SIZE'</tt> resource. This information is returned as flags that can be combined with a bitwise or, though they probable are not all relevent to Mac OS X
	<ul>
		<li>modeReserved</li>
		<li>modeControlPanel</li>
		<li>modeDeskAccessory</li>
		<li>modeMultiLaunch</li>
		<li>modeNeedSuspendResume</li>
		<li>modeCanBackground</li>
		<li>modeDoesActivateOnFGSwitch</li>
		<li>modeOnlyBackground</li>
		<li>modeGetFrontClicks</li>
		<li>modeGetAppDiedMsg</li>
		<li>mode32BitCompatible</li>
		<li>modeHighLevelEventAware</li>
		<li>modeLocalAndRemoteHLEvents</li>
		<li>modeStationeryAware</li>
		<li>modeUseTextEditServices</li>
		<li>modeDisplayManagerAware</li>
	</ul>
	@result A combination of the previously list values.
 */

- (UInt32)mode;

/*!
	@method launcher
	@abstract Process launcher
	@discussion A <tt>NDProcess</tt> for the process that launched the application. If the original launcher of the process is no longer open, the <tt>NDProcess</tt> will have the process serial number <tt>kNoProcess</tt>.
	@result A <tt>NDProcess</tt> for the receviers launching process.
 */
- (NDProcess *)launcher;

/*!
	@method launchTime
	@abstract Launch time in seconds
	@discussion The value of the Ticks global variable in secods at the time that the process was launched.
	@result The time in <tt>NSTimeInterval</tt> (seconds).
 */
- (NSTimeInterval)launchTime;

/*!
	@method url
	@abstract Process url.
	@discussion The url for the receviers process, this may be within the contents of some application package.
	@result A file url <tt>NSURL</tt> to a file containing the process.
 */
- (NSURL *)url;

/*!
	@method path
	@abstract Process path.
	@discussion The path for the receviers process, this may be within the contents of some application package.
	@result A path <tt>NSString</tt> to a file containing the process.
 */
- (NSString *)path;

/*!
	@method processID
	@abstract Obtains the preocess ID
	@discussion Returns the UNIX ocess ID for the reciever.
	@result A <tt>pid_t</tt> for the reciever or -1 if an error occurs.
 */
- (pid_t)processID;

@end