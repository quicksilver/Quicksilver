#!/bin/sh
#
# Install Homebrew then "brew install appledoc"
#

PATH=$PATH:/usr/local/bin

PWD=`basename \`dirname $0\``

APPLEDOC_LOGFORMAT="0"
if [ "x$SRCROOT" != "x" ]; then
    # Use Xcode env var for the source root
    PROJECT_ROOT=$SRCROOT
    APPLEDOC_LOGFORMAT="xcode"
elif [ "x$PWD" != "x." ]; then
     # Running from source root
    PROJECT_ROOT="$(pwd)"
else
    # Running from ./Tools
    PROJECT_ROOT="$(pwd)/.."
fi

# cd $PROJECT_ROOT

DOCUMENTATION_SEARCH_PATHS="$PROJECT_ROOT/Code-QuickStep* $PROJECT_ROOT/Code-App"
DOCSET_URL="http://qsapp.com/docs"
OUTPUT_DIRECTORY="$PROJECT_ROOT/Docs"
PROJECT_NAME="Quicksilver"
COMPANY_ID="com.qsapp"

APPLEDOC_ARGUMENTS=" --exit-threshold 2 \
 --no-warn-undocumented-object \
 --no-warn-undocumented-member \
 --keep-undocumented-members \
 --keep-undocumented-objects \
 --print-settings \
 --project-name $PROJECT_NAME \
 --project-company $PROJECT_NAME \
 --company-id $COMPANY_ID \
 --output "$OUTPUT_DIRECTORY" \
 --logformat $APPLEDOC_LOGFORMAT \
"

# -d or --docset enables docset creation
if [ "x$1" = "x-d" -o "x$1" = "x--docset" ]; then
    DOCSET_ARGUMENTS="--docset-feed-url \"$DOCSET_URL/%DOCSETATOMFILENAME\" --docset-package-url \"$DOCSET_URL/%DOCSETPACKAGEFILENAME\" --create-docset --keep-intermediate-files"
else
    DOCSET_ARGUMENTS="--no-create-docset"
fi

echo "appledoc $APPLEDOC_ARGUMENTS $DOCSET_ARGUMENTS $DOCUMENTATION_SEARCH_PATHS"

# --logformat xcode \
appledoc \
 $APPLEDOC_ARGUMENTS \
 $DOCSET_ARGUMENTS \
$DOCUMENTATION_SEARCH_PATHS
