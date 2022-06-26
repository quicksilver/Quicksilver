# About Quicksilver #

Quicksilver is a fast and free macOS productivity application that gives you the power to control your Mac quickly and elegantly. Quicksilver learns your habits, making your everyday chores simple and efficient. Learn more at: https://qsapp.com

# About This Code Repository #

This repository contains the source code for the Quicksilver main app. It is also the place to browse existing issues and open new issues, via the [issue tracker](https://github.com/quicksilver/Quicksilver/issues). 

The `main` branch contains the source for the currently released Quicksilver.

If you want more info about [Quicksilver](http://qsapp.com) you can read the [about page](http://qsapp.com/about.php) or view it on [Wikipedia](http://en.wikipedia.org/wiki/Quicksilver_%28software%29 "Quicksilver Wikipedia article"). For help and support, visit the [Quicksilver Support Group](http://groups.google.com/group/blacktree-quicksilver "Quicksilver Google Group"). Developers can find help in the [Developer Support Group](https://groups.google.com/forum/?hl=en_US&fromgroups#!forum/quicksilver---development)

## Where to download Quicksilver? ##

Visit [QSApp.com](http://qsapp.com/download.php), and download the right version for your operating system.

## Before Trying the Source Code ##

Before building and testing Quicksilver, **ALWAYS BACKUP** your user data!  
This is easily done by backing up the following:

  * `~/Library/Application Support/Quicksilver`
  * `~/Library/Caches/Quicksilver`
  * `~/Library/Preferences/com.blacktree.Quicksilver.plist`

Now if anything happens you can always restore the exact state Quicksilver was in before your were trying out this version. When switching between versions, you should generally clear caches with

    rm -r ~/Library/Caches/*Quicksilver

## Getting Started with Development ##

[The Map](The_Map.md) should give you a head start if you're approaching this project for the first time.

## Multiple copies of Quicksilver.app on your Mac ##

Having multiple copies of Quicksilver.app on the system can cause issues with the Services System in OS X and AppleScript.

Specifically, Services will not register properly when the pasteboard server (`/System/Library/CoreServices/pbs`) sees multiple Quicksilver.app packages each with their own Info.plist file defining the same services. AppleScript will also get confused with more than one Quicksilver.app on your Mac.

In order to ensure that the Services System and AppleScript work correctly, zip any old Quicksilver.app packages you want to keep, so you only have one Quicksilver.app file on your filesystem. Also do not forget to empty your trash after you deleted the older Quicksilver.app packages.

## Development ##

You should be able to build Quicksilver by following the instructions as seen in the Quicksilver Wiki on [Building Quicksilver](http://qsapp.com/wiki/Building_Quicksilver).

## Legal Stuff ##

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
