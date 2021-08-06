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
    echo "${last_command} command failed with exit code $1."
  fi
}

# Check whether the current working tree is the same as what git is tracking
# Put in function so doesn't activate traps
check_is_same() {
  git --no-pager diff --exit-code --quiet
  echo $?
  return
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
    # SSH key set so use it

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

# rsync built docs into repo
cd ../repo
git checkout $5 #Checkout selected docs branch
rsync -a ../build/docs/html/* ./


# If working directory is different from git's tracking
if [ ! "$(check_is_same)" -eq 0 ]
then
	echo "Github Pages needs updating."

	# Add working tree to index, log status
	git add .
        git status
        echo "Should we push? $4"
        if [[ $4 =~ y|Y|yes|Yes|YES|true|True|TRUE|on|On|ON ]]
        then
                # DANGER AREA!
                # These commands modify the repo.

		echo "Pushing..."

                git config --global user.email "$GITHUB_ACTOR@users.noreply.github.com"
                git config --global user.name "Github Action"

                git commit -m "[Bot] Update gh-pages"
                git push
        fi

fi
