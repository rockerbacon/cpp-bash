#!/bin/bash

REPOSITORIES_DIR="$DEPENDENCIES_DIR/git"

INITIAL_WORKDIR=$PWD
FROZEN_ARGS=""
GIT_COMMIT=""
LOCAL_ONLY=""
GIT_OBJS_DIR=""
GIT_INCLUDE_DIR=""
BEFORE_LINKING_SCRIPT=""
DEPENDENCY_NAME=""
GIT_SERVER_DOMAIN=""
DOWNLOAD_PROTOCOL=""

rollback_installation () {
	if [ -d "$DEPENDENCY_REPOSITORY_DIR/.git" ]; then
		echo "Rolling back: deleting '$DEPENDENCY_REPOSITORY_DIR'"
		rm -rf "$DEPENDENCY_REPOSITORY_DIR"
		cd "$INITIAL_WORKDIR"
	fi
}

mkdir -p "$REPOSITORIES_DIR"

##################### Command Line Interface ##########################
GIT_PATH="$1"
shift
if [ "$GIT_PATH" == "" ]; then
	log_error "unspecified git path"
	return 1
fi
FROZEN_ARGS="$GIT_PATH"

until [ -z "$1" ]; do

	case "$1" in

	--version)
		GIT_COMMIT="$2"
		shift
	;;

	--local-only)
		LOCAL_ONLY=true
		FROZEN_ARGS="$FROZEN_ARGS --local-only"
	;;

	--objs-dir)
		GIT_OBJS_DIR="$2"
		FROZEN_ARGS="$FROZEN_ARGS --objs-dir '$GIT_OBJS_DIR'"
		shift
	;;

	--include-dir)
		GIT_INCLUDE_DIR="$2"
		FROZEN_ARGS="$FROZEN_ARGS --include-dir '$GIT_INCLUDE_DIR'"
		shift
	;;

	--before-linking)
		BEFORE_LINKING_SCRIPT="$2"
		FROZEN_ARGS="$FROZEN_ARGS --before-linking '$BEFORE_LINKING_SCRIPT'"
		shift
	;;

	--alias)
		DEPENDENCY_NAME="$2"
		FROZEN_ARGS="$FROZEN_ARGS --alias '$DEPENDENCY_NAME'"
		shift
	;;

	--domain)
		GIT_SERVER_DOMAIN="$2"
		FROZEN_ARGS="$FROZEN_ARGS --domain '$GIT_SERVER_DOMAIN'"
		shift
	;;

	--use-http)
		DOWNLOAD_PROTOCOL="http"
		FROZEN_ARGS="$FROZEN_ARGS --use-http"
	;;

	esac

	shift
done
##################### Command Line Interface ##########################

if [ "$IGNORE_LOCAL_DEPENDENCIES" == "true" ] && [ "$LOCAL_ONLY" == "true" ]; then
	log_info "skipping local dependency 'git ${GIT_PATH}'"
	return 0
else
	log_info "installing dependency 'git ${GIT_PATH}'"
fi

if [ "$DEPENDENCY_NAME" == "" ]; then
	DEPENDENCY_NAME=$(echo "$GIT_PATH" | sed "s/^.*\///")
fi

DEPENDENCY_REPOSITORY_DIR="$REPOSITORIES_DIR/$DEPENDENCY_NAME"

if [ "$DOWNLOAD_PROTOCOL" == "" ]; then
	DOWNLOAD_PROTOCOL="https"
fi

if [ "$GIT_SERVER_DOMAIN" == "" ]; then
	GIT_SERVER_DOMAIN="github.com"
fi

REPOSITORY_URL="$DOWNLOAD_PROTOCOL://$GIT_SERVER_DOMAIN/$GIT_PATH.git"

if [ -d "$DEPENDENCY_REPOSITORY_DIR" ]; then
	log_info "dependency '$DEPENDENCY_REPOSITORY_DIR' already cloned"
else
	git clone "$REPOSITORY_URL" "$DEPENDENCY_REPOSITORY_DIR"; CLONE_STATUS=$?
	if [ $CLONE_STATUS -ne 0 ]; then
		return 1
	fi
fi

