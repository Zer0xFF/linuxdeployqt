#!/bin/bash

set -x

ARCH=`dpkg --print-architecture`
if [ "$ARCH" == "amd64" ]
then

source /opt/qt*/bin/qt*-env.sh
/opt/qt*/bin/qmake CONFIG+=release CONFIG+=force_debug_info linuxdeployqt.pro
# make -j$(nproc) # Not doing here but below with "pvs-tool trace"

# Test
wget -q -O - http://files.viva64.com/etc/pubkey.txt | sudo apt-key add -
sudo wget -O /etc/apt/sources.list.d/viva64.list http://files.viva64.com/etc/viva64.list
sudo apt-get update
sudo apt-get -y install --no-install-recommends pvs-studio
pvs-studio-analyzer credentials probono@puredarwin.org $PVS_KEY -o ./licence.lic
pvs-studio-analyzer trace -- make -j$(nproc)
pvs-studio-analyzer analyze -e /opt -e /usr -o pvs-studio.log -j $(nproc) -l ./licence.lic
plog-converter -a GA:1,2 -t tasklist -o pvs-studio-report.txt pvs-studio.log
rm ./licence.lic

else

export CXX="g++-5" CC="gcc-5" QMAKE_CC="gcc-5" QMAKE_CXX="g++-5" ;
export QT_SELECT=qt5
qmake CONFIG+=release CONFIG+=force_debug_info linuxdeployqt.pro

make -j$(nproc) CXX="g++-5" CC="gcc-5"

fi

# exit on failure
set -e
mkdir -p linuxdeployqt.AppDir/usr/{bin,lib}
cp /usr/local/bin/{desktop-file-validate,appimagetool,patchelf,zsyncmake} linuxdeployqt.AppDir/usr/bin/
./bin/linuxdeployqt --version
cp ./bin/linuxdeployqt linuxdeployqt.AppDir/usr/bin/
cp -r /usr/local/lib/appimagekit linuxdeployqt.AppDir/usr/lib/
chmod +x linuxdeployqt.AppDir/AppRun
find linuxdeployqt.AppDir/
ldd linuxdeployqt.AppDir/usr/bin/*
export VERSION=continuous
if [ ! -z $TRAVIS_TAG ] ; then export VERSION=$TRAVIS_TAG ; fi
./bin/linuxdeployqt linuxdeployqt.AppDir/linuxdeployqt.desktop -verbose=3 -appimage \
    -executable=linuxdeployqt.AppDir/usr/bin/desktop-file-validate || echo "ignore"
ls -lh
find *.AppDir
xpra start :99

export DISPLAY=:99

until xset -q
do
        echo "Waiting for X server to start..."
        sleep 1;
done

# enable core dumps
# echo "/tmp/coredump" | sudo tee /proc/sys/kernel/core_pattern

# ulimit -c unlimited
# ulimit -a -S
# ulimit -a -H

# error handling performed separately
set +e

# print version number
gdb -ex=r -ex="bt full" ./linuxdeployqt-*.AppImage --version

# TODO: reactivate tests
#bash -e tests/tests.sh
true
RESULT=$?

curl --upload-file linuxdeployqt-*.AppImage https://madnation.net/transfer.php/linuxdeployqt/linuxdeployqt-continuous-$ARCH.AppImage

if [ $RESULT -ne 0 ]; then
  echo "FAILURE: linuxdeployqt CRASHED -- uploading files for debugging to transfer.sh"
  set -v
  [ -e /tmp/coredump ] && curl --upload-file /tmp/coredump https://transfer.sh/coredump
  find -type f -iname 'libQt5Core.so*' -exec curl --upload {} https://transfer.sh/libQt5Core.so \; || true
  exit $RESULT
fi
