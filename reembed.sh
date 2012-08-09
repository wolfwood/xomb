#!/bin/sh

cd app/d/init
rm -r objs
./build || exit
cd ../../..


cd build
./makeiso

#bochs -q
cd ..
#./run.sh --sata