log_info "changing directory to '$DEPENDENCY_REPOSITORY_DIR'"
cd "$DEPENDENCY_REPOSITORY_DIR"

if [ "$GIT_COMMIT" == "" ]; then
	GIT_COMMIT=$(git tag --sort refname | tail -n 1)
	log_info "commit not specified, using latest tagged commit ($GIT_COMMIT)"
fi
FROZEN_ARGS="$FROZEN_ARGS --version $GIT_COMMIT"

log_info "checking out $GIT_COMMIT"
git checkout -q $GIT_COMMIT; CHECKOUT_STATUS=$?
if [ $CHECKOUT_STATUS -ne 0 ]; then
	log_error "not a valid commit: '$GIT_COMMIT'"
	rollback_installation
	return 1
fi

if [ "$BEFORE_LINKING_SCRIPT" != "" ]; then
	log_info "executing script '$BEFORE_LINKING_SCRIPT'"
	$BEFORE_LINKING_SCRIPT
fi

if [ "$GIT_OBJS_DIR" == "" ]; then
	GIT_OBJS_DIR="src/objs"
	log_info "--objs-dir not specified, using '$GIT_OBJS_DIR'"
fi

if [ "$GIT_INCLUDE_DIR" == "" ]; then
	GIT_INCLUDE_DIR="src/objs"
	log_info "--include-dir not specified, using '$GIT_INCLUDE_DIR'"
fi

if [ ! -d "$DEPENDENCY_REPOSITORY_DIR/$GIT_OBJS_DIR" ]; then
		log_error "no directory '$GIT_OBJS_DIR' in project's root"
		rollback_installation
		return 1
fi

if [ ! -d "$DEPENDENCY_REPOSITORY_DIR/$GIT_INCLUDE_DIR" ]; then
		log_error "no directory '$GIT_INCLUDE_DIR' in project's root"
		rollback_installation
		return 1
fi

if [ "$LOCAL_ONLY" == "" ]; then
	LOCAL_ONLY="false"
fi

if [ "$LOCAL_ONLY" == "false" ]; then
	DEPENDENCY_INSTALL_DIR="$DEPENDENCIES_OBJS_DIR/$DEPENDENCY_NAME"
else
	DEPENDENCY_INSTALL_DIR="$DEPENDENCIES_LOCAL_OBJS_DIR/$DEPENDENCY_NAME"
fi
mkdir -p "$DEPENDENCY_INSTALL_DIR"

log_info "linking '$DEPENDENCY_REPOSITORY_DIR/$GIT_OBJS_DIR/*' in '$DEPENDENCY_INSTALL_DIR/'"
ln -s "$DEPENDENCY_REPOSITORY_DIR/$GIT_OBJS_DIR/"* "$DEPENDENCY_INSTALL_DIR/"
if [ "$GIT_OBJS_DIR" != "$GIT_INCLUDE_DIR" ]; then
	log_info "linking '$DEPENDENCY_REPOSITORY_DIR/$GIT_INCLUDE_DIR/*' in '$DEPENDENCY_INSTALL_DIR/'"
	ln -s "$DEPENDENCY_REPOSITORY_DIR/$GIT_INCLUDE_DIR/"* "$DEPENDENCY_INSTALL_DIR/"
fi

if [ -f "$DEPENDENCY_REPOSITORY_DIR/dependencies.sh" ]; then
	log_info "recursively installing dependencies"
	"$DEPENDENCY_REPOSITORY_DIR/dependencies.sh" install --ignore-local-dependencies
	HAS_RECURSIVE_DEPENDENCIES=$(ls -A "$DEPENDENCY_REPOSITORY_DIR/external_dependencies/objs")
	if [ "$HAS_RECURSIVE_DEPENDENCIES" != "" ]; then
		log_info "linking '$DEPENDENCY_REPOSITORY_DIR/external_dependencies/objs/*' in '$DEPENDENCIES_OBJS_DIR/'"
		ln -s "$DEPENDENCY_REPOSITORY_DIR/external_dependencies/objs/"* "$DEPENDENCIES_OBJS_DIR/"
	fi
fi

freeze_args "$FROZEN_ARGS"
cd "$INITIAL_WORKDIR"

