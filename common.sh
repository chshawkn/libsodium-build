#!/usr/bin/env bash

SOURCE="$0"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
export SCRIPT_PATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "SCRIPT_PATH: ${SCRIPT_PATH}"

: "${LIB_NAME:=libsodium-1.0.12}"
LIB_VERSION="$(echo ${LIB_NAME} | awk -F- '{print $2}')"
ARCHIVE="${LIB_NAME}.tar.gz"
ARCHIVE_URL="https://github.com/jedisct1/libsodium/releases/download/${LIB_VERSION}/${ARCHIVE}"

if [[ ! -v AND_ARCHS ]]; then
    # mips32 is recognized as mips64
    #: "${AND_ARCHS:=android android-armeabi android-mips android-x86 android64 android64-aarch64}"
    : "${AND_ARCHS:=android android-armeabi android-x86 android64 android64-aarch64}"
fi

if [[ ! -v IOS_ARCHS ]]; then
    : "${IOS_ARCHS:=arm64 armv7 armv7s i386 x86_64}"
fi

FILTER="${SCRIPT_PATH}/filter"
