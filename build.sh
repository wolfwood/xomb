#!/bin/sh

mkdir -p build/root/binaries
mkdir -p build/iso/binaries

cd runtimes/mindrt
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
dsss clean && rm dsss.last && dsss build || exit
cd ../../..

cd app/d/posix
dsss clean && rm dsss.last && dsss build || exit
cd ../../..

cd app/d/xsh
dsss clean && rm dsss.last && dsss build || exit
cd ../../..

cd app/d/init
dsss clean && rm dsss.last && dsss build || exit
cd ../../..


cd build
dsss clean && rm dsss.last && dsss build || exit

bochs -q
