#!/bin/bash

set -e

git config --global user.email "you@example.com"
git config --global user.name "Your Name"

git clone https://github.com/NixOS/patchelf
cd patchelf
git checkout 21a85cc
git cherry-pick 2b3c9602e710a92f5ab2c6f0a6143fc382aca724
git cherry-pick 2b3c9602e710a92f5ab2c6f0a6143fc382aca724...20ccc36b9cdb4119fe326724bfee70d1619e31ee
bash ./bootstrap.sh
./configure
make -j2
sudo make install

cd -
cd /tmp/

ARCH=`dpkg --print-architecture`
if [ "$ARCH" == "amd64" ]
then
	sudo add-apt-repository --yes ppa:beineri/opt-qt58-trusty
	sudo apt-get update -qq
	wget -c "https://github.com/probonopd/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"

	sudo apt-get -y install qt58base qt58declarative qt58webengine binutils xpra

else
	sudo apt-get update -qq
	sudo apt install -y zlib1g zlib1g-dev
	wget -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-aarch64.AppImage"

	sudo apt install -y --no-install-recommends cmake gcc-5 g++-5 qt5-qmake pkg-config fuse file qtbase5-dev desktop-file-utils xpra
fi

chmod +x appimagetool*AppImage
./appimagetool*AppImage --appimage-extract
sudo cp squashfs-root/usr/bin/* /usr/local/bin/
sudo cp -r squashfs-root/usr/lib/appimagekit /usr/local/lib/
sudo chmod +rx /usr/local/lib/appimagekit
cd -
