#!/usr/bin/env bash

set -e

source common.sh

function package() {
    local target_dir="${1}"
    local lib_name="${2}"
    local artifact_dirs=($(find ${target_dir} -mindepth 1 -maxdepth 1 -type d | awk -F "${target_dir}/" '{print $2}' | grep "${lib_name}-"))
    for artifact_dir in "${artifact_dirs[@]}"; do
        echo "package: ${artifact_dir} into ${artifact_dir}.tar.gz"
        tar czf "${artifact_dir}.tar.gz" "${artifact_dir}"
    done
}

mkdir -p target
[ -f "target/${ARCHIVE}" ] || aria2c --file-allocation=none -c -x 10 -s 10 -m 0 --console-log-level=notice --log-level=notice --summary-interval=0 -d "$(pwd)/target" -o "${ARCHIVE}" "${ARCHIVE_URL}"

# Install gcc-6.3.0_1.sierra
#brew install gcc
brew install libtool autoconf automake

# build-libsodium-darwin.sh
if [ -z "${AND_ARCHS}" ] && [ -z "${IOS_ARCHS}" ]; then
    brew tap chshawkn/homebrew-brew-tap
    brew install chshawkn/brew-tap/libsodium@1.0.12

    if [ -d ../target/${LIB_NAME}-x86_64-apple-darwin ]; then rm -rf ../target/${LIB_NAME}-x86_64-apple-darwin; fi
    mkdir -p ../target/${LIB_NAME}-x86_64-apple-darwin
    cp -r /usr/local/Cellar/libsodium@1.0.12/1.0.12/* ../target/${LIB_NAME}-x86_64-apple-darwin/

    rm -f "../target/${LIB_NAME}-x86_64-apple-darwin.tar.gz"
    # create archive by package function
    tar czf "../target/${LIB_NAME}-x86_64-apple-darwin.tar.gz" -C "../target" "${LIB_NAME}-x86_64-apple-darwin"
fi

unset CXX
unset CC
#export CXX=clang++
#export CC=clang
ORIGINAL_PATH="${PATH}"

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

    export TOOLCHAIN_DIR="$(pwd)/android-toolchain-${TARGET_ARCH}"
    export PATH="${TOOLCHAIN_DIR}/bin:${ORIGINAL_PATH}"
    (./autogen.sh)
    echo "./dist-build/android-${SCRIPT_SUFFIX}.sh"
    (./dist-build/android-${SCRIPT_SUFFIX}.sh | ${FILTER} || cat config.log)
    unset TOOLCHAIN_DIR
    export PATH="${ORIGINAL_PATH}"

    cd ../
    rm -rf ${LIB_NAME}-${RUST_AND_ARCH}
    mkdir -p ${LIB_NAME}-${RUST_AND_ARCH}
    cp -r ${LIB_NAME}/$(echo ${LIB_NAME} | awk -F- '{print $1}')-android-${TARGET_ARCH}/* ${LIB_NAME}-${RUST_AND_ARCH}/
    cd ../
done

source build-libsodium-ios.sh

(cd target; package "." "${LIB_NAME}"; ls -l .;)
