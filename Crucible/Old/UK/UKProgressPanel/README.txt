PROGRESS PANEL
--------------


WHAT IS IT?

UKProgressPanel is a class that displays a scrolling list of progress bars and
status text fields, plus a "Stop" button, in a single window, just like the
Finder does it when copying files, or MT-NewsWatcher does when retrieving news.

This is a very useful commodity e.g. in threaded applications for displaying
feedback for a number of processes without littering the desktop with progress
windows or hiding away status fields and progress bars at the bottom of the
window.

UKProgressPanel has been written to be thread-safe. However, I'm new to
threaded programming, and most of Cocoa isn't yet thread-safe. It worked in my
tests, but be sure to perform testing if you're using a progress panel from
another thread than the main thread.


HOW DO I USE IT?

The progress panel has been designed to be hassle-free:

1) create a UKProgressPanelTask when you begin your operation
2) use it like a progress bar (the method names are the same)
3) have it send you a message or check its "stopped" member variable to find
out whether the user wants to cancel the operation.
4) release the object to have its entry in the progress panel removed.

UKProgressPanelTask will automatically take care of creating a progress panel
if needed. If you just want to use the progress panel, you needn't really
concern yourself with this class.

There is also an action method orderFrontProgressPanel: added to NSApplication,
which you can use to add a "Tasks" menu item to your "Window" menu to re-show
the task panel once the progress panel has been hidden through a click in its
close box.


WHAT LICENSE IS THIS UNDER?

UKProgressPanel is free for use in Freeware and in-house applications, as
long as you put a notice somewhere visible (about screen is OK) in the
application that states that you're using UKProgressPanel (c) 2003 by M.
Uli Kusterer.

For use in commercial or Shareware products, contact me to obtain a license.
Please include some information about the program you're using
UKProgressPanel in.

Another requirement for use of UKProgressPanel is that you make any
changes you do to the source code available to me so I can consider them for
inclusion in the official distribution.

You may distribute the source code as long as no more than the cost price
of the actual transfer medium (online fees or media cost) are charged, and
the code is unchanged, and this readme file is included. If you want to
distribute this code otherwise, contact me to get a license.


REVISIONS:
	0.1	-	First public release.


CONTACT INFORMATION

You can find the newest version of UKProgressPanel at
	http://www.zathras.de/programming/cocoa_stuff.php

E-Mail: witness.of.teachtext@gmx.net




M. Uli Kusterer, Heidelberg, 2003-09-25