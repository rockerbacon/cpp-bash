#!/bin/bash

ESCAPED_DEPENDENCY_MODULES_DIR=$(echo "$DEPENDENCY_MANAGER_MODULES_DIR" | sed 's/\//\\\//g; s/\./\\\./g')

################ Command Line Interface ##################
print_add_help () {
	AVAILABLE_MODULES=("$DEPENDENCY_MANAGER_MODULES_DIR/*")
	echo "Help:"
	echo "Add new dependencies to the project. Dependency information is stored inside the project so that other developers are able to easily get them"
	echo
	echo "Usage: ./dependencies.sh add TYPE"
	echo "For detailed information about a type use: ./dependencies.sh add TYPE --help"
	echo
	echo "TYPE:"
	for MODULE in $AVAILABLE_MODULES
	do
		CLEAN_MODULE_NAME=$(echo "$MODULE" | sed "s/$ESCAPED_DEPENDENCY_MODULES_DIR\///")
		echo "	$CLEAN_MODULE_NAME: $(cat "$MODULE/description.txt")"
	done
}

check_dependency_type_is_valid () {
	if [ "$DEPENDENCY_TYPE" == "" ]; then
		echo "Error: unspecified dependency type"
		echo
		print_add_help
		exit 1
	elif [ ! -d "$DEPENDENCY_TYPE_MODULE_DIR" ]; then
		echo "Error: unknown dependency type '$DEPENDENCY_TYPE'"
		echo
		print_add_help
		exit 1
	fi
}

print_dependency_help () {
	cat "$DEPENDENCY_TYPE_MODULE_DIR/add_help.txt"
}

if [ "$1" == "--help" ]; then
	print_add_help
	exit 0
else
	DEPENDENCY_TYPE="$1"
	shift
	DEPENDENCY_TYPE_MODULE_DIR="$DEPENDENCY_MANAGER_MODULES_DIR/$DEPENDENCY_TYPE"
	check_dependency_type_is_valid
	if [ "$1" == "--help" ]; then
		print_dependency_help
		exit 0
	fi
fi
################ Command Line Interface ##################

LOCAL_INSTALL_OUTPUT=$(source "$DEPENDENCY_TYPE_MODULE_DIR/install.sh" "$@")
DEPENDENCY_INSTALL_STATUS=$?
if [ "$DEPENDENCY_INSTALL_STATUS" != "0" ]; then
	echo "$LOCAL_INSTALL_OUTPUT"
	echo "Error: dependency not added because it could not be installed locally"
	echo
	print_dependency_help
	exit 1
fi

DEPENDENCY_FROZEN_INSTALL_ARGUMENTS=$(echo "$LOCAL_INSTALL_OUTPUT" | grep "Info: dependency configured: " | tail -n 1 | sed "s/Info: dependency configured: //")
if [ "$DEPENDENCY_FROZEN_INSTALL_ARGUMENTS" == "" ]; then
	DEPENDENCY_FROZEN_INSTALL_ARGUMENTS="$@"
fi

DEPENDENCY_UNIVERSAL_INSTALL_COMMAND="$DEPENDENCY_TYPE/install.sh $DEPENDENCY_FROZEN_INSTALL_ARGUMENTS"

if [ -f "$DEPENDENCY_MANAGER_DIR/install.sh" ]; then
	DEPENDENCY_ALREADY_EXISTS=$(cat "$DEPENDENCY_MANAGER_DIR/install.sh" | grep -o "$DEPENDENCY_UNIVERSAL_INSTALL_COMMAND")
	if  [ "$DEPENDENCY_ALREADY_EXISTS" != "" ]; then
		echo "Error: dependency already in dependencies list"
		exit 1
	fi
fi

echo "Info: local installation successful, listing dependency on '$DEPENDENCY_MANAGER_DIR/install.sh'"
echo "source $DEPENDENCY_UNIVERSAL_INSTALL_COMMAND" >> "$DEPENDENCY_MANAGER_DIR/install.sh"

