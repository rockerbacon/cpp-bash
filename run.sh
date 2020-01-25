#!/bin/bash

export PROJECT_ROOT=$(realpath $(dirname $0))

############# Command Line Interface ###############
print_help () {
	echo "Help:"
	echo "Automatically build a target (if necessary) and execute it"
	echo
	echo "Usage: ./run.sh [OPTIONS] TARGET [TARGET ARGS]"
	echo
	echo "	TARGET: any source file, with or without the .cpp suffix"
	echo "	TARGET ARGS: arguments to be passed to the target"
	echo "	OPTIONS:"
	echo "		--debug: only show the target's STDERR output"
	echo "		--no-debug: only show the target's STDOUT output. This is the default behaviour for test targets"
	echo "		--full-output: show both the target's STDERR and STDOUT outputs. This is the default behaviour for main targets"
}

if [ "$#" == "0" ]; then
	echo "Error: unspecified target"
	echo
	print_help
	exit 1
fi

OUTPUT_MODE="default"
FIRST_ARG_IS_PREFIX_OPTION=$(echo "$1" | grep -oe "^--")
until [[ -z "$1" || "$FIRST_ARG_IS_PREFIX_OPTION" == "" ]]
do
	if [ "$1" == "--debug" ]; then
		OUTPUT_MODE="stderr"
	elif [ "$1" == "--full-output" ]; then
		OUTPUT_MODE="full"
	elif [ "$1" == "--no-debug" ]; then
		OUTPUT_MODE="stdout"
	elif [ "$1" == "--help" ]; then
		print_help
		exit 0
	fi
	shift
	FIRST_ARG_IS_PREFIX_OPTION=$(echo "$1" | grep -oe "^--")
done

TARGET="$1"
shift
if [ "$TARGET" == "" ]; then
	echo "Error: unspecified target"
	echo
	print_help
	exit 1
fi

############ Command Line Interface ###############

source "${PROJECT_ROOT}/.assertions/get_target_info.sh"

./build.sh target "$TARGET"
BUILD_STATUS=$?
if [ "$BUILD_STATUS" != "0" ]; then
	exit 1
fi

if [ $TARGET_IS_TEST ] && [ "$OUTPUT_MODE" == "default" ]; then
	"$TARGET_BINARY_PATH" "$@" 2>/dev/null
elif [ "$OUTPUT_MODE" == "stderr" ]; then
	"$TARGET_BINARY_PATH" "$@" 1>/dev/null
elif [ "$OUTPUT_MODE" == "stdout" ]; then
	"$TARGET_BINARY_PATH" "$@" 2>/dev/null
else
	"$TARGET_BINARY_PATH" "$@"
fi

TARGET_STATUS="$?"
exit $TARGET_STATUS

