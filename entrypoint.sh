#!/bin/bash -l

# Exit when any command fails
set -e

# Keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG


# Trap right before exiting
trap 'catch $? $LINENO' EXIT
catch() {
  # If last exit code was erroneous
  if [ "$1" != "0" ]; then
    # error handling goes here
    echo "${last_command} command failed with exit code $1."
  fi
}

# Setup repo workspace
mkdir -p repo
cd repo

# If SSH key not set, use token
if [ -z "$2" ]
then

    #Add extra http header telling Github what our auth token is
    git config --global http.https://github.com/.extraheader "$3"

    # Clone using HTTPS
    git clone https://github.com/$1.git .
else
    # Not using token, so use SSH instead

    # Setup SSH
    mkdir -p ~/.ssh -m 700
    echo $2 > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    #echo "SSH ID:"
    #cat ~/.ssh/id_rsa

    eval "$(ssh-agent)"

    ssh-add ~/.ssh/id_rsa
    ssh-add -l -E sha256

    # Clone using SSH
    git clone git@github.com:$1 .
fi

# Debug info about repo contents
echo "Contents:"
ls -al

# Create build dir outside repo and cd to it
mkdir -p ../build
cd ../build

# Build docs, assuming the CMakeLists.txt is using CMinx
cmake ../repo -DBUILD_DOCS=ON
make docs

# rsync built docs into repo, show diff for debug
cd ../repo
git checkout gh-pages
rsync -a ../build/docs/html/* ./
git --no-pager diff
