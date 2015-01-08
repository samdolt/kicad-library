#!/usr/bin/env bash

# Download official Git repo of pretty modules
# From : https://github.com/johnbeard/kicad_pretties

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    TARGET="$(readlink "$SOURCE")"
    if [[ $SOURCE == /* ]]; then
        echo "SOURCE '$SOURCE' is an absolute symlink to '$TARGET'"
        SOURCE="$TARGET"
    else
        DIR="$( dirname "$SOURCE" )"
        echo "SOURCE '$SOURCE' is a relative symlink to '$TARGET' (relative to '$DIR')"
        SOURCE="$DIR/$TARGET" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    fi
done
SRC="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
ORIGINAL_PWD=`pwd`

cd "$SRC"

echo -e "\n"
echo "Init footprints libraries (Git submodules)"
echo "========================================="
git submodule init
git submodule update

echo -e "\n"
echo "Search and clone new footprints libs"
echo "===================================="
KYGITHUB="https://github.com/KiCad"

githubUser="KiCad"

cat  "$SRC/template/fp-lib-table.for-github" \
| grep "name" \
| cut -d ' ' -f 5 \
| cut -d ')' -f 1 \
| xargs -I SM git submodule add git://github.com/${githubUser}/SM.pretty.git modules/SM.pretty


echo -e "\n"
echo "Upgrade footprints libraries"
echo "============================"
git submodule foreach git pull

cd "$ORIGINAL_PWD"
