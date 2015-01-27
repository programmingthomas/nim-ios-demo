#!/bin/sh

# This script is based on the one in https://github.com/gradha/nimrod-on-ios
# with additional work by Thomas Denney in order to support both 32-bit and 
# 64-bit iOS devices. Please note that Xcode will produce a lot of warnings for
# the .h and .m files that this generates. If you want to avoid these, add the
# '-w' flag to each of the files' build phase.

# Basically this script builds separate .h/.m files for 32-bit and 64-bit
# targets and then joins them together using compiler macros.

# To use this script:

# * Modify the PATH_TO_NIM below
# * Create a 'src' directory inside your project. This will be where you store
#   your .nim source files
# * Create a 'scripts' directory inside your project, at the same level as the
#   'src' directory. Add this script to that directory. Add a run script build
#   phase for this script
# * Add your nim files to the src directory and do CMD+B. Make sure they aren't
#   a member of the project target otherwise Xcode will try to build them with
#   clang.
# * Add the build/nimcache directory to your project. This contains the output 
#   .h and .m files
# * Include the appropriate headers in your Objective-C source

# N.B. Use NSInteger, not int!

# Set this to the path of your Nim directory. This should be the path that
# contains the bin/ and lib/ directories.
PATH_TO_NIM=~/Downloads/nim-0.10.2/

# Set this to the name of the project.
PROJECT_DIR=nim-ios-demo

# Path of the actual Nim compiler
PATH_TO_NIM_COMPILER=$PATH_TO_NIM"bin/nim"
PATH_TO_NIMBASE=$PATH_TO_NIM"lib/nimbase.h"

# Force errors to fail script.
set -e

# If we are running from inside the scripts subdir, get out.
if [ ! -d $PROJECT_DIR/src ]
then
	cd ..
fi

cd $PROJECT_DIR

DEST_NIMBASE=src/build/nimcache/nimbase.h

# Ok, are we out now?
if [ -d src ]
then
    # Compile the 32-bit code. There are minor differences
    # between the two
    $PATH_TO_NIM_COMPILER objc --noMain  --app:lib \
		--cpu:i386 --nimcache:build/nimcache32 --compileOnly \
		--header src/*.nim
    # Compile 64-bit code
    $PATH_TO_NIM_COMPILER objc --noMain  --app:lib \
    --cpu:amd64 --nimcache:build/nimcache64 --compileOnly \
    --header src/*.nim

    mkdir -p src/build/nimcache

    FILES=src/build/nimcache32/*
    for source in $FILES
    do
        # And now for the hack of the year!
        # We take the two files in the 32-bit and 64-bit directory
        # and concatenate them, but inserting the appropriate IFDEF
        # for separate 32-bit and 64-bit code. This means that we can
        # easily build for both platforms.
        b=$(basename $source)
        dst="src/build/nimcache/$b"
        echo "#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64" > $dst
        cat "src/build/nimcache64/$b" >> $dst
        echo "#else" >> $dst
        cat $source >> $dst
        echo "#endif" >> $dst
    done
    
    # Cleanup, don't need to keep the nimcache32/nimcache64 files
    rm -R src/build/nimcache32
    rm -R src/build/nimcache64

    # Copy nimbase.h. This is platform neutral
	if [ "${PATH_TO_NIMBASE}" -nt "${DEST_NIMBASE}" ]
	then
		echo "Updating nimbase.h"
		cp "${PATH_TO_NIMBASE}" "${DEST_NIMBASE}"
	fi
else
	echo "Uh oh, src directory not found? $(pwd)"
	exit 1
fi
