About Quicksilver B5X on Github
===============================

This repository contains the current source code of Quicksilver. If you're having issues with the latest Quicksilver version, feel free to log them at the [issue tracker](https://github.com/quicksilver/Quicksilver/issues). 

This branch contains the source for the currently released Quicksilver.
The alcor branch contains the code for the "next-gen" Quicksilver. Right now it features an updated plugin system, and Catalyst, which aims to provide triggers as a preference pane, and that's it. It is usable, but all plugins are incompatible without some extra work.

If you want more info about [Quicksilver](http://en.wikipedia.org/wiki/Quicksilver_%28software%29 "Quicksilver Wikipedia article") 
just do a search on YouTube - there's tons of very helpful instructional and informational video tutorials.
Or visit the [mailing list](http://groups.google.com/group/blacktree-quicksilver "Quicksilver Google Group") hosted at Google Groups.

Where to find it ?
---------------------

Go look on the download pages around. The "most official" one is [here](https://github.com/quicksilver/Quicksilver/downloads), but there are some others lying around in the forest of forks. Choose the one with the biggest number ;-).

Before You Try It Out
---------------------
    
Before trying out new Quicksilver versions **ALWAYS BACKUP** your user data!  
This is easily done by backing up the following folders 

(`<user>` stands for your short user name):

`/Users/<user>/Library/Application Support/Quicksilver`  
`/Users/<user>/Library/Caches/Quicksilver`

and just to be safe, let's also backup the present

`/Applications/Quicksilver.app`

before you overwrite it with this version.  
Now if anything happens you can always restore the exact state Quicksilver was in before
your were trying out this version. 



Facts, Features and Fixes 
-------------------------

The biggest change first and foremost:  

    Minimum runtime requirement for this version is Mac OS X 10.5 ("Leopard"). 
    There are no plans for supporting Mac OS X 10.4 ("Tiger").

<br />

The following is a short, assorted list of facts and enhancements you may find in this version.   
For a more comprehensive list take a look at the commit messages.  
<br />

* Default compiler changed to Clang, Apple's and the Open Source community's next gen compiler.  

    By doing that a 20 to 40% increase in runtime speed was gained while managing a catalog library with approx. 13k items. Quicksilver also feels a lot snappier too. This, of course, is mostly subjective (read: YMMV).

* Actions should now appear localized again where appropriate.  

    (e.g. 'Copy to...' for example in German could also be typed as 'Bewegen nach...' or 'Open' as 'Ouvrir' in French.   
    .lproj folders for English, French, Italian, German, Spanish, Danish, Finish, Norwegian, Polish, and Swedish have been included. Mind you, the end result really depends on how Mac OS X handles this in the target language as Quicksilver just asks the OS for the localized representation of some common actions).

* Composed characters like German umlauts (e.g. 'ä') will now show both parts (the letter 'a' and the 'dots'. Previously only letters would show up).

* The broken action menu now shows up with a cross-selection of all enabled actions from the Actions preferences. 

* The Smart Replace and Replace dialog actions no longer crash Quicksilver and will now actually append numbers via a smart numbering system if a file to be copied or moved already exists at the destination.  

    In order to use the Smart Replace dialog you will need to set the feature level equal to or higher than 3.To do that enter the following _exactly_ into the Terminal and press Return:  `defaults write com.blacktree.Quicksilver "Feature Level" 3`

* File operation requiring credentials no longer crash QS after providing the password. 

* The Large Type action now keeps the text visible again for prolonged periods.

* Icons associated with custom file actions (e.g. like custom AppleScript actions) are now correctly displayed instead of a generic file placeholder icon.

* AppleScript actions which return something now cause Quicksilver to reappear again ready to use the result for the next action.

* Mouse tracking for triggers ('Mouse entered' / 'Mouse exited')  now seems to work more reliably. 

* The Extras pref pane no longer has a row spacing issue upon first loading of the associated NIB file.

* Excessive log outputs have been silenced to only occur if certain debugging environment variables are set in order to avoid spamming the Console.

* Dozens of API upgrades like replacing deprecated methods with safer variants or adding declaration names for the new way of handling informal protocols.

* All NIB files were converted to a SCM and collaboration friendly XIB format. A lot of clipping warnings have been fixed.

* Triggers with wierd keys (like Function keys) are now displayed again.

* Updated French and German localization.

* Various other housekeeping tasks.


Notes Specific to Snow Leopard
------------------------------

Snow Leopard has a reworked Services system. This is relevant because preferences like *"Pull selection from front application instead of Finder"* (`Preferences > Extras`) make use of two services called *"Get Current Selection"* and *"Send to Quicksilver"*. 

It appears that these services will not register properly when the pasteboard server (`/System/Library/CoreServices/pbs`) sees multiple Quicksilver.app packages each with their very own Info.plist file defining the same services.

The result is that none of the services for any Quicksilver.app will register and thus the default Cmd + Esc hotkey combo won't do anything much no matter which application is currrently frontmost.
The solution to this is to zip any old Quicksilver.app packages you want to keep around and delete every Quicksilver.app package except the one you want to run. 
Also do not forget to empty your trash after you deleted the older Quicksilver.app packages.


Development
-----------

You should be able to build Quicksilver by opening the project file with Xcode and pressing "Build". Be aware that the build system **will overwrite** the Quicksilver located in your /Applications folder.

A Few Notes on Working With Git
-------------------------------

The following (non-exhaustive) list shows files which need to be treated specially within git:

`Quicksilver/PlugIns-Main/Bezel/Info.plist`  
`Quicksilver/PlugIns-Main/Finder/Info.plist`  
`Quicksilver/PlugIns-Main/PrimerInterface/Info.plist`  
`Quicksilver/PlugIns-Main/QSHotKeyPlugIn/Info.plist`  

That is because they change each time the project is built (e.g. the hexadecimal build number is updated by 'bltrversion' for each plugin).

We can't just remove them from the project and add them to the repository-wide .gitignore file because we still need to push those files up to the remote so that another developer will get them when he/she clones the project. 
Also because this project was converted from SVN we can't just tell everyone to add those files to their personal repository-wide exclude file (in .git/info/exclude) and be done with it. If the file is already tracked adding it to any ignore file won't keep git from tracking it (gitignore(5) has more info on that).

What we need is to tell git to just keep the initial version in the repository but not track any changes.  
The following commands seem to do just that:

`git update-index --assume-unchanged Quicksilver/PlugIns-Main/Bezel/Info.plist`  
`git update-index --assume-unchanged Quicksilver/PlugIns-Main/Finder/Info.plist`  
`git update-index --assume-unchanged Quicksilver/PlugIns-Main/PrimerInterface/Info.plist`  
`git update-index --assume-unchanged Quicksilver/PlugIns-Main/QSHotKeyPlugIn/Info.plist`  

This will keep git from noticing any changes but will still keep it (do a `git-ls-files | grep QSHotKeyPlugIn/Info.plist` to confirm).

If you need to make changes to any of those files and you need these changes visible for others to clone then you must revert the commands issued above before commiting.  
To do so just run the commands again but this time with `--no-assume-unchanged`.

PS.: If any of the git veterans has a better way of handling this please send me a message to my (andreberg) github inbox.


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


Which basically means: whatever you do, I can't be held accountable if something breaks.  
