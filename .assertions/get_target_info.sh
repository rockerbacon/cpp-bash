#!/bin/bash

if [ "$TARGET" != "$CURRENT_TARGET" ]; then
	print_target_help () {
		echo "Help:"
		echo "A target is any file inside ./src/main or ./tests"
		echo
		echo " - Files don't need to be suffixed with .cpp"
	   	echo "	Eg: src/main/main or tests/some_test"
		echo " - Files inside ./src/main never need the folder prefix"
	   	echo "	Eg: main.cpp"
		echo " - Files inside ./tests don't need the folder prefix when using test.sh but do need the prefix when using build.sh"
		echo "	Eg: './build.sh target tests/some_test' or './test.sh some_test'"
	}

	TESTS_SRC_DIR="$PROJECT_ROOT/tests"
	MAIN_SRC_DIR="$PROJECT_ROOT/src/main"
	BUILD_DIR="$PROJECT_ROOT/build"
	TESTS_BUILD_DIR="$BUILD_DIR/tests"
	PROGRAM_BUILD_DIR="$BUILD_DIR/release/bin"

	ESCAPED_PROJECT_ROOT=$(echo "$PROJECT_ROOT" | sed 's/\//\\\//g; s/\./\\\./g')

	export_target_rule () {
		TARGET_CLEAN_PATH=$(echo "$TARGET" | sed "s/${ESCAPED_PROJECT_ROOT}\///g; s/src\/main\///; s/.cpp$//")
		export TARGET_RULE=$(echo $TARGET_CLEAN_PATH | sed "s/\//_/g")
	}

	export_target_is_test () {
		CONTAINS_TEST_PREFIX=$(echo $TARGET_RULE | grep -oe '^tests_')
		if [ "$CONTAINS_TEST_PREFIX" != "" ]; then
			export TARGET_IS_TEST=true
		fi
	}

	export_target_source_path() {
		TARGET_RELATIVE_PATH="$TARGET_CLEAN_PATH.cpp"
		if [ $TARGET_IS_TEST ]; then
			export TARGET_SOURCE_PATH="$PROJECT_ROOT/$TARGET_RELATIVE_PATH"
		else
			export TARGET_SOURCE_PATH="$MAIN_SRC_DIR/$TARGET_RELATIVE_PATH"
		fi
		if [ ! -f "$TARGET_SOURCE_PATH" ]; then
			echo "Error: no target '${TARGET}'"
			echo
			print_target_help
			echo
			exit 1
		fi
	}

	export_target_binary_path() {
		if [ $TARGET_IS_TEST ]; then
			export TARGET_BINARY_PATH="$TESTS_BUILD_DIR/$TARGET_RULE"
		else
			export TARGET_BINARY_PATH="$PROGRAM_BUILD_DIR/$TARGET_RULE"
		fi
	}

	export_target_rule
	export_target_is_test
	export_target_source_path
	export_target_binary_path

	export CURRENT_TARGET=$TARGET
fi
