#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

JSONCPP_VERSION="0.5.0"
JSONCPP_SOURCE_DIR="jsoncpp-src-"$JSONCPP_VERSION

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autobuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

stage="$(pwd)/stage"

build=${AUTOBUILD_BUILD_ID:=0}
echo "${JSONCPP_VERSION}.${build}" > "${stage}/VERSION.txt"

pushd "$JSONCPP_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            load_vsvars

            build_sln "./makefiles/vs120/jsoncpp.sln" "Debug|Win32"
            build_sln "./makefiles/vs120/jsoncpp.sln" "Release|Win32"

            mkdir --parents "$stage/lib/debug"
            mkdir --parents "$stage/lib/release"
            mkdir --parents "$stage/include/json"

            cp ./build/vs120/debug/lib_json/json_libmtd.lib "$stage/lib/debug"
            cp ./build/vs120/release/lib_json/json_libmt.lib "$stage/lib/release"

            cp ../"${JSONCPP_SOURCE_DIR}"/include/json/*.h "$stage/include/json"
        ;;
        "darwin")
            ./scons.py platform=darwin

            mkdir -p "$stage/lib/release"
            mkdir -p "$stage/include/json"
            cp lib/release/*.a "$stage/lib/release"
            cp include/json/*.h "$stage/include/json"
        ;;
        "linux")
            ./scons.py platform=linux

            mkdir -p "$stage/lib/release"
            mkdir -p "$stage/include/json"
            cp lib/release/*.a "$stage/lib/release"
            cp include/json/*.h "$stage/include/json"
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp LICENSE "$stage/LICENSES/jsoncpp.txt"
popd

pass
