#!/bin/sh

cd app/d/init
dsss clean
rm dsss.last
dsss build || exit
cd ../../..


cd build
./buildiso.sh

bochs -q
