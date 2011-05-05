#!/bin/sh

mkdir -p build/root/binaries
mkdir -p build/iso/binaries

cd runtimes/mindrt
make || exit
cd ../..

cd user/c
make || exit
cd ../..


cd app/c/hello
make || exit
cd ../../..

cd app/d/hello
dsss clean && dsss build || exit
cd ../../..

cd app/d/posix
dsss clean && dsss build || exit
cd ../../..

cd app/d/xsh
dsss clean && dsss build || exit
cd ../../..

cd app/d/init
dsss clean && dsss build || exit
cd ../../..


cd build
dsss clean && dsss build || exit

bochs -q
