#!/bin/bash

apt --version > /dev/null
APT_IS_INSTALLED=$?
if [ "$APT_IS_INSTALLED" != "0" ]; then
	echo "Warning: APT not installed on this machine. Make sure the package manager your Operating System uses is supported by this project" 1>&2
	exit 0
fi

PACKAGE=$1
if [ "$PACKAGE" == "" ]; then
	echo "Error: unspecified package"
	exit 1
fi

dpkg-query -s "$PACKAGE" > /dev/null
PACKAGE_ALREADY_INSTALLED=$?
if [ "$PACKAGE_ALREADY_INSTALLED" == "0" ]; then
	echo "Info: package '$PACKAGE' already installed. Remember to keep your packages up-to-date" 1>&2
else
	echo "Info: attempting to install package '$PACKAGE'" 1>&2
	sudo apt install $PACKAGE
fi
