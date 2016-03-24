#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

JSONCPP_SOURCE_DIR="jsoncpp-src"
# version number is conveniently found in a file with no other content
JSONCPP_VERSION="$(<$JSONCPP_SOURCE_DIR/version)"

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

# load autobuild provided shell functions and variables
set +x
eval "$("$autobuild" source_environment)"
set -x

# set LL_BUILD and friends
set_build_variables convenience Release

stage="$(pwd)/stage"

build=${AUTOBUILD_BUILD_ID:=0}
echo "${JSONCPP_VERSION}.${build}" > "${stage}/VERSION.txt"

pushd "$JSONCPP_SOURCE_DIR"
    case "$AUTOBUILD_PLATFORM" in
        windows*)
            load_vsvars

            build_sln "./makefiles/vs$AUTOBUILD_VSVER/jsoncpp.sln" "Release|$AUTOBUILD_WIN_VSPLATFORM"

            mkdir --parents "$stage/lib/release"
            mkdir --parents "$stage/include/json"

            if [ "$AUTOBUILD_ADDRSIZE" = 32 ]
            then cp "./build/vs$AUTOBUILD_VSVER/release/lib_json/json_libmd.lib" "$stage/lib/release"
            else cp "./makefiles/vs$AUTOBUILD_VSVER/x64/release/json_libmd.lib" "$stage/lib/release"
            fi

            cp ../"${JSONCPP_SOURCE_DIR}"/include/json/*.h "$stage/include/json"
        ;;
        darwin*)
            export CCFLAGS="-arch $AUTOBUILD_CONFIGURE_ARCH $LL_BUILD"
            export CXXFLAGS="$CCFLAGS"
            ./scons.py platform=darwin

            mkdir -p "$stage/lib/release"
            mkdir -p "$stage/include/json"
            cp lib/release/*.a "$stage/lib/release"
            cp include/json/*.h "$stage/include/json"
        ;;
        linux*)
            export CCFLAGS="-m$AUTOBUILD_ADDRSIZE $LL_BUILD"
            export CXXFLAGS="$CCFLAGS"
            ./scons.py platform=linux-gcc

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
