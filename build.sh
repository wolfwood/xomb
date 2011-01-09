#!/bin/sh
cd runtimes/mindrt
make
cd ../..

cd app/d/posix
dsss clean && dsss build
cd ../../..

cd app/d/xsh
dsss clean && dsss build
cd ../../..

cd app/d/init
dsss clean && dsss build
cd ../../..


cd build
dsss clean && dsss build

bochs -q
