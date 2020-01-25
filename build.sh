#!/bin/bash

PROJECT_ROOT=$(realpath $(dirname $0))
BUILD_DIR="$PROJECT_ROOT/build"
DEPENDENCIES_DIR="$PROJECT_ROOT/external_dependencies"
DEPENDENCY_MANAGER_DIR="$PROJECT_ROOT/.assertions/dependency_manager"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

######### Command Line Interface #########
print_help () {
	echo "Help:"
	echo "Build targets to ./build/release or ./build/tests depending on whether the target is a test or not"
	echo
	echo "Usage: ./build.sh [COMMAND]"
	echo "If no COMMAND is provided then all possible targets will be built"
	echo
	echo "COMMAND:"
	echo "	target [LIST OF TARGETS]: build specific targets. Each target is a source file, with or without the .cpp prefix. Targets should be separated with spaces"
	echo "	clean: delete all built binaries and auto-generated configurations (everything inside ./build)"
	echo "	cmake: execute cmake to auto-generate configurations, but do not build anything"
	echo "	compile-commands: execute cmake and link compile commands to the root of the project. Useful for integrating the project with certain external tools"
}

if [ "$#" -eq 0 ]; then
	ACTION="all"
else
	ACTION="$1"
	if [ "$ACTION" == "--help" ]; then
		print_help
		exit 0
	fi
	shift
	until [ -z "$1" ]
	do
		TARGETS+=("$1")
		shift
	done
fi
######### Commnd Line Interface #########

update_dependencies_if_needed () {
	DEPENDENCIES_OUTDATED=""
	if [ ! -d "$DEPENDENCIES_DIR" ]; then
		DEPENDENCIES_OUTDATED=true
	else
		DEPENDENCIES_LIST_MODIFICATION_TIME=$(stat -c %Y "$DEPENDENCY_MANAGER_DIR/install.sh")
		DEPENDENCIES_DIR_MODIFICATION_TIME=$(stat -c %Y "$DEPENDENCIES_DIR")
		if [ "$DEPENDENCIES_LIST_MODIFICATION_TIME" -gt "$DEPENDENCIES_DIR_MODIFICATION_TIME" ]; then
			DEPENDENCIES_OUTDATED=true
		fi
	fi
	if [ $DEPENDENCIES_OUTDATED ]; then
		echo "Info: updating dependencies..."
		"$PROJECT_ROOT"/dependencies.sh install
	fi
}

if [ "$ACTION" == "clean" ]; then
	rm -rf "$BUILD_DIR"
elif [ "$ACTION" == "cmake" ]; then
	update_dependencies_if_needed
	cmake "$PROJECT_ROOT"
elif [ "$ACTION" == "compile-commands" ]; then
	update_dependencies_if_needed
	cmake "$PROJECT_ROOT"
	ln -s "$BUILD_DIR/compile_commands.json" "$PROJECT_ROOT/compile_commands.json"
elif [ "$ACTION" == "all" ]; then
	update_dependencies_if_needed
	if [ ! -f "$BUILD_DIR/Makefile" ] || [ $DEPENDENCIES_OUTDATED ]; then
		cmake "$PROJECT_ROOT"
	fi
	make
elif [ "$ACTION" == "target" ]; then
	update_dependencies_if_needed
	if [ ! -f "$BUILD_DIR/Makefile" ] || [ $DEPENDENCIES_OUTDATED ]; then
		cmake "$PROJECT_ROOT"
	fi
	for TARGET in "${TARGETS[@]}"
	do
		export TARGET=$TARGET
		source "$PROJECT_ROOT/.assertions/get_target_info.sh"
		make $TARGET_RULE
	done
else
	echo "Error: unknown action $ACTION"
	echo
	print_help
	exit 1
fi

BUILD_STATUS=$?
if [ ! "$BUILD_STATUS" -eq 0 ]; then
	exit $BUILD_STATUS
fi

