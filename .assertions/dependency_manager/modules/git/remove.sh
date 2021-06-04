#!/bin/bash

REPOSITORIES_DIR="$DEPENDENCIES_DIR/git"

##################### Command Line Interface ##########################
REPOSITORY_PATH="$1"
if [ "$REPOSITORY_PATH" == "" ]; then
	log_error "unspecified repository path"
	return 1
fi
##################### Command Line Interface ##########################

DEPENDENCY_NAME=$(echo "$REPOSITORY_PATH" | sed "s/^.*\///")
DEPENDENCY_REPOSITORY_DIR="$REPOSITORIES_DIR/$DEPENDENCY_NAME"

if [ ! -d "$DEPENDENCY_REPOSITORY_DIR" ]; then
	log_info "dependency not installed"
else
	if [ ! -d "$DEPENDENCY_REPOSITORY_DIR/.git" ]; then
		log_error "dependency is not a git repository"
		return 1
	fi
	log_info "deleting '$DEPENDENCY_REPOSITORY_DIR'"
	rm -rf "$DEPENDENCY_REPOSITORY_DIR"
fi

if [ ! -d "$DEPENDENCIES_OBJS_DIR/$DEPENDENCY_NAME" ]; then
	log_info "dependency not linked"
else
	log_info "removing links in '$DEPENDENCIES_OBJS_DIR/$DEPENDENCY_NAME'"
	rm -rf "$DEPENDENCIES_OBJS_DIR/$DEPENDENCY_NAME"
fi

if [ ! -d "$DEPENDENCIES_LOCAL_OBJS_DIR/$DEPENDENCY_NAME" ]; then
	log_info "dependency not linked as a local dependency"
else
	log_info "removing links in '$DEPENDENCIES_LOCAL_OBJS_DIR/$DEPENDENCY_NAME'"
	rm -rf "$DEPENDENCIES_LOCAL_OBJS_DIR/$DEPENDENCY_NAME"
fi

ALL_INSTALLED_DEPENDENCIES=$(ls -f -1 --color=never "$DEPENDENCIES_OBJS_DIR")
for INSTALLED_DEPENDENCY in $ALL_INSTALLED_DEPENDENCIES; do
	ABSOLUTE_DEPENDENCY_PATH="$DEPENDENCIES_OBJS_DIR/$INSTALLED_DEPENDENCY"
	readlink -qe "$ABSOLUTE_DEPENDENCY_PATH"
	DEPENDENCY_NOT_BROKEN=$?
	if [ "$DEPENDENCY_NOT_BROKEN" != "0" ]; then
		log_info "removing broken dependency '$INSTALLED_DEPENDENCY'"
		rm -rf "$ABSOLUTE_DEPENDENCY_PATH"
	fi
done

