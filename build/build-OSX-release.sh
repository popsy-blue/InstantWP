#!/bin/bash

echo ----------------------------
echo OSX IWP Release Build Script
echo ----------------------------
cd "${0%/*}"


# get the version numbers
read IWP_VERSION < ./IWP_VERSION.txt
read VM_VERSION < ./VM_VERSION.txt

# set constants
mkdir ../release
REL_ROOT=../release
SOURCE_DIR=../../InstantWP-Next-Generation
VM_FILE="$VM_VERSION".qcow2

# set release root
REL_DIR=$REL_ROOT/IWP-"$IWP_VERSION"-macOS

echo Installing perl dependencies
cpanm Config::INI
cpanm Proc::ProcessTable
cpanm Proc::Terminator
cpanm Term::Spinner

#for iwpcli
cpanm Proc::Background

#for ssh perl script
cpanm IO::Stty
cpanm Expect

#for Telnet perl script
cpanm Net::Telnet

echo Making release directory $REL_DIR
mkdir $REL_DIR/

echo Making build directories...
mkdir $REL_DIR/bin
mkdir $REL_DIR/config
mkdir $REL_DIR/docs
mkdir $REL_DIR/docs/images
mkdir $REL_DIR/platform
mkdir $REL_DIR/vm
mkdir $REL_DIR/controlpanel

echo Building perl applications...

echo Building iwp
pp --compile --output=$REL_DIR/bin/iwp --lib=$SOURCE_DIR/core/lib  $SOURCE_DIR/core/bin/iwp.pm
echo Building ssh-term
pp --compile --output=$REL_DIR/bin/ssh-term --lib=$SOURCE_DIR/core/lib  $SOURCE_DIR/core/bin/ssh-term.pm
echo Building iwpcli
pp --compile --output=$REL_DIR/iwpcli --lib=$SOURCE_DIR/core/lib  $SOURCE_DIR/core/iwpcli.pm
echo Building IWPQEMUTelnet
pp --compile --output=$REL_DIR/platform/osx/IWPQEMUTelnet  $SOURCE_DIR/components/IWPQEMUTelnetMac/IWPQEMUTelnet.pm

echo Copying files...

# startup files
#cp $SOURCE_DIR/core/iwpcli $REL_DIR/
cp $SOURCE_DIR/core/Start-InstantWP $REL_DIR/
cp $SOURCE_DIR/core/ReadMe/ReadMe-First-macOS.html $REL_DIR/

# bin directory
#cp $SOURCE_DIR/core/bin/iwp $REL_DIR/bin/
#cp $SOURCE_DIR/core/bin/ssh-term $REL_DIR/bin/
cp $SOURCE_DIR/core/bin/run-iwpcli $REL_DIR/bin/
cp $SOURCE_DIR/core/bin/startIWP $REL_DIR/bin/

# config directory
cp $SOURCE_DIR/core/config/iwp-osx.ini $REL_DIR/config/

# doc directory
cp $SOURCE_DIR/core/docs/about.html $REL_DIR/docs
cp $SOURCE_DIR/core/docs/documentation.html $REL_DIR/docs/
cp $SOURCE_DIR/core/docs/InstantWP-User-Guide.pdf $REL_DIR/docs/
cp $SOURCE_DIR/core/docs/LICENSE.txt $REL_DIR/LICENSE.txt
cp -R $SOURCE_DIR/core/docs/images $REL_DIR/docs/

# control panel dir
cp -R $SOURCE_DIR/core/controlpanel/distribute/InstantWP.app $REL_DIR/controlpanel/
cp -R $SOURCE_DIR/core/images $REL_DIR/images
cp $SOURCE_DIR/core/controlpanel/start-ui $REL_DIR/controlpanel/

# platform directory
cp -R $SOURCE_DIR/core/platform/osx $REL_DIR/platform/

# vm directory
cp $SOURCE_DIR/core/vm/$VM_FILE $REL_DIR/vm

# update the version numbers
perl -pi -e "s/IWP_VERSION/$IWP_VERSION/g" $REL_DIR/docs/about.html 
perl -pi -e "s/IWP_VERSION/$IWP_VERSION/g" $REL_DIR/config/iwp-osx.ini
perl -pi -e "s/VM_VERSION/$VM_VERSION/g" $REL_DIR/config/iwp-osx.ini


echo Done!


