#!/bin/bash

ESCAPED_DEPENDENCY_MODULES_DIR=$(echo "$DEPENDENCY_MANAGER_MODULES_DIR" | sed 's/\//\\\//g; s/\./\\\./g')

################ Command Line Interface ##################
print_remove_help () {
	AVAILABLE_MODULES=("$DEPENDENCY_MANAGER_MODULES_DIR/*")
	echo "Help:"
	echo "Remove dependencies from the project. Dependency information is stored inside the project so that other developers are able to easily get them"
	echo
	echo "Usage: ./dependencies.sh remove TYPE DEPENDENCY_IDENTIFICATION"
	echo "For detailed information about a type use: ./dependencies.sh remove TYPE --help"
	echo
	echo "DEPENDENCY_IDENTIFICATION: should be the same as the arguments used for the dependency addition. If you're unsure use './dependencies.sh remove TYPE --help' or './dependencies.sh list'"
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
		print_remove_help
		exit 1
	elif [ ! -d "$DEPENDENCY_TYPE_MODULE_DIR" ]; then
		echo "Error: unknown dependency type '$DEPENDENCY_TYPE'"
		echo
		print_remove_help
		exit 1
	fi
}

print_dependency_help () {
	cat "$DEPENDENCY_TYPE_MODULE_DIR/remove_help.txt"
}

if [ "$1" == "--help" ]; then
	print_remove_help
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

if [ "$1" == "" ]; then
	log_error "no dependency identification"
	print_remove_help
	exit 1
fi

if [ ! -f "$DEPENDENCY_MANAGER_DIR/install.sh" ]; then
	log_error "project contains no dependencies"
	print_remove_help
	exit 1
fi

echo "Do you really want to attempt removal of dependency '$DEPENDENCY_TYPE $@'? (y/n)"
read CONFIRMATION

if [ "${CONFIRMATION[0]}" != "y" ] && [ "${CONFIRMATION[1]}" != "Y" ]; then
	log_info "operation canceled"
	exit 0
fi

source "$DEPENDENCY_TYPE_MODULE_DIR/remove.sh" "$@"
DEPENDENCY_REMOVAL_STATUS=$?
if [ "$DEPENDENCY_REMOVAL_STATUS" != "0" ]; then
	log_error "dependency not removed because it could not be removed locally"
	print_dependency_help
	exit 1
fi

log_info "local removal successful, unlisting dependency from '$DEPENDENCY_MANAGER_DIR/install.sh'"
DEPENDENCY_LISTING_MATCH="$DEPENDENCY_TYPE/install.sh $@"
grep -v "$DEPENDENCY_LISTING_MATCH" "$DEPENDENCY_MANAGER_DIR/install.sh" > "$DEPENDENCY_MANAGER_DIR/install.sh.swp" || true

mv "$DEPENDENCY_MANAGER_DIR/install.sh" "$DEPENDENCY_MANAGER_DIR/install.sh.bak"
mv "$DEPENDENCY_MANAGER_DIR/install.sh.swp" "$DEPENDENCY_MANAGER_DIR/install.sh"

