#!/bin/bash

SCRIPT_DIR=$(dirname $0)
PROJECT_ROOT=$(realpath "$SCRIPT_DIR/../../../..")
MODULE_ROOT=$(realpath "$SCRIPT_DIR")
DEPENDENCIES_DIR="$PROJECT_ROOT/external_dependencies"
DEPENDENCIES_OBJ_DIR="$DEPENDENCIES_DIR/objs"
DEPENDENCIES_LOCAL_OBJ_DIR="$DEPENDENCIES_DIR/local_objs"
REPOSITORIES_DIR="$DEPENDENCIES_DIR/git"

rollback_installation () {
	if [ -d "$DEPENDENCY_REPOSITORY_DIR/.git" ]; then
		echo "Rolling back: deleting '$DEPENDENCY_REPOSITORY_DIR'"
		rm -rf "$DEPENDENCY_REPOSITORY_DIR"
	fi
}

mkdir -p "$REPOSITORIES_DIR"

##################### Command Line Interface ##########################
GIT_URL="$1"
if [ "$GIT_URL" == "" ]; then
	echo "Error: unspecified git URL"
	exit 1
fi
GIT_COMMIT="$2"
LOCAL_ONLY="$3"
GIT_OBJS_DIR="$4"
GIT_INCLUDE_DIR="$5"
POST_DOWNLOAD_SCRIPT="$6"
##################### Command Line Interface ##########################

if [ "$IGNORE_LOCAL_DEPENDENCIES" == "true" ] && [ "$LOCAL_ONLY" == "true" ]; then
	echo "Info: skipping local dependency 'git ${GIT_URL}'" 1>&2
	exit 0
else
	echo "Info: installing dependency 'git ${GIT_URL}'" 1>&2
fi

GIT_URL_IS_HTTP=$(echo "$GIT_URL" | grep -oe "^http")
if [ "$GIT_URL_IS_HTTP" == "" ]; then
	echo "Error: not an HTTP git URL"
	exit 1
fi

RELATIVE_DEPENDENCY_REPOSITORY_DIR=$(echo "$GIT_URL" | sed "s/^.*\///; s/\.git$//")
DEPENDENCY_REPOSITORY_DIR="$REPOSITORIES_DIR/$RELATIVE_DEPENDENCY_REPOSITORY_DIR"

if [ -d "$DEPENDENCY_REPOSITORY_DIR" ]; then
	echo "Info: Dependency '$DEPENDENCY_REPOSITORY_DIR' already cloned" 1>&2
else
	cd "$REPOSITORIES_DIR"
	git clone "$GIT_URL"
	GIT_EXECUTION_STATUS=$?
	if [ "$GIT_EXECUTION_STATUS" != "0" ]; then
		exit 1
	fi
fi
cd "$DEPENDENCY_REPOSITORY_DIR"

if [ "$GIT_COMMIT" == "" ]; then
	LASTEST_TAGGED_COMMIT=$(git tag --sort refname | tail -n 1)
	echo "Info: commit not specified, using latest tagged commit ($LASTEST_TAGGED_COMMIT)" 1>&2
	GIT_COMMIT=$LASTEST_TAGGED_COMMIT
fi

echo "Info: checking out $GIT_COMMIT" 1>&2
git checkout -q $GIT_COMMIT
CHECKOUT_STATUS=$?
if [ "$CHECKOUT_STATUS" != "0" ]; then
	echo "Error: not a valid commit: '$GIT_COMMIT'"
	rollback_installation
	exit 1
fi

if [ "$POST_DOWNLOAD_SCRIPT" != "" ]; then
	echo "Info: executing post download script '$POST_DOWNLOAD_SCRIPT'" 1>&2
	$POST_DOWNLOAD_SCRIPT
fi

if [ "$GIT_OBJS_DIR" == "" ]; then
	GIT_OBJS_DIR="src/objs"
	echo "Info: OBJS_DIR not specified, using '$GIT_OBJS_DIR'"
fi

if [ "$GIT_INCLUDE_DIR" == "" ]; then
	GIT_INCLUDE_DIR="src/objs"
	echo "Info: INCLUDE_DIR not specified, using '$GIT_INCLUDE_DIR'"
fi

if [ ! -d "$DEPENDENCY_REPOSITORY_DIR/$GIT_OBJS_DIR" ]; then
		echo "Error: no directory '$GIT_OBJS_DIR' in project's root"
		rollback_installation
		exit 1
fi

if [ ! -d "$DEPENDENCY_REPOSITORY_DIR/$GIT_INCLUDE_DIR" ]; then
		echo "Error: no directory '$GIT_INCLUDE_DIR' in project's root"
		rollback_installation
		exit 1
fi

if [ "$LOCAL_ONLY" == "" ]; then
	LOCAL_ONLY="false"
fi

if [ "$LOCAL_ONLY" == "false" ]; then
	DEPENDENCY_INSTALL_DIR="$DEPENDENCIES_OBJ_DIR/$RELATIVE_DEPENDENCY_REPOSITORY_DIR"
else
	DEPENDENCY_INSTALL_DIR="$DEPENDENCIES_LOCAL_OBJ_DIR/$RELATIVE_DEPENDENCY_REPOSITORY_DIR"
fi
mkdir -p "$DEPENDENCY_INSTALL_DIR"

echo "Info: linking '$DEPENDENCY_REPOSITORY_DIR/$GIT_OBJS_DIR/*' in '$DEPENDENCY_INSTALL_DIR/'" 1>&2
ln -s "$DEPENDENCY_REPOSITORY_DIR/$GIT_OBJS_DIR/"* "$DEPENDENCY_INSTALL_DIR/"
if [ "$GIT_OBJS_DIR" != "$GIT_INCLUDE_DIR" ]; then
	echo "Info: linking '$DEPENDENCY_REPOSITORY_DIR/$GIT_INCLUDE_DIR/*' in '$DEPENDENCY_INSTALL_DIR/'" 1>&2
	ln -s "$DEPENDENCY_REPOSITORY_DIR/$GIT_INCLUDE_DIR/"* "$DEPENDENCY_INSTALL_DIR/"
fi

if [ -f "$DEPENDENCY_REPOSITORY_DIR/dependencies.sh" ]; then
	echo "Info: recursively installing dependencies" 1>&2
	"$DEPENDENCY_REPOSITORY_DIR/dependencies.sh" install --ignore-local-dependencies
	HAS_RECURSIVE_DEPENDENCIES=$(ls -A "$DEPENDENCY_REPOSITORY_DIR/external_dependencies/objs")
	if [ "$HAS_RECURSIVE_DEPENDENCIES" != "" ]; then
		echo "Info: linking '$DEPENDENCY_REPOSITORY_DIR/external_dependencies/objs/*' in '$DEPENDENCIES_OBJ_DIR/'" 1>&2
		ln -s "$DEPENDENCY_REPOSITORY_DIR/external_dependencies/objs/"* "$DEPENDENCIES_OBJ_DIR/"
	fi
fi

echo "Info: dependency configured: $GIT_URL $GIT_COMMIT $LOCAL_ONLY \"$GIT_OBJS_DIR\" \"$GIT_INCLUDE_DIR\" \"$POST_DOWNLOAD_SCRIPT\""

