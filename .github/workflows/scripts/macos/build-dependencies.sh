#!/bin/bash

set -e

if [ "$GUI" == "Qt" ]; then
	export MACOSX_DEPLOYMENT_TARGET=10.14
else
	export MACOSX_DEPLOYMENT_TARGET=10.13
fi
INSTALLDIR="$HOME/deps"
NPROCS="$(getconf _NPROCESSORS_ONLN)"
SDL=SDL2-2.24.0
PNG=1.6.37
JPG=9e
SAMPLERATE=libsamplerate-0.1.9
PORTAUDIO=pa_stable_v190700_20210406
SOUNDTOUCH=soundtouch-2.3.1
WXWIDGETS=3.1.6
QT=6.3.1

mkdir deps-build
cd deps-build

export PKG_CONFIG_PATH="$INSTALLDIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export LDFLAGS="-L$INSTALLDIR/lib -dead_strip $LDFLAGS"
export CFLAGS="-I$INSTALLDIR/include -Os $CFLAGS"
export CXXFLAGS="-I$INSTALLDIR/include -Os $CXXFLAGS"

cat > SHASUMS <<EOF
91e4c34b1768f92d399b078e171448c6af18cafda743987ed2064a28954d6d97  $SDL.tar.gz
505e70834d35383537b6491e7ae8641f1a4bed1876dbfe361201fc80868d88ca  libpng-$PNG.tar.xz
4077d6a6a75aeb01884f708919d25934c93305e49f7e3f36db9129320e6f4f3d  jpegsrc.v$JPG.tar.gz
0a7eb168e2f21353fb6d84da152e4512126f7dc48ccb0be80578c565413444c1  $SAMPLERATE.tar.gz
47efbf42c77c19a05d22e627d42873e991ec0c1357219c0d74ce6a2948cb2def  $PORTAUDIO.tgz
6900996607258496ce126924a19fe9d598af9d892cf3f33d1e4daaa9b42ae0b1  $SOUNDTOUCH.tar.gz
4980e86c6494adcd527a41fc0a4e436777ba41d1893717d7b7176c59c2061c25  wxWidgets-$WXWIDGETS.tar.bz2
0a64421d9c2469c2c48490a032ab91d547017c9cc171f3f8070bc31888f24e03  qtbase-everywhere-src-$QT.tar.xz
7b19f418e6f7b8e23344082dd04440aacf5da23c5a73980ba22ae4eba4f87df7  qtsvg-everywhere-src-$QT.tar.xz
c412750f2aa3beb93fce5f30517c607f55daaeb7d0407af206a8adf917e126c1  qttools-everywhere-src-$QT.tar.xz
d7bdd55e2908ded901dcc262157100af2a490bf04d31e32995f6d91d78dfdb97  qttranslations-everywhere-src-$QT.tar.xz
EOF

curl -L \
	-O "https://libsdl.org/release/$SDL.tar.gz" \
	-O "https://downloads.sourceforge.net/project/libpng/libpng16/$PNG/libpng-$PNG.tar.xz" \
	-O "https://www.ijg.org/files/jpegsrc.v$JPG.tar.gz" \
	-O "http://www.mega-nerd.com/SRC/$SAMPLERATE.tar.gz" \
	-O "http://files.portaudio.com/archives/$PORTAUDIO.tgz" \
	-O "https://www.surina.net/soundtouch/$SOUNDTOUCH.tar.gz" \
	-O "https://github.com/wxWidgets/wxWidgets/releases/download/v$WXWIDGETS/wxWidgets-$WXWIDGETS.tar.bz2" \
	-O "https://download.qt.io/official_releases/qt/${QT%.*}/$QT/submodules/qtbase-everywhere-src-$QT.tar.xz" \
	-O "https://download.qt.io/official_releases/qt/${QT%.*}/$QT/submodules/qtsvg-everywhere-src-$QT.tar.xz" \
	-O "https://download.qt.io/official_releases/qt/${QT%.*}/$QT/submodules/qttools-everywhere-src-$QT.tar.xz" \
	-O "https://download.qt.io/official_releases/qt/${QT%.*}/$QT/submodules/qttranslations-everywhere-src-$QT.tar.xz" \

shasum -a 256 --check SHASUMS

echo "Installing SDL..."
tar xf "$SDL.tar.gz"
cd "$SDL"
./configure --prefix "$INSTALLDIR" --without-x
make "-j$NPROCS"
make install
cd ..

echo "Installing libpng..."
tar xf "libpng-$PNG.tar.xz"
cd "libpng-$PNG"
./configure --prefix "$INSTALLDIR" --disable-dependency-tracking
make "-j$NPROCS"
make install
cd ..

