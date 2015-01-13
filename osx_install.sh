#!/usr/bin/env bash

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
DEST="/Library/Application Support/kicad"
PREF="$HOME/Library/Preferences/kicad"
STARTUP="/etc/launchd.conf"

echo -e "\n"
echo "Create links - $DEST"
echo "===================="


echo "Creating Kicad directory"
sudo mkdir "$DEST"
chmod 774 "$DEST"

echo "Source directory is $SRC"
echo "Destination directory is $SRC"

echo "Create symlinks for library"
echo ln -s "$SRC/library" "$DEST/library"
ln -n -f -s "$SRC/library" "$DEST/library"

echo "Create symlinks for modules"
echo ln -s "$SRC/modules" "$DEST/modules"
ln -n -f -s "$SRC/modules" "$DEST/modules"

echo "Create symlinks for template"
echo ln -s "$SRC/template" "$DEST/template"
ln -n -f -s "$SRC/template" "$DEST/template"
# Bug: Default template path is /Applications/kicad.app/Contents/SharedSupport/template
# Fix:
if [ -d "/Applications/kicad.app/Contents/SharedSupport" ];
then
    echo "Patch kicad.app/Contents/SharedSupport/"
    TEMPLATE="/Applications/kicad.app/Contents/SharedSupport/template"
    if [[ -L "$TEMPLATE" && -d "$TEMPLATE" ]]
    then
        echo "$TEMPLATE is a symlink"
    else
        echo "Remove default $TEMPLATE dirs"
        rm -r "$TEMPLATE"
    fi 
    echo "Fix: Create symlinks for template in kicad.app"
    ln -n -f -s "$SRC/template" "$TEMPLATE"
else
    echo "/Applications/kicad.app/Contents/SharedSupport not found"
fi

echo -e "\n"
echo "Creating user's preferences directory"
echo "====================================="

mkdir "$PREF"

echo "Create symlinks for fp-lib-table"
ln -f -s "$SRC/template/fp-lib-table.for-pretty" "$PREF/fp-lib-table"

echo -e "\n"
echo "Fix KISYSMOD variable"
echo "====================="

if [ -f "$STARTUP" ];
then
    echo "File $STARTUP exist"
else
   echo "File $STARTUP doesn't exist."
   echo "Creating $STARTUP"
   sudo touch "$STARTUP"
fi

grep -w "KISYSMOD" "$STARTUP" > /dev/null

if [ $? -eq 0 ]
then
    echo "KISYSMOD is already set in $STARTUP"
else
    echo "Writing KISYSMOD to $STARTUP"
    echo "setenv KISYSMOD /Library/Application\ Support/kicad/modules"  \
    | sudo tee "$STARTUP"

fi

echo "SETENV KISYSMOD"
launchctl setenv KISYSMOD /Library/Application\ Support/kicad/modules

echo -e "\n"

bash "$SRC/modules_init.sh"

echo "   END   "
echo "========="
