#! /bin/bash

set -x
set -e

TEMP_BASE=/tmp

BUILD_DIR=$(mktemp -d -p "$TEMP_BASE" openrct2-appimage-build-XXXXXX)

cleanup () {
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
}

trap cleanup EXIT

# store repo root as variable
REPO_ROOT=$(readlink -f $(dirname $(dirname $0)))
ORIG_CWD=$(readlink -f .)

pushd "$BUILD_DIR"

# fetch URL to latest build
url=$(wget -qO- http://openrct2.org/downloads/master/latest | sed 's/"/\n/g' | grep linux-x86_64.tar.gz | egrep '^http')

export VERSION=$(echo "$url" | sed 's/OpenRCT2-/\n/g' | grep linux-x86_64.tar.gz | sed 's/-linux-x86_64.tar.gz/\n/g' | head -n1)
# extract version number from URL

# create appdir
mkdir appdir/
pushd appdir/

# put OpenRCT2 binaries and resources into usr/bin/ for now
mkdir -p usr/bin/
pushd usr/bin/

wget -O- "$url" | tar xz --strip-components=1

popd
popd

# create desktop file
cat > openrct2.desktop <<EOF
[Desktop Entry]
Name=OpenRCT2
Icon=openrct2
Exec=openrct2
Type=Application
Categories=Game;
EOF

# download icon
wget https://github.com/OpenRCT2/OpenRCT2/raw/develop/resources/logo/icon_x256.png -O openrct2.png

# download linuxdeploy
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage

chmod +x linuxdeploy*-x86_64.AppImage

export UPD_INFO="gh-releases-zsync|TheAssassin|openrct2-appimage|continuous|OpenRCT2*.AppImage.zsync"
#export LD_LIBRARY_PATH=appdir/usr/bin/usr/lib
#bash
./linuxdeploy-x86_64.AppImage --appimage-extract-and-run --appdir appdir -i openrct2.png -d openrct2.desktop --output appimage

# move AppImage to original location
mv OpenRCT2*.AppImage* "$ORIG_CWD"
