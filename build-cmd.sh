#!/usr/bin/env bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

JSONCPP_SOURCE_DIR="jsoncpp-1.9.5"
# version number is conveniently found in a file with no other content
JSONCPP_VERSION="1.9.5"

if [ -z "$AUTOBUILD" ] ; then 
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

stage="$(pwd)/stage"

# load autobuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

build=${AUTOBUILD_BUILD_ID:=0}
echo "${JSONCPP_VERSION}.${build}" > "${stage}/VERSION.txt"

pushd "$stage"
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
            export CCFLAGS="-arch $AUTOBUILD_CONFIGURE_ARCH $LL_BUILD_RELEASE"
            export CXXFLAGS="$CCFLAGS"
            ./scons.py platform=darwin

            mkdir -p "$stage/lib/release"
            mkdir -p "$stage/include/json"
            cp lib/release/*.a "$stage/lib/release"
            cp include/json/*.h "$stage/include/json"
        ;;
        linux*)
            export CCFLAGS="-m$AUTOBUILD_ADDRSIZE $LL_BUILD_RELEASE"
            export CXXFLAGS="$CCFLAGS"
	    cmake ../$JSONCPP_SOURCE_DIR
	    make -j 6

            mkdir -p "$stage/lib/release"
            mkdir -p "$stage/include/json"
            cp lib/*.a "$stage/lib/release"
            cp ../$JSONCPP_SOURCE_DIR/include/json/*.h "$stage/include/json"
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp ../$JSONCPP_SOURCE_DIR/LICENSE "$stage/LICENSES/jsoncpp.txt"
popd
