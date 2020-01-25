#!/bin/bash

export PROJECT_ROOT=$(realpath $(dirname $0))
TESTS_SRC_DIR="$PROJECT_ROOT/tests"

default_text_color=7	#color used to reset terminal text to default color. 0 will reset to black and 7 to white. See the tput command documentation for other colors
red_color=`tput setaf 1`
green_color=`tput setaf 2`
reset_color=`tput setaf $default_text_color`
up_line=`tput cuu 1`
clear_line=`tput el 1`

############## Command Line Interface ################
print_help () {
	echo "Help:"
	echo "Execute tests and give a summary of the test results"
	echo
	echo "Usage: ./test.sh [LIST OF TESTS]"
	echo " - If no test is specified then all tests will be executed"
	echo " - Tests must be space separated"
	echo " - A test is any source file (with or without the .cpp suffix) or folder inside ./tests. The folder suffix 'tests/' is optional. Eg:"
	echo "	* './test.sh some_test.cpp' will execute the tests defined inside ./tests/some_test.cpp"
	echo "	* './test.sh many_tests' will recursively execute all tests inside the folder ./tests/many_tests/"
}

if [ "$1" == "--help" ]; then
	print_help
	exit 0
elif [ "$#" -gt 0 ] && [ "$1" != "all" ]; then
	TESTS=("$1")
	shift
	until [ -z "$1" ]
	do
		TESTS+=("$1")
		shift
	done
else
	TESTS=("${TESTS_SRC_DIR}")
fi
############## Command Line Interface ################

add_tests_from_directory () {
	TESTS_IN_FOLDER="${CURRENT_TEST}/*"
	for INNER_TEST in $TESTS_IN_FOLDER
	do
		IS_NOT_TEST=$(echo "$INNER_TEST" | grep -oE "(.h|.hpp)$")
		if [ "$IS_NOT_TEST" == "" ]; then
			TESTS+=("$INNER_TEST")
		fi
	done
}

next_test () {
	CURRENT_TEST="${TESTS[0]}"
	TESTS=("${TESTS[@]:1}")
}

determine_successful_tests_this_run () {
	SUCCESSFUL_TESTS_THIS_RUN=$(echo "$TEST_STDERR_OUTPUT" | grep -oe "\"successful_tests\":[0-9]*" | sed "s/\"successful_tests\"://")
}

exec 3>&1 # save stdout address

TESTS_SRC_DIR_PREFIX_LENGTH=$(expr length $TESTS_SRC_DIR + 1)
TOTAL_FAILED_TESTS=0
TOTAL_SUCCESSFUL_TESTS=0
until [ "${TESTS[0]}" == "" ]
do
	next_test

	if [ -d "$CURRENT_TEST" ]; then
		add_tests_from_directory
	else
		CURRENT_TEST_WITHOUT_PREFIX=${CURRENT_TEST:$TESTS_SRC_DIR_PREFIX_LENGTH}
		echo "Info: initializing tests from '$CURRENT_TEST_WITHOUT_PREFIX'..."
		./build.sh target "$CURRENT_TEST"
		BUILD_STATUS="$?"
		if [ ! "$BUILD_STATUS" -eq 0 ]; then
			echo "${red_color}Build failed:${reset_color}"
			TOTAL_FAILED_TESTS_THIS_RUN=$(grep -oE 'test_case\s*\(' "$CURRENT_TEST" | wc -l)
			TOTAL_FAILED_TESTS=`expr $TOTAL_FAILED_TESTS_THIS_RUN + $TOTAL_FAILED_TESTS`
		else
			TEST_STDERR_OUTPUT=$(./run.sh --full-output "$CURRENT_TEST" 2>&1 1>&3)
			FAILED_TESTS_THIS_RUN=$?
			determine_successful_tests_this_run
			TOTAL_SUCCESSFUL_TESTS=`expr $SUCCESSFUL_TESTS_THIS_RUN + $TOTAL_SUCCESSFUL_TESTS`
			TOTAL_FAILED_TESTS=`expr $FAILED_TESTS_THIS_RUN + $TOTAL_FAILED_TESTS`
		fi
	fi
done

exec 3>&- # clear FD

echo "-------------------TESTS SUMMARY-------------------"
if [ $TOTAL_SUCCESSFUL_TESTS -gt 0 ]; then
	echo "${green_color}$TOTAL_SUCCESSFUL_TESTS tests passed${reset_color}"
else
	echo "$TOTAL_SUCCESSFUL_TESTS tests passed"
fi
if [ $TOTAL_FAILED_TESTS -gt 0 ]; then
	echo "${red_color}$TOTAL_FAILED_TESTS tests failed${reset_color}"
else
	echo "$TOTAL_FAILED_TESTS tests failed"
fi
echo "-------------------TESTS SUMMARY-------------------"

exit $TOTAL_FAILED_TESTS

