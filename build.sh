 #! /bin/bash

set -x
set -e

TEMP_BASE=/tmp

BUILD_DIR=$(mktemp -d -p "$TEMP_BASE" AppImageUpdate-build-XXXXXX)

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

# create basic structure
mkdir -p usr/{bin,lib,share/{applications,icons/hicolor/256x256/apps}}

# put OpenRCT2 binaries and resources into usr/bin/ for now
pushd usr/bin/

wget -O- "$url" | tar xz --strip-components=1

# move libraries in usr/lib/
mv *.so* ../lib/

popd

# install desktop file and icons
pushd usr/share/

# create desktop file
cat > applications/openrct2.desktop <<EOF
[Desktop Entry]
Name=OpenRCT2
Icon=openrct2
Exec=openrct2
Type=Application
Categories=Game;
EOF

# download icon
wget https://github.com/OpenRCT2/OpenRCT2/raw/develop/resources/logo/icon_x256.png -O icons/hicolor/256x256/apps/openrct2.png

popd
popd

# download linuxdeployqt
wget https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage

# extract AppImage to be able to run this script in a standard Docker container (which doesn't provide FUSE)
chmod +x linuxdeployqt-continuous-x86_64.AppImage
./linuxdeployqt-continuous-x86_64.AppImage --appimage-extract

EXTRA_LINUXDEPLOYQT_ARGUMENTS=

# make sure moved libraries are found
export LD_LIBRARY_PATH=$(readlink -f appdir/usr/lib/)

# bundle libraries with linuxdeployqt and generate AppImage
squashfs-root/AppRun appdir/usr/share/applications/openrct2.desktop -bundle-non-qt-libs -appimage $EXTRA_LINUXDEPLOYQT_ARGS

# move AppImage to original location
mv OpenRCT2*.AppImage "$ORIG_CWD"
