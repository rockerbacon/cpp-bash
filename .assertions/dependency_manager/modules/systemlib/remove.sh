#!/bin/bash

SCRIPT_DIR=$(dirname $0)
PROJECT_ROOT=$(realpath "$SCRIPT_DIR/../../../..")
DEPENDENCIES_DIR="$PROJECT_ROOT/external_dependencies"
DEPENDENCIES_LIB_DIR="$DEPENDENCIES_DIR/lib"

################### Command Line Interface #########################
LIBRARY="$1"
if [ "$LIBRARY" == "" ]; then
	echo "Error: unspecified library"
	exit 1
fi
################### Command Line Interface #########################

LIBRARY_LINK=$(find "$DEPENDENCIES_LIB_DIR" -maxdepth 1 -regextype posix-egrep -regex "$DEPENDENCIES_LIB_DIR/lib${LIBRARY}\.(so|a)")

if [ "$LIBRARY_LINK" == "" ]; then
	echo "Info: dependency not linked to project" 1>&2
elif [ ! -L "$LIBRARY_LINK" ]; then
	echo "Error: '$LIBRARY_LINK' is not a symbolic link"
	exit 1
else
	echo "Info: removing link '$LIBRARY_LINK'" 1>&2
	rm "$LIBRARY_LINK"
fi

