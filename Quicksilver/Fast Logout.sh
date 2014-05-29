#!/bin/sh
if [[ -z $1 ]]; then
  /System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend > /dev/null
else
  USERID=`id -u $1`;
  if [[ -z $USERID ]]; then
    exit -1;
  fi;
  /System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -switchToUserID $USERID > /dev/null
fi;
