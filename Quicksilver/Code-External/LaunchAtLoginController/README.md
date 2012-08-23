# LaunchAtLoginController

A very simple to implement Controller for use in Cocoa Mac Apps to register/deregister itself for Launch at Login using LSSharedFileList.

It uses LSSharedFileList which means your Users will be able to check System Preferences > Accounts > Login Items.

I'm currently using it on 10.6 (32/64) successfully. I've not investigated being able to flag the "Hide" flag which is possible from System Preferences.

## IMPLEMENTATION (Code):

### Will app launch at login?

    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
	BOOL launch = [launchController launchAtLogin];
	[launchController release];

### Set launch at login state.

	LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
	[launchController setLaunchAtLogin:YES];
	[launchController release];

## IMPLEMENTATION (Interface builder):

* Open Interface Builder
* Place a NSObject (the blue box) into the nib window
* From the Inspector - Identity Tab (Cmd+6) set the Class to LaunchAtLoginController
* Place a Checkbox on your Window/View
* From the Inspector - Bindings Tab (Cmd+4) unroll the > Value item
  * Bind to Launch at Login Controller
  * Model Key Path: launchAtLogin

## IS IT WORKING:

After implementing either through code or through IB, setLaunchAtLogin:YES and then check System Preferences > Accounts > Login Items. You should see your app in the list of apps that will start when the user logs in.

## CAVEATS (HelperApp Bundles):

If you're trying to set a different bundle (perhaps a HelperApp as a resource to your main bundle) you will simply want to change 
    - (NSURL *)appURL 
to return the path to this other bundle.

## REQUIREMENTS:

Works on 10.6/10.5

## ORIGINAL CODE IDEAS:

* Growl. 
* User: invariant Link: (http://stackoverflow.com/questions/815063/how-do-you-make-your-app-open-at-login/2318004#2318004)


## LICENSE:

(The MIT License)

Copyright (c) 2010 Ben Clark-Robinson, ben.clarkrobinson@gmail.com

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
