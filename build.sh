#!/usr/bin/env bash

set -e

: "${LIB_NAME:=libsodium-1.0.12}"
LIB_VERSION="$(echo ${LIB_NAME} | awk -F- '{print $2}')"
ARCHIVE="${LIB_NAME}.tar.gz"
ARCHIVE_URL="https://github.com/jedisct1/libsodium/releases/download/${LIB_VERSION}/${ARCHIVE}"

# Install gcc-6.3.0_1.sierra
#brew install gcc
brew install libtool autoconf automake

mkdir -p target
[ -f "target/${ARCHIVE}" ] || aria2c --file-allocation=none -c -x 10 -s 10 -m 0 --console-log-level=notice --log-level=notice --summary-interval=0 -d "$(pwd)/target" -o "${ARCHIVE}" "${ARCHIVE_URL}"

if [[ ! -v AND_ARCHS ]]; then
    # mips32 is recognized as mips64
    #: "${AND_ARCHS:=android android-armeabi android-mips android-x86 android64 android64-aarch64}"
    : "${AND_ARCHS:=android android-armeabi android-x86 android64 android64-aarch64}"
fi

AND_ARCHS_ARRAY=(${AND_ARCHS})
for ((i=0; i < ${#AND_ARCHS_ARRAY[@]}; i++))
do
    rm -rf "target/${LIB_NAME}"
    mkdir -p "target/${LIB_NAME}"
    echo $(pwd)
    tar xzf "target/${ARCHIVE}" --strip-components=1 -C "target/${LIB_NAME}"

    AND_ARCH="${AND_ARCHS_ARRAY[i]}"
    SCRIPT_SUFFIX="unknown"
    if [ "${AND_ARCH}" == "android" ]; then
        SCRIPT_SUFFIX="arm"
        TARGET_ARCH="armv6"
        RUST_AND_ARCH="arm-linux-androideabi"
    elif [ "${AND_ARCH}" == "android-armeabi" ]; then
        SCRIPT_SUFFIX="armv7-a"
        TARGET_ARCH="armv7-a"
        RUST_AND_ARCH="armv7-linux-androideabi"
    elif [ "${AND_ARCH}" == "android-mips" ]; then
        SCRIPT_SUFFIX="mips32"
        TARGET_ARCH="mips32"
        RUST_AND_ARCH="mips-linux-android"
    elif [ "${AND_ARCH}" == "android-x86" ]; then
        SCRIPT_SUFFIX="x86"
        TARGET_ARCH="i686"
        RUST_AND_ARCH="i686-linux-android"
    elif [ "${AND_ARCH}" == "android64" ]; then
        SCRIPT_SUFFIX="x86_64"
        TARGET_ARCH="westmere"
        RUST_AND_ARCH="x86_64-linux-android"
    elif [ "${AND_ARCH}" == "android64-aarch64" ]; then
        SCRIPT_SUFFIX="armv8-a"
        TARGET_ARCH="armv8-a"
        RUST_AND_ARCH="aarch64-linux-android"
    else
        SCRIPT_SUFFIX="unknown"
        TARGET_ARCH="unknown"
        RUST_AND_ARCH="unknown"
    fi

    cd target/${LIB_NAME}
    if [ -z "${NDK_PLATFORM}" ]; then
        export NDK_PLATFORM="android-22"
    fi
    if [ -z "${ANDROID_NDK_HOME}" ]; then
        export ANDROID_NDK_HOME="/usr/local/opt/android-ndk/android-ndk-r14b"
    fi
    ./autogen.sh
    echo "./dist-build/android-${SCRIPT_SUFFIX}.sh"
    ./dist-build/android-${SCRIPT_SUFFIX}.sh
    cd ../
    rm -rf ${LIB_NAME}-${RUST_AND_ARCH}
    mkdir -p ${LIB_NAME}-${RUST_AND_ARCH}
    cp -r ${LIB_NAME}/$(echo ${LIB_NAME} | awk -F- '{print $1}')-android-${TARGET_ARCH}/* ${LIB_NAME}-${RUST_AND_ARCH}/
    cd ../
done
