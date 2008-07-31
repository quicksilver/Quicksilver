The B5X branch contains the source for the currently released Quicksilver.
This branch is a mess, and trunk is intended to clean it up for the future.
B5X compatibility for plug-ins may not continue for long.

Building Quicksilver will require you to edit the Configuration/Developer.xcconfig file and point the QS_SOURCE_ROOT configuration variable (drag the Quicksilver folder next to this file in the Developer.xcconfig window and remove "file://localhost/" and the ending slash).