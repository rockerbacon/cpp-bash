#!/bin/bash

SYSTEM_LIBRARY_DIRS=("/lib/x86_64-linux-gnu")
SYSTEM_LIBRARY_DIRS+=("/usr/lib/x86_64-linux-gnu")
SYSTEM_LIBRARY_DIRS+=("/lib/i386-linux-gnu")
SYSTEM_LIBRARY_DIRS+=("/usr/lib/i386-linux-gnu")

SCRIPT_DIR=$(realpath $(dirname $0))
PROJECT_ROOT=$(realpath "$SCRIPT_DIR/../../../../")
DEPENDENCIES_DIR="$PROJECT_ROOT/external_dependencies"
DEPENDENCIES_LIB_DIR="$DEPENDENCIES_DIR/lib"

################### Command Line Interface #################
LIBRARY="$1"
if [ "$LIBRARY" == "" ]; then
	echo "Error: unspecified library"
	exit 1
fi
LINK_STATICALLY="$2"
################## Command Line Interface #################

if [ "$LINK_STATICALLY" == "static" ]; then
	FULL_LIBRARY_NAME="lib${LIBRARY}.a"
else
	FULL_LIBRARY_NAME="lib${LIBRARY}.so"
fi

echo "Info: searching for library file '${FULL_LIBRARY_NAME}'" 1>&2
for LIBRARY_DIR in ${SYSTEM_LIBRARY_DIRS[@]}
do
	echo "Info: searching folder ${LIBRARY_DIR}" 1>&2
	LIBRARY_FILE=$(find "$LIBRARY_DIR" -regex ".*$FULL_LIBRARY_NAME.*" -print -quit)
	if [ "$LIBRARY_FILE" != "" ]; then
		break
	fi
done

if [ "$LIBRARY_FILE" == "" ]; then
	echo "Error: could not find '${FULL_LIBRARY_NAME}'"
	exit 1
fi

echo "Info: found file '$LIBRARY_FILE'" 1>&2

if [ -f "$DEPENDENCIES_LIB_DIR/$FULL_LIBRARY_NAME" ]; then
	echo "Info: library already linked"
else
	echo "Info: linking dependency to '$DEPENDENCIES_LIB_DIR'" 1>&2
	ln -s "$LIBRARY_FILE" "$DEPENDENCIES_LIB_DIR/$FULL_LIBRARY_NAME"
fi

echo "Info: dependency configured: $LIBRARY $LINK_STATICALLY" 1>&2

