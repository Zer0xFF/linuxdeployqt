#!/bin/bash

set -e

git clone https://github.com/NixOS/patchelf.git
cd patchelf
bash ./bootstrap.sh
./configure
make -j2
sudo make install

cd -

ARCH=`dpkg --print-architecture`
if [ "$ARCH" == "amd64" ]
then
	sudo add-apt-repository --yes ppa:beineri/opt-qt58-trusty
	sudo apt-get update -qq

	cd /tmp/
	wget -c "https://github.com/probonopd/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
	chmod +x appimagetool*AppImage
	./appimagetool*AppImage --appimage-extract
	sudo cp squashfs-root/usr/bin/* /usr/local/bin
	cd -

	sudo apt-get -y install qt58base qt58declarative qt58webengine binutils xpra

else
	sudo apt-get update -qq
	sudo apt install -y zlib1g zlib1g-dev
	cd /tmp/
	wget -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-aarch64.AppImage"
	chmod +x appimagetool*AppImage
	./appimagetool*AppImage --appimage-extract
	sudo cp squashfs-root/usr/bin/* /usr/local/bin/
	sudo cp -r squashfs-root/usr/lib/appimagekit /usr/local/lib/
	sudo chmod +rx /usr/local/lib/appimagekit
	cd -

	sudo apt install -y --no-install-recommends cmake gcc-5 g++-5 qt5-qmake pkg-config fuse file qtbase5-dev desktop-file-utils xpra
fi
