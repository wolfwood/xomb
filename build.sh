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

cd app/c/hello
make || exit
cd ../../..

cd app/c/simplymm
make || exit
cd ../../..

cd app/d/hello
./build || exit
cd ../../..

cd app/d/dynhello
./build || exit
cd ../../..

cd app/d/posix
./build || exit
cd ../../..

cd app/d/xsh
./build || exit
cd ../../..

cd app/d/init
./build || exit
cd ../../..


cd build
./build || exit

bochs -q
