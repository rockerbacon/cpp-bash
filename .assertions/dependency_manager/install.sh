#!/bin/bash
source apt-package/install.sh g++
source apt-package/install.sh cmake
source apt-package/install.sh make
source git/install.sh rockerbacon/assertions-test --local-only --version v3.1