echo "Installing libjpeg..."
tar xf "jpegsrc.v$JPG.tar.gz"
cd "jpeg-$JPG"
./configure --prefix "$INSTALLDIR" --disable-dependency-tracking
make "-j$NPROCS"
make install
cd ..

echo "Installing libsamplerate..."
tar xf "$SAMPLERATE.tar.gz"
cd "$SAMPLERATE"
sed -i "" "s/Carbon.h/Carbon\\/Carbon.h/" examples/audio_out.c
./configure --prefix "$INSTALLDIR" --disable-dependency-tracking --disable-sndfile
make "-j$NPROCS"
make install
cd ..

echo "Installing portaudio..."
tar xf "$PORTAUDIO.tgz"
cd portaudio
./configure --prefix "$INSTALLDIR" --enable-mac-universal=no
make "-j$NPROCS"
make install
cd ..

echo "Installing soundtouch..."
tar xf "$SOUNDTOUCH.tar.gz"
cd "$SOUNDTOUCH"
cmake -B build -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DCMAKE_BUILD_TYPE=MinSizeRel
make -C build "-j$NPROCS"
make -C build install
cd ..

if [ "$GUI" == "wxWidgets" ]; then
	echo "Installing wx..."
	tar xf "wxWidgets-$WXWIDGETS.tar.bz2"
	cd "wxWidgets-$WXWIDGETS"
	./configure --prefix "$INSTALLDIR" --with-macosx-version-min="$MACOSX_DEPLOYMENT_TARGET" --enable-clipboard --enable-dnd --enable-std_string --with-cocoa --with-libiconv --with-libjpeg --with-libpng --with-zlib --without-libtiff --without-regex
	make "-j$NPROCS"
	make install
	cd ..
fi

if [ "$GUI" == "Qt" ]; then
	echo "Installing Qt Base..."
	tar xf "qtbase-everywhere-src-$QT.tar.xz"
	cd "qtbase-everywhere-src-$QT"
	cmake -B build -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DCMAKE_BUILD_TYPE=Release -DFEATURE_optimize_size=ON -DFEATURE_dbus=OFF -DFEATURE_framework=OFF -DFEATURE_icu=OFF -DFEATURE_opengl=OFF -DFEATURE_printsupport=OFF -DFEATURE_sql=OFF
	make -C build "-j$NPROCS"
	make -C build install
	cd ..
	echo "Installing Qt SVG..."
	tar xf "qtsvg-everywhere-src-$QT.tar.xz"
	cd "qtsvg-everywhere-src-$QT"
	cmake -B build -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DCMAKE_BUILD_TYPE=MinSizeRel
	make -C build "-j$NPROCS"
	make -C build install
	cd ..
	echo "Installing Qt Tools..."
	tar xf "qttools-everywhere-src-$QT.tar.xz"
	cd "qttools-everywhere-src-$QT"
	# Linguist relies on a library in the Designer target, which takes 5-7 minutes to build on the CI
	# Avoid it by not building Linguist, since we only need the tools that come with it
	patch -u src/linguist/CMakeLists.txt <<EOF
--- src/linguist/CMakeLists.txt
+++ src/linguist/CMakeLists.txt
@@ -14,7 +14,7 @@
 add_subdirectory(lrelease-pro)
 add_subdirectory(lupdate)
 add_subdirectory(lupdate-pro)
-if(QT_FEATURE_process AND QT_FEATURE_pushbutton AND QT_FEATURE_toolbutton AND TARGET Qt::Widgets AND NOT no-png)
+if(QT_FEATURE_process AND QT_FEATURE_pushbutton AND QT_FEATURE_toolbutton AND TARGET Qt::Widgets AND TARGET Qt::PrintSupport AND NOT no-png)
     add_subdirectory(linguist)
 endif()
EOF
	cmake -B build -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DCMAKE_BUILD_TYPE=Release -DFEATURE_assistant=OFF -DFEATURE_clang=OFF -DFEATURE_designer=OFF -DFEATURE_kmap2qmap=OFF -DFEATURE_pixeltool=OFF -DFEATURE_pkg_config=OFF -DFEATURE_qev=OFF -DFEATURE_qtattributionsscanner=OFF -DFEATURE_qtdiag=OFF -DFEATURE_qtplugininfo=OFF
	make -C build "-j$NPROCS"
	make -C build install
	cd ..
	echo "Installing Qt Translations..."
	tar xf "qttranslations-everywhere-src-$QT.tar.xz"
	cd "qttranslations-everywhere-src-$QT"
	cmake -B build -DCMAKE_PREFIX_PATH="$INSTALLDIR" -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" -DCMAKE_BUILD_TYPE=Release
	make -C build "-j$NPROCS"
	make -C build install
	cd ..
fi

echo "Cleaning up..."
cd ..
rm -r deps-build
