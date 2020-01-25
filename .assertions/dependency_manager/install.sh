#!/bin/bash
apt-package/install.sh g++
apt-package/install.sh cmake
apt-package/install.sh make
git/install.sh rockerbacon/assertions-test --local-only --version v2.0.4
