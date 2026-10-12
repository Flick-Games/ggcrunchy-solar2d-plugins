#!/bin/bash

path=`dirname $0`

OUTPUT_DIR=$1
TARGET_NAME=Bytemap
OUTPUT_SUFFIX=dylib
CONFIG=Release

#
# Checks exit value for error
# 
checkError() {
    if [ $? -ne 0 ]
    then
        echo "Exiting due to errors (above)"
        exit -1
    fi
}

# 
# Canonicalize relative paths to absolute paths
# 
pushd $path > /dev/null
dir=`pwd`
path=$dir
popd > /dev/null

if [ -z "$OUTPUT_DIR" ]
then
    OUTPUT_DIR=.
fi

pushd $OUTPUT_DIR > /dev/null
dir=`pwd`
OUTPUT_DIR=$dir
popd > /dev/null

echo "OUTPUT_DIR: $OUTPUT_DIR"

xcodebuild -project "$path/Plugin.xcodeproj" -configuration $CONFIG clean
checkError

# Flick: universal (Apple silicon + Intel), macOS 12 to match Solar2D, built into the project's build folder
xcodebuild -project "$path/Plugin.xcodeproj" -configuration $CONFIG ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO MACOSX_DEPLOYMENT_TARGET=12.0 SYMROOT="$path/build"
checkError

# Flick: install as games.flick, never over the stock com.xibalbastudios plugin
PLUGINS_DIR=~/Solar2DPlugins/games.flick/plugin.$TARGET_NAME/mac-sim

mkdir -p "$PLUGINS_DIR"

cp "$path/build/$CONFIG/$TARGET_NAME.$OUTPUT_SUFFIX" "$OUTPUT_DIR/plugin_$TARGET_NAME.$OUTPUT_SUFFIX"
checkError

# Flick: arm64 dylibs must be signed to load; ad-hoc is enough for the simulator
codesign -s - -f "$OUTPUT_DIR/plugin_$TARGET_NAME.$OUTPUT_SUFFIX"
checkError

COPYFILE_DISABLE=1 tar -czf "$OUTPUT_DIR/data.tgz" -C "$OUTPUT_DIR" "plugin_$TARGET_NAME.$OUTPUT_SUFFIX"
checkError

cp "$OUTPUT_DIR/data.tgz" "$PLUGINS_DIR/data.tgz"
checkError
echo "Installed $PLUGINS_DIR/data.tgz"
