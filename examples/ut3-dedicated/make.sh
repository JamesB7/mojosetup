#!/bin/sh

# This script is not robust for all platforms or situations. Use as a rough
#  example, but invest effort in what it's trying to do, and what it produces.
#  (make sure you don't build in features you don't need, etc).

# Stop if anything produces an error.
set -e

DEBUG=0
if [ "$1" = "--debug" ]; then
    echo "debug build!"
    DEBUG=1
fi

# Show everything that we do here on stdout.
set -x

if [ "$DEBUG" = "1" ]; then
    LUASTRIPOPT=
    BUILDTYPE=Debug
    TRUEIFDEBUG=TRUE
    FALSEIFDEBUG=FALSE
else
    LUASTRIPOPT=-s
    BUILDTYPE=MinSizeRel
    TRUEIFDEBUG=FALSE
    FALSEIFDEBUG=TRUE
fi

# this is a little nasty, but it works!
TOTALINSTALL=`du -sb data |perl -w -pi -e 's/\A(\d+)\s+data\Z/$1/;'`
TOTALINSTALLSVN=`du -sb data/.svn |perl -w -pi -e 's/\A(\d+)\s+data\/\.svn\Z/$1/;'`
let TOTALINSTALL=$TOTALINSTALL-$TOTALINSTALLSVN
perl -w -pi -e "s/\A\s*(local TOTAL_INSTALL_SIZE)\s*\=\s*\d+\s*;\s*\Z/\$1 = $TOTALINSTALL;\n/;" scripts/config.lua

# Clean up previous run, build fresh dirs for Base Archive.
rm -rf image mojosetup UT3-linux-server-*.bin pdata.zip
mkdir image
mkdir image/guis
mkdir image/scripts
mkdir image/data

# Build MojoSetup binaries from scratch.
cd ../..
rm -rf `svn propget svn:ignore .`
cmake \
    -DCMAKE_BUILD_TYPE=$BUILDTYPE \
    -DCMAKE_C_COMPILER=/opt/crosstool/gcc-4.1.2-glibc-2.3.6/i686-unknown-linux-gnu/i686-unknown-linux-gnu/bin/gcc \
    -DCMAKE_CXX_COMPILER=/opt/crosstool/gcc-4.1.2-glibc-2.3.6/i686-unknown-linux-gnu/i686-unknown-linux-gnu/bin/g++ \
    -DMOJOSETUP_LUA_PARSER=$TRUEIFDEBUG \
    -DMOJOSETUP_ARCHIVE_TAR=FALSE \
    -DMOJOSETUP_ARCHIVE_TAR_BZ2=FALSE \
    -DMOJOSETUP_ARCHIVE_TAR_GZ=FALSE \
    -DMOJOSETUP_ARCHIVE_ZIP=TRUE \
    -DMOJOSETUP_BUILD_LUAC=TRUE \
    -DMOJOSETUP_CHECKSUM_CRC32=FALSE \
    -DMOJOSETUP_CHECKSUM_MD5=FALSE \
    -DMOJOSETUP_CHECKSUM_SHA1=FALSE \
    -DMOJOSETUP_GUI_GTKPLUS2=FALSE \
    -DMOJOSETUP_GUI_GTKPLUS2_STATIC=FALSE \
    -DMOJOSETUP_GUI_NCURSES=FALSE \
    -DMOJOSETUP_GUI_NCURSES_STATIC=FALSE \
    -DMOJOSETUP_GUI_STDIO=TRUE \
    -DMOJOSETUP_GUI_STDIO_STATIC=TRUE \
    -DMOJOSETUP_GUI_WWW=FALSE \
    -DMOJOSETUP_INTERNAL_BZLIB=FALSE \
    -DMOJOSETUP_INTERNAL_ZLIB=TRUE \
    -DMOJOSETUP_URL_FTP=FALSE \
    -DMOJOSETUP_IMAGE_JPG=FALSE \
    -DMOJOSETUP_IMAGE_PNG=FALSE \
    .

#make -j5 VERBOSE=1
make -j5

# Strip the binaries and GUI plugins, put them somewhere useful.
if [ "$DEBUG" != "1" ]; then
    strip ./mojosetup
fi

mv ./mojosetup examples/ut3-dedicated/

for feh in *.so *.dll *.dylib ; do
    if [ -f $feh ]; then
        if [ "$DEBUG" != "1" ]; then
            strip $feh
        fi
        mv $feh examples/ut3-dedicated/image/guis
    fi
done

# Compile the Lua scripts, put them in the base archive.
for feh in scripts/*.lua ; do
    ./mojoluac $LUASTRIPOPT -o examples/ut3-dedicated/image/${feh}c $feh
done

# Don't want the example config...use our's instead.
rm -f examples/ut3-dedicated/image/scripts/config.luac
./mojoluac $LUASTRIPOPT -o examples/ut3-dedicated/image/scripts/config.luac examples/ut3-dedicated/scripts/config.lua

# Fill in the rest of the Base Archive...
cd examples/ut3-dedicated
cp -R data/* image/data/

# Make a .zip archive of the Base Archive dirs and nuke the originals...
cd image
zip -9r ../pdata.zip *
cd ..
rm -rf image

# Append the .zip archive to the mojosetup binary, so it's "self-extracting."
cat pdata.zip >> ./mojosetup
rm -f pdata.zip

# Rename it, and we're good to go.
mv ./mojosetup UT3-linux-server-`date +%m%d%Y`.bin

# ...and that's that.
set +e
set +x
echo "Successfully built!"

if [ "$DEBUG" = "1" ]; then
    echo
    echo
    echo
    echo 'ATTENTION: THIS IS A DEBUG BUILD!'
    echo " DON'T DISTRIBUTE TO THE PUBLIC."
    echo ' THIS IS PROBABLY BIGGER AND SLOWER THAN IT SHOULD BE.'
    echo ' YOU HAVE BEEN WARNED!'
    echo
    echo
    echo
fi

exit 0

