#!/bin/bash

path=`dirname $0`

OUTPUT_DIR=$1
TARGET_NAME=plugin_Bytemap
OUTPUT_SUFFIX=a
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

# Clean
xcodebuild -project "$path/Plugin.xcodeproj" -configuration $CONFIG clean
checkError

# iOS (Flick: device only, arm64, iOS 15 to match Solar2D; no simulator slice, as device and
# simulator are both arm64 now and can't be lipo'd together, and we never use the iOS simulator)
xcodebuild -project "$path/Plugin.xcodeproj" -configuration $CONFIG -sdk iphoneos ARCHS=arm64 ONLY_ACTIVE_ARCH=NO IPHONEOS_DEPLOYMENT_TARGET=15.0 SYMROOT="$path/build"
checkError

cp "$path"/build/$CONFIG-iphoneos/lib$TARGET_NAME.$OUTPUT_SUFFIX "$OUTPUT_DIR"/lib$TARGET_NAME.$OUTPUT_SUFFIX
checkError

echo "$OUTPUT_DIR"/lib$TARGET_NAME.$OUTPUT_SUFFIX

# Flick: package with metadata.lua (same as the published v9 package) and install as games.flick
PLUGINS_DIR=~/Solar2DPlugins/games.flick/plugin.Bytemap/iphone
mkdir -p "$PLUGINS_DIR"
cp "$path/metadata.lua" "$OUTPUT_DIR/metadata.lua"
COPYFILE_DISABLE=1 tar -czf "$OUTPUT_DIR/data.tgz" -C "$OUTPUT_DIR" lib$TARGET_NAME.$OUTPUT_SUFFIX metadata.lua
checkError
cp "$OUTPUT_DIR/data.tgz" "$PLUGINS_DIR/data.tgz"
checkError
echo "Installed $PLUGINS_DIR/data.tgz"
