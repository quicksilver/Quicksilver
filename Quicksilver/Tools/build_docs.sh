#!/bin/sh
#
# Install Homebrew then "brew install appledoc"
#

PATH=$PATH:/usr/local/bin

PWD=`basename \`dirname $0\``

if [ "x$SRCROOT" != "x" ]; then
    # Use Xcode env var for the source root
    PROJECT_ROOT=$SRCROOT
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
APPLEDOC_LOGFORMAT="html"

# -d or --docset enables docset creation
if [ "x$1" = "x-d" -o "x$1" = "x--docset" ]; then
    APPLEDOC_LOGFORMAT="xcode"
    DOCSET_ARGUMENTS="--docset-feed-url \"$DOCSET_URL/%DOCSETATOMFILENAME\" --docset-package-url \"$DOCSET_URL/%DOCSETPACKAGEFILENAME\" --publish-docset --keep-intermediate-files"
else
    DOCSET_ARGUMENTS="--no-create-docset"
fi

echo "appledoc --output $OUTPUT_DIRECTORY $DOCSET_ARGUMENTS $DOCUMENTATION_SEARCH_PATHS"

# --logformat xcode \
appledoc \
 --exit-threshold 2 \
 --keep-undocumented-members \
 --keep-undocumented-objects \
 --print-settings \
 --project-name $PROJECT_NAME \
 --project-company $PROJECT_NAME \
 --company-id $COMPANY_ID \
 --output "$OUTPUT_DIRECTORY" \
 --logformat $APPLEDOC_LOGFORMAT \
 $DOCSET_ARGUMENTS \
$DOCUMENTATION_SEARCH_PATHS
