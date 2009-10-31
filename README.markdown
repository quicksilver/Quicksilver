About Quicksilver B5X on Github
===============================

This repository is an off-the-side copy of the Quicksilver B5X Subversion repository currently hosted at [Google Code](http://code.google.com/p/blacktree-alchemy "Quicksilver Subversion Repository").
I have done this in the hopes of improving Quicksilver by fixing bugs and enhancing it wherever possible.

If you want more info about [Quicksilver](http://en.wikipedia.org/wiki/Quicksilver_%28software%29 "Quicksilver Wikipedia article") 
just do a search on YouTube - there's tons of very helpful instructional and informational video tutorials.
Or visit the [mailing list](http://groups.google.com/group/blacktree-quicksilver "Quicksilver Google Group") hosted at Google Groups.

<br />
Facts, Features and Fixes 
-------------------------

The biggest change first and foremost:  

    Minimum runtime requirement for this version of Quicksilver B5X is Mac OS X 10.5 ("Leopard"). 
    There are no plans to support this version on Mac OS X 10.4 ("Tiger").

<br />

To avoid confusion with Quicksilver's regular beta versions hosted at Google Code I will append my initials `(ab)` to the revision number. Currently I am not sure how to best integrate my work with the Subversion repository at Google Code as I don't have write access to that repository. Talking to a project owner revealed that in the future development might happen at GitHub but until that happens I will have to cook my own soup so to speak. 


The following is a short, assorted list of facts and enhancements you may find in this version.   
For a more comprehensive list take a look at the commit messages.  
<br />

* Default compiler now is Clang, Apple's and the Open Source community's next gen compiler.

 By doing that a 20 to 40% increase in runtime speed was gained while managing a catalog library with approx. 13k items. Quicksilver also feels a lot snappier too. This, of course, is mostly subjective (read: YMMV).

* Actions should now appear localized again where appropriate.  

  (e.g. 'Copy to...' for example in German sould also be typed as 'Bewegen nach...' or 'Open' as 'Ouvrir' in French.   
  .lproj folders for English, French, Italian, German, Spanish, Danish, Finish, Norwegian, Polish, and Swedish have been included. Mind you, the end result really depends on how Mac OS X handles this in the target language as Quicksilver just asks the OS for the localized representation of some common actions).

* Composed characters like German umlauts (e.g. 'ä') will now show both parts (the letter 'a' and the 'dots'. Previously only letters would show up).

* The broken action menu now shows up with a cross-selection of all enabled actions from the Actions preferences. 

* The Smart Replace and Replace dialog actions no longer crash Quicksilver and will now actually append numbers via a smart numbering system if a file to be copied or moved already exists at the destination.  

  In order to use the Smart Replace dialog you will need to set the feature level equal to or higher than 3.To do that enter the following _exactly_ into the Terminal and press Return:   
  `defaults write com.blacktree.Quicksilver "Feature Level" 3`

* File operation requiring credentials no longer crash QS after providing the password. 

* Icons associated with custom file actions (e.g. like custom AppleScript actions) are now correctly displayed instead of a generic file placeholder icon.

* AppleScript actions which return something now cause Quicksilver to reappear again ready to use the result for the next action.

* Mouse tracking for triggers ('Mouse entered' / 'Mouse exited')  now seems to work more reliably. 

* The Extras pref pane no longer has a row spacing issue upon first loading of the associated NIB file.

* Excessive log outputs have been silenced to only occur if certain debugging environment variables are set in order to avoid spamming the Console.

* Dozens of API upgrades like replacing deprecated methods with safer variants or adding decleration names for the new way of handling informal protocols.

* All NIB files were converted to a SCM and collaboration friendly XIB format. A lot of clipping warnings have been fixed.

* Various other housekeeping tasks.

<br />
Development
-----------

In case you checkout or clone this repository here is one part of Quicksilver's readme which details an important step in setting Xcode up to build:

>"Building Quicksilver will require you to edit the Configuration/Developer.xcconfig file and point the QS\_SOURCE\_ROOT configuration variable (drag the Quicksilver folder next to this file in the Developer.xcconfig window and remove "file://localhost/" and the ending slash)."

This step is **absolutely crucial**. If you still get lots of errors open the Build Settings panel and make sure that each build configuration is based on the correct xcconfig file (the names should match). Sometimes Xcode just "forgets" that a particular build configuration was based on a xcconfig file, thus losing important settings. 

It is also neccesary to define two Quicksilver specific source trees in Xcode's preferences:

* **QS\_SOURCE\_ROOT** which points to the source root of the download.  
This is so that it can find the Configuration folder and the Xcode project.  
example path: `<source_download>/B5X/Quicksilver`
  

* **QSFrameworks** which points to the Frameworks directory inside Quicksilver.app.  
This obviously needs a previously acquired Quicksilver.app presumably in Applications.  
example path: `/Applications/Quicksilver.app/Contents/Frameworks`. 

Note: The names in bold are important and should be entered *exactly* as shown.

<br />
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
To do so just run the commands again but this time with `--no-assume-unchanged`.

PS.: If any of the git veterans has a better way of handling this please send me a message to my (andreberg) github inbox.