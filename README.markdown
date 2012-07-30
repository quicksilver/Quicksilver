About Quicksilver ß6X on Github
===============================

This repository contains the current source code of Quicksilver. If you're having issues with the latest Quicksilver version, feel free to log them at the [issue tracker](https://github.com/quicksilver/Quicksilver/issues). 

This master branch contains the source for the currently released Quicksilver.
The alcor branch contains the code for the "next-gen" Quicksilver. Right now it features an updated plugin system, and Catalyst, which aims to provide triggers as a preference pane, and that's it. It is usable, but all plugins are incompatible without some extra work. There are currently no plans to ever release this version.

If you want more info about [Quicksilver](http://qsapp.com) you can read the [about page](http://qsapp.com/about.php) or view it on [Wikipedia](http://en.wikipedia.org/wiki/Quicksilver_%28software%29 "Quicksilver Wikipedia article").
For help and support, visit the [Quicksilver Support Group](http://groups.google.com/group/blacktree-quicksilver "Quicksilver Google Group"). Developers can find help in the [Developer Support Group](https://groups.google.com/forum/?hl=en_US&fromgroups#!forum/quicksilver---development)


Where to download Quicksilver?
------------------------------

Visit [QSApp.com](http://qsapp.com/download.php), and download the right version for your operating system.


Before Trying the Source Code
-----------------------------

Before building and testing Quicksilver, **ALWAYS BACKUP** your user data!  
This is easily done by backing up the following 2 folders and preference file:

(`<user>` stands for your short user name):

`/Users/<user>/Library/Application Support/Quicksilver`  
`/Users/<user>/Library/Caches/Quicksilver`  
`/Users/<user>/Library/Preferences/com.blacktree.Quicksilver.plist`  

Now if anything happens you can always restore the exact state Quicksilver was in before
your were trying out this version. 


Notice on version compatibility
-------------------------------


    Minimum runtime requirement for this version is Mac OS X 10.6 ("Snow Leopard"). 

Notes Specific to Snow Leopard and Lion
---------------------------------------

The Services System in OS X will not register properly when the pasteboard server (`/System/Library/CoreServices/pbs`) sees multiple Quicksilver.app packages each with their very own Info.plist file defining the same services.

In order to ensure that the Service System works correctly, zip any old Quicksilver.app packages you want to keep, so you only have one Quicksilver.app file on your filesystem.
Also do not forget to empty your trash after you deleted the older Quicksilver.app packages.


Development
-----------

You should be able to build Quicksilver after following the instructions as seen in the Quicksilver Wiki on [Building Quicksilver](http://qsapp.com/wiki/Building_Quicksilver). Be aware that the build system **will overwrite** the Quicksilver located in your /Applications folder.


Legal Stuff 
-----------

By downloading and/or using this software you agree to the following terms of use:

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this software except in compliance with the License.
    You may obtain a copy of the License at
    
      http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
