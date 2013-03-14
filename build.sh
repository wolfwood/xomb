#!/bin/sh

mkdir -p build/root/binaries
mkdir -p build/iso/binaries

cd runtimes/mindrt
rm -r dsss* *.a
make || exit
cd ../..

cd runtimes/dyndrt
rm -r dsss* *.a
make || exit
cd ../..

cd user/c
make || exit
cd ../..

cd ../buildtools
./embedlibs.sh
cd -

cd app/c/hello
make || exit
cd ../../..

cd app/c/simplymm
make || exit
cd ../../..

cd app/d/hello
rm -r objs
./build || exit
cd ../../..

cd app/d/nettest
rm -r objs
./build || exit
cd ../../..

cd app/d/dynhello
rm -r objs
./build || exit
cd ../../..

cd app/d/posix
rm -r objs
./build || exit
cd ../../..

cd app/d/xsh
rm -r objs
./build || exit
cd ../../..

cd app/d/init
rm -r objs
./build || exit
cd ../../..


cd build
./veryclean
./build || exit

bochs -q
