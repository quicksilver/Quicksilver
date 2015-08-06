<!--
This is meant to be rendered using Python-Markdown with its "extra" and
"toc" extensions, or something that supports the same features
-->
[TOC]

# Quicksilver Source Code Guide #

Quicksilver is a large project with lots of history and tribal knowlege. It may seem unapproachable to a new person. It's not (barely), but if we can make things easier, we will.

The goal of this document is to help you get oriented and quickly find what interests you so you can scratch that itch and make Quicksilver better!

## Terminology ##

QSObject
  : The main class for anything that appears in one of Quicksilver's three panes.

The Registry (QSReg)
  : A dumping ground for things you want to keep handy. It's basically a dictionary of global variables.

QSLibrarian
  : A collection of QSObjects. This is essentially what users know as the catalog.

Object Source
  : A class that's responsible for creating and providing information about QSObjects.
 
Catalog Entry
  : These are the things users see under Preferences → Catalog. Each entry defines which object source is responsible for creating and returning objects. There can be many entries using the same object source, changing it's results by passing in settings. For example, entries that use the File & Folder Scanner object source pass it a filesystem path.

Preset
  : Catalog entries that are defined by a plug-in. Everything other than the Custom section of the catalog, in other words.

Direct Object
  : The object in the first pane.

Action
  : The object in the second pane. This should be an instance of `QSAction`. Actions do something with the direct object and (optionally), the indirect object.

Indirect Object
  : The object in the third pane.

Command
  : A command is made up of a direct object, action, and indirect object. This is what actually gets run when you do something in Quicksilver. Triggers are nothing more than commands with some associated event that will execute them.

Results
  : Anything that matched your search, or appears as children of an object. The window that shows a list of items attached to the main interface is called the results list, or results viewer.

Children
  : Many QSObjects have children. These are additional QSObjects that can be accessed by hitting right-arrow or slash.

Alternate Action
  : An action related to an existing action that's commonly desired instead of the more common action. Most actions don't have alternates, but those that do can be run by holding ⌘ when the action is selected. Note that alternate actions can, and usually do, stand alone as normal actions that can be accessed directly.

Mnemonic
  : An abbreviation that points to a QSObject.

Right-arrowing
  : Hitting → or / to reveal an object's children. Left arrow can reverse the process in some cases, for what it's worth.

Comma Trick
  : The name given to the ability to select multiple objects in the first and third panes by hitting ','.

Validation
  : Most actions appear in the second pane based simply on the type of object in the first pane, but some action providers will do additional tests on the object(s) before deciding if an action should be available or not.

## Top-Level Directories ##

The top-level folders are laid out more or less identically in the Xcode project and on the filesystem. Here's a short description of what's in each.

### Configuration ###

Xcode configurations.

Some of the things you see under the Build Settings for the project are set here.

The plug-ins' Xcode projects also use these configurations indirectly. (When you build Quicksilver, this directory is copied to `/tmp/QS/Configuration`. *That* is what the plug-ins actually refer to.)

### QuickStepCore ###

Code for the fundamental objects used in Quicksilver. Some notable examples:

  * QSLibrarian
  * QSRegistry
  * QSObject
  * QSCommand
  * Plug-ins
  * Triggers
  * Rankers
  * Types

More detail is available under "Important Classes" below.

### QuickStepFoundation ###

Mostly customizations and enhancements for existing classes from NeXT and Apple. Also includes some utilities like `QSGCD` and `QSUTI`.

### QuickStepInterface ###

Code related to interface elements.

  * Interface Controller
  * Search Object View
  * Object Cell
  * Borderless Windows
  * Docking Windows
  * Large Type

Except for `QSWindow`, which is under QuickStepEffects for some reason.

### Code-App ###

Code related to launching, managing, and shutting down the application.

### Code-External ###

Third party classes that Quicksilver depends on. Some (but not all) of this code is pulled in as Git submodules.

### QuickStepEffects ###

Code related to transitions and animations …and `QSWindow`.

### PlugIns-Main ###

Code for all the built-in plug-ins.

  * Core Support
  * Keyboard Triggers (formerly "hot keys")
  * Primer Interface
  * Bezel Interface
  * Finder plug-in

### PropertyLists ###

Most (but not all) of the property lists used by the core application.

The application's final `Info.plist` is generated from `Quicksilver-Info.plist`.

`QSRegistration.plist` defines a lot of defaults and fundamental things that aren't in any plug-in.

Some of the most important property lists are under Resources.

### Nibs ###

Most (but not all) of the NIBs used by the core application.

### Resources ###

Images, HTML, and other non-executable stuff.

There are also some important property lists here. Most are self-explanatory. The ones below are especially important.

`QSDefaults.plist` contains the default values for user preferences. (That is, if nothing is set in `~/Library/Preferences/com.blacktree.Quicksilver.plist`, the value here will be used instead.)

`DefaultsMap.plist` defines the contents of the "Extras" section of the preferences.

`ResourceLocations.plist` defines keys and values for images. The key can be passed to `-[QSReg imageNamed:]`. The value can be one of:

  * an absolute path to an image
  * a dictionary defining the bundle that contains the image and the relative path within the bundle
  * an array containing multiple paths or bundle+path dictionaries (useful for supporting multiple versions of the OS when Apple moves things around)

