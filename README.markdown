About Quicksilver B5X on Github
===============================

This repository is an off-the-side copy of the Quicksilver B5X Subversion repository currently hosted at [Google Code](http://code.google.com/p/blacktree-alchemy "Quicksilver Subversion Repository").
I have done this in the hopes of improving Quicksilver by enhancing it wherever possible and of course fixing bugs over time.

If you want more info about [Quicksilver](http://en.wikipedia.org/wiki/Quicksilver_%28software%29 "Quicksilver Wikipedia article") 
just do a search on YouTube - there's tons of very helpful instructional and informational video tutorials.
Or visit the [mailing list](http://groups.google.com/group/blacktree-quicksilver "Quicksilver Google Group") hosted at Google Groups.


A word of advice, if I may: Don't clone the repository just yet. as I am still trying to build an infrastrucure which will be capable of sustaining easy local development, remote tracking and 

Facts, Features and Fixes 
-------------------------

The following is an assorted shortlist of facts and enhancements you may find in this version.   
For a more elaborate list take a look at the commit message queue. 

The biggest change first and foremost:


    Quicksilver now has a 10.5+ only tag.  
    The minimum runtime requirement is now Mac OS X 10.5 Leopard. 


* Now compiled with Clang, Apple's and the Open Source community's next gen compiler. Just by doing that I gained about 20 to 40% increase in runtime speed while managaing my 13k items catalog library. Quicksilver also feels a lot snappier too. Of course this is mostly subjective (read: YMMV).

* Actions should now be localized again where appropriate (e.g. 'Copy to...' for example in German can also be typed as 'Bewegen nach...' or 'Open' as 'Ouvrir' in French. I have included .lproj folders for English, French, Italian, German, Spanish, Danish, Finish, Norwegian, Polish, and Swedish. Mind you, the end result really depends on how Mac OS X handles this in the target language as Quicksilver just asks the OS for the localized representation of some common actions).

* As an added bonus to the last point, composed characters like German umlauts (e.g. 'ä') will now show both parts (the letter 'a' and the 'dots'. Previously only letters would show up).

* The broken action menu now shows up with a cross-selection of all enabled actions from the Actions preferences. 

* The Smart Replace and Replace actions no longer crash Quicksilver and now actually will append numbers via a smart numbering system if a file to be copied or moved already exists at the destination. To use the Smart Replace dialog you will need to set the feature level equal to or higher than 3. To do that enter the following _exactly_ into the Terminal and press Return:   
`defaults write com.blacktree.Quicksilver "Feature Level" 3`

* Icons associated with custom file actions (e.g. like custom AppleScript actions) now display correctly instead of the generic file placeholder icon.

* AppleScript actions which return something now will cause Quicksilver to reappear again ready for piping the result into the next action.

* Mouse tracking for triggers ('Mouse entered' / 'Mouse exited')  now seems to work more reliably. 

* I have silenced excessive log outputs to only occur if certain debugging environment variables are set, in order to avoid spamming the Console.

* Literally dozens of API upgrades to call safer variants on older methods or adding decleration names for the new way of handling informal protocols.

* All NIB files where converted to the more collaboration friendly XIB format. I also took the opportunity to fix a lot of clipping warnings.

* Various other housekeeping tasks.

* To avoid confusion with Quicksilver's regular beta versions hosted at Google Code I will append my initials (ab) to the revision number.
I am currently unsure how to integrate my work with the Subversion repo at GC as I don't have write access. Talking to a project owner revealed that in the future development might happen at GitHub but until that happens I will have to cook my own soup so to speak. 


Development
-----------

In case you checkout or clone this repository here is one part of Quicksilver's readme which details an important step in setting Xcode up to build:

>"Building Quicksilver will require you to edit the Configuration/Developer.xcconfig file and point the QS\_SOURCE\_ROOT configuration variable (drag the Quicksilver folder next to this file in the Developer.xcconfig window and remove "file://localhost/" and the ending slash)."

This step is **`absolutely crucial`**. If you still get lots of errors open the Build Settings panel and make sure that each build configuration is based on the correct xcconfig file (the names should match). Sometimes Xcode just "forgets" that a particular build configuration was based on a xcconfig file, thus losing important settings. 

It is also neccesary to define two Quicksilver specific source trees in Xcode's preferences:

* **QS\_SOURCE\_ROOT** which points to the source root of the download.  
This is so that it can find the Configuration folder and the Xcode project.  
example path: `<source_download>/B5X/Quicksilver`
  

* **QSFrameworks** which points to the Frameworks directory inside Quicksilver.app.  
This obviously needs a previously acquired Quicksilver.app presumably in Applications.  
example path: `/Applications/Quicksilver.app/Contents/Frameworks`. 

Note: The names in bold are important and should be entered *exactly* as shown.


A Few Notes on Working With Git
-------------------------------

The following (non-exhaustive) list shows files which need to be treated specially within git:

`Quicksilver/Configuration/Developer.xcconfig`  
`Quicksilver/PlugIns-Main/Bezel/Info.plist`  
`Quicksilver/PlugIns-Main/Finder/Info.plist`  
`Quicksilver/PlugIns-Main/PrimerInterface/Info.plist`  
`Quicksilver/PlugIns-Main/QSHotKeyPlugIn/Info.plist`  

That is because they must be changed on a developer-by-developer basis (Developer.xcconfig) or they change each time the project is built (e.g. the hexadecimal build number is updated by 'bltrversion' for each plugin).

We can't just remove them from the project and add them to the repository-wide .gitignore file because we still need to push those files up to the remote so that another developer will get them when he/she clones the project. 
Also because this project was converted from SVN we can't just tell everyone to add those files to their personal repository-wide exclude file (in .git/info/exclude) and be done with it. If the file is already tracked adding it to any ignore file won't keep git from tracking it (gitignore(5) has more info on that).

What we need is to tell git to just keep the initial version in the repository but not track any changes. 
The following commands seem to do just that:

`git update-index --assume-unchanged Quicksilver/Configuration/Developer.xcconfig`  
`git update-index --assume-unchanged Quicksilver/PlugIns-Main/Bezel/Info.plist`  
`git update-index --assume-unchanged Quicksilver/PlugIns-Main/Finder/Info.plist`  
`git update-index --assume-unchanged Quicksilver/PlugIns-Main/PrimerInterface/Info.plist`  
`git update-index --assume-unchanged Quicksilver/PlugIns-Main/QSHotKeyPlugIn/Info.plist`  

This will keep git from noticing any changes but will still keep it (do a `git-ls-files | grep Developer.xcconfig` to confirm).

If you need to make changes to any of those files and you need these changes visible for others to clone then you must revert the commands issued above before commiting.
To do so just run the command again but this time with `--no-assume-unchanged`.

PS.: If any of the git veterans has a better way of handling this please send me a message to my (andreberg) github inbox.