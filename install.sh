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

if [[ "$OSTYPE" == "darwin"* ]]; then
    DEST="/Library/Application Support/kicad"
    PREF="$HOME/Library/Preferences/kicad"
    STARTUP="/etc/launchd.conf"
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    DEST="/usr/share/kicad"
    PREF="$HOME/.config/kicad"
elif [[ "$OSTYPE" == "msys" ]]; then
    DEST='/C/PROGRA~1/KiCad/share/kicad'
    PREF="$HOME/AppData/Roaming/kicad"

    # Fake sudo
    echo "#!/usr/bin/bash" > sudo
    echo "\$@" >> sudo
    chmod +x sudo
    PATH=$PATH:$PWD
else
    echo "Not supported OS"
    exit 1
fi

echo "Kicad library install script"

echo -e "\n"

echo "This script link some folder from /usr/share/kicad or OSX equivalent"
echo "to this git repo"

echo -e "\n"

echo "Warning: This script don't work if"
echo "modules, template or library exist in"
echo "$DEST"

sleep 2

echo -e "\n"
echo "Create links - $DEST"
echo "===================="

echo "Creating Kicad directory"
sudo mkdir "$DEST"
sudo chmod 775 "$DEST"

echo "Source directory is $SRC"
echo "Destination directory is $SRC"

echo "Create symlinks for library"
echo ln -s "$SRC/library" "${DEST}/library"
sudo ln -n -f -s "$SRC/library" "${DEST}/library"

echo "Create symlinks for modules"
echo ln -s "$SRC/modules" "${DEST}/modules"
sudo ln -n -f -s "$SRC/modules" "${DEST}/modules"

echo "Create symlinks for template"
echo ln -s "$SRC/template" "${DEST}/template"
sudo ln -n -f -s "$SRC/template" "${DEST}/template"

echo -e "\n"
echo "Creating user's preferences directory"
echo "====================================="

mkdir "$PREF"

echo "Create symlinks for fp-lib-table"
ln -f -s "$SRC/template/fp-lib-table.for-pretty" "$PREF/fp-lib-table"

if [[ "$OSTYPE" == "darwin"* ]]; then
    bash $SRC/osx_patch.sh
fi

echo -e "\n"
echo "Patching git"
echo "====================================="

GIT_EXCLUDE="$SRC/.git/info/exclude"

if [ -f "$GIT_EXCLUDE" ];
then
    echo "File $GIT_EXCLUDE exist"
else
   echo "File $GIT_EXCLUDE doesn't exist."
   echo "Creating $GIT_EXCLUDE"
   sudo touch "$GIT_EXCLUDE"
fi

grep "^modules/\*\.pretty$" "$GIT_EXCLUDE" > /dev/null
if [ $? -eq 0 ]
then
    echo "$GIT_EXCLUDE already patched"
else
    echo "Patching $GIT_EXCLUDE"
    echo -e "*.bck\n*.bak\nmodules/*.pretty\n"  \
    | tee "$GIT_EXCLUDE"

fi

echo -e "\n"

#bash "$SRC/modules_init.sh"

echo "   END   "
echo "========="