### SharedSupport ###

Some HTML that appears in the application.

### QSDroplet ###

Code and resources for the QSDroplet application.

### Scripting ###

AppleScript and Automator support.

### Tests ###

Code for running unit tests.

## Important Classes ##

### QSObject ###

### QSProxyObject ###

### QSCatalogEntry ###

### QSTrigger ###

### QSCommand ###

### QSObjectRanker ###

## Q&A ##

### Where is the code for this action? ###

Since most actions in plug-ins aren't localized, finding them is pretty straightforward. It can be a bit trickier in the core application.

Assuming you know the name of the action, you can usually find it by:

  1. Figuring out the action's identifier
  2. Finding the identifier in the appropriate plug-in's property list under `QSActions`
  3. Searching within the same plug-in for all or part of the `actionSelector` listed for that action in the property list

Step 1 usually boils down to searching the entire project for the name of the action. You will probably find it in many `.strings` files. Just pick one to open that file and select the text you searched for. The line above should contain the key for that localization, which is also the identifier for that action.

You could search the entire project again for the identifier to complete step 2, but it will appear in all the localizations, and since we're talking about the core application, almost every action is defined in the Core Support plug-in anyway. So once you have the identifier, you can most likely find the action by just searching within `QSCorePlugIn-Info.plist`.

Once you find the action under `QSActions`, the `actionClass` and `actionSelector` will tell you where the code is. If you know where the class is defined, just go to it. If not, searching for the name of the class or the selector should get you there.

Keep in mind that actions that take something in the third pane will have a selector like `openFile:with:`, but the corresponding code will be `openFile:dObject with:iObject`. So for actions that take more than one argument, don't try searching for the literal `actionSelector`. You won't find it.

### Where is the code that handles keystrokes? ###

When the main Quicksilver interface has focus, keystrokes are intercepted by `keyDown:` in `QSSearchObjectView`. This is where keys with special behavior, like `/`, `~`, Spacebar, etc. are detected and handled.

### How does Quicksilver learn? ###

The information in `~/Library/Application Support/Quicksilver/Mnemonics.plist` heavily influences an object's rank. This file is constantly updated and stores a single dictionary with two top-level keys: `abbreviation` and `implied`.

Every sequence of letters and numbers you type into Quicksilver becomes a key under `abbreviation`. The value for each is an array of object identifiers. If you type an abbreviation, then "use" a particular object, Quicksilver will remember that so it can rank that object higher next time.

"Using" an object includes anything where the user indicates "this is the one I wanted":

  * running an action on it
  * right-arrowing into it
  * selecting additional objects with the comma trick

The `implied` dictionary is sort of the reverse of `abbreviation`. The keys are object identifiers and the values are dictionaries of abbreviations used for that object, along with the number of times that abbreviation was used. This helps break ties for abbreviations that have been used for many things. It's especially important for one-letter abbreviations, since there's so little to go on.

Open up your own `Mnemonics.plist` and look around. It's pretty straightforward.

### How is the list of actions populated? ###

There are two things to discuss here: What actions are on the list, and what order are they in?

Order first. When an object is selected in the first pane, the list of actions in the second pane is ordered according to the arrangement in Preferences → Actions. The number of times you've used an action is irrelevant at this point. As soon as you type single letter, that all goes out the window and actions are sorted by rank. Rank is mostly determined by what Quicksilver has learned and stored in `Mnemonics.plist`.

As for which actions are on the list in the first place, there are three main factors.

  * the object's type
  * the file type (if the object represents a file)
  * the result of any additional validation

Objects can have more than one type, and actions can support more than one type but in the end, if an action claims to support a particular type and the selected object has that type, the action could potentially appear. (It could still be excluded based on file type or validation.) For example, the primary type for URLs is `QSURLType`, which the Open URL action supports. But URLs also have `QSTextType`, which allows any action that works on text to also work on URL objects in Quicksilver.

Actions that apply to `QSFileType` can be more specific by also listing specific types of files the action should support. For example, the action that runs AppleScript files will not appear unless the file in the first pane is an AppleScript.

The validation process (defined by `validActionsForDirectObject:indirectObject:` in each individual action provider class) can further limit the actions that appear on the list by examining the direct and indirect objects. For example, the Quit action can be limited by type to applications, but it really doesn't make sense to show "Quit" for an application that isn't running. The validation process can see if the direct object represents a running application before returning the Quit action's identifier.

As an aside, checking file types is really just a special case of validation. It was just such a common use-case that it was made much easier to implement (by just listing types in a property list).

## Check Lists ##

There are many parts of the application that work together. Getting everything hooked up correctly and having all the supporting elements in place is one of the biggest challenges. Here are some common things you might want to do and a short description of the requirements.

Many of these things, like adding actions, proxy objects, object sources, etc. are already discussed in the [Plug-in Development Reference][pluginref] and won't be repeated here.

### Add a new Preference ###

  * choose a key name for the preference
  * optionally, define a constant for the name
  * add the control to the appropriate NIB
  * set a default value for the preference in `Resources/QSDefaults.plist`
  * write code to read the preference like you normally would

[pluginref]: http://projects.skurfer.com/QuicksilverPlug-inReference.mdown
