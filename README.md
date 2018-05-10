# AppImages for OpenRCT2

This repository contains scripts that can be used to build AppImages from the
Linux tarballs the OpenRCT2 project provides.

The script automatically fetches the latest stable version by parsing the
project website, builds an AppDir from it, and then generates an AppImage
using [linuxdeployqt](https://github.com/probonopd/linuxdeployqt).
