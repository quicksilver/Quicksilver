#!/bin/bash
#
# Build the doxygen documentation for the project and load the docset into Xcode 
#
# Created by Fred McCann on 03/16/2010.
# Last updated 10/26/2010.
# http://www.duckrowing.com
#
# Based on the build script provided by Apple:
# http://developer.apple.com/tools/creatingdocsetswithdoxygen.html
#
# Set the variable $COMPANY_RDOMAIN_PREFIX equal to the reverse domain name of your comany
# Example: com.duckrowing
#

DOXYGEN_PATH="/Applications/Doxygen.app/Contents/Resources/doxygen"
OUTPUT_PATH="$TARGET_BUILD_DIR/Docs"

mkdir -p $OUTPUT_PATH

if ! [ -f "$SOURCE_ROOT/Tools/Doxyfile" ] ; then
  echo doxygen config file does not exist
  $DOXYGEN_PATH -g "$SOURCE_ROOT/Doxyfile"
fi

#  Append the proper input/output directories and docset info to the config file.
#  This works even though values are assigned higher up in the file. Easier than sed.

cp "$SOURCE_ROOT/Tools/Doxyfile" "$TEMP_DIR/Doxyfile"

echo "INPUT = \"$SOURCE_ROOT\"" >> "$TEMP_DIR/Doxyfile"
echo "OUTPUT_DIRECTORY = \"$OUTPUT_PATH\"" >> "$TEMP_DIR/Doxyfile"
echo "RECURSIVE = YES" >> "$TEMP_DIR/Doxyfile"
if [ "$1" = "BUILD_DOCSET" ] ; then
	echo "Building Docset"
	echo "GENERATE_DOCSET       = YES" >> "$TEMP_DIR/Doxyfile"
	echo "DOCSET_FEEDNAME       = $PRODUCT_NAME Documentation" >> "$TEMP_DIR/Doxyfile"
	echo "DOCSET_BUNDLE_ID      = $COMPANY_RDOMAIN_PREFIX.$PRODUCT_NAME" >> "$TEMP_DIR/Doxyfile"
	echo "DOCSET_PUBLISHER_ID   = $COMPANY_RDOMAIN_PREFIX.$PRODUCT_NAME" >> "$TEMP_DIR/Doxyfile"
	echo "DOCSET_PUBLISHER_NAME = $PRODUCT_NAME" >> "$TEMP_DIR/Doxyfile"
fi
echo "STRIP_FROM_PATH = $SOURCE_ROOT" >> "$TEMP_DIR/Doxyfile"

#  Run doxygen on the updated config file.
#  Note: doxygen creates a Makefile that does most of the heavy lifting.

$DOXYGEN_PATH "$TEMP_DIR/Doxyfile"

exit 0				
