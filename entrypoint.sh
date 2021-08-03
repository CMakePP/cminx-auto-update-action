#!/bin/sh -l

mkdir -p ~/.ssh -m 700
echo $2 > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
#echo "SSH ID:"
#cat ~/.ssh/id_rsa

eval "$(ssh-agent)"

ssh-add
ssh-add -l -E sha256

mkdir -p repo
cd repo
git clone git@github.com:$1 .
echo Contents
ls -al
mkdir -p build
cd build
cmake .. -DBUILD_DOCS=ON
make docs
cd ..
git checkout gh-pages
rsync -a build/docs/html/* ./
ls -al
