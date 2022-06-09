#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the SwiftLinuxBacktrace open source project
##
## Copyright (c) 2019-2020 Apple Inc. and the SwiftLinuxBacktrace project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.txt for the list of SwiftLinuxBacktrace project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

#!/bin/bash

# This script creates a vendored copy of libbacktrace that is
# suitable for building with the Swift Package Manager.
#
# Usage:
#   1. Run this script in the package root. It will place
#      a local copy of the libbacktrace sources in Sources/CBacktrace.
#      Any prior contents of Sources/CBacktrace will be deleted.

set -eou pipefail

if [ "$(uname -s)" != "Linux" ]
then
    echo "This script may only be run on Linux"
    exit 1
fi

HERE=$(pwd)
DSTROOT=Sources/CBacktrace
TMPDIR=$(mktemp -d /tmp/.workingXXXXXX)
SRCROOT="${TMPDIR}/src/libbacktrace"

echo "REMOVING any previously-vendored libbacktrace code"
rm -rf "${DSTROOT:?}/"*

echo "CLONING libbacktrace"
mkdir -p "$SRCROOT"
git clone https://github.com/ianlancetaylor/libbacktrace.git "$SRCROOT"
echo "CLONED libbacktrace"

echo "CONFIGURING libbacktrace"
cd "$SRCROOT"
./configure > configure_log.txt 2>&1
cd "$HERE"

PATTERNS=(
'*.c'
'*.h'
'LICENSE'
)

for pattern in "${PATTERNS[@]}"
do
  echo "COPYING $pattern"
  cp "$SRCROOT"/$pattern "$DSTROOT"
done

EXCLUDES=(
'*test*'
'nounwind.c'
'pecoff.c'
'read.c'
'unknown.c'
'xcoff.c'
'macho.c'
'alloc.c'
'allocfail.c'
'instrumented_alloc.c'
)

for exclude in "${EXCLUDES[@]}"
do
  echo "EXCLUDING $exclude"
  find $DSTROOT -name "$exclude" -exec rm -rf {} \;
done

echo "MOVING backtrace.h"
mkdir -p "$DSTROOT/include"
mv "$DSTROOT/backtrace.h" "$DSTROOT/include"

echo "REPLACING references to \"backtrace.h\" with \"include/backtrace.h\""
find $DSTROOT -name "*.[ch]" -print0 | xargs -0 sed -i -e 's#"backtrace.h"#"include/backtrace.h"#g'

echo "ADDING preprocessor conditionals"
find $DSTROOT -name "*.[ch]" -print0 | xargs -0 sed -i -e '1i#ifdef __linux__' -e '$a#endif'

echo "DONE"
