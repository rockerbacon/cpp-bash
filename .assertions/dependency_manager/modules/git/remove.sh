#!/bin/bash

SCRIPT_DIR=$(dirname $0)
PROJECT_ROOT=$(realpath "$SCRIPT_DIR/../../../..")
MODULE_ROOT=$(realpath "$SCRIPT_DIR")
DEPENDENCIES_DIR="$PROJECT_ROOT/external_dependencies"
DEPENDENCIES_OBJ_DIR="$DEPENDENCIES_DIR/objs"
REPOSITORIES_DIR="$DEPENDENCIES_DIR/git"

##################### Command Line Interface ##########################
REPOSITORY_PATH="$1"
if [ "$REPOSITORY_PATH" == "" ]; then
	echo "Error: unspecified repository path"
	exit 1
fi
##################### Command Line Interface ##########################

DEPENDENCY_NAME=$(echo "$REPOSITORY_PATH" | sed "s/^.*\///")
DEPENDENCY_REPOSITORY_DIR="$REPOSITORIES_DIR/$DEPENDENCY_NAME"

if [ ! -d "$DEPENDENCY_REPOSITORY_DIR" ]; then
	echo "Info: dependency not installed" 1>&2
else
	if [ ! -d "$DEPENDENCY_REPOSITORY_DIR/.git" ]; then
		echo "Error: dependency is not a git repository"
		exit 1
	fi
	echo "Info: deleting '$DEPENDENCY_REPOSITORY_DIR'" 1>&2
	rm -rf "$DEPENDENCY_REPOSITORY_DIR"
fi

if [ ! -d "$DEPENDENCIES_OBJ_DIR/$DEPENDENCY_NAME" ]; then
	echo "Info: dependency source not linked" 1>&2
else
	echo "Info: removing links in '$DEPENDENCIES_OBJ_DIR/$DEPENDENCY_NAME'" 1>&2
	rm -rf "$DEPENDENCIES_OBJ_DIR/$DEPENDENCY_NAME"
fi

ALL_INSTALLED_DEPENDENCIES=$(ls -f -1 --color=never "$DEPENDENCIES_OBJ_DIR")
for INSTALLED_DEPENDENCY in $ALL_INSTALLED_DEPENDENCIES; do
	ABSOLUTE_DEPENDENCY_PATH="$DEPENDENCIES_OBJ_DIR/$INSTALLED_DEPENDENCY"
	readlink -qe "$ABSOLUTE_DEPENDENCY_PATH"
	DEPENDENCY_NOT_BROKEN=$?
	if [ "$DEPENDENCY_NOT_BROKEN" != "0" ]; then
		echo "Info: removing broken dependency '$INSTALLED_DEPENDENCY'" 1>&2
		rm -rf "$ABSOLUTE_DEPENDENCY_PATH"
	fi
done

