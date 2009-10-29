About Quicksilver on Github
===========================

This repository is an off-the-side copy of the Quicksilver B5X Subversion repository currently hosted at Google Code.
I have done this in the hopes of improving Quicksilver and fixing bugs over time.

If you want more info about [Quicksilver](http://en.wikipedia.org/wiki/Quicksilver_%28software%29 "Quicksilver Wikipedia article") just do a search on YouTube - there's tons of very helpful instructional and informational video tutorials.
Or visit the [mailing list](http://groups.google.com/group/blacktree-quicksilver "Quicksilver Google Group") hosted at Google Groups.

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

`Quicksilver/Configuration/Developer.xcconfig
Quicksilver/PlugIns-Main/Bezel/Info.plist
Quicksilver/PlugIns-Main/Finder/Info.plist
Quicksilver/PlugIns-Main/PrimerInterface/Info.plist
Quicksilver/PlugIns-Main/QSHotKeyPlugIn/Info.plist`

That is because they must be changed on a developer-by-developer basis (Developer.xcconfig) or they change each time the project is built (e.g. the hexadecimal build number is updated by 'bltrversion' for each plugin).

We can't just remove them from the project and add them to the repository-wide .gitignore file because we still need to push those files up to the remote so that another developer will get them when he/she clones the project. 
Also because this project was converted from SVN we can't just tell everyone to add those files to their personal repository-wide exclude file (in .git/info/exclude) and be done with it. If the file is already tracked adding it to any ignore file won't keep git from tracking it (gitignore(5) has more info on that).

What we need is to tell git to just keep the initial version in the repository but not track any changes. 
The following commands seem to do just that:

`git update-index --assume-unchanged Quicksilver/Configuration/Developer.xcconfig
git update-index --assume-unchanged Quicksilver/PlugIns-Main/Bezel/Info.plist
git update-index --assume-unchanged Quicksilver/PlugIns-Main/Finder/Info.plist
git update-index --assume-unchanged Quicksilver/PlugIns-Main/PrimerInterface/Info.plist
git update-index --assume-unchanged Quicksilver/PlugIns-Main/QSHotKeyPlugIn/Info.plist`

This will keep git from noticing any changes but will still keep it (do a `git-ls-files | grep Developer.xcconfig` to confirm).

If you need to make changes to any of those files and you need these changes visible for others to clone then you must revert the commands issued above before commiting.
To do so just run the command again but this time with `--no-assume-unchanged`.

PS.: If any of the git veterans has a better way of handling this please send me a message to my (andreberg) github inbox.