#!/bin/sh

# c_library repository update script
# Author: Thomas Gubler <thomasgubler@gmail.com>
#
# This script can be used together with a github webhook to automatically
# generate new c header files and push to the c_library repository whenever
# the message specifications are updated.
# The script assumes that the git repositories in MAVLINK_GIT_PATH and
# CLIBRARY_GIT_PATH are set up prior to invoking the script.
#
# Usage, for example:
# cd ~/src
# git clone git@github.com:mavlink/mavlink.git
# cd mavlink
# git remote rename origin upstream
# mkdir -p include/mavlink/v1.0
# cd include/mavlink/v1.0
# git clone git@github.com:mavlink/c_library.git .
# cd ~/src/mavlink
# ./scripts/update_c_library.sh

# settings
MAVLINK_PATH=$PWD
MAVLINK_GIT_REMOTENAME=upstream
MAVLINK_GIT_BRANCHNAME=master
CLIBRARY_PATH=$MAVLINK_PATH/include/mavlink/v1.0/
CLIBRARY_GIT_REMOTENAME=origin
CLIBRARY_GIT_BRANCHNAME=master

# fetch latest message specifications
echo "Fetching latest protocol specifications"
cd $MAVLINK_PATH
git pull $MAVLINK_GIT_REMOTENAME $MAVLINK_GIT_BRANCHNAME || exit 1

# save git hash
MAVLINK_GITHASH=$(git rev-parse @)

# delete old c headers
rm -rf $CLIBRARY_PATH/*

# generate new c headers
echo "start to generate c headers"
python2 pymavlink/generator/mavgen.py \
    --output $CLIBRARY_PATH \
    --lang C \
    message_definitions/v1.0/common.xml
echo "finished generating c headers"

# git add and git commit in local c_library repository
cd $CLIBRARY_PATH
git add -A || exit 1
COMMIT_MESSAGE="autogenerated headers for "$MAVLINK_GITHASH
git commit -m "$COMMIT_MESSAGE" || exit 1

# push to c_library repository
git push $CLIBRARY_GIT_REMOTENAME $CLIBRARY_GIT_BRANCHNAME || exit 1
echo "headers updated and pushed successfully"
